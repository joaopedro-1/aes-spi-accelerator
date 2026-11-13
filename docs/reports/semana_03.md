# Semana 3 — Microarquitetura e transformações de rodada (entrega 06/11)

## O que foi feito

- Documento de microarquitetura: `docs/architecture/microarquitetura_v1.0.md` (diagrama, AES iterativo, FSM do
  `minisoc_aes_top`, CDC entre `spi_sclk`, `clk` e `sys_clk`, reset).
- `rtl/minisoc_aes/minisoc_aes_mix_columns.sv`
- `rtl/minisoc_aes/minisoc_aes_inv_mix_columns.sv`
- `rtl/minisoc_aes/minisoc_aes_add_round_key.sv` (era `rtl/add_round_key.sv`, mudei de pasta e de nome)
- InvSubBytes e InvShiftRows já estavam prontos desde a semana 2.
- `tb/tb_minisoc_aes_round.sv` e alvo `make semana03` no Makefile.

## Como funciona

MixColumns: cada coluna é multiplicada pela matriz `02 03 01 01` (girando a cada linha) em GF(2^8). Multiplicar por
02 é o `xtime` (desloca 1 bit e faz XOR com 0x1b se o bit 7 era 1) e por 03 é `xtime(x) ^ x`. Juntando os termos,
a primeira linha fica `xtime(s0 ^ s1) ^ s1 ^ s2 ^ s3`.

InvMixColumns: em vez de multiplicar por 0e, 0b, 0d e 09, usei a decomposição do livro *The Design of Rijndael*.
A matriz inversa é igual à do MixColumns vezes `05 00 04 00`, então faço um pré-passo
(`s0 ^= 04.(s0^s2)`, `s1 ^= 04.(s1^s3)`, ...) e passo pelo MixColumns que já existe.

AddRoundKey é só XOR e serve para cifra e decifra.

## Testbench

`tb_minisoc_aes_round` confere:
- coluna `db135345 -> 8e4da1bc` no MixColumns e a volta no InvMixColumns;
- apêndice B, rodadas 1 a 10: MixColumns e saída de cada rodada; na rodada 10 sai `3925841d...0b32`;
- InvMixColumns(MixColumns(x)) = x nas rodadas 1 a 9;
- apêndice C.1, rodadas 1 a 10: `is_row`, `is_box` e saída de cada rodada; no fim sai `00112233...eeff`.

## Resultados

| Etapa | Ferramenta | Resultado |
|---|---|---|
| `make semana03` | VCS | |
| lint | VCS `+lint=all` | |
| simulação | Verilator 5.020 | TEST PASSED |

Logs em `docs/reports/logs/`.
