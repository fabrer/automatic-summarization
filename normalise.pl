#!/usr/bin/perl -w

use strict;
use warnings;
use open qw(:std :utf8);
use Lingua::Stem;

if($#ARGV+1 != 4){
  print "Vous devez renseigner les deux arguments\n $0 input.fon output.lemm langue stemmer\n";
  exit(0);
}

# Vérification de la langue donnée en paramètre.
my @languages_allow = ('eng', 'fra');
if(!in_array(\@languages_allow, $ARGV[2])){
  print "Le paramètre de langue doit être eng ou fra\n";
  exit(0);
}

# Vérification de la langue donnée en paramètre.
my @stemmer_allow = (1, 2);
if(!in_array(\@stemmer_allow, $ARGV[3])){
  print "Le paramètre du choix de stemmer doit être 1 pour un ultra stemming ou 2 pour l'utilisation de l'algorithme de Porter\n";
  exit(0);
}

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");

my (@words,$word, $final_row, $isset, $stopword);

if($ARGV[3]==1){
  while( defined( my $row = <FILER> ) ) {
    $final_row = "";
    $row =~ s/[0-9]//g; # Suppression des chiffres.
    chomp($row);
    @words = split(' ',$row);
    foreach $word (@words){
      $final_row .= lc(substr($word, 0, 1)) . " ";
    }
    chomp($final_row);
    print( FILEW "$final_row\n");
  }
}
else{
  my $stemmer;
  #Définition de la variable de langue pour le stemmer.
  if($ARGV[2] eq "eng"){
    $stemmer = Lingua::Stem->new(-locale => 'EN-UK');
  }
  else{
    $stemmer = Lingua::Stem->new(-locale => 'FR');
  }

  while( defined( my $row = <FILER> ) ) {
    $final_row = "";
    chomp($row);
    @words = split(' ',$row);
    foreach $word (@words){
      $final_row .= $stemmer->stem($word)->[0] . " ";
    }
    chomp($final_row);
    print( FILEW "$final_row\n");
  }
}
close(FILER);
close(FILEW);

# Fonction de verification de la presence d'une chaine dans un tableau.
sub in_array
{
  my ($arr,$search_for) = @_;
  my %items = map {$_ => 1} @$arr;
  return (exists($items{$search_for}))?1:0;
}
