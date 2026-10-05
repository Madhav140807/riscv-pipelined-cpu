IVERILOG = iverilog -I rtl
VVP      = vvp
SIM      = sim
BUILD    = build

# RISC V compiler (Homebrew name; CI overrides this)
RISCV_PREFIX ?= riscv64-elf-
CFLAGS = -march=rv32i -mabi=ilp32 -O1 -nostdlib -ffreestanding -mno-relax

TESTS = alu regfile imm_gen control branch_unit instr_mem data_mem cpu cpu_pipe forward_unit pipe_forward hazard_unit pipe_loaduse pipe_basic pipe_branch pipe_perf c_fib

.PHONY: test clean $(TESTS)

test: $(TESTS)
	@echo "=== All test suites passed ==="

$(SIM) $(BUILD):
	mkdir -p $@

$(TESTS): %: | $(SIM)
	@echo "--- Testing $@ ---"
	$(IVERILOG) -s $@_tb -o $(SIM)/$@_tb.out rtl/*.v tb/$@_tb.v
	$(VVP) $(SIM)/$@_tb.out | tee $(SIM)/$@.log
	grep -q "ALL TESTS PASSED" $(SIM)/$@.log

# C program -> hex file the CPU can load
$(BUILD)/%.hex: sw/%.c sw/crt0.S sw/link.ld tools/bin2hex.py | $(BUILD)
	$(RISCV_PREFIX)gcc $(CFLAGS) -T sw/link.ld -o $(BUILD)/$*.elf sw/crt0.S $<
	$(RISCV_PREFIX)objcopy -O binary $(BUILD)/$*.elf $(BUILD)/$*.bin
	python3 tools/bin2hex.py $(BUILD)/$*.bin > $@
	$(RISCV_PREFIX)objdump -d $(BUILD)/$*.elf > $(BUILD)/$*.dump

# C program tests need their hex file built first
c_fib: $(BUILD)/fib.hex

clean:
	rm -rf $(SIM) $(BUILD)