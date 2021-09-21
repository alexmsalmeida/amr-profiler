import os

configfile: 'config/config.yml'
ncores = config['ncores']

INPUT_FILE = config['input_file']
OUTPUT_DIR = config['output_dir']

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

os.system("chmod -R +x scripts")

samp2path = {}
with open(INPUT_FILE) as f:
    for line in f:
        cols = line.strip().split()
        fwd = cols[0]
        rev = cols[1]
        sample = os.path.basename(cols[0]).split("_1.fastq")[0]
        samp2path[sample] = [fwd, rev]

def concat(input, output):
    with open(output, 'w') as outfile:
        for fname in input:
            with open(fname) as infile:
                outfile.write(infile.read())

rule targets:
    input:
        OUTPUT_DIR+"/summary/amr_counts.tsv",
        OUTPUT_DIR+"/summary/amr_classes.tsv"

rule download_db:
    input:
        INPUT_FILE
    output:
        directory("database/groot-db.90")
    conda:
        "config/environment.yml"
    shell:
        "groot get -d groot-db -o database"

rule setup_files:
    input:
        fwd = lambda wildcards: samp2path[wildcards.sample][0],
        rev = lambda wildcards: samp2path[wildcards.sample][1],
        db = rules.download_db.output
    output:
        fwd = temp(OUTPUT_DIR+"/runs/{sample}/{sample}_1.fastq.gz"),
        rev = temp(OUTPUT_DIR+"/runs/{sample}/{sample}_2.fastq.gz"),
        index = temp(directory(OUTPUT_DIR+"/runs/{sample}/groot_index"))
    conda:
        "config/environment.yml"
    resources:
        ncores = ncores
    shell:
        """
        reformat.sh in1={input.fwd} in2={input.rev} out1={output.fwd} out2={output.rev} minlength=31
        python scripts/groot-index.py -t {resources.ncores} -i {input.db} -r {output.fwd} -o {output.index}
        """

rule groot_main:
    input:
        fwd = OUTPUT_DIR+"/runs/{sample}/{sample}_1.fastq.gz",
        rev = OUTPUT_DIR+"/runs/{sample}/{sample}_2.fastq.gz",
        db = OUTPUT_DIR+"/runs/{sample}/groot_index"
    output:
        graph = directory(OUTPUT_DIR+"/runs/{sample}/{sample}_graphs"),
        report = OUTPUT_DIR+"/runs/{sample}/{sample}.report",
        counts = OUTPUT_DIR+"/runs/{sample}/{sample}_amr_counts.tsv",
        classes = OUTPUT_DIR+"/runs/{sample}/{sample}_amr_classes.tsv"
    params:
        log = OUTPUT_DIR+"/runs/{sample}/groot.log",
        res_db = "scripts/res_classes.tsv"
    conda:
        "config/environment.yml"
    resources:
        ncores = ncores
    shell:
        """
        groot align -p {resources.ncores} -t 0.95 -i {input.db} -f {input.fwd},{input.rev} -g {output.graph} --log {params.log} | groot report -c 0.95 --log {params.log} > {output.report}
        python scripts/parse_groot-report.py {params.res_db} {output.report}
        """

rule summarize:
    input:
        counts = expand(OUTPUT_DIR+"/runs/{sample}/{sample}_amr_counts.tsv", sample=samp2path.keys()),
        classes = expand(OUTPUT_DIR+"/runs/{sample}/{sample}_amr_classes.tsv", sample=samp2path.keys())
    output:
        counts = OUTPUT_DIR+"/summary/amr_counts.tsv",
        classes = OUTPUT_DIR+"/summary/amr_classes.tsv"
    params:
        sum_dir = OUTPUT_DIR+"/summary/"
    run:
        if not os.path.exists(params.sum_dir):
            os.makedirs(params.sum_dir)

        concat(input.counts, output.counts)
        concat(input.classes, output.classes)
