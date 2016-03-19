# GetProphagesByBlast.sh
# Geoffrey Hannigan
# Pat Schloss Lab
# University of Pennsylvania
# NOTE: One way to predict whether a phage is associated with a
# bacterium is to determine whether the phage integrates into that
# bacterium. The simplest way to do this is simply using blast to
# determine whether the phage or it's genes are found within the
# bacterial host.

# Platform: Axiom

#PBS -N GetProphagesByBlast
#PBS -q first
#PBS -l nodes=1:ppn=8,mem=44gb
#PBS -l walltime=500:00:00
#PBS -j oe
#PBS -V
#PBS -A schloss_lab

#######################
# Set the Environment #
#######################
export WorkingDirectory=/mnt/EXT/Schloss-data/ghannig/Hannigan-2016-ConjunctisViribus/data
export Output='InteractionsByBlast'

export PhageGenomes=/mnt/EXT/Schloss-data/ghannig/Hannigan-2016-ConjunctisViribus/data/phageSVAnospace.fa
export BacteriaGenomes=/mnt/EXT/Schloss-data/ghannig/Hannigan-2016-ConjunctisViribus/data/bacteriaSVAnospace.fa

# Make the output directory and move to the working directory
echo Creating output directory...
cd ${WorkingDirectory}
mkdir ./${Output}

BlastPhageAgainstBacteria () {
	# 1 = Phage Genomes
	# 2 = Bacterial Genomes

	echo Making blast database...
	makeblastdb \
		-dbtype nucl \
		-in ${2} \
		-out ./${Output}/BacteraGenomeReference

	echo Running blastn...
	blastn \
    	-query ${1} \
    	-out ./${Output}/PhageToBacteria.blastn \
    	-db ./${Output}/BacteraGenomeReference \
    	-evalue 1e-3 \
    	-num_threads 8\
    	-outfmt 6

    echo Formatting blast output...
    # Get the Spacer ID, Phage ID, and Percent Identity
	cut -f 1,2,3 ./${Output}/PhageToBacteria.blastn \
		| sed 's/_\d\+\t/\t/' \
		> ./${Output}/PhageBacteriaHits.tsv
}

export -f BlastPhageAgainstBacteria

BlastPhageAgainstBacteria \
	${PhageGenomes} \
	${BacteriaGenomes}