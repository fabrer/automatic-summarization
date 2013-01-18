#!/usr/bin/perl -w

use strict;
use warnings;

if($#ARGV+1 != 2){
  print "Vous devez renseigner les deux arguments\n $0 input.seg output.fil\n";
  exit(0);
}

open(FILER,"<$ARGV[0]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en lecture");
open(FILEW,">$ARGV[1]") or die("Fichier introuvable ou Impossible d'ouvrir le fichier en ecriture");

while( defined( my $row = <FILER> ) ) {
  chomp($row);
  $row =~ s/[^áíñéèàëê-äïîöôç'a-zA-Z0-9\s]//g; # Suppression des caracteres de ponctuation.
  $row =~ s/['-]/ /g; # Remplacement de l'apostrophe par un espace. 
  if($row ne " " and $row ne "") {
    print( FILEW "$row\n");
  }
}
# On ferme les fichiers de lecture et d'ecriture.
close(FILER);
close(FILEW);
