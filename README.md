# Characterizing AMR genes in metagenomes

This is a Snakemake workflow relying on [GROOT](https://github.com/will-rowe/groot) for profiling antibiotic resistance genes in shotgun metagenomics data. It uses the `groot-db`, a reference database combining all sequences in ResFinder, ARG-annot and CARD clustered at 90% identity.

## Installation

1. Install [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html ) and [snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)

2. Clone repository
```
git clone https://github.com/alexmsalmeida/amr-profiler.git
```

## How to run

1. Edit the configuration file [`config/config.yml`](config/config.yml).
    - `input_file`: TSV file with paths to forward and reverse metagenomic reads to analyse (ending _1.fastq.gz and _2.fastq.gz).
    - `output_dir`: Directory to save output results.
    - `threshold`: Coverage and identity threshold for detecting gene presence (Default: `0.95`)
    - `ncores`: Number of cores to use for the analyses.

2. (option 1) Run the pipeline locally (adjust `-j` based on the number of available cores)
```
snakemake --use-conda -k -j 4
```
2. (option 2) Run the pipeline on a cluster (e.g., LSF)
```
snakemake --use-conda -k -j 100 --profile config/lsf --latency-wait 90
```

3. View the results in `{output_dir}/summary/`.

Files `amr_counts.tsv` contains the list of AMR genes and the number of reads mapped per sample. File `amr_classes.tsv` includes the list of genes detected per antibiotic class per sample.
