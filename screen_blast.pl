use strict;
use warnings;
use Getopt::Long;

sub usage {
    my $help = <<EOF;

    This Script can screen the blast -m 8 result

    USAGE
    =====

        perl $0 -b [blast result] -o [output file] -l [align length] -i [align identity]

    OPTION
    ======

        -b|--fasta      the blast query file 

        -o|--out        the output file name

        -l|--length     the align length threshold

        -i|--identity   the align identity threshold

        --stdin         read the data from command line

        --stdout        output the screen to command line

        --help          help infomation
EOF
    print STDERR $help, "\n";
    exit(0);
}

# get arguments
GetOptions(
    "b|blast=s"    => \(my $blast),  # blast result
    "l|length:i"   => \(my $length_t = 50),
    "i|identity:f" => \(my $identity_t = 0.5),
    # "t|title:s"    => \(my $title),
    "o|output:s"   => \(my $output), # output directory
    "stdin"        => \(my $stdin),  #
    "stdout"       => \(my $stdout), # output into STDOUT
    "h|help"       => \(my $help),   # help info
);

my $handle;
if(defined $stdin) {
    $handle = *{STDIN}{IO};
}else{
    open $handle, "<", $blast or die $!;
}

my @screen = ();

# 0       1       2        3               4        5          6       7     8       9     10      11
# ---------------------------------------------------------------------------------------------------------
# 1       2       3        4               5        6          7       8     9       10    11      12
# Queryid Sbjctid identity alignmentLength MisMatch GapOpening Q.start Q.end S.start S.end E-value BitScore

while(<$handle>){
    chomp;
    if(m/^$/){
        next;
    }
    my @l = split(/\t/, $_);
    my $len = $l[3];
    my $ide = $l[2];
    my $flag = 1;
    if ( $len < $length_t ){
        $flag = 0;
    }
    if ( $ide < $identity_t * 100 ){
        $flag = 0;
    }
    if ( $flag ){
        if ($stdout){
            print STDOUT $_,"\n";
        }else{
            push @screen, $_;
        }
    }
}

if ( defined $output ){
    open my $f, ">", $output or die $!;
    for my $line (@screen){
        print {$f} "$line\n";
    }
    close $f;
}
