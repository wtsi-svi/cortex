#!/usr/bin/perl -w
use strict;

use File::Basename;

my $mem_height = 22;
my $mem_width = 73;
my $pop="";

my $vcf=shift;
my $outfile = shift;
my $kmer = shift;


open(OUT, ">".$outfile)||die("Cannot open the specified output file: $outfile\n");   

open(VCF, $vcf)||die();
while (<VCF>)
{
    my $line = $_;
    if ($line !~ /^\#/)
    {
	my @sp = split(/\t/, $line);
	my $name = $sp[2];
	my $ref = $sp[3];
	my $alt = $sp[4];
	my $info = $sp[7];
	my $left;
	my $right;

	## left_flank=ATTAGATTTGACCTTCAGCAAGGTCAAAGGGAGTC;right_flank=GAACTAGTCTCAGGCTTCAACATCGAAT
	if ($info =~ /left_flank=(\S+);right_flank=(\S+)/)
	{
	    $left  = uc($1);
	    $right = uc($2);
	    if ( (length($left)<$kmer) || (length($right)<$kmer) )
	    {
		## just pad with Ns - this must be a call at the end of a chromosome.
		while (length($left)<$kmer)
		{
		    $left = "N".$left;
		}
		while (length($right)<$kmer)
		{
		    $left = $right."N";
		}
	    }
	}



	my $lflank = substr($left, -$kmer);
	my $branch1= $ref.substr($right,0, $kmer);
	my $branch2= $alt.substr($right,0, $kmer);
	
	my $st1 = substr($branch1,0,1);
	my $st2 = substr($branch2,0,1);
	if ( $st1 eq $st2  )
	{
	    ##VCF has padded, adding a base at the start
	#    $lflank = $lflank.$st1;
	    $branch1 = substr($branch1,1);
	    $branch2 = substr($branch2,1);
	}
	my $rflank = substr($right, $kmer, length($right)-$kmer);
	print OUT ">".$name."_5p_flank\n$lflank\n".">".$name."_branch_1\n$branch1\n".">".$name."_branch_2\n$branch2\n".">".$name."_3p_flank\n$rflank\n";
    }
}
close(VCF);
