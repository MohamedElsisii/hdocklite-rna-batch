# RNA-Protein Docking Using HDOCKlite
![Untitled-1](https://github.com/user-attachments/assets/6dbed2ed-e0f3-4877-afab-6853bd8fb5a2)
A Bash script pipeline to automate RNA-to-protein molecular docking. Processes multiple RNA ligands against a target protein using HDocklite.
This script is designed to be run in a project directory, where it will loop through all `.pdb` files in a `Ligands/` directory, run them against a specified receptor, and organize all outputs neatly into a `Results/` directory.

## Features

* **Batch Processing**: Dock hundreds of ligands with a single command.
* **Automated Organization**: Creates a dedicated folder for each ligand's results.
* **Resumable**: Automatically skips ligands that have already been processed.
* **User-Friendly Output**: Color-coded terminal output shows successes, skips, and errors.
* **Dependency Check**: Verifies that `hdock` and `createpl` are installed before running.
* **Portable**: Uses relative paths, so it can be run from any directory.

## Dependencies

This script acts as a wrapper for **HDocklite**. You must have the HDocklite executables (`hdock` and `createpl`) installed and available in your system's `$PATH`.

* **Download HDocklite:** You can download the program from the official website:
    [**http://huanglab.phys.hust.edu.cn/software/hdocklite/**](http://huanglab.phys.hust.edu.cn/software/hdocklite/)

## Required Directory Structure

For the script to work, your project folder **must** be organized as follows:

```text
.
├── BCL-2.pdb           <-- Your protein receptor PDB file
├── rsite.txt           <-- Your receptor binding site file
├── HDOCK.sh         <-- This script
│
├── Ligands/            <-- Directory containing all your ligand files
│   ├── rna_aptamer_1.pdb
│   ├── rna_aptamer_2.pdb
│   └── ...
│
└── Results/            <-- This directory will be created by the script
    ├── rna_aptamer_1/
    │   ├── rna_aptamer_1_hdock.out
    │   ├── rna_aptamer_1_hdock.log
    │   ├── rna_aptamer_1_top10.pdb
    │   ├── model_1.pdb
    │   ├── ...
    │   └── model_10.pdb
    │
    └── rna_aptamer_2/
        └── ...
```


        
**Note:** You must edit the `HDOCK.sh` script to match your filenames for the `RECEPTOR` (`BCL-2.pdb`) and `RSITE` (`rsite.txt`) files.

```bash
# --- Path Definitions ---
# ...
RECEPTOR="$WORKDIR/BCL-2.pdb"  # <-- EDIT THIS
RSITE="$WORKDIR/rsite.txt"     # <-- EDIT THIS
LIGAND_DIR="$WORKDIR/Ligands"
# ...
```
# Usage

1.  **Place Files:** Organize your files as shown in the directory structure above.
2.  **Make Executable:** Open your terminal and give the script execute permissions:
    ```bash
    chmod +x HDOCK.sh
    ```
3.  **Run:** Execute the script from your main project directory:
    ```bash
    ./HDOCK.sh
    ```

The script will begin processing all ligands in the `Ligands` folder. You will see its progress, and all output files will be sorted into the `Results` directory.
