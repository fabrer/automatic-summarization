#!/usr/bin/perl -w

use strict;
use warnings;

if($#ARGV+1 != 3){
  print "Vous devez renseigner les deux arguments\n $0 input.fil output.fon langue\n";
  exit(0);
}

# Vérification de la langue donnée en paramètre.
my @languages_allow = ('eng', 'esp', 'fra');
if(!in_array(\@languages_allow, $ARGV[2])){
  print "Le paramètre de langue doit être eng esp ou fra\n";
  exit(0);
}

# Ouverture du fichier de stoplist correspondant à la langue choisie.
open(FILEZ,"<TOOLS/STOPLIST/fonctionnels_$ARGV[2].txt") or die("Fichier introuvable ou Impossible d'ouvrir le fichier de stoplist en lecture");

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");

my @stoplist = ();
my (@words, $word, $final_row, $isset, $stopword);

# Construction du tableau des stopwords.
while( defined( my $r = <FILEZ> ) ) {
  if($r !~ /^[#\s]/){
    chomp($r);
    push(@stoplist,lc($r));
  }
}

# Lecture ligne a ligne du fichier.
while( defined( my $row = <FILER> ) ) {
  $final_row = "";
  chomp($row);

  # Découpage de la phrase en mots.
  @words = split(' ',$row);
  foreach $word (@words){
    chomp($word);
    $isset = 0; # Variable passée à 1 si le mot est un stopword.
    foreach $stopword (@stoplist){
      # Test du mot en cours.
      if($stopword eq lc($word)){
        $isset = 1;
      }
    }
    if($isset == 1){
    }
    else{
      $final_row .= "$word ";
    }
  }
  
  print( FILEW "$final_row\n");
}
close(FILEZ);
close(FILER);
close(FILEW);

# Fonction de verification de la presence d'une chaine dans un tableau.
sub in_array
{
  my ($arr,$search_for) = @_;
  my %items = map {$_ => 1} @$arr;
  return (exists($items{$search_for}))?1:0;
}
