#!/usr/bin/perl -w
use strict;


my $callfile = shift; ## callfile output by Cortex
my $number_of_colours = shift;
my $ref_colour = shift;## if one of the colours is the reference, specify here. If none if them is a reference, set this to -1.


my $outfile = $callfile.".covg_for_classifier";

open(CALLS, $callfile)||die();
open(OUT, ">".$outfile)||die();
#print OUT "VAR\tREF_FILTER\tBR1_LEN\tBR2_LEN\tREF_COV_BR1\tREF_COV_BR2\tSAMPLES...\n";

my $name = "";
my $reads_on_branch=0;

while (<CALLS>)
{
    my $line = $_;
    
    if ($line =~ /^\>(var_\d+)_5p_flank/)
    {
	$name = $1;
	my $lenbr1;
	my $lenbr2;

	print OUT "$name\t";
	my @array_counts_for_each_colour=(); ## will be an array of strings of the form "1/14", "2,3", etc where "a,b" at index i means colour i has count a on branch1  and count b on branch 2

	my $all_nodes_br1_in_ref=0;
	my $all_nodes_br2_in_ref=0;

	$line = <CALLS>;
	$line = <CALLS>;
	$line = <CALLS>;## br1 seq
	chomp $line;
	$lenbr1 = length($line);
	$line = <CALLS>;
	$line = <CALLS>;
	chomp $line;
	$lenbr2 = length($line);
	$line = <CALLS>;
	$line = <CALLS>;
	while ($line !~ /branch1 coverages/)
	{
	    	$line = <CALLS>;
	}
	$line = <CALLS>;
	if ($line !~ /Covg in Colour 0/)
	{
	    die("PArsing error at line $line");
	}

	my $current_colour = 0;
	while ($current_colour <= $number_of_colours-1)
	{
	    my $line_of_counts = <CALLS>;
	    chomp $line_of_counts;
	    $reads_on_branch  =count_reads($line_of_counts);
	    push @array_counts_for_each_colour, $reads_on_branch;
	    
	    if ($current_colour == $ref_colour)
	    {
		$all_nodes_br1_in_ref=are_all_nodes_in_ref($line_of_counts);
	    }
	    $current_colour++;
	    $line = <CALLS>;
	}

	if ($line !~ /branch2 coverages/)
	{
	    die("Expected branch2 coverages but got $line");
	}
	$current_colour = 0;
	$line = <CALLS>;

	while ($current_colour <= $number_of_colours-1)
	{
	    my $line_of_counts = <CALLS>;
	    chomp $line_of_counts;
	    $reads_on_branch=count_reads($line_of_counts);
	    $array_counts_for_each_colour[$current_colour] = $array_counts_for_each_colour[$current_colour]."\t".$reads_on_branch;

	    if ($current_colour == $ref_colour)
	    {
		$all_nodes_br2_in_ref=are_all_nodes_in_ref($line_of_counts);
	    }


	    $current_colour++;
	    $line=<CALLS>;
	}

	my $i;

	if ( ($all_nodes_br1_in_ref==1) && ($all_nodes_br2_in_ref==1) )
	{
	    print OUT "REF_BUBBLE\t";
	}
	else
	{
	    print OUT "NOT_IN_REF\t";
	}
	print OUT $lenbr1."\t".$lenbr2."\t";
	print OUT $array_counts_for_each_colour[$ref_colour];
	print OUT "\t";
	for ($i=0; $i<$number_of_colours; $i++)
	{
	    if ($i==$ref_colour)
	    {
		next;
	    }
	    print OUT $array_counts_for_each_colour[$i];
	    if ($i<$number_of_colours-1)
	    {
		print OUT "\t";
	    }
	    else
	    {
		print OUT "\n";
	    }
	}

    }


}
close(CALLS);
close(OUT);


sub are_all_nodes_in_ref
{
    my ($line) = @_;
    my @sp = split(/\s+/, $line);
    my $i;
    my $total = $sp[1];
    if (scalar @sp < 3)
    {
	return 0;
    }

    my $all_nodes_in_ref=1;
    for ($i=2; $i< scalar(@sp)-1; $i++)##ignore first and last
    {
	if ($sp[$i]==0)
	{
	    $all_nodes_in_ref=0;
	    last;
	}
    }
    return $all_nodes_in_ref;

}



sub count_reads
{
    my ($line) = @_;
    my @sp = split(/\s+/, $line);
    my $i;
    my $total = $sp[1];
    if (scalar @sp < 3)
    {
	return 0;
    }

    for ($i=2; $i< scalar(@sp)-1; $i++)##ignore first and last
    {
	my $jump = $sp[$i] - $sp[$i-1];
	if ($jump >0)
	{
	    if ($i+1 < scalar(@sp)-1) ## ie if there is a next base in this array
	    {
		my $next_jump = $sp[$i+1]-$sp[$i];
		if ($next_jump != -$jump)  ## ie provided the jump was not a spike on a single kmer
		{
		    $total += $jump;
		}
	    }
	    else
	    {
		$total +=$jump;
	    }
	}
    }


    return $total;
}