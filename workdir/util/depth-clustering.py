#!/bin/bash
# Generating the finalized clusters
#   Arguments: a list of depths .tsv files, with the last argument being the output directory

import sys
import numpy as np
from sklearn.preprocessing import normalize
from scipy.cluster.hierarchy import linkage, fcluster

cellnames = []
depths = {}
groupname = sys.argv[1].split('/')[-1].split('_')[1].split('.')[0]
outdir = sys.argv[-1]

for filename in sys.argv[1:-1]:
    cellnames.append(filename.split('/')[-1].split('_')[0])
    with open(filename) as file:
        for line in file:
            row = line.replace('\n', '').split('\t')
            if row[0] not in depths:
                depths[row[0]] = []
            depths[row[0]].append([ len(cellnames) - 1, float(row[2]) ])

contigs = []
mat = np.zeros((len(cellnames), len(depths)))

for contig, contig_depths in depths.items():
    contigs.append(contig)
    for depth in contig_depths:
        mat[depth[0]][len(contigs) - 1] = depth[1]

# The feature vectors are the rows
normalized = normalize(normalize(mat, axis = 0), axis = 1)

# Cluster assignments
assignments = fcluster(linkage(normalized, method = 'complete', metric='euclidean'), 1.4, 'distance')

# Writing to files
gathered = [ [] for i in range(max(assignments)) ]

for i, assign in enumerate(assignments):
    gathered[assign - 1].append(cellnames[i])

for i, group in enumerate(gathered):
    with open(outdir + '/' + groupname + '-' + str(i + 1) + '.tsv', 'w') as outfile:
        for cellname in gathered[i]:
            outfile.write('%s\n' % cellname)
