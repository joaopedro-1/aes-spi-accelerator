# Backlog — AES-128 + SPI (15 semanas)

| Sem | Tema | Tarefas macro | Critério de aceite |
|---|---|---|---|
| 1 | Kick-off, estudo e ambiente | Repositório, Makefile (lint/compilação/simulação), exemplo mínimo, estudo AES/SPI | Clone limpo + `make` sem erros ✅ |
| 2 | Arquitetura | Diagrama de blocos, interfaces, modo SPI, mapa de registradores, estratégia de CDC, defesa | Arquitetura aprovada |
| 3 | RTL AES I | SubBytes, ShiftRows, MixColumns, AddRoundKey + testes unitários | Bate com intermediários da FIPS-197; lint limpo |
| 4 | RTL AES II | Expansão de chave, FSM de controle, núcleo completo + TB com vetores FIPS-197 | Todos os vetores passam |
| 5 | RTL SPI + registradores | SPI slave, banco de registradores, TB de leitura/escrita | R/W de todos os registradores via SPI |
| 6 | Integração | Top-level, teste ponta a ponta, lint + CDC, tag `rtl-v1.0` | Operação completa via SPI |
| 7 | Síntese (Design Compiler) | SDC, scripts DC, netlist, relatórios de área/timing/potência | Sem erros/latches; timing atendido |
| 8 | Formal I | Plano de propriedades, assertions SVA, VC Formal | Propriedades provadas ou CEX registrado |
| 9 | Formal II + Formality | Fechamento do formal, equivalência RTL × netlist (LEC), tag `rtl-v1.1` | Equivalência confirmada |
| 10 | Arquitetura de energia | Domínios, modos, tabela de estados de potência, sequências | Aprovada na defesa |
| 11 | UPF | Arquivo UPF, verificação estática, simulação power-aware | UPF sem erros; isolamento/retenção OK |
| 12 | Low power I | Controlador de energia, power gating do núcleo AES | Funcionalidade preservada |
| 13 | Low power II | Clock gating e outras técnicas, tag `rtl-v2.0` | Funcionalidade da v1.0 preservada |
| 14 | Síntese low power | Síntese com UPF, comparação com o baseline, regressão formal/LEC | Ganhos e custos quantificados |
| 15 | Encerramento | Release, documentação, apresentação, artigo preliminar | Tudo reproduzível por scripts |
