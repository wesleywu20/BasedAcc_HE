SHELL = /bin/bash -o pipefail

#Collect All Source Files
PKG_SRCS := $(PWD)/pkg/rv32i_mux_types.sv $(PWD)/pkg/rv32i_types.sv $(PWD)/pkg/I_queue_types.sv $(PWD)/pkg/design_types.sv
HDL_SRCS := $(shell find $(PWD)/cpu -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
TST_SRCS :=  $(shell find $(PWD)/testcode -name '*.sv' -o -name '*.v')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS) $(TST_SRCS)

SYNTH_TCL := $(CURDIR)/synthesis.tcl

VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/10ps -debug_acc+all -kdb -fsdb -msg_config=../warn.config -l compile.log +incdir+../pkg +incdir+../hvl -top mp4_tb


sim/simv: $(SRCS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) 

run: sim/simv $(ASM)
	rv_load_memory.sh $(ASM) 2>&1 | tee ../sim/asm.log
	cd sim && ./simv -l simulation.log
	cd sim && fsdb2saif dump.fsdb

based: $(ASM)
	cd sim && ./simv -l simulation.log
	cd sim && fsdb2saif dump.fsdb

cringe: sim/simv

correct: sim/simv
	cd bin_new
	make run ASM=accel.S
	cd ..


synth: $(SRCS) $(SYNTH_TCL) 
	mkdir -p synth/reports
	cd synth && dc_shell -f $(SYNTH_TCL)  2>&1 | tee synthesis.log
	@if grep -q -i -e error -e LINK-5 synth/synthesis.log; then \
		echo -e "\033[0;31m Fix errors below \033[0m"; \
		grep -i -e error -e LINK-5 synth/synthesis.log; exit 1; \
	else \
		echo -e "\033[0;32m Synthesis Successful \033[0m Check timing and power report under synth/reports/"; \
    fi

clean:
	rm -rf sim synth

.PHONY: clean
.PHONY: run





