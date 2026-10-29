# Semana 2 — Desafio: SubBytes e ShiftRows (entrega 30/10)

> Roteiro revisado em 27/10/2026: o projeto passa a seguir o **Block Guide do MiniSoC AES (v1.0.0)**
> e tem 13 semanas de entrega. O backlog (`docs/backlog.md`) foi atualizado para o novo cronograma.

## 1. O que foi feito

| Arquivo | O que é |
|---|---|
| `rtl/minisoc_aes/minisoc_aes_sbox.sv` | S-box: 8 bits → 8 bits, combinacional, tabela de 256 entradas (FIPS-197, Figura 7) |
| `rtl/minisoc_aes/minisoc_aes_sub_bytes.sv` | SubBytes: estado de 128 bits, 16 instâncias da S-box em paralelo |
| `rtl/minisoc_aes/minisoc_aes_shift_rows.sv` | ShiftRows: estado de 128 bits, só reordenação de fios |
| `rtl/minisoc_aes/minisoc_aes_inv_sbox.sv` | (opcional) S-box inversa (FIPS-197, Figura 14) |
| `rtl/minisoc_aes/minisoc_aes_inv_sub_bytes.sv` | (opcional) InvSubBytes |
| `rtl/minisoc_aes/minisoc_aes_inv_shift_rows.sv` | (opcional) InvShiftRows |
| `tb/tb_minisoc_aes_subbytes_shiftrows.sv` | Testbench autoverificável |
| `Makefile` | Agora roda lint + simulação de **todos** os testbenches com um único `make` |

### Convenção do estado
Igual ao Block Guide (a Word 0 de um bloco é `[127:96]`): o byte 0 fica em `[127:120]` e o byte 15 em `[7:0]`.
O byte *n* é `s[r][c]` com `r = n mod 4` e `c = n div 4` (FIPS-197, seção 3.4). Ou seja, cada coluna do
estado são 4 bytes seguidos, e cada Word de 32 bits da memória é uma coluna.

### Decisões
- **S-box como tabela constante** (`localparam logic [7:0] Sbox [256]`, 16 valores por linha, igual à
  Figura 7 da FIPS-197) e saída `assign data_o = Sbox[data_i]`. É o mesmo estilo do `aes_sbox_lut.sv` do
  OpenTitan. O sintetizador transforma a tabela em lógica combinacional, não em memória. A S-box por
  cálculo em GF(2⁸) (*composite field*) costuma ocupar menos área e fica como alternativa para a síntese.
- **SubBytes** são 16 instâncias da S-box geradas por um `for (genvar ...)`, todas em paralelo.
- **ShiftRows não tem lógica**: o estado é separado em 16 bytes e remontado numa concatenação, uma linha
  por coluna de saída. Na síntese vira só roteamento.
- Nomes seguem o guia de estilo da lowRISC: sufixos `_i`/`_o`, blocos gerados com `gen_`, instâncias com
  `u_`, constantes em maiúsculas.
- As inversas foram feitas já agora porque a decriptação (ECB, CBC, PCBC) vai precisar delas na Semana 3.

## 2. Testbench

`tb/tb_minisoc_aes_subbytes_shiftrows.sv` confere:

1. **S-box nas 256 entradas** contra um modelo de referência calculado no próprio TB pela definição
   matemática (inverso multiplicativo em GF(2⁸) módulo `0x11B` + transformação afim com `0x63`).
   A tabela do RTL é assim comparada com uma fonte independente. Também confere `sbox(00)=63` e `sbox(53)=ed`.
   Os módulos ficam em cadeia (SubBytes → ShiftRows → InvShiftRows → InvSubBytes), então um único estímulo
   testa as quatro transformações.
2. **SubBytes e ShiftRows** nos estados do Apêndice B da FIPS-197, de "Start of Round" → "After SubBytes"
   → "After ShiftRows", nas **rodadas 1 a 10** (o roteiro pede pelo menos 1 e 10).
3. **Opcional:** `InvSubBytes(SubBytes(x)) = x` para os 256 bytes e para os 10 estados, e
   `InvShiftRows(ShiftRows(x)) = x`.

Rodada 1 (referência do roteiro):
```
start of round  : 193de3bea0f4e22b9ac68d2ae9f84808
after SubBytes  : d42711aee0bf98f1b8b45de51e415230
after ShiftRows : d4bf5d30e0b452aeb84111f11e2798e5
```

## 3. Resultados

