#!/bin/bash

prefix="OUTPUT"

while getopts f:v: option
  do
    case $option in
      f)
        folder=$OPTARG
        ;;
    esac
  done

for f in $(find $folder -iname "*.txt"); 
  do
    a=${f##*/}
    a=${a%.txt}
    mkdir $prefix/$a
    ./segmenteur.pl $f $prefix/$a/$a.seg
    ./filtrage.pl $prefix/$a/$a.seg $prefix/$a/$a.fil
    echo "Quelle est la langue du document $a.txt ? (eng, esp ou fra)"
    read langue
    ./fonctionnel.pl $prefix/$a/$a.fil $prefix/$a/$a.fon $langue
    echo "Quel stemmer voulez vous utiliser ? (1 pour l'ultra-stemming / 2 pour Porter)"
    read stemmer
    ./normalise.pl $prefix/$a/$a.fon $prefix/$a/$a.lemm $langue $stemmer
    #./PACKAGE_ROUGE_FRESA/fresa.sh  $f
  done
