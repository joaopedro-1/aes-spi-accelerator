# Fluxo minimo: lint + compilacao + simulacao (VCS)
# Uso: source /Tools/synopsys-scripts/snps.sh && make
#      make sim-<testbench>   roda so um testbench (ex.: make sim-tb_minisoc_aes_subbytes_shiftrows)
SHELL         := /bin/bash
.SHELLFLAGS   := -o pipefail -c
.RECIPEPREFIX := >

LOGS = docs/reports/logs

# Cada testbench em tb/<nome>.sv, com a lista de RTL que ele usa
TESTS = tb_add_round_key tb_minisoc_aes_subbytes_shiftrows
SRCS_tb_add_round_key                  = rtl/add_round_key.sv
SRCS_tb_minisoc_aes_subbytes_shiftrows = $(wildcard rtl/minisoc_aes/*.sv)

VCS = vcs -full64 -sverilog -timescale=1ns/1ps

.PHONY: all check-env lint sim semana02 clean
all: lint sim

check-env:
> @command -v vcs >/dev/null || { echo "ERRO: rode 'source /Tools/synopsys-scripts/snps.sh'"; exit 1; }

lint: $(TESTS:%=lint-%)
sim:  $(TESTS:%=sim-%)
> @echo ">> FLUXO OK"

semana02: lint-tb_minisoc_aes_subbytes_shiftrows sim-tb_minisoc_aes_subbytes_shiftrows

lint-%: check-env
> @test -n "$(SRCS_$*)" || { echo "ERRO: nenhum RTL mapeado para $*"; exit 1; }
> @mkdir -p $(LOGS)
> $(VCS) +lint=all,noVCDE -top $* $(SRCS_$*) tb/$*.sv -o lint_simv_$* | tee $(LOGS)/$*_lint.log

sim-%: check-env
> @test -n "$(SRCS_$*)" || { echo "ERRO: nenhum RTL mapeado para $*"; exit 1; }
> @mkdir -p $(LOGS)
> $(VCS) -top $* $(SRCS_$*) tb/$*.sv -o simv_$* | tee $(LOGS)/$*_compile.log
> ./simv_$* -no_save | tee $(LOGS)/$*_sim.log
> @grep -q "TEST PASSED" $(LOGS)/$*_sim.log

clean:
> rm -rf simv* lint_simv* csrc ucli.key *.vpd *.fsdb