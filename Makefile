IVERILOG = iverilog -I rtl
VVP      = vvp
SIM      = sim

TESTS = alu regfile imm_gen control branch_unit instr_mem data_mem cpu cpu_pipe

.PHONY: test clean $(TESTS)

test: $(TESTS)
	@echo "=== All test suites passed ==="

$(SIM):
	mkdir -p $(SIM)

$(TESTS): %: | $(SIM)
	@echo "--- Testing $@ ---"
	$(IVERILOG) -s $@_tb -o $(SIM)/$@_tb.out rtl/*.v tb/$@_tb.v
	$(VVP) $(SIM)/$@_tb.out | tee $(SIM)/$@.log
	grep -q "ALL TESTS PASSED" $(SIM)/$@.log

clean:
	rm -rf $(SIM)