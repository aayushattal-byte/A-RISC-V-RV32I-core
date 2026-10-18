#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p results
iverilog -g2012 -s tb_rv32i -o results/sim.vvp rtl/rv32i_core.v tb/tb_rv32i.v
vvp results/sim.vvp | tee results/simulation_log.txt
printf '\nWaveform: results/rv32i.vcd\n'
