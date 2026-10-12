# Semana 1 — Kick-off, estudo e ambiente

## 1. O que foi feito
- Repositório com a estrutura padrão (`rtl/`, `tb/`, `docs/`, `scripts/`, `syn/`, `formal/`, `upf/`), `.gitignore` e README.
- Fluxo mínimo com comando único (`make` / `make all`): lint, compilação e simulação com VCS X-2025.06-SP2.
- Exemplo mínimo: `add_round_key` (XOR de 128 bits do AES) com testbench autoverificável.
- Backlog das 15 semanas (`docs/backlog.md`).

## 2. Resultados
| Etapa | Ferramenta | Resultado |
|---|---|---|
| Lint | `vcs +lint=all` | 0 avisos |
| Compilação | VCS | OK |
| Simulação | `simv` | `TEST PASSED` (inclui vetor da FIPS-197, Apêndice B) |

Logs em `docs/reports/logs/`. Critério de aceite verificado: clone em pasta limpa + `make` executa sem erros.

## 3. Estudo: AES-128 (FIPS-197)

### 3.1 Visão geral
- Cifra de bloco **simétrica**: a mesma chave cifra e decifra.
- Bloco de **128 bits**. Chave de 128/192/256 bits → **10/12/14 rodadas**. O projeto usa AES-128.
- O bloco é uma matriz **4×4 bytes** (o "estado"), preenchida coluna a coluna.

```
AddRoundKey(K0)
Rodadas 1..9: SubBytes → ShiftRows → MixColumns → AddRoundKey(Kr)
Rodada 10:    SubBytes → ShiftRows →              AddRoundKey(K10)
```

### 3.2 Aritmética em GF(2⁸)
- Cada byte é um polinômio de grau ≤ 7 com coeficientes em {0,1}.
- **Soma = XOR.**
- **Multiplicação** módulo o polinômio irredutível m(x) = x⁸ + x⁴ + x³ + x + 1 (0x11B).
- `xtime(a)` = multiplicação por 2: deslocamento à esquerda + XOR com 0x1B se o MSB era 1. Multiplicar por 3 = `xtime(a) ⊕ a`.

### 3.3 Transformações
| Etapa | Operação | Função |
|---|---|---|
| SubBytes | S-box por byte: inverso multiplicativo em GF(2⁸) + transformação afim (constante 0x63) | Única etapa **não linear** (confusão) |
| ShiftRows | Linha *r* rotaciona *r* bytes à esquerda | Difusão entre colunas (só fiação no HW) |
| MixColumns | Cada coluna × matriz `[02 03 01 01; 01 02 03 01; 01 01 02 03; 03 01 01 02]` em GF(2⁸) | Difusão dentro da coluna |
| AddRoundKey | Estado ⊕ subchave da rodada | Única etapa que usa a chave |

A última rodada não tem MixColumns: ela não acrescenta segurança e deixa a decifragem simétrica.

### 3.4 Expansão de chave
- Gera 44 palavras de 32 bits = 11 subchaves (K0..K10).
- `w[i] = w[i-4] ⊕ temp`. Se `i mod 4 = 0`: `temp = SubWord(RotWord(w[i-1])) ⊕ Rcon[i/4]`.
- Rcon = 01, 02, 04, 08, 10, 20, 40, 80, 1B, 36 (quebra a simetria entre rodadas).
- Em hardware: geração **on-the-fly**, uma subchave por rodada, sem armazenar as 11.

### 3.5 Decifragem
Usa InvSubBytes, InvShiftRows e InvMixColumns (coeficientes 09, 0B, 0D, 0E), com as subchaves em ordem inversa (K10 → K0).

### 3.6 Vetores de referência
| Fonte | Chave | Texto claro | Texto cifrado |
|---|---|---|---|
| FIPS-197 B | `2b7e151628aed2a6abf7158809cf4f3c` | `3243f6a8885a308d313198a2e0370734` | `3925841d02dc09fbdc118597196a0b32` |
| FIPS-197 C.1 | `000102030405060708090a0b0c0d0e0f` | `00112233445566778899aabbccddeeff` | `69c4e0d86a7b0430d8cdb78070b4c55a` |

## 4. Estudo: SPI

### 4.1 Sinais (IP como escravo)
| Sinal | Direção no IP | Função |
|---|---|---|
| SCLK | entrada | Clock gerado pelo mestre |
| CS_N | entrada | Seleção do escravo (ativo baixo), delimita o quadro |
| MOSI | entrada | Dado mestre → escravo |
| MISO | saída | Dado escravo → mestre |

Comunicação serial **síncrona**, **full-duplex** (dois shift registers em anel), sem endereço no barramento e sem ACK.

### 4.2 Modos CPOL/CPHA
| Modo | CPOL | CPHA | SCLK em repouso | Amostra na borda |
|---|---|---|---|---|
| 0 | 0 | 0 | baixo | subida |
| 1 | 0 | 1 | baixo | descida |
| 2 | 1 | 0 | alto | descida |
| 3 | 1 | 1 | alto | subida |

Proposta: **modo 0**, MSB primeiro. Quadro: `R/W (1b) | ENDEREÇO (7b) | DADO (32b)`.

## 5. Problemas encontrados
- Caminho com espaço/acento ("Área de trabalho") quebrava scripts internos do VCS. Solução: projeto movido para `~/projetos`.

## 6. Próximos passos (Semana 2)
- Documento de arquitetura v1.0: modo SPI, formato de quadro, mapa de registradores, microarquitetura do AES, estratégia de CDC.
