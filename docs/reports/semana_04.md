# Semana 4 — Expansão de chave e datapath AES-128 (entrega 13/11)

## O que foi feito

- `rtl/minisoc_aes/minisoc_aes_key_exp.sv`: expansão de chave pré-computada.
- `rtl/minisoc_aes/minisoc_aes_dp.sv`: datapath iterativo, cifra e decifra.
- `tb/tb_minisoc_aes_key_exp.sv` e `tb/tb_minisoc_aes_dp.sv`.
- Alvo `make semana04` no Makefile.

## key_exp

```
temp = SubWord(RotWord(w3)) ^ Rcon
w0' = w0 ^ temp,  w1' = w1 ^ w0',  w2' = w2 ^ w1',  w3' = w3 ^ w2'
```

No `start_i` guarda a chave como K0 e calcula uma chave por ciclo (4 S-boxes). O Rcon começa em 01 e passa pelo
`xtime` a cada ciclo (01, 02, 04, ..., 80, 1b, 36). Depois de 11 ciclos `ready_o` sobe e qualquer chave pode ser
lida por `rnd_i`.

Escolhi pré-computar porque a decifra usa as chaves de trás para frente (K10 primeiro). On-the-fly ia precisar
calcular até K10 antes de começar ou ter a expansão inversa. Com até 256 blocos por operação, a expansão é feita
uma vez só. O custo é 11 x 128 = 1408 flip-flops em vez de 128.

## dp

- start: `state = bloco ^ K0` (cifra) ou `bloco ^ K10` (decifra)
- rodadas 1 a 10, uma por ciclo, a 10 sem (Inv)MixColumns
- decifra com a cifra inversa da FIPS-197 5.3: InvShiftRows, InvSubBytes, AddRoundKey, InvMixColumns
- o dp pede a chave em `rnd_o` (0..10 na cifra, 10..0 na decifra) e recebe em `rk_i`
- `done_o` pulsa 11 ciclos depois do `start_i`

Ligação entre os dois: `key_exp.rnd_i = dp.rnd_o` e `dp.rk_i = key_exp.rk_o`.

## Testbenches

`tb_minisoc_aes_key_exp`:
- as 11 chaves do apêndice A.1 (chave `2b7e1516...`);
- chave 10 do apêndice C.1 (chave `000102..0f`): `13111d7f...30c5`;
- `ready_o` sobe 11 ciclos depois do start.

`tb_minisoc_aes_dp` (key_exp + dp juntos):
- apêndice B rodada a rodada, saída `3925841d02dc09fbdc118597196a0b32`;
- decifra do B, volta para `3243f6a8...0734`;
- apêndice C.1: cifra `00112233...eeff` -> `69c4e0d86a7b0430d8cdb78070b4c55a` e decifra de volta;
- 50 chaves e blocos aleatórios com decifra(cifra(x)) == x;
- latência de 11 ciclos em todos os blocos.

Para ver se o TB pega erro, troquei 0x1b por 0x1d no `xtime` do MixColumns e o `tb_minisoc_aes_dp` falhou.

## Resultados

| Etapa | Ferramenta | Resultado |
|---|---|---|
| `make semana04` | VCS X-2025.06-SP2 | TEST PASSED nos dois TBs |
| lint | VCS `+lint=all` | RTL sem avisos |
| simulação | Verilator 5.020 | TEST PASSED nos dois TBs |

## Próxima semana

SPI modo 0 com frame de 40 bits, banco de registradores e modelo do PLL.
