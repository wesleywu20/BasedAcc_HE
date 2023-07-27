SHELL = /bin/bash -o pipefail

run: $(ASM)
	./rv_load_memory.sh $(ASM) 2>&1 | tee ../sim/asm.log

.PHONY: clean
.PHONY: run
