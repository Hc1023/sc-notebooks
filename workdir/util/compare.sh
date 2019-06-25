#!/bin/bash
# Compare a list of cells
# Arguments:
#   $1  File containing a list of cells
#   $2  Signature dir
#   $3  Output base name

# Lines for configuring sourmash
# Modify them accordingly
module add c3ddb/miniconda/3.7
source activate sourmash

CELLS=$(cat $1)
SIGS=""

for CELL in $CELLS; do
    SIGS="$SIGS $2/$CELL.json"
done

sourmash compare $SIGS -k 51 --output $3.npy --csv $3.csv
