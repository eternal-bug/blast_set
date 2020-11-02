package Scale::Relationship;

use strict;
use warnings;

sub merge {
    my $l_lr = shift;
    my $cross_restrict = shift || 0;
    # =========   =========       =========            ========
    # ==========      =========             ========               ========
    #     1            2                   3                     4
    my @new_l_lr = sort { $a->[0] <=> $b->[0] } @$l_lr;
    my $index = -1;
    LOOP:{
        my $new_l;
        if ( defined $new_l_lr[$index - 1] ){
            my $item_r = $new_l_lr[$index];
            my $item_l = $new_l_lr[$index - 1];
            if ($item_r->[0] <= $item_l->[1] + $cross_restrict ){
                my $max = List::Util::max($item_l->[1],$item_r->[1]);
                $new_l = [$item_l->[0],$max];
                splice(@new_l_lr,$index-1,2,$new_l);
            }else{
                $index -= 1;
            }
            redo LOOP;
        }else{
            last LOOP;
        }
    }
    return \@new_l_lr;
}


sub convert_ref_to_list{
    my $ref_hr = shift;
    my $list_lr = [];
    while(my($key,$value) = each %$ref_hr){
        push @$list_lr,[$key,$value];
    }
    return [sort {$a->[0] <=> $b->[0]} @$list_lr];
}

=item complement

This function is complement.

    my @list1 = ([0,1000]);
    my @list2 = ([3,50],[700,900] [950,1200]);
    complement(\@list1, \@list2);  # [0,2],[51,699],[901,949]

=back

=cut

sub diffuse_scale {
    my $host_lr  = shift;
    my $guest_lr = shift;
    my $space    = shift || 1;

    # merge and sort
    $host_lr = merge($host_lr,$space);
    $guest_lr = merge($guest_lr,$space);

    my @complement = ();
    my $guest_len = scalar(@$guest_lr)-1;
    my $host_len  = scalar(@$host_lr)-1;

    GUEST:
    for my $g_i (0..$guest_len){
        HOST:
        for my $h_i (0..$host_len){
            if ($guest_lr->[$g_i][1] < $host_lr->[$h_i][0]){
                # host       ========
                # guest ====
                next GUEST;
            }elsif ( $guest_lr->[$g_i][0] > $host_lr->[$h_i][1] ){
                # host  ========
                # guest          ====
                next HOST;
            }else{
                if ( $guest_lr->[$g_i][1] < $host_lr->[$h_i][1] ){
                    my $anterior  = [$host_lr->[$h_i][0], $guest_lr->[$g_i][0] - 1];
                    my $posterior = [$guest_lr->[$g_i][1] + 1, $host_lr->[$h_i][1]];
                    if ( $anterior->[1] >= $anterior->[0] ){
                        push @{$complement[$h_i]}, $anterior;
                    }
                    # change the list
                    $host_lr->[$h_i] = $posterior;
                }else{
                    my $anterior = [$host_lr->[$h_i][0], $guest_lr->[$g_i][0] - 1];
                    push @{$complement[$h_i]}, $anterior;
                    # die the list
                    $host_lr->[$h_i] = [-1,-2];
                }
            }
        }
    }
    # exclude the died list
    for my $i (0..$host_len){
        if($host_lr->[$i][1] > $host_lr->[$i][0]){
            push @{$complement[$i]}, $host_lr->[$i];
        }
    }
    return \@complement;
}

sub remove_no_use_scale { # 移除类似于[1,1],[99,99]之类的
    my $list_lr = shift;

    my $list_len = scalar(@$list_lr) - 1;
    my @new_list;
    for my $num (0..$list_len){
        if($list_lr->[$num]->[0] == $list_lr->[$num]->[1]){
            # splice(@$list_lr,$num,1);
            1;
        }else{
            push @new_list,$list_lr->[$num];
        }
    }
    return \@new_list;
}


1;
