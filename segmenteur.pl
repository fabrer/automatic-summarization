#!/usr/bin/perl -w

use strict;
use warnings;

# Gestion des erreurs relatives au nombre d'arguments.
if($#ARGV+1 != 2){
  print "Vous devez renseigner les deux arguments\n $0 input.txt output.seg\n";
  exit(0);
}

# Ouverture du fichier en lecture et de l'autre en écriture.
open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en écriture");

# Définition des caractères délimitants une phrase.
my @ponct = ('!', '?', '.');

# Lecture ligne a ligne du fichier.
while( defined( my $row = <FILER> ) ) {
  chomp($row); # Nettoyage des caracteres de fin de ligne.
  # Recuperation du titre
  if($. == 1){
    print( FILEW "$row\n");
  }
  else{
    my($s,@sentences,$last);
    # Suppression des espaces de fin de ligne.
    $row =~ s/[ \t]+$//;
    # Suppression des espaces de debut de ligne.
    $row =~ s/^[ \t]+//g;
    # Recuperation du dernier caractere de la ligne.
    $last = substr($row,-1);
    # Decoupage de la ligne en phrases.
    @sentences = split( /(?<=\.|\?|!)/, $row );
    # Lecture du tableau des phrases.
    foreach $s (@sentences) {
      # Suppression des espaces de debut de phrase.
      $s =~ s/^[ \t]+//g;
      # Si la phrase courante n'est pas la derniere du tableau.
      if($s ne $sentences[$#sentences]){
        print( FILEW "$s\n");
      }
      else{
        # On verifie si le dernier caractere de la ligne est un signe de ponctuation.
        if(in_array(\@ponct, $last)){
          # Alors c'est une phrase complete.
          print( FILEW "$s\n");
        }
        else{
          # Sinon ce n'est qu'un morceau de phrase.
          print( FILEW "$s ");
        }
      }
    }
  }
}
# On ferme les fichiers de lecture et d'ecriture.
close(FILER);
close(FILEW);

# Fonction de verification de la presence d'une chaine dans un tableau.
sub in_array
{
  my ($arr,$search_for) = @_;
  my %items = map {$_ => 1} @$arr; # create a hash out of the array values
  return (exists($items{$search_for}))?1:0;
}
