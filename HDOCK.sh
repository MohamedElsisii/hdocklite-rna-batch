#!/bin/bash
#
#####################################
#                                   #
#                                   #
# Copyright (c) 2025 Mohamed Elsisi #
#                                   #
#                                   #
#####################################
# ==============================================================================
# Batch Protein-Ligand Docking with HDOCK
# ==============================================================================
#
# Description:
#   This script automates batch docking for a single protein receptor against
#   multiple RNA aptamer ligands using the HDOCKlite program.
#
#   It performs the following steps for each ligand:
#     1. Creates a dedicated result directory.
#     2. Runs 'hdock' using the specified receptor and ligand.
#     3. Moves the main 'Hdock.out' file to the result directory.
#     4. Runs 'createpl' to generate the top 10 complex models.
#     5. Moves the 'hdock.log' file for review.
#
# Dependencies:
#   - HDOCK (both 'hdock' and 'createpl' executables must be in your $PATH)
#
# Assumed Directory Structure:
#   ./                      (Your project root, where you run this script)
#   ├── BCL-2.pdb           (Your receptor file)
#   ├── rsite.txt           (Receptor binding site file)
#   ├── Ligands/            (Directory containing all ligand .pdb files)
#   │   ├── aptamer1.pdb
#   │   └── aptamer2.pdb
#   ├── Results/            (This directory will be created)
#   └── dock_all.sh         (This script)
#
# Usage:
#   1. Place this script in your project's root directory.
#   2. Make it executable: chmod +x dock_all.sh
#   3. Run it: ./dock_all.sh
#
# ==============================================================================

# --- Script Configuration ---

# 'set -e': Exit immediately if any command fails.
# 'set -u': Treat unset variables as an error.
# 'set -o pipefail': Causes a pipeline (e.g., cmd1 | cmd2) to fail
#                    if any command in it fails.
set -euo pipefail

# --- Path Definitions ---
# By using $(pwd), the script becomes portable. It uses the directory
# from which it's run as the base, instead of a hardcoded '~/...' path.
WORKDIR=$(pwd)
RECEPTOR="$WORKDIR/BCL-2.pdb"
RSITE="$WORKDIR/rsite.txt"
LIGAND_DIR="$WORKDIR/Ligands"
RESULTS_DIR="$WORKDIR/Results"

# --- Helper Function: Dependency Check ---
# Checks if 'hdock' and 'createpl' are installed and in the $PATH
check_dependencies() {
    echo "🔎 Checking for dependencies..."
    if ! command -v hdock &> /dev/null; then
        echo "❌ ERROR: 'hdock' command not found."
        echo "Please install HDOCK and ensure 'hdock' is in your system's PATH."
        exit 1
    fi
    if ! command -v createpl &> /dev/null; then
        echo "❌ ERROR: 'createpl' command not found."
        echo "Please install HDOCK and ensure 'createpl' is in your system's PATH."
        exit 1
    fi
    echo "✅ All dependencies found."
}

# --- Main Script ---

# 1. Run Pre-Flight Checks
check_dependencies

echo "================================================="
echo "        HDOCK Batch Processing Started"
echo "================================================="
echo "Receptor: $RECEPTOR"
echo "Ligands:  $LIGAND_DIR"
echo "Results:  $RESULTS_DIR"
echo "-------------------------------------------------"

# Check that required files and directories exist
if [ ! -f "$RECEPTOR" ]; then
    echo "❌ ERROR: Receptor file not found at $RECEPTOR"
    exit 1
fi
if [ ! -f "$RSITE" ]; then
    echo "❌ ERROR: Receptor site file not found at $RSITE"
    exit 1
fi
if [ ! -d "$LIGAND_DIR" ]; then
    echo "❌ ERROR: Ligand directory not found at $LIGAND_DIR"
    exit 1
fi

# Create the main results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# 2. Start the Processing Loop
#    Find all .pdb files in the LIGAND_DIR
find "$LIGAND_DIR" -maxdepth 1 -type f -name "*.pdb" | while read -r LIGAND_PATH; do
    
    # Extract just the filename (e.g., "aptamer1.pdb")
    LIGAND_FILE=$(basename "$LIGAND_PATH")
    # Extract the name without extension (e.g., "aptamer1")
    LIGAND_NAME="${LIGAND_FILE%.pdb}"
    
    # Define paths for this specific ligand
    LIGAND_RESULT_DIR="$RESULTS_DIR/$LIGAND_NAME"
    HDOCK_OUT="$LIGAND_RESULT_DIR/${LIGAND_NAME}_hdock.out"

    echo -e "\n--- Processing Ligand: $LIGAND_NAME ---"

    # Skip if output already exists (makes the script resumable)
    if [ -f "$HDOCK_OUT" ]; then
        echo "⏭️ Skipping (result file already exists)"
        continue
    fi

    # Create the dedicated result directory for this ligand
    mkdir -p "$LIGAND_RESULT_DIR"

    # --- Run HDOCK ---
    echo "🔄 Running HDOCK..."
    # 'hdock' writes its output (Hdock.out) to the current working directory
    hdock "$RECEPTOR" "$LIGAND_PATH" -rsite "$RSITE"

    # Move and rename the Hdock.out file
    if [ -f "$WORKDIR/Hdock.out" ]; then
        mv "$WORKDIR/Hdock.out" "$HDOCK_OUT"
    else
        echo "❌ HDOCK failed to produce Hdock.out for $LIGAND_NAME"
        # Clean up the empty directory we just made
        rmdir "$LIGAND_RESULT_DIR"
        continue # Move to the next ligand
    fi

    # --- Run createpl ---
    echo "🧬 Generating top 10 models..."
    
    # This is a cleaner way to handle output files.
    # 'pushd' changes directory, and 'popd' returns you to where you were.
    # We go *into* the result directory so 'createpl' writes all its
    # output files (model_*.pdb, top10.pdb) directly there.
    pushd "$LIGAND_RESULT_DIR" > /dev/null
    
    createpl "$HDOCK_OUT" \
             "${LIGAND_NAME}_top10.pdb" \
             -nmax 10 -complex -models -rsite "$RSITE"

    # Return to the main WORKDIR
    popd > /dev/null

    # Clean up the log file 'hdock' leaves in the main directory
    if [ -f "$WORKDIR/hdock.log" ]; then
        mv "$WORKDIR/hdock.log" "$LIGAND_RESULT_DIR/${LIGAND_NAME}_hdock.log"
    fi

    echo "✅ Finished: $LIGAND_NAME"
done

echo "================================================="
echo "🎉 All ligands processed successfully!"