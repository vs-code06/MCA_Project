#!/usr/bin/env bash
# ============================================================================
# Script: run_sim.sh
# Project: Project 9 - Instruction and Data Memory Hierarchy
# Authors: Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, Kartik Mehra
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=================================================================="
echo "  [1/3] Assembling Benchmark Program (generating .mem hex files)..."
echo "=================================================================="
python3 scripts/assembler.py

echo ""
echo "=================================================================="
echo "  [2/3] Compiling and Running Harvard Architecture Simulation..."
echo "=================================================================="
iverilog -g2005-sv -o sim/tb_harvard.vvp \
    rtl/common/program_counter.v \
    rtl/common/address_decoder.v \
    rtl/common/simple_processor.v \
    rtl/harvard/instruction_memory.v \
    rtl/harvard/data_memory.v \
    rtl/harvard/memory_controller.v \
    rtl/harvard/harvard_top.v \
    tb/tb_harvard_memory.v

vvp sim/tb_harvard.vvp

echo ""
echo "=================================================================="
echo "  [3/3] Compiling and Running Comparative Benchmark (Harvard vs Von Neumann)..."
echo "=================================================================="
iverilog -g2005-sv -o sim/tb_comparison.vvp \
    rtl/common/program_counter.v \
    rtl/common/address_decoder.v \
    rtl/common/simple_processor.v \
    rtl/harvard/instruction_memory.v \
    rtl/harvard/data_memory.v \
    rtl/harvard/memory_controller.v \
    rtl/harvard/harvard_top.v \
    rtl/von_neumann/arbiter.v \
    rtl/von_neumann/shared_memory_top.v \
    tb/tb_shared_vs_harvard.v

vvp sim/tb_comparison.vvp

echo ""
echo "=================================================================="
echo "  Simulations Completed Successfully!"
echo "  Waveforms generated:"
echo "    - sim/harvard_sim.vcd"
echo "    - sim/comparison_sim.vcd"
echo "=================================================================="
