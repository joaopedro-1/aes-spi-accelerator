# Fluxo minimo: lint + compilacao + simulacao (VCS)
# Uso: source /Tools/synopsys-scripts/snps.sh && make
SHELL         := /bin/bash
.SHELLFLAGS   := -o pipefail -c
.RECIPEPREFIX := >

TOP  = tb_add_round_key
SRCS = rtl/add_round_key.sv tb/tb_add_round_key.sv
LOGS = docs/reports/logs

.PHONY: all check-env lint sim clean
all: lint sim

check-env:
> @command -v vcs >/dev/null || { echo "ERRO: rode 'source /Tools/synopsys-scripts/snps.sh'"; exit 1; }

lint: check-env
> @mkdir -p $(LOGS)
> vcs -full64 -sverilog +lint=all,noVCDE -top $(TOP) $(SRCS) -o lint_simv | tee $(LOGS)/lint.log

sim: check-env
> @mkdir -p $(LOGS)
> vcs -full64 -sverilog -timescale=1ns/1ps -top $(TOP) $(SRCS) -o simv | tee $(LOGS)/compile.log
> ./simv -no_save | tee $(LOGS)/sim.log
> @grep -q "TEST PASSED" $(LOGS)/sim.log && echo ">> FLUXO OK"

clean:
> rm -rf simv* lint_simv* csrc ucli.key *.vpd *.fsdb
