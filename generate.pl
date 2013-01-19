#!/usr/bin/perl -w

use strict;
use warnings;
use open qw(:std :utf8);

if($#ARGV+1 != 4){
  print "Vous devez renseigner les deux arguments\n $0 input.seg input.phr output.txt taux_de_compression\n";
  print "Le taux de compression doit être compris entre 0 et 100%\n";
  exit(0);
}

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILERR,"<$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[2]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");
my $taux = $ARGV[3];

my (@phr,@mots,@score,$i,$j,$k,$nb);
$i=0;
while( defined( my $row = <FILER> ) ) {
  chomp($row);
  if($row ne " " and $row ne "") {
    $phr[$i]=$row;
    $i++;
  }
}

$nb = int(($#phr * $taux) / 100);

my $cpt=0;
while( defined( my $line = <FILERR> ) ) {
  @mots = split("\t",$line);
  $score[$cpt]=[$mots[0],$mots[1]];
  $cpt++;
}

my ($a1,$b1);
@score=sort byvalue @score;
sub byvalue {
  $a1 = $$a[1];
  $b1 = $$b[1];
  $a1 <=> $b1;
}

my (@tokeep,$l,$limit);
$l=0;
$limit = $#score - $nb;
for $k (0..$#score) {
  if($k >= $limit) {
    $tokeep[$l] = $score[$k][0];
    $l++;
  }
}

my $m;
for $m (0..$#phr) {
  if(in_array(\@tokeep,$m)) {
    print(FILEW "$phr[$m]\n");
  }
}

close(FILER);
close(FILERR);
close(FILEW);

# Fonction de verification de la presence d'une chaine dans un tableau.
sub in_array
{
  my ($arr,$search_for) = @_;
  my %items = map {$_ => 1} @$arr;
  return (exists($items{$search_for}))?1:0;
}
