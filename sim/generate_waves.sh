#!/usr/bin/env bash
# ============================================================================
# Script: generate_waves.sh
# Project: Project 9 - Instruction and Data Memory Hierarchy
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "harvard_sim.vcd" ]; then
    echo "[INFO] Running simulation first to generate VCD..."
    ../sim/run_sim.sh
fi

if command -v gtkwave &> /dev/null; then
    echo "[INFO] Launching GTKWave on sim/harvard_sim.vcd..."
    gtkwave harvard_sim.vcd &
else
    echo "[NOTE] GTKWave is not installed or not in PATH."
    echo "       You can install it on macOS via: brew install --cask gtkwave"
    echo "       Waveform VCD files are generated and ready at:"
    echo "         1. $(pwd)/harvard_sim.vcd"
    echo "         2. $(pwd)/comparison_sim.vcd"
fi