| Etapa | Ferramenta | Resultado |
|---|---|---|
| Lint | `vcs +lint=all` | _preencher após rodar no servidor_ |
| Simulação | VCS X-2025.06-SP2 | _preencher_ (esperado `TEST PASSED`) |
| Simulação (conferência) | Verilator 5.020 | `TEST PASSED` |
| Lint (conferência) | Verilator 5.020 `-Wall`, RTL e testbench | 0 avisos |

Teste do próprio testbench: trocando uma entrada da S-box (`sbox(53)` de `ed` para `ee`) e um byte do
ShiftRows, o TB acusa os dois defeitos e termina com `TEST FAILED`.

Comando único: `source /Tools/synopsys-scripts/snps.sh && make` (ou `make semana02` só para este TB).
Logs em `docs/reports/logs/`.

## 4. Dúvidas e ambiguidades do Block Guide (seções 1 a 3 e 8)

Para levar ao instrutor e ao verificador parceiro:

**Seções 1 a 3 (visão geral, arquitetura, interfaces)**
1. `clk` é de 2 GHz e também é o domínio always-on do SPI e do banco de registradores. Qual frequência
   usar como alvo na síntese desse domínio? (o roteiro diz que as frequências-alvo serão definidas pelo instrutor)
2. Com `PLL_DIV_SEL = 00` o AES rodaria a 2 GHz. Qual divisor é o alvo de timing do `sys_clk`?
3. A memória é single-port e o clock dela vem de `mem_clk` ou de `sys_clk` conforme `MEM_SEL_AES`.
   Quem garante a troca de clock sem glitch: um mux de clock dedicado ou só a regra de "trocar com tudo ocioso"?
4. Qual a latência de leitura em `mem_o_data` (1 ciclo de `mem_clk`?) e o que ele mostra enquanto o AES
   é dono da memória (valor mantido, zero ou X)?
5. A interface MEMORY DATA não tem sinal de "válido": com `mem_i_wr_en = 0` há uma leitura a cada ciclo.
   Está correto assumir isso?

**Seção 8 (AES engine)**
6. Os blocos sempre começam no endereço 0 (palavras 0 a 4·NUM_BLOCKS−1)? Não há registrador de endereço base.
7. **CTR:** o roteiro diz "IV **XOR** contador de 64 bits zero-estendido". O padrão NIST SP 800-38A
   costuma usar o contador nos bits baixos do bloco (soma/concatenação). Confirmar que é XOR e o que
   acontece quando o contador passa de 2⁶⁴−1.
8. **CFB:** qual o tamanho do segmento (assumindo CFB-128)? E o bit `DECRYPT` vale para CFB? (na decriptação
   do CFB o realimentado é o texto cifrado de entrada, então o modo precisa saber a direção.)
9. **OFB e CTR** são iguais nos dois sentidos. O bit `DECRYPT` é ignorado nesses modos?
10. **PCBC:** confirmar a definição usada (`C_i = E(P_i ⊕ P_{i−1} ⊕ C_{i−1})`, com o IV no primeiro bloco).
11. Ao terminar uma operação encadeada, o IV/COUNTER do registrador é atualizado para permitir continuar
    em um novo START, ou cada START recomeça do valor programado?
12. ERROR: ele também ativa DONE? É limpo no próximo START válido, como o DONE?
13. O que é um "START válido"? O que acontece com START enquanto BUSY = 1, com `MEM_SEL_AES = 0`
    ou com o PLL ainda não travado?
14. Lendo `AES_CONTROL`, o bit START (write-one-pulse) volta como 0?
15. NUM_BLOCKS = 0 gera ERROR (fora de 1..256)? E valores acima de 256 nos 32 bits do registrador?

## 5. Próximos passos (Semana 3, entrega 06/11)
- Documento de microarquitetura v1.0 (`docs/architecture/`), seguindo o Block Guide.
- MixColumns, AddRoundKey (mover `rtl/add_round_key.sv` para `rtl/minisoc_aes/`) e InvMixColumns.
- Testes unitários com os intermediários dos Apêndices B e C.1 da FIPS-197.

## Referências
- NIST FIPS-197, *Advanced Encryption Standard* (Figuras 7 e 14, Apêndice B).
- OpenTitan AES, `hw/ip/aes/rtl/aes_sbox_lut.sv` e `aes_shift_rows.sv` (lowRISC).
- lowRISC Verilog Coding Style Guide.