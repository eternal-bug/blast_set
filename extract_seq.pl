#!/usr/bin/perl
# author: eternal-bug
# edit(last): 2019-10-25
# function: extract the gene scale
# It will be accomply with read_blast_to_yml.pl
use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;
use File::Spec;
use FindBin qw/$Bin/;
use lib "$FindBin::Bin/lib/";
use Seq::Extract;
use Seq::Transform;
use Fasta::Read;


GetOptions(
    "f|fasta=s"     => \(my $fasta),
    "y|yml=s"       => \(my $yml),
    "o|out=s"       => \(my $output = "result.fa"),
    "help"          => \(my $help),
);

sub usage {
    my $usage =<<EOF;

    This Script is used to extract the seq

  OPTION
  ======

    -f|--fasta   the fasta sequence.
    -y|--yml     the yml file.
    -o|--output  the  output file.
    --help       help info.

EOF
}

die usage() if $help;


my $data;

my $file_type = file_format($yml);
if ( $file_type eq "yml" ){
    $data = YAML::Syck::LoadFile($yml);
}else{
    $data = LoadTxt($yml);
}

my $fasta_o = Fasta::Read->new($fasta);


# 
open my $f, ">", $output or die $!;

for my $title ( keys %$data ){
    my $seq = $fasta_o->get_seq_by_name($title);
    for my $scale ( @{ $data->{$title} } ){
        my $seq = Seq::Extract::substr_seq($seq, $scale)->[0];
        my $title_new = new_title($title, $scale);
        print {$f} out_fasta($title_new, $seq);
    }
}

sub out_fasta {
    my $title = shift;
    my $seq   = shift;
    $seq = Seq::Transform::seq_wrap($seq);
    return sprintf(">%s\n%s\n", $title, $seq);
}

sub new_title {
    my $title = shift;
    my $scale = shift;
    my $scale_str = join("-", @$scale);
    my $direction;
    if( $scale->[0] < $scale->[1] ){
        $direction = "+";
    }else{
        $direction = "-";
    }
    my $title_new = join("\|", $title, $direction, $scale_str);
    return $title_new;
}

sub file_format {
    my $name = shift;
    if ( $name =~ m/.ya?ml$/i ){
        return "yml";
    }else{
        return "txt";
    }
}

# title1 100-200 400-600
# title1 1000-2000
# title2 300-500
sub LoadTxt {
    my $file = shift;
    my $data = {};
    open my $f_h, "<", $file or die $!;
    while(my $line = <$f_h>){
        chomp;
        my @items = split(/\s+/, $line);
        my $title = shift(@items);
        my @scales = map { my $scale = [split("-", $_)]; $scale; } @items;
        push @{ $data->{$title} }, \@scales;
    }
    close $f_h;
    return $data;
}
