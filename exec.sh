#!/bin/bash

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
    mkdir $a
    ./segmenteur.pl $f $a/$a.seg
    ./filtrage.pl $a/$a.seg $a/$a.fil
    echo "Quelle est la langue du document $a.txt ? (eng, esp ou fra)"
    read langue
    ./fonctionnel.pl $a/$a.fil $a/$a.fon $langue
    echo "Quel stemmer voulez vous utiliser ? (1 pour l'ultra-stemming / 2 pour Porter)"
    read stemmer
    ./normalise.pl $a/$a.fon $a/$a.lemm $langue $stemmer
    #./PACKAGE_ROUGE_FRESA/fresa.sh  $f
  done
