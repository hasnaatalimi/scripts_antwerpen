#!/bin/bash

while getopts ':I:R:F:Q:h' OPTION ; do
case $OPTION in
        
	R) ref=$OPTARG;;
	F) r1=$OPTARG;;
	Q) r2=$OPTARG;;
	I) i=$OPTARG;;
	h) echo "USAGE of the program:"
	echo "   -R    Genome reference file"
	echo "   -F    R1 fastq file"
	echo "   -Q    R2 fastq file"
	echo "   -I    Prefix"
	exit 0;;

esac
done



PICARD=/home/hasnaa/Leishmania_NGS/tools/picard-tools-1.140/picard.jar
GATK=/home/hasnaa/Leishmania_NGS/tools/gatk-4.0.10.1/GenomeAnalysisTK.jar
#Trimmomatic=/home/hasnaa/Leishmania_NGS/tools/Trimmomatic-0.36/trimmomatic-0.36.jar

#Trimming
#java -jar $Trimmomatic SE -phred33 $f1 ${i}_r1.fastq.gz LEADING:30 TRAILING:30 SLIDINGWINDOW:4:30 MINLEN:30
#r1=${i}_r1.fastq.gz

#java -jar $Trimmomatic SE -phred33 $f2 ${i}_r2.fastq.gz LEADING:30 TRAILING:30 SLIDINGWINDOW:4:30 MINLEN:30
#r2=${i}_r2.fastq.gz

#index the fasta file
bwa index -a bwtsw $ref

#Mapping 
bwa mem -M -t 4 $ref $r1 $r2 > ${i}.sam


#sam to bam
samtools view -Shb ${i}.sam > ${i}.bam

#to sort the bam file
samtools sort ${i}.bam -o ${i}_sorted.bam

#to index the bam file after the sort
samtools index ${i}_sorted.bam

#Indexing Reference
samtools faidx $ref

#CreateDictionary
java -jar $PICARD CreateSequenceDictionary R=$ref O=${i}.dict VALIDATION_STRINGENCY=SILENT

#AddOrReplaceReadGroups
java -jar $PICARD AddOrReplaceReadGroups I=${i}_sorted.bam O=${i}_sorted_AORRG.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT RGLB=Library RGPL=illumina RGID=Sample RGPU=Unit RGSM=Sample_name

#Indexing BAM
samtools index ${i}_sorted_AORRG.bam

## GATK RealignerTargetCreator
java -jar $GATK -T RealignerTargetCreator -R $ref -I ${i}_sorted_AORRG.bam -o ${i}_sorted_AORRG.intervals


## GATK IndelRealigner
java -jar -Xmx8g $GATK -T IndelRealigner -targetIntervals ${i}_sorted_AORRG.intervals -R $ref -I ${i}_sorted_AORRG.bam -o ${i}_sorted_AORRG_realigned.bam


#MarkDuplicats
java -jar $PICARD MarkDuplicates I=${i}_sorted_AORRG_realigned.bam O=${i}_sorted_AORRG_realigned_rmdup.bam VALIDATION_STRINGENCY=LENIENT M=${i}.MarkDup.log TMP_DIR=${i}_MarkDuplicatesTMPDIR


#Indexing BAM
samtools index ${i}_sorted_AORRG_realigned_rmdup.bam




echo " \n \n E N D "

