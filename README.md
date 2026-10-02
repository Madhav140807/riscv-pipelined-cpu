# RISC V Pipelined CPU

A five stage pipelined RV32I processor written from scratch in Verilog, with full hazard handling and a self checking test suite. Everything is simulated, no hardware needed.

Built by Madhav Agarwal, Computer Engineering at UC Irvine.

## Highlights

- Classic five stage pipeline: Fetch, Decode, Execute, Memory, Writeback
- **Forwarding** from the MEM and WB stages, so back to back dependent instructions run with no delay
- **Load use hazard detection** that stalls exactly one cycle when an instruction needs data a load hasn't returned yet
- **Branch and jump flushing** that cancels wrong path instructions on taken branches, `jal`, and `jalr`
- A single cycle version of the same CPU, kept as a reference to check the pipeline against
- 15 automated test suites (130+ checks), from individual modules up to full programs

## Architecture

```mermaid
flowchart LR
    IF[IF<br/>fetch] --> R1[IF/ID]
    R1 --> ID[ID<br/>decode, regfile,<br/>hazard unit]
    ID --> R2[ID/EX]
    R2 --> EX[EX<br/>ALU, branch unit,<br/>forwarding]
    EX --> R3[EX/MEM]
    R3 --> MEM[MEM<br/>data memory]
    MEM --> R4[MEM/WB]
    R4 --> WB[WB<br/>writeback]
    R3 -. forward .-> EX
    R4 -. forward .-> EX
    EX -. redirect + flush .-> IF
```

### Hazard handling

| Hazard | Example | Solution | Cost |
| Data | `add x1, ...` then `sub x4, x1, ...` | Forward the result from EX/MEM or MEM/WB | 0 cycles |
| Load use | `lw x2, 0(x0)` then `add x3, x2, x2` | Stall one cycle, then forward from WB | 1 cycle |
| Control | taken `beq`, `jal`, `jalr` | Predict not taken, flush 2 wrong path instructions | 2 cycles |

### Supported instructions

All RV32I computational, memory, and control instructions:
`lui auipc jal jalr beq bne blt bge bltu bgeu lb lh lw lbu lhu sb sh sw addi slti sltiu xori ori andi slli srli srai add sub sll slt sltu xor srl sra or and`
Project structure
'''
rtl/        CPU design
  cpu_pipe.v       five stage pipelined CPU (top level)
  cpu.v            single cycle reference CPU
  alu.v            arithmetic and logic
  regfile.v        32 registers, optional write through
  imm_gen.v        immediate decoding for all formats
  control.v        main control unit
  branch_unit.v    branch comparisons
  forward_unit.v   forwarding logic
  hazard_unit.v    load use stall detection
  instr_mem.v      instruction memory, loads hex programs
  data_mem.v       byte, halfword, and word access
  defines.vh       shared constants
tb/         self checking testbenches, one per module and program
programs/   hand assembled test programs (hex)
```

Running the tests

Requires [Icarus Verilog](https://github.com/steveicarus/iverilog).


Every testbench prints `ALL TESTS PASSED` on success, and `make` stops with an error if any suite fails.

To view waveforms, open any `.vcd` file from `sim/` in [Surfer](https://app.surfer-project.org) or GTKWave.

 Verification approach

- **Unit tests** for every module, focused on edge cases: signed vs unsigned compares, sign extension, shifting by more than 31, writes to x0, little endian byte access
- **Real instruction encodings** in every test instead of made up bit patterns
- **Program level tests** that target each hazard on purpose: back to back dependencies, every load use pattern, taken and not taken branches, and a function call and return
- **Performance checks**, not just correctness: the load use test asserts exactly 3 stalls
- **Reference comparison:** the pipeline runs the same program as the single cycle CPU and must produce identical results

## Design decisions

- **Branches resolve in EX.** Simplest correct design, at the cost of 2 cycles per taken branch. Branch prediction is planned for Version 2.
- **Register file write through is a parameter.** The pipeline needs it so WB and ID can share a cycle. The single cycle CPU must turn it off, because there it creates a combinational loop.
- **Forwarding priority favors MEM over WB**, since MEM holds the newer value when both match.
- **`jal` and `jalr` forward PC+4**, not the ALU result, because that's the value they actually write.
- **ALU control codes match `{funct7[5], funct3}`**, which keeps the control logic small. Immediate instructions only use bit 30 for `srai`, since in `addi` that bit belongs to the immediate.

## Known limitations

- Memory accesses must be aligned
- No CSRs, exceptions, `ecall`, `ebreak`, or `fence`
- The load use stall can trigger on unused `rs2` bits (costs a cycle, never gives a wrong result)
- Memories use simulation only features (`$readmemh`, combinational reads)

## Roadmap

- [x] Single cycle RV32I CPU
- [x] Five stage pipeline with forwarding, stalls, and flushing
- [ ] Compile and run C programs with the RISC V GCC toolchain
- [ ] Performance counters (cycles, instructions, CPI)
- [ ] Branch prediction
- [ ] Instruction and data caches
- [ ] Continuous integration with GitHub Actions
- [ ] UART output and a tiny kernel