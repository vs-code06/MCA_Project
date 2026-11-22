#!/usr/bin/env bash
# ============================================================================
# Script: run_phase2_sim.sh
# Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
# Team: Decoders07
# Description: Compiles and runs Phase 2 Level-1 Cache and AMAT simulations
#              using Icarus Verilog (iverilog) and VVP.
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=================================================================="
echo "  [1/3] Assembling Phase 2 Benchmark Memory Images..."
echo "=================================================================="
python3 scripts/phase2_assembler.py

echo ""
echo "=================================================================="
echo "  [2/3] Compiling and Running L1 Cache Verification Testbench..."
echo "=================================================================="
iverilog -g2005-sv -o sim/tb_cache_system.vvp \
    rtl/common/program_counter.v \
    rtl/common/simple_processor.v \
    rtl/cache/i_cache.v \
    rtl/cache/d_cache.v \
    rtl/cache/main_memory.v \
    rtl/cache/modified_harvard_top.v \
    tb/tb_cache_system.v

vvp sim/tb_cache_system.vvp

echo ""
echo "=================================================================="
echo "  [3/3] Compiling and Running 3-Way AMAT Comparative Benchmark..."
echo "=================================================================="
iverilog -g2005-sv -o sim/tb_phase2_amat.vvp \
    rtl/common/program_counter.v \
    rtl/common/address_decoder.v \
    rtl/common/simple_processor.v \
    rtl/harvard/instruction_memory.v \
    rtl/harvard/data_memory.v \
    rtl/harvard/memory_controller.v \
    rtl/harvard/harvard_top.v \
    rtl/von_neumann/arbiter.v \
    rtl/von_neumann/shared_memory_top.v \
    rtl/cache/i_cache.v \
    rtl/cache/d_cache.v \
    rtl/cache/main_memory.v \
    rtl/cache/modified_harvard_top.v \
    tb/tb_phase2_amat.v

vvp sim/tb_phase2_amat.vvp

echo ""
echo "=================================================================="
echo "  Phase 2 Simulations Completed Successfully!"
echo "  Waveforms generated:"
echo "    - sim/phase2_cache.vcd"
echo "    - sim/phase2_amat.vcd"
echo "=================================================================="
