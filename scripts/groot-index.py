#!/usr/bin/env python

from Bio import SeqIO
import gzip
import sys
import os
import argparse
import subprocess

def findMaxLength(reads):
    print("Finding maximum read length ...")
    maxLength = 0
    with gzip.open(reads, "rt") as f:
        for record in SeqIO.parse(f, "fastq"):
            if len(record.seq) > 0:
                maxLength = len(record.seq)
    return maxLength

def grootIndex(args, length):
    print("Indexing GROOT database ...")
    cmd_groot = ["groot", "index", "-p", args.threads, "-w", str(length), "-m", 
             args.database, "-i", args.output, "--log", args.output+"/index.log"]
    subprocess.check_call(cmd_groot)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Index GROOT database')
    parser.add_argument('-t', dest='threads', help='Number of threads', required=True)
    parser.add_argument('-i', dest='database', help='Database path', required=True)
    parser.add_argument('-r', dest='reads', help='FASTQ read file', required=True)
    parser.add_argument('-o', dest='output', help='Output name', required=True)
    if len(sys.argv) < 5:
        parser.print_help()
        sys.exit(1)
    else:
        args = parser.parse_args()
        maxLength = findMaxLength(args.reads)
        grootIndex(args, maxLength)
