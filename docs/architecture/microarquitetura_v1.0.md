# Microarquitetura v1.0

Projeto: MiniSoC AES (AES-128 + SPI). Referencias: Block Guide MiniSoC AES v1.0.0 e FIPS-197.

O Block Guide ja define as interfaces de topo, os nomes dos modulos e o mapa de registradores. Aqui fica
como eu vou implementar o AES por dentro, a FSM do `minisoc_aes_top`, o CDC e o reset.

## 1. Diagrama de blocos

```
 spi_sclk                 clk (always-on)                     sys_clk (PLL)
+-------------+       +---------------------+       +-----------------------------------+
| minisoc_spi | ----> | banco de regs       | ----> | minisoc_aes_top                   |
| shift 40b   | toggle| KEY, IV, CONTROL... | START |   FSM                             |
+-------------+       +---------------------+       |   minisoc_aes_key_exp  (11 chaves) |
                        |                           |   minisoc_aes_dp       (rodadas)   |
                        v                           +-----------------------------------+
                      minisoc_pll  --- sys_clk --->            |  mem_i_* / mem_o_data
                                                               v
                                                        memoria 1024x32
```

Dentro do `minisoc_aes_top`:

```
            rnd_o (0..10)
 key_exp <--------------- dp
         --------------->
            rk_o
```

O `dp` nao guarda chave nenhuma, ele pede o indice da chave em `rnd_o` e o `key_exp` devolve em `rk_o`.

## 2. Estado

Byte 0 em `[127:120]` e byte 15 em `[7:0]`, igual ao Block Guide (Word 0 = `[127:96]`). O byte n e `s[n%4][n/4]`,
entao cada coluna do estado e uma Word de 32 bits da memoria.

## 3. Arquitetura do AES

Escolhi a iterativa de 128 bits com uma rodada por ciclo.

| Opcao | Ciclos por bloco | S-boxes | Comentario |
|---|---|---|---|
| Serial 8 bits | ~160 | 1 | menor area, mas muito lenta para 256 blocos |
| Serial 32 bits | ~40 | 4 | controle mais complicado |
| Iterativa 128 bits (escolhida) | 11 | 16 + 16 inversas + 4 | controle simples |
| Desenrolada | 1 (pipeline) | 160 | area muito grande |

O caminho critico e state -> S-box -> MixColumns -> XOR -> state. A 2 GHz isso pode nao fechar. Se a sintese
(semana 8) nao fechar, divido a rodada em 2 ciclos sem mudar as portas dos modulos.

## 4. Datapath (`minisoc_aes_dp`)

- Ciclo do start: `state = bloco ^ K0` na cifra ou `bloco ^ K10` na decifra.
- Rodadas 1 a 10, uma por ciclo:
  - cifra: SubBytes, ShiftRows, MixColumns, AddRoundKey com K1..K10
  - decifra (cifra inversa da FIPS-197 5.3): InvShiftRows, InvSubBytes, AddRoundKey com K9..K0, InvMixColumns
  - na rodada 10 um mux pula o (Inv)MixColumns
- Interface start/done: `done_o` pulsa 11 ciclos depois do `start_i`.

| Modulo | Como foi feito |
|---|---|
| sbox / inv_sbox | tabela de 256 posicoes |
| shift_rows / inv_shift_rows | so troca de fios |
| mix_columns | xtime (x2) e x3 = x2 ^ x |
| inv_mix_columns | pre-passo com x4 e depois o proprio MixColumns |
| add_round_key | XOR de 128 bits, serve nos dois sentidos |

## 5. Expansao de chave (`minisoc_aes_key_exp`)

Pre-computada. No start guarda K0 e calcula uma chave por ciclo com 4 S-boxes (RotWord, SubWord, XOR com Rcon).
Depois de 11 ciclos `ready_o` sobe e as 11 chaves ficam em registradores.

| | Pre-computada (escolhida) | On-the-fly |
|---|---|---|
| Flip-flops | 11 x 128 = 1408 | 128 |
| Decifra | le K10..K0 direto pelo indice | precisa chegar ate K10 e ter a expansao inversa |
| Varios blocos | expande uma vez para ate 256 blocos | refaz a cada bloco |

O custo e a area dos 1408 FFs. Como o banco so e escrito durante a expansao, ele e candidato a clock gating na
semana 12.

## 6. FSM do `minisoc_aes_top`

Fica no `sys_clk`. No START captura KEY, IV, COUNTER, modo, sentido e NUM_BLOCKS. Cada bloco e lido da memoria,
processado e escrito no mesmo endereco.

```
IDLE --START--> CHECK --erro--> ERROR --> IDLE
                  | ok
                  v
               KEY_EXP --ready--> READ --4 words--> RUN --done--> WRITE --+--> mais blocos: READ
                                                                          +--> ultimo: DONE --> IDLE
```

| Estado | O que faz |
|---|---|
| IDLE | BUSY = 0, espera START |
| CHECK | testa NUM_BLOCKS (1..256) e o modo |
| KEY_EXP | da start no key_exp e espera ready |
| READ | le as 4 words do bloco |
| RUN | da start no dp e espera done. Em CBC/CTR etc. faz o XOR com IV ou contador antes/depois |
| WRITE | escreve as 4 words no mesmo endereco e atualiza IV/contador |
| DONE | seta DONE no AES_STATUS |

Cada bloco gasta mais ou menos 4 + 11 + 4 = 19 ciclos. A expansao (11 ciclos) e feita uma vez por operacao.

## 7. Clocks e CDC

| Dominio | De onde vem | O que roda |
|---|---|---|
| spi_sclk | mestre SPI | shift register de 40 bits, contador de bits, MISO |
| clk | oscilador (always-on) | banco de registradores, controle do PLL |
| sys_clk | PLL | minisoc_aes_top, key_exp, dp, acesso a memoria |

spi_sclk -> clk (secao 5.3 do Block Guide, toggle):
1. No fim dos 40 bits o frame vai para um registrador de hold e um bit de toggle inverte.
2. O toggle passa por 2 FFs no clk. Um XOR com o valor anterior gera um pulso de "frame pronto".
3. O frame nao precisa de sincronizador porque fica parado no hold ate o proximo frame.
4. Leitura em duas transacoes: a primeira escolhe o endereco, a segunda manda o valor pelo MISO (endereco NOP 0x3F).

clk -> sys_clk: o START tambem vira toggle + 2 FFs. KEY, IV e o resto sao escritos antes do START e capturados
nele, entao nao precisam de sincronizador. Escrita nesses registradores com BUSY = 1 e ignorada.

sys_clk -> clk: BUSY, DONE e o locked do PLL passam por 2 FFs antes de ir para os registradores de status.

## 8. Reset (secao 4.2 do Block Guide)

1. rst_n = 0: zera o banco de registradores, PLL desligado, locked = 0, sys_clk parado.
2. rst_n = 1: o banco ja responde ao SPI.
3. O mestre liga o PLL e escolhe o divisor no SYSTEM_CONTROL.
4. O PLL trava, locked sobe e o sys_clk e liberado.
5. O reset do sys_clk entra assincrono e sai sincrono (2 FFs com entrada rst_n & locked).
6. O minisoc_aes_top sai do reset em IDLE.

Se o locked cair no meio de uma operacao, o dominio sys_clk volta para reset e a operacao e perdida. No nucleo AES
so os registradores de controle tem reset. State e chaves nao tem, quem diz se o valor vale e o ready/done.

Pendente: conferir no Block Guide quantos ciclos esperar depois do locked e os nomes dos campos do
SYSTEM_CONTROL/SYSTEM_STATUS.
