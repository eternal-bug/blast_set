package Seq::Transform;

use strict;
use warnings;
use List::Util qw/max/;

#获得互补并且翻转的序列，调用seq_com和seq_rev函数
sub seq_comp_rev{
  my $r_c_seq = &seq_com(&seq_rev(shift));
  return $r_c_seq;
}

# 获得互补序列
sub seq_com{
  return shift =~ tr/AGTCagtc/TCAGtcag/r;
}

# get reverse sequence
sub seq_rev{
  my $temp = reverse shift;
  return $temp;
}

# seq warp line
sub seq_wrap {
    my $seq = shift;
    my $line_word = shift || 70;
    my $len = length($seq);
    my @t = ();
    WARP:
    for(my $i = 0;$i < $len; $i += $line_word ){
        if ($i + $line_word >= $len - 1){
            my $seg = substr($seq, $i, $len - $i + 1);
            push @t, $seg;
            last WARP;
        }else{
            push @t, substr($seq, $i, $line_word);
        }
    }
    return join("\n",@t);
}

1;
