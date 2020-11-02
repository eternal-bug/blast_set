# ================================
# read blast tab split file. output
# the align region.
# such as
# ===============================================================================
# Pt  Mt  99.98   4602    1   0   20916   25517   293639  289038  0.0e+00 8921.0
# Pt  Mt  99.95   2034    1   0   50803   52836   121392  123425  0.0e+00 3943.0
# ===============================================================================

use strict;
use warnings;
use autodie;
use YAML::Syck qw/Dump/;
use Getopt::Long;
use List::Util;
use FindBin qw/$Bin/;
use lib "$FindBin::Bin";
use Scale::Relationship;

GetOptions(
    "i|in=s"     => \(my $input),
    "o|out:s"    => \(my $output),
    "length=i"   => \(my $len_restrict = 100),
    "identity=s" => \(my $identity),
    "help"       => \(my $help)
);

sub usage {
    my $help_str =<<EOF;
    
    This script is to transform the blast result to yml data

    OPTION
    ======

       -i      the input blast result

       -o      the output file

       -l      the blast length restrict

EOF
    return $help_str;
}

die usage() if $help;

#                          blast result
#====================================================================
#   col1    |   col2   |    col3     |       col4        |  col5    |
# -------------------------------------------------------------------
# Queryid   |  Sbjctid |   identity% |  alignmentLength  | MisMatch |
#====================================================================
#====================================================================
#   col6    |  col7   | col8  | col9    | col10 |  col11  |  col12  |
#--------------------------------------------------------------------
# GapOpening| Q.start | Q.end | S.start | S.end | E-value | BitScore|
#====================================================================

open my $f_h ,"<","$input" or die $!;;

my $hash = {};
while(<$f_h>){
    chomp;
    my @l = split /\t/,$_;
    my $query  = $l[0];
    my $qstart = $l[6];
    my $qend   = $l[7];
    if ( $qend - $qstart + 1 >= $len_restrict ){
        push @{ $hash->{$query} } , [$qstart,$qend];
    }
}
close $f_h;

for my $q_id ( keys %$hash){
    my @l = @{ $hash->{$q_id} };
    my $merge = Scale::Relationship::merge(\@l);
    $hash->{$q_id} = $merge;
}

if ( ! defined $output ){
    $output = "result.yml";
}

open my $w_h,">", $output;
print $w_h YAML::Syck::Dump($hash);
close $w_h;
