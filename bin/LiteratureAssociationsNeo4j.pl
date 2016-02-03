#!usr/bin/perl
# LiteratureAssociationsNeo4j.pl
# Geoffrey Hannigan
# Patrick Schloss Lab
# University of Michigan

# NOTE: Don't need an output file for this since the
# neo4j connected database is the output

# WARNING: This is reading off of the disk, which
# needs to be changed to memory to improve performance.

# Set use
use strict;
use warnings;
# Use the neo4j module to facilitate interaction
use REST::Neo4p;
# For documentation and whatnot
use Getopt::Long;
use Pod::Usage;
# And because I like timing myself
my $start_run = time();

# Set variables
my $opt_help;
my $output;
my $input;
my $flag = 0;
my $n1;
my $n2;
my $sequence;
my $formatVar;
my $FullName;
my $Genus;
my $Species;
my $formname = 0;
my $Spacer;
my $crispr;
my $PhageTarget;
my $PercentID;

# Startup the neo4j connection using default location
# Be sure to set username and password as neo4j
# User = 2nd value, PW = 3rd value
eval {
    REST::Neo4p->connect('http://127.0.0.1:7474','neo4j','neo4j');
};
ref $@ ? $@->rethrow : die $@ if $@;

# Set the options
GetOptions(
    'h|help' => \$opt_help,
    'i|input=s' => \$input,
    'c|crispr=s' => \$crispr
);

pod2usage(-verbose => 1) && exit if defined $opt_help;

# Open files
open(IN, "<$input") || die "Unable to read in $input: $!";
open(CRISPR, "<$crispr") || die "Unable to read in $crispr: $!";

# Parse the input and save into neo4j
# Get the literature data
foreach my $line (<IN>) {
    chomp $line;
    # Start the script by resetting the flag for each iteraction
    # within the file
    if ($line =~ /^ID\s/) {
        print STDOUT "Resetting counter...\n";
        $flag = 0;
        $n1 = 0;
        $n2 = 0;
        $formatVar = 0;
        $formname = 0;
        next;
    } elsif ($flag =~ 0 & $line =~ /^OS\s+(\w.+$)/) {
        # File really should already be without spaces though
        ($formname = $1) =~ s/\s/_/g;
        print STDOUT "Phage is $formname\n";
        $n1 = REST::Neo4p::Node->new( {Name => $formname} );
        $n1->set_property( {Organism => 'Phage'} );
        $flag = 1;
        next;
    } elsif ($flag =~ 1 & $line =~ /host=\"(.+)\"/) {
        ($FullName = $1) =~ s/\s/_/g;
        print STDOUT "Host is $FullName\n";
        $Genus = (split /_/, $FullName)[0];
        $Species = $Genus."_".(split /_/, $FullName)[1];
        print STDOUT "Host genus is $Genus\n";
        print STDOUT "Host species is $Species\n";
        $n2 = REST::Neo4p::Node->new( {Name => $FullName} );
        $n2->set_property( {Genus => $Genus} );
        $n2->set_property( {Species => $Species} );
        $n2->set_property( {Organism => 'Bacterial_Host'} );
        $n1->relate_to($n2, 'Infects');
    } elsif ($flag =~ 1 && $line =~ /^\s+([agct\s]+[agct])\s+[0-9]+$/) {
        $formatVar = $1;
        $formatVar =~ s/\s//g;
        $sequence = $formatVar;
        $flag = 2;
    } elsif ($flag =~ 2 && $line =~ /^\s+([agct\s]+[agct])\s+[0-9]+$/) {
        $formatVar = $1;
        $formatVar =~ s/\s//g;
        $sequence = $sequence.$formatVar;
    } elsif ($flag =~ 2 && $line =~ /^\/\//) {
        $n1->set_property({ Sequence => $sequence });
        $flag = 1;
        $sequence = 0;
    } else {
        next;
    }
}

# Add in the CRISPR match data
foreach my $line (<CRISPR>) {
    chomp $line;
    $line =~ s/^(\S+)_\d+\t/$1/g;
    $Spacer = (split /\t/, $line)[0];
    $PhageTarget = (split /\t/, $line)[1];
    $PercentID = (split /\t/, $line)[2];
    $n1 = REST::Neo4p::Node->new( {Name => $PhageTarget} );
    $n2 = REST::Neo4p::Node->new( {Name => $Spacer} );
    $n2->relate_to($n1, 'CrisprTarget');
}


# See how long it took
my $end_run = time();
my $run_time = $end_run - $start_run;
print STDERR "Processed the file in $run_time seconds.\n";
