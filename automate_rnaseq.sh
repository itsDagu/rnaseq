#!/bin/bash
# This script is intended to automate the data cleaning process of the RNA-Seq pipeline.
# Requirements:

# Dependencies:
# - 'Trimmomatic'
# - 'FastQC'
# - 'Burrows-Wheeler Aligner'
# - 'SAMtools'
# - 'samstat'
# - 'htseq-count'

# Start input args:
# '-foo' main project directory
# Args:

# prints SRR#.fastq.gz
for files in fastq/*.fastq.gz;do echo $(basename $files});done
# prints SRR#,...
for files in fastq/*.fastq.gz;do echo $(basename ${files%.fastq.gz});done

# -----------
# TRIMMOMATIC 
# -----------

sudo apt install trimmomatic
mkdir -p trimmed
for files in fastq/*.fastq.gz; do java -jar /usr/share/java/trimmomatic-0.36.jar SE -trimlog trimmed/$(basename ${files%.fastq.gz})_log.txt fastq/$(basename ${files%.fastq.gz}).fastq.gz trimmed/`basename "${files%.fastq.gz}"`_trimmed.fastq.gz ILLUMINACLIP:/usr/share/trimmomatic/TruSeq3-SE.fa:2:3:10 SLIDINGWINDOW:4:20 MINLEN:36; done

# trimjar = /usr/share/java/trimmomatic-0.36.jar
# y = $(`basename $files`)
# trimmed/`$y`_log.txt

# ------
# FastQC
#-------

mkdir -p trimmed_fastqc
fastqc trimmed/*_trimmed.fastq.gz --outdir trimmed_fastqc/

# -------
# BWA-mem
# -------

# 1. Must donwnload genome fasta file and make index using
# bwa index [genome.fa]

mkdir -p bwa
for files in trimmed/*.fastq.gz; do bwa mem -t 8 GRCh38.p3.genome.fa.gz $files > bwa/$(basename ${files%_trimmed.fastq.gz}).sam; done

# --------
# SAMtools
# --------

mkdir -p bam
#convert sam>bam
for files in bwa/*.sam; do samtools view -b -S $files > bam/$(basename ${files%.sam}).bam;done
# compile bam files as sorted by chromosomal location
for files in bam/*.bam; do samtools sort $files -o bam/$(basename ${files%.bam}).sorted.bam;done

# -------
# SAMstat
# -------

samstat bam/*.sorted.bam

# -----------------
# SAMtools Namesort
# -----------------

mkdir -p namesort
for files in bam/*.sorted.bam; do samtools sort -n $files -o namesort/$(basename ${files%.sorted.bam}).namesorted.bam;done

# ---------------
# FastQC Namesort
# ---------------

mkdir -p bam_fastqc
fastqc namesort/*.namesorted.bam -o bam_fastqc

# -----------
# HTseq-Count
# -----------

mkdir -p counts
for files in namesort/*.bam;do samtools view -h $files | htseq-count --mode intersection-strict --stranded no --minaqual 1 --type exon --idattr gene_id - gencode.v23.annotation.gtf > counts/$(basename ${files%.namesorted.bam}).counts.table.tsv; done