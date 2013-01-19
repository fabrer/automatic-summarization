#!/bin/bash
clear

N=`basename $1`
echo "# ROUGE $N"

perl ./ROUGE-RELEASE-1.5.5/ROUGE-1.5.5.pl -a -e ./ROUGE-RELEASE-1.5.5/data/ -n 2 -x -m -2 4 -u -c 95 -r 1000 -f A -p 0.5 -t 0 -d $1  > tmp/$N.tmp 

grep -i "_R:" tmp/$N.tmp

#rm tmp/$N.tmp
