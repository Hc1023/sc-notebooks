#!/bin/bash
# Dividing the raw data to several divisions
# and generate lists of cell numbers

# Configurations
DIVISION_SIZE=4000
SOURCE_DIR="raw"
TARGET_DIR="divisions"
mkdir -p $TARGET_DIR

FILES=$(cd $SOURCE_DIR && ls *_1.fastq)

i=0
for FILE in $FILES; do
    if ! (( i % $DIVISION_SIZE )); then
        printf "" > "$TARGET_DIR/$(( i/$DIVISION_SIZE )).tsv"
    fi
    FILE_NO=${FILE//_1.fastq}
    echo $FILE_NO >> "$TARGET_DIR/$(( i/$DIVISION_SIZE )).tsv"
    i=$(( i + 1 ))
done
