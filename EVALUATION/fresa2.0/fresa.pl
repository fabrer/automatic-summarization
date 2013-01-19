# Copyright (C) 2010/12  Juan-Manuel Torres-Moreno
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -----	FRESA (a FRamework for Evaluating Summaries Automatically   	
#	V 0.5     14 decembre 2009/28 janvier 2010/10 juin 2012
#  	Juan-Manuel Torres-Moreno LIA/Avignon   juan-manuel.torres@univ-avignon.fr
use strict ;
use encoding 'utf8';
require "./fresa2.0/fresa_eval.pl" ;

use XML::Twig ;
my $twig = new XML::Twig ;		# creation d'un objet twig
   $twig = XML::Twig->parse($ARGV[0]) ; 	# fichier de configuration fraise
my $root = $twig->root ;		# racine du XML
my $nb=0 ;
my %fresa_moy = () ;
my $langue=$ARGV[1];

print "Version 2.0\n";
foreach my $eval ($root->children ) {	# Chaque eval
    print "\t---> EVAL ", $eval->att('ID') ; 
    my $PATH_model = $eval->first_child('TEXTE-ROOT')->text ;
    my $PATH_summ  = $eval->first_child('SUMM-ROOT')->text ;
    my $texte      = $eval->first_child('TEXTE')->text ;	  
    print ": ", $texte,"\n" ; 
    if ( my $summarizers = $eval->first_child('SUMMARIZERS') ) {	    # Summarizers
    	foreach my $resume ( $summarizers->children('SUMM') ) {
      		my $peer        = $resume->att('ID') ;	
      		my $resume_peer = $resume->att('TXT') ;	
      		my %fresa       = fresa($PATH_model.$texte, $PATH_summ.$resume_peer,$langue) ; 	# FRESA
      		printf  "%10s ", $peer ; 
		for my $key (sort keys %fresa ) { 
			my $value = 1 - $fresa{$key} ; 	
		        printf "FRESA_%s: %5.4f ",$key,$value ;  
			$fresa_moy{$peer}{$key} += $value ;
		}
		print "\n" ;
    	}  # chaque SUMM
    }
    $nb++;
}

my %fresita;	# Pour trier par FRESA_M
for my $system ( keys %fresa_moy ) {
	for my $key (sort { $b <=> $a } keys %{ $fresa_moy{$system} } ) {	# Hash de hash
#		printf "<FRESA_%s>: %5.4f ",$key,$fresa_moy{$system}{$key}/$nb;
		$fresita{$system} = $fresa_moy{$system}{$key}/$nb if $key eq "M";	# Garder FRESA_M
	}
}

printf "\n\t*** Moyennes|Average / %d eval ***\n",$nb ;		# Tries par FRESA_M
printf "-----------------------------------------------------------------------\n";
printf "       SYSTEME  FRESA_4	FRESA_2	FRESA_1	FRESA_M\n";
for my $system (sort { $fresita{$b} <=> $fresita{$a} } keys %fresita ) {
	printf "%s\t",$system ;
	for my $key (sort { $b <=> $a } keys %{ $fresa_moy{$system} } ) {	# Hash de hash
		printf "%8.5f\t",$fresa_moy{$system}{$key}/$nb;
	}
	print "\n";
}


