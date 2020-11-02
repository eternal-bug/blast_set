package Seq::Extract;

use strict;
use warnings;

BEGIN{
    eval{ use Seq::Transform };
    if($@){
        die "The module Seq::Transform and List::Layer is personal module.";
    }
}

# extract file
sub substr_seq {
    my $seq = shift;
    my $scale = shift;

    if( ! ref $scale->[0]){
        $scale = [$scale];
    }

    my $len = length($seq);
    my @l = ();
    for my $pair (@$scale){
        my $start = $pair->[0];
        my $end   = $pair->[1];
        my $r_c_flag = 0; # reverse and com
        if($start > $end){
            $r_c_flag = 1;
            ($start, $end) = ($end, $start);
        }else{
            1; # do nothing
        }
        # check
        if($end > $len){
            warn("The scale($start, $end) is out scale.It will get the tail of seq");
            $end = $len;
        }
        my $space = $end - $start + 1;
        my $extract = substr($seq, $start - 1, $space);
        if($r_c_flag){
            $extract = Seq::Transform::seq_comp_rev($extract);
        }
        push @l, $extract;
    }
    return \@l;
}



1;
