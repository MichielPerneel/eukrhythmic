#!/bin/bash

snakemake   \
        --jobs 100 --use-conda -s ../modules/trimmomatic-snake  \
        --cluster-config ../cluster.yaml --cluster "sbatch --parsable --qos=unlim --partition={cluster.queue} --job-name=WAP.{rule}.{wildcards} --mem={cluster.mem}gb --time={cluster.time} --ntasks={cluster.threads} --nodes={cluster.nodes}"
