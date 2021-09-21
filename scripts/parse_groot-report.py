#!/usr/bin/env python

import sys
import os

if len(sys.argv) < 2:
    print("usage: script.py res_classes.tsv groot.report")
    sys.exit(1)

bla = ["CTX", "TEM", "OXA", "SHV", "OXY", "LEN", 
       "MIR", "DHA", "CMY", "PDC", "OKP", "CBL"]

arg = {"AGL": "Aminoglycoside", "MLS": "MLS",
       "TMT": "Trimethoprim", "PHE": "Phenicol"} 

resfinder = {}

# store resfinder ontology
with open(sys.argv[1], "r") as f:
    for line in f:
        line = line.strip("\n")
        cols = line.split("\t")
        gene = cols[0][:3].upper()
        name = cols[1]
        resfinder[gene] = name

groot = {}
name = sys.argv[2].split(".report")[0]
amr_counts = open(name+"_amr_counts.tsv", "w")
amr_classes = open(name+"_amr_classes.tsv", "w")

# go through groot report
with open(sys.argv[2], "r") as f:
    for line in f:
        line = line.strip("\n")
        cols = line.split("\t")
        amr_counts.write("%s\t%s\n" % (os.path.basename(name), "\t".join(cols[:-1])))
        full_gene = cols[0]
        if "RESFINDER" in full_gene:
            gene = full_gene.split("__")[-1].split("_")[0].upper()
            abclass = resfinder[gene[:3]]
        elif "CARD" in full_gene:
            gene = full_gene.split("|")[-1].upper()
            try:
                abclass = resfinder[gene[:3]]
            except:
                if gene[:3] in bla:
                    abclass = "Beta-lactam"
                else:
                    abclass = "Other"
        elif "ARGANNOT" in full_gene:
            gene = full_gene.split("__")[-1].split(":")[0].upper()
            if "(AGly_Flqn)" in gene:
                abclass = "Aminoglycoside/Fluoroquinolone"
            else:
                try:
                    abclass = resfinder[gene[1:4]]
                except:
                    try:
                        gene_name = gene.split(")")[-1][:3]
                        abclass = resfinder[gene_name]
                    except:
                        abbrev = gene[1:4]
                        try:
                            abclass = arg[abbrev]
                        except:
                            abclass = "Other"
        if abclass not in groot.keys():
            groot[abclass] = 1
        else:
            groot[abclass] += 1

for class_name in groot:
    amr_classes.write("%s\t%s\t%i\n" % (os.path.basename(name), class_name, groot[class_name]))

amr_counts.close()
amr_classes.close()
