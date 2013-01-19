#!/usr/bin/perl -w

use strict;
use warnings;
use open qw(:std :utf8);

if($#ARGV+1 != 2){
  print "Vous devez renseigner les deux arguments\n $0 input.mat output.phr\n";
  exit(0);
}

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");

# Calcul du TF * IDF normalisé 
my (%tf,%n,@words,$words,$P);
while( defined( my $row = <FILER> ) ) {
  @words = split("\t",$row);
  $tf{$words[1]}{$words[0]} = $words[2];
  $n{$words[1]}++;
  $P = $words[0];
}
my (%w,%score,$c,$v,$d,$w,$sum);
while (($c,$v) = each(%tf)) {
  while (($d,$w) = each($v)){
    $w{$c}{$d} = $w * log($P / $n{$c});
    $sum += ( $w**2 ) * ( log($P / $n{$c}))**2; 
  }
}
while (($c,$v) = each(%w)) {
  while (($d, $w) = each($v)) {
    $score{$c}{'tfidf'} += $w/sqrt($sum);
  }
}

# Calcul des scores de phrases
open(FILER2,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
my (%sentences,@mots);
while( my $line = <FILER2> ) {
  @mots = split("\t",$line);
  $sentences{$mots[0]} += $score{$mots[1]}{'tfidf'};
}

while (($c,$v) = each(%sentences)) {
  print(FILEW "$c\t$v\n");
}

close(FILER);
close(FILER2);
close(FILEW);
