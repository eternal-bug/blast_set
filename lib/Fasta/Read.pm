package Fasta::Read;
# core module
use strict;
use warnings;

# new built object
sub new {
    my $class = shift;
    my $self  = bless({},$class);
    my $file  = shift;
    $self->{FILE} = $file if defined $file;
    # record the show fasta order
    $self->{CONUT} = 1;
    $self->store() if defined $file;
    return $self;
}

# store fasta
# list is order
# hash is not order
sub store {
    my $self = shift;
    my $file = shift || $self->{FILE};
    $self->{FASTA} = [];
    my $title;
    my %seq; # judge the fasta name
    my @temp = (); # store the fasta seq (title,seq)
    my $n; # title suffix
    my $index = -1;
    open my $read_fasta,"<",$file or die "There is no file <$file>";
    while(my $line = <$read_fasta>){
        # There is "\r" at windows system.
        $line =~ s/\r?\n$//;
        if($line =~ m/^>/){
            $index++;
            $n = 1;
            # check name
            fasta_name_check($line);
            $title = ($line =~ s/^>//r);
            $title =~ s/\s+$//g;
            push(@{$self->{FASTA}}, [@temp]) if @temp;
            @temp = ();
            my $title_in = $title;
            # check the name prevent the same name in fasta
            NameCheck : {
                if (exists $seq{$title_in}){
                    my $warn = join ("\n","WARNING : ","There are same name in fasta file <$file>!",
                              "WARNING : ","The program will paste the number behind the <$title_in>!\n");
                    warn $warn;
                    $title_in = $title . $n;
                    $n++;
                    redo NameCheck;
                }else{
                    $temp[0] = $title_in;
                    $temp[1] = "";
                    $seq{$title_in} = $index;
                }
            }
        }else{
            $temp[1] .= $line;
        }
    }
    push @{$self->{FASTA}}, [@temp] if @temp;
    close $read_fasta;
    $self->{INDEX} = \%seq;
    return $self->{FASTA};
}

# show the next fasta seq to return result
sub next_seq {
    my $self = shift;
    # diff way to output fasta seq
    my $output_type = shift || "scalar";  # scalar ; fasta; list; hash;
    if($self->{CONUT} > scalar(@{ $self->{FASTA} })){
        return wantarray ? () : undef;
    }else{
        my $str;
        my $title = $self->{FASTA}[$self->{CONUT} - 1][0];
        my $seq   = $self->{FASTA}[$self->{CONUT} - 1][1];
        $self->{CONUT}++;
        return out_seq([$title, $seq], $output_type);
    }
}

# check the fasta name is available
sub fasta_name_check {
    my $line = shift;
    chomp($line);
    if ($line =~ m/\s+(.+)/){
        debug("The line ::: ${line} ::: maybe encounter problem. Please be cautious");
    }
}

# out seq by appoint name
sub get_seq_by_name {
    my $self = shift;
    my $name = shift;
    my $out_type = shift || "seq";
    if (exists $self->{INDEX}{$name}){
        return out_seq($self->{FASTA}[$self->{INDEX}{$name}], $out_type);
    }else {
        return undef;
    }
}

#
sub get_seq_by_index {
    my $self = shift;
    my $index = shift;
    my $out_type = shift || "seq";
    if (exists $self->{FASTA}[$index]){
        return out_seq($self->{FASTA}[$index], $out_type);
    }else {
        return undef;
    }
}

# return fasta seq list
sub get_data {
    my $self = shift;
    return $self->{FASTA};
}

# get total sequence
sub get_total_seq {
    my $self = shift;
    my @seqs = map { $_->[1] } @{ $self->{FASTA} };
    return \@seqs;
}

# set the print number
sub set_index {
    my $self = shift;
    my $num = shift;
    $self->{CONUT} = $num;
    return $self;
}

# get title by fasta file order
sub get_title_by_file_order {
    my $self = shift;
    my @t = map { $_->[0] } @{ $self->{FASTA} };
    return \@t;
}

# get title by name order
sub get_title_by_name_order {
    my $self = shift;
    my $t = $self->get_title_by_file_order();
    return [sort {$a cmp $b} @$t ];
}

# ========== no oo =========

sub out_seq {
    my $title_seq_h = shift;
    my $output_type = shift || "scalar";
    my $title = $title_seq_h->[0];
    my $seq   = $title_seq_h->[1];
    if( $output_type eq "scalar" ){
        return sprintf(">%s\n%s\n",$title,$seq);
    }elsif( $output_type eq "fasta" ){
        return wantarray ? ($title,$seq) : die "Please give me two variables!";
    }elsif( $output_type eq "list" ){
        return $title_seq_h;
    }elsif( $output_type eq "hash" ){
        my %hash;
        $hash{$title} = $seq;
        return \%hash;
    }elsif( $output_type eq "seq" ){
        return $seq;
    }
}

sub debug {
    my $info = shift;
    print STDERR "$info\n";
}

1;
