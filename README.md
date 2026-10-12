# Acelerador AES-128 com interface SPI e baixo consumo

Projeto Hands-on da Residência em Microeletrônica, trilha RTL (15 semanas).

## Estrutura
- `rtl/` RTL · `tb/` testbenches · `formal/` · `syn/` · `upf/` · `scripts/`
- `docs/spec` especificação · `docs/architecture` · `docs/reports` relatórios semanais e logs
- `docs/backlog.md` planejamento

## Como executar
```
git clone https://github.com/joaopedro-1/aes-spi-accelerator.git
cd aes-spi-accelerator
source /Tools/synopsys-scripts/snps.sh
make
```
Resultado esperado: `TEST PASSED` e `>> FLUXO OK`.

Ferramenta: Synopsys VCS X-2025.06-SP2.
