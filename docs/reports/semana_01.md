# Semana 1 — Kick-off, estudo e ambiente

## O que foi feito
- Repositório com a estrutura padrão, `.gitignore` e README.
- Fluxo mínimo (`make`): lint, compilação e simulação com VCS X-2025.06-SP2.
- Exemplo mínimo: `add_round_key` (XOR de 128 bits do AES) com testbench autoverificável.
- Backlog das 15 semanas.

## Resultados
- Lint VCS sem avisos; simulação `TEST PASSED` (vetor da FIPS-197, Apêndice B). Logs em `docs/reports/logs/`.

## Estudo AES
- Cifra de bloco de 128 bits; AES-128 usa chave de 128 bits e 10 rodadas.
- Rodada: SubBytes → ShiftRows → MixColumns → AddRoundKey. A última rodada não tem MixColumns.
- A expansão de chave gera 11 subchaves de 128 bits (RotWord, SubWord, Rcon).
- Vetor de teste (FIPS-197 C.1): chave `000102…0f`, texto `00112233…ff`, cifrado `69c4e0d86a7b0430d8cdb78070b4c55a`.

## Estudo SPI
- Quatro fios: SCLK, CS_N, MOSI, MISO. O IP será escravo.
- Modos CPOL/CPHA 0–3. Proposta: modo 0, MSB primeiro.
- Banco de registradores previsto: CTRL, STATUS, KEY, DIN e DOUT. A definição fica para a Semana 2.

## Problemas
- Caminho com espaço/acento ("Área de trabalho") quebrava scripts internos do VCS; projeto movido para `~/projetos`.

## Próximos passos
- Documento de arquitetura (Semana 2): modo SPI, mapa de registradores e microarquitetura do AES.
