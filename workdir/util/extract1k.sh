#!/bin/bash
# Extract the contigs > 1k of an assembly
#   $1  Source file
#   $2  Target file

UTIL_DIR='util'
$UTIL_DIR/bioawk -c fastx '{if(length($seq)>1000){print ">"$name; print $seq}}' $1 > $2
