clear
echo "----------------- FRESA 2.0 (a FRamework for Evaluating Summaries Automatically)"
echo "(c) 2012 Juan-Manuel Torres juan-manuel.torres@univ-avignon.fr"
# $1 fichier de parametres : fresa.in
# $2 Langue : en fr es 


if test -z "$2"	# Si LANGUE=vide
then
	echo "Syntaxe: ./fresa.sh fichier_configuration.fresa langue=es|en|fr"
	exit
fi

echo "Langue = $2"

perl fresa2.0/fresa.pl $1 $2

