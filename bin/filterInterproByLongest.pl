#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;

my ($fasta, $interpro, $output);
GetOptions(
    "fasta=s"    => \$fasta,
    "interpro=s" => \$interpro,
    "output=s"   => \$output,
    ) or die "Usage: $0 --fasta <file> --interpro <file> --output <file>\n";

die "Missing --fasta\n"    unless $fasta;
die "Missing --interpro\n" unless $interpro;
die "Missing --output\n"   unless $output;

# ------------------------------------------------------------
# STEP 1 — Read FASTA and store longest protein per gene
# ------------------------------------------------------------

my %longest;       # gene    => { prot_id => ..., length => ... }
my %prot_to_gene;  # prot_id => gene

open(my $FA, "<", $fasta) or die "Cannot read $fasta: $!\n";

my ($header, $seq) = ("", "");

while (<$FA>) {
    chomp;
    if (/^>(.+)$/) {
        if ($header && $seq) {
            process_fasta_entry($header, $seq, \%longest, \%prot_to_gene);
        }
        $header = $1;
        $seq    = "";
    } else {
        $seq .= $_;
    }
}

# last entry
process_fasta_entry($header, $seq, \%longest, \%prot_to_gene) if ($header && $seq);

close $FA;

# ------------------------------------------------------------
# STEP 2 — Read InterPro output and keep only longest proteins
# ------------------------------------------------------------

open(my $IN,  "<", $interpro) or die "Cannot read $interpro: $!\n";
open(my $OUT, ">", $output)   or die "Cannot write $output: $!\n";

while (<$IN>) {
    chomp;
    my @fields = split(/\t/);
    my $prot   = $fields[0];

    my $gene = $prot_to_gene{$prot};

    if ($gene
        && exists $longest{$gene}
        && $longest{$gene}{prot_id} eq $prot
    ) {
        print $OUT $_, "\n";
    }
}

close $IN;
close $OUT;

exit(0);

# ------------------------------------------------------------
# Subroutine: process a FASTA entry
# ------------------------------------------------------------
sub process_fasta_entry {
    my ($header, $seq, $longest_href, $prot_to_gene_href) = @_;
    return unless $header;

    # protein ID = first token
    my ($prot_id) = split(/\s+/, $header);

    # extract gene=XXX
    my $gene;
    if ($header =~ /\bgene=([^\s]+)/) {
        $gene = $1;
    } else {
        die "ERROR: No gene= found in FASTA header:\n>$header\n";
    }

    $prot_to_gene_href->{$prot_id} = $gene;

    my $len = length($seq);

    if (
        !exists $longest_href->{$gene}
        || $len > $longest_href->{$gene}{length}
    ) {
        $longest_href->{$gene} = {
            prot_id => $prot_id,
            length  => $len
        };
    }
}
