# RV32I Single-Cycle Core in Verilog (+ Spartan-7 FPGA demo)

A from-scratch RV32I processor written in plain Verilog-2001 (no TL-Verilog), with a
self-checking testbench, an assembler and golden-reference ISS written in Python, and a
Spartan-7 (Arty S7) top level that prints over UART and drives LEDs.

```
            +----------------------------- riscv_core -----------------------------+
 imem  <--- | PC -> [imem] -> control + imm_gen -> regfile -> ALU -> dmem/align -> WB |
 (ROM)      |        ^                                  |  branch cmp -> next-PC mux  |
            +------- pc ---------------------------------+----------------------------+
                                                          |
                                           soc.v address decode
                       RAM 0x00000000 (4 KiB) | LED 0x10000000 | UART 0x10000004
```

## Repository layout

| Path | Contents |
|---|---|
| `rtl/riscv_core.v` | Single-cycle datapath (fetch, decode, execute, memory, write-back) |
| `rtl/alu.v`, `regfile.v`, `imm_gen.v`, `control.v` | ALU, 32x32 register file, immediate generator, main decoder |
| `rtl/imem.v`, `dmem.v` | Instruction ROM (`$readmemh`) and byte-enable data RAM |
| `rtl/uart_tx.v`, `rtl/soc.v` | 8N1 UART transmitter, SoC with memory-mapped LED/UART |
| `rtl/fpga_top.v` | Spartan-7 top: MMCM 100 -> 50 MHz, reset synchroniser |
| `tb/tb_soc.v` | Self-checking testbench (PASS/FAIL, VCD dump, instruction trace, UART receiver) |
| `sw/*.S` | Test programs: `sum`, `fib`, `loadstore`, `alu_branch`, `demo_uart_led` |
| `sw/asm.py` | Two-pass RV32I assembler (no RISC-V toolchain needed) |
| `sw/iss.py` | Independent golden-reference instruction-set simulator |
| `sim/hex/` | Assembled program images |
| `sim/expected/` | Golden-model results (`.json`) and instruction traces (`.trace`) |
| `docs/wave_*.png` | Golden-model PC / register plots per program |
| `fpga/arty_s7.xdc`, `fpga/build.tcl` | Constraints and Vivado batch build |

## Supported ISA

All RV32I user-level instructions: `LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW`
`ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ADD SUB SLL SLT SLTU XOR SRL SRA OR AND`.
`FENCE` is a NOP. `ECALL`/`EBREAK` halt the core (used by the testbench).

Not implemented: CSRs, interrupts/exceptions, misaligned access traps, M/C extensions.
The pipelined version (the "optional extra") is **not** included - this is the single-cycle core only.

## Simulate

```bash
sudo apt install iverilog gtkwave        # or brew install icarus-verilog gtkwave
make sim        # assemble, run all 5 tests on the RTL, write sim/logs/*.log and sim/waves/*.vcd
make compare    # RTL instruction trace == golden-model trace for every program
make wave       # open sim/waves/fib.vcd in GTKWave
```

A passing run ends every log with:

```
RESULT: PASS  test=<name>  (<n> checks)
```

Tests and what they check:

| Test | Checks | Expected |
|---|---|---|
| `sum` | loop + branch + store | 1+...+10 : `a0 = 55`, `mem[0] = 55` |
| `fib` | loop, `sw`/`lw`, array in RAM | `mem[0..15] = 0,1,1,2,3,5,...,610`, `a0 = 610 (0x262)` |
| `loadstore` | `sb sh sw lb lbu lh lhu lw`, sign extension, byte lanes | e.g. `lb -> 0xFFFFFFD4`, `lh -> 0xFFFFA1B2`, `mem[2] = 0xBEEF0000` |
| `alu_branch` | all 10 ALU ops + immediates, 6 branch types (taken & not taken), LUI, AUIPC, JAL, JALR | see `tb/tb_soc.v` |
| `demo` | MMIO, UART bit timing (decoded by a testbench receiver), LEDs | UART prints `RV32I OK fib(10)=55` + CRLF, LEDs = 55 |

The expected values were produced by `sw/iss.py` (written independently of the RTL) and
cross-checked by hand. Waveform views from the golden model are in `docs/wave_*.png`.

> **Status note:** the RTL in this repository was written and reviewed, but at the time of
> environment had none). Run `make sim` and `make compare` first; commit the generated
> `sim/logs/*.log` and `sim/waves/*.vcd` (small, except `demo.vcd`) as your real results.
> Only the Python golden model and plots in `docs/` and `sim/expected/` were executed.

## Run on the Spartan-7 board (Arty S7)

1. `make hex` - builds `sim/hex/demo_uart_led.hex`.
2. `make vivado` (or open Vivado and add `rtl/*.v` + `fpga/arty_s7.xdc`, top = `fpga_top`,
   pass generic `INIT_FILE` = absolute path of the hex file).
3. **Check `fpga/arty_s7.xdc` pins against Digilent's master XDC for your exact board**;
   for a different Spartan-7 board change the part in `build.tcl` and the pins.
4. Program `build/rv32i_arty_s7.bit`, open the USB serial port at **115200 8N1**
   (`screen /dev/ttyUSB1 115200` or PuTTY).

Expected on hardware:
- Terminal prints `RV32I OK fib(10)=55`.
- LEDs show `0111` (low nibble of 55) for ~0.6 s, then count up in binary every ~0.2 s.
- `BTN0` resets the CPU and prints the banner again.

The CPU runs at 50 MHz from the MMCM because a single-cycle datapath
(ROM -> regfile -> ALU -> RAM -> regfile) is long; check `build/timing.rpt` and adjust
`CLKOUT0_DIVIDE_F`/`CLKS_PER_BIT` if needed. Add photos / a screenshot of your terminal to
`docs/` once you have run it.

## Writing your own program

```bash
python3 sw/asm.py sw/myprog.S sim/hex/myprog.hex
python3 sw/iss.py sim/hex/myprog.hex          # golden result
```
Memory map for software: RAM `0x0000_0000`, LED `0x1000_0000`, UART `0x1000_0004`
(write = send byte, read bit 0 = busy).

## Possible extensions
5-stage pipeline with forwarding/hazard unit, M extension, CSR/trap support, block-RAM based memories.

## References
RISC-V Unprivileged ISA spec; the MYTH / "RISC-V in a day" workshop for architecture ideas
(this core is an independent Verilog implementation).
