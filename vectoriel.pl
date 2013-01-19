#!/usr/bin/perl -w

use strict;
use warnings;
use open qw(:std :utf8);

if($#ARGV+1 != 2){
  print "Vous devez renseigner les deux arguments\n $0 input.stem output.mat\n";
  exit(0);
}

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");

my (%matrice,%M,@words,$word,$nb_ligne,$exist);
my($c,$v,$i,$d,$w,$e,$x);

while( defined( my $row = <FILER> ) ) {
  chomp($row);
  @words = split(' ',$row);
  foreach $word (@words){
    $matrice{$word}{$.}++;
    $M{$word}++;
  }
  $nb_ligne = $.;
}
close(FILER);

for($i=1;$i<=$nb_ligne;$i++){
  while (($c,$v) = each(%matrice)) {
    while (($d,$w) = each($v)){
      if($d==$i){
        if($w==1){
          $exist = 0;
          while(($e,$x) = each(%M)){
            if($c eq $e){
              if($x<=1){
                $exist = 1;
              }
            }
          }
          if($exist == 0){
            print(FILEW "$i\t$c\t$w\n");
          }
        }
        else{
          print(FILEW "$i\t$c\t$w\n");
        }
      }
    }
  }
}

close(FILEW);
