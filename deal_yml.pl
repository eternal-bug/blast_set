use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;
use List::Util;
use File::Spec;
use Data::Dumper qw/Dumper/;
use FindBin qw/$Bin/;
use lib "$FindBin::Bin";
use Fasta::Read;
use Scale::Relationship;

sub usage {
    my $help = <<EOF;

    This Script can deal read_blast_to_yml.pl Script output yml file

    USAGE
    =====

        perl $0 -f [fasta file] -y [yml file] -o [output file]

    OPTION
    ======

        -f|--fasta      the blast query file 

        -y|--yml        the blast scale yml file

        -o|--out        the output file name
        
        --overlap       the scale will be merge if overlap length is appropriate.
                        such as:
                                                 overlap = 0
                          [1, 200], [205, 400] --------------> [1, 200], [205, 400] ( do nothing)
                                                 overlap = -5
                          [1, 200], [205, 400] --------------> [1, 400] ( merge )
                                                 overlap = 5
                          [1, 200], [195, 400] --------------> [1, 200], [205, 400] ( do nothing)

        --get_no_match  get the no match scale
EOF
    print STDERR $help, "\n";
    exit(0);
}

GetOptions(
    "f|fasta=s"     => \(my $fasta),
    "y|yml=s"       => \(my $yml),
    "o|out:s"       => \(my $output),
    "l|length=i"    => \(my $len_restrict = 30),
    "distance=i"    => \(my $distance = 0),
    "get_no_match"  => \(my $get_no_match),
    "help"          => \(my $help)
);

die usage() if $help;


my $data = YAML::Syck::LoadFile($yml);
my $f_o  = Fasta::Read->new($fasta);

my $new_yml;

# the blast item
my @blast_query = ();
for my $query ( keys %$data ){
    push @blast_query, $query;
    my $scale_match = $data->{$query};
    my $seq   = $f_o->get_seq_by_name($query);
    my $seq_len = length($seq);
    my $scale_total   = [[1, $seq_len]];
    if ( defined $get_no_match ){
        my @match_screens = grep { abs( $_->[1] - $_->[0] ) > $len_restrict } @$scale_match;
        my $scale_diffuse = Scale::Relationship::diffuse_scale($scale_total, \@match_screens, $distance);
        my $scale         = $scale_diffuse->[0];
        my @no_match_screens = grep { abs( $_->[1] - $_->[0] ) > $len_restrict } @$scale;
        $new_yml->{$query} = \@no_match_screens;
    }else{
        my @screens       = grep { abs( $_->[1] - $_->[0] ) > $len_restrict } @$scale_match;
        $new_yml->{$query} = \@screens;
    }
}

if( defined $get_no_match ){
    my @all_blast_query = @{ $f_o->get_title_by_file_order() };
    my @not_blast_query = ();
    # the not blast item
    for my $query (@all_blast_query){
        if( List::Util::first { $query eq $_ } @blast_query ){
            1;
        }else{
            push @not_blast_query, $query;
        }
    }

    for my $query (@not_blast_query){
        my $seq   = $f_o->get_seq_by_name($query);
        my $seq_len = length($seq);
        $new_yml->{$query} = [[1, $seq_len]];
    }
}

my $dumpfile;
if ( defined $get_no_match ){
    if( ! defined $output ){
        $dumpfile = File::Spec->catfile("./", "no_match.yml");
    }else{
        $dumpfile = $output;
    }
}else{
    if( ! defined $output ){
        $dumpfile = File::Spec->catfile("./", "match.yml");
    }else{
        $dumpfile = $output;
    }
}

# output
YAML::Syck::DumpFile($dumpfile, $new_yml);
