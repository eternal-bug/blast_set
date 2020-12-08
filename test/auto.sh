#!/usr/bin/env bash

function usage() {
    cat <<EOF >&2
bash $0 query.fa database.fa outdir prefix

necessary: query.fa database.fa outdir

option: prefix

EOF
}

if [[ $# -lt 3 ]];
then
  usage
  exit 255
fi

query=$1
database=$2
outdir=$3

if [[ ! -z $4 ]];
then
    prefix=$4
else
    prefix="qwerty"
fi

path=$( dirname "$0" )

if [[ ! -d "$outdir" ]];
then
    echo "==> new dir $outdir" >&2
    mkdir -p $outdir
fi

echo "==> begin..." >&2

perl $path/../process_blast.pl -i $query -d $database -o $outdir/$prefix.txt
perl $path/../read_blast_to_yml.pl -i $outdir/$prefix.txt  --length 30 --identity 90 -o $outdir/$prefix.yml
perl $path/../deal_yml.pl -f query.fa -y $outdir/$prefix.yml --get_no_match -o $outdir/$prefix.no.yml
perl $path/../extract_seq.pl -f query.fa -y $outdir/$prefix.no.yml -o $outdir/$prefix.out.fa

echo "==> Complete" >&2

rm $outdir/$prefix.yml $outdir/$prefix.no.yml
