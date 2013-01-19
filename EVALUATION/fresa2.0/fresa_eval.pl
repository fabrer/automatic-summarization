#----------------------------------------------------------------------------------
#    Copyright (C) 2010  Juan-Manuel Torres-Moreno
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# -----	FRESA (a FRamework for Evaluating of Summaries Automatically   	
#	Base sur la divergence de KL (INEX 11, SanJuan et al 2011)
#	v 0.1	mai 2012
#	v 0.2	mai 2012	Acceleration: calcul des ngrammes du texte a priori
#	v 0.3 	7-10 decembre 2009 
#	v 0.4	10 juin 10 2012
#	v 0.5	1 septembre 2012	fonctionnesl de es fr en
#	v 0.6	10 octobre 2012	stemming porter
#  	Juan-Manuel Torres-Moreno LIA/Avignon   juan-manuel.torres@univ-avignon.fr
#----------------------------------------------------------------------------------
use strict  ;
use encoding 'utf8';
use Lingua::Stem::Snowball;

sub fresa { 
   my ($doc, $resumen, $lang) = @_ ;
   $lang="fr";
   open TEXTO,   $doc     or die "Pas de texte $doc" ; 
   open RESUMEN, $resumen or die "Pas de resume $resumen" ;
   my $text    = " "; while (my $line = <TEXTO>)  { $text    .= lc($line) } ; $text    .= " " ; close TEXTO ;
   my $summary = " "; while (my $line = <RESUMEN>){ $summary .= lc($line) } ; $summary .= " " ; close RESUMEN ;
   my @text    = clean($text,$lang) ;		# Minimal linguistic cleaninig, lemmatization, functional verbs and stopwords
   my @summary = clean($summary,$lang) ;		# Minimal linguistic cleaninig, lemmatization, functional verbs and stopwords
   @text 	 = stemming($lang,@text);		# Stemming du texte
   @summary 	 = stemming($lang,@summary) ;	# Stemming du resume

   my $js = 0 ; my $js2 = 0 ; my $js4 = 0 ; my $jsM = 0 ; # ------------- Divergences: uni, bi, skip-grammes et Moyenne
   if (@summary > 0) { 				# Il y a un mot
      my %text_uni = unigrammes(@text) ;		# unigrammes
      my %summary  = unigrammes(@summary) ;
      $js = kl_symm(\%text_uni, \%summary) ;	# Divergence de KL_symm	
      if (@summary > 1) { 				#-------------- au moins 2 mots
#-------------- Bigrammes 
      	 my %text_bi = bigrammes(@text) ;		# Bigrammes
	 %summary = () ;				# Il y a 2 mots
   	 %summary = bigrammes(@summary) ;		# Bigrammes de la phrase
        $js2 = kl_symm(\%text_bi, \%summary) ;	# Divergence de KL_symm	
#-------------- Bigrammes a trous
	 my %text_su4 = bigrammes_skip(@text) ;	# Bigrammes a trous
	 %summary = () ;
   	 %summary = bigrammes_skip(@summary) ;	# Bigrammes a trous de la phrase
        $js4 = kl_symm(\%text_su4, \%summary) ; 	# Divergence de KL_symm
      }  # @summary > 1  				Tiene al menos 2 palabras ?
      else { $js2 = $js4 = 1 } 			# Pas de bigrammes: divergence maximale a JS2 JS4
   }  # @summary > 0 ?				No tiene palabras
   else { $js = $js2 = $js4 = 1 }  		# Pas de mots: divergence maximale a JS 	
   $jsM = ($js + $js2 + $js4)/3 ;			# JSM = moyenne de JS + JS2 + JS4
   my %fresa ;					# FRamework for Evaluating of Summaries Automatically 1,2,4,M
   $fresa{1} = $js ; $fresa{2} = $js2; $fresa{4} = $js4; $fresa{M} = $jsM ; 
   return %fresa 
}
#====================== SUBS ======================

#------------------------------------------------------------------------------------------- NGRAMMES
sub unigrammes {	#---------------------- Calcul de Unigrammes
	my %unigrammes = () ;
	for (my $i = 0; $i < @_; $i++) {# Parcourir chaque mot de $text
	      	$unigrammes{$_[$i]}++;     	# Stocker le unigramme dans l'index du hachage %unigr ($unigr{"puces"}=1, $unigr{"informatique"}=1, etc}
 	}
 	return %unigrammes 
}

sub bigrammes {	#---------------------- Calcul de Bigrammes
 	my $nbmots    = @_-1 ;
 	my %bigrammes = () ;
 	for (my $i = 0; $i < $nbmots; $i++) {	# Parcourir chaque mot de $text
	      	$bigrammes{$_[$i]." ".$_[$i+1]}++ ;     	# Stocker le bigram dans l'index du hachage %bigr ($bigr{"puces"}=1, $bigr{"informatique"}=1, etc}
 	}
 	return %bigrammes 
}

sub bigrammes_skip {	#---------------------- Calcul de Bigrammes a trous < 4
  	my $nbmots    = @_-1 ;
  	my %bigrammes = () ;
  	my $trou   = 4 ;	# Trous < 4
  	for (my $i = 0; $i<$nbmots; $i++) {	# Parcourir chaque mot de $text
		for (my $j = $i+1; $j < $i+$trou; $j++) {	# generer 4 bigrammes
    			$bigrammes{$_[$i]." ".$_[$j]}++ if($j < $nbmots+1) ; 	
       	}
  	}
  	return %bigrammes
}

sub kl_symm {
	my ($text, $summary) = @_;	# $text=pointeur texte, $summary=pointeur a la phrase  
       sub log2{ return log(shift)/log(2) }	# Fonction log base 2
   	my %deja_V = () ; my %deja_VS = () ;	# Identifier les symboles de la distribution P
	map{ $deja_V{$_}++ }  (keys %$text) ;    my @V  = sort keys %deja_V ;  my $N_text = @V ;   # print "|Texte|=",  $N_text;
	map{ $deja_VS{$_}++ } (keys %$summary) ; my @VS = sort keys %deja_VS ; my $N_summary=@VS; #print "|Summary|=",$N_summary,"\n"; 
	my $s = 0;	# somme de divergences
	my $a = 1/$N_text;# Penalité si le mot n'existe pas dans le résumé

   	foreach my $mot (@V) {	# Calcul de frequences du $text
		if(!exists($summary->{$mot})) { $s+= $a; } # Lissage = prob_mot(texte)/|Vocabulaire texte|
		else 	{
			my ($v0,$v1)=( log2($text->{$mot}+1), log2($summary->{$mot}/$N_summary*$N_text+1) );
	 		if ($v1>$v0)	   {$s+=$a*(1-$v0/$v1)}
        		            else {$s+=$a*(1-$v1/$v0)};
			}
	}		
	return $s;
}

##################################################### Spanish Functional words
my @Es=("a", "abajo", "acaso", "adelante", "además", "adónde", "afuera", "afueras", "ah", "ahi", "ahí", "ahora", "ajá", "al", "algo", "alguien", "algún", "alguna", "algunas", "alguno", "algunos", "alla", "allá", "allí", "alrededor", "ambos", "ante", "anteayer", "anterior", "anteriores", "anteriormente", "antes", "aparte", "apenas", "aproximadamente", 
"aquel", "aquél", "aquella", "aquélla", "aquellas", "aquéllas", "aquello", "aquellos", "aquéllos", "aqui", "aquí", "arriba", "artículo ", "asi", "así", "asimismo", "atrás", "aun",  "aún", "aunque", "ay", "ayer", "bah", "bajo", "bastante", "bastantes", "bien", "cabe", "cabo", "cada", "capítulo", "casi", "cerca", "cercano", "cercanos", "cercas", "chas", "chau",  "che", "chist", "chito", "chitón", "cierta", "ciertamente", "ciertas", "ciertísima", "ciertísimas", "ciertísimo", "ciertísimos", "cierto", "ciertos", "clic", "como", "cómo",  "comoquiera", "completamente", "con", "concerniente", "concernientes", "conmigo", "conque", "consequentemente", "consigo", "contigo", "contra", "cosa", "cosas", "cual", "cuál",  "cuales", "cuáles", "cualesquier", "cualesquiera", "cualesquieras", "cualquier", "cualquiera", "cuan", "cuán", "cuando", "cuándo", "cuandoquiera", "cuanta", "cuánta", "cuantas",  "cuántas", "cuanto", "cuánto", "cuantos", "cuántos", "cuya", "cuyas", "cuyo", "cuyos", "de", "debajo", "decía", "decían", "decir", "definitivamente", "del", "demás", "demasiada",
 "demasiadas", "demasiado", "demasiados", "dentro", "desde", "después", "detrás", "diferente", "diferentes", "diga", "digamos", "digan", "digo", "dije", "dijeron", "dijo", "dirían", "diversas", "diversos", "donde", "dónde", "dondequiera", "dondequieras", "durante", "e", "efectivamente", "eh", "el", "él", "ella", "ellas", "ello", "ellos", "email", "en",
 "enseguida", "entonces", "entre", "entretanto", "era", "erais", "éramos", "eran", "eras", "eres", "es", "esa", "ésa", "esas", "ésas", "ese", "ése", "eso", "esos", "ésos", "esta", "ésta", "Ésta", "está", "estaba", "estabais", "estábamos", "estaban", "estabas", "estad", "estada", "estadas", "estado", "estados", "estáis", "estamos", "estan", "están", "estando", "estar", "estará", "estarán", "estarás", "estaré", "estaréis", "estaremos", "estaría", "estaríais", "estaríamos", "estarían", "estarías", "estas", "éstas", "estás", "este", "éste", "esté", "estéis", "estemos", "estén", "estés", "esto", "ésto", "estos", "éstos", "estoy", "estuve", "estuviera", "estuvierais", "estuviéramos", "estuvieran", "estuvieras", "estuvieron", "estuviese", "estuvieseis", "estuviésemos", "estuviesen", "estuvieses", "estuvimos", "estuviste", "estuvisteis", "estuvo", "etc", "etcétera", "exactamente", 
"extra", "fue", "fuera", "fuerais", "fuéramos", "fueran", "fueras", "fueron", "fuese", "fueseis", "fuésemos", "fuesen", "fueses", "fui", "fuimos", "fuiste", "fuisteis", "generalmente", "gracias", "guau", "ha", "habéis", "había", "habíais", "habíamos", "habían", "habías", "habida", "habidas", "habido", "habidos", "habiendo", "habrá", "habrán", "habrás", "habré", "habréis", "habremos", "habría", "habríais", "habríamos", "habrían", "habrías", "hacer", "hacia", "haga", "hagamos", "hagan", "hago", "han", "harían", "harta", "hartas", "harto", "hartos", "has", "hasta", "hay", "haya", "hayáis", "hayamos", "hayan", "hayas", "he", "helo", "hemos", "hi", "hice", "hicieron", "hizo", "hola", "hoy", "hube",
 "hubiera", "hubierais", "hubiéramos", "hubieran", "hubieras", "hubieron", "hubiese", "hubieseis", "hubiésemos", "hubiesen", "hubieses", "hubimos", "hubiste", "hubisteis", "hubo", "idem", "igual", "incluso", "inmediata", "inmediatamente", "inmediatas", "inmediato", "inmediatos", "ja", "jam", "jamás", "junto", "juntos", "la", "las", "le", "les", "lo", 
"los", "luego", "mas", "más", "me", "mediante", "mejor", "menos", "mi", "mí", "mia", "mía", "mias", "mías", "mientras", "mio", "mío", "mios", "míos", "mis", "misma", "mismas", "mismo", "mismos", "mucha", "muchas", "mucho", "muchos", "muy", "nada", "nadie", "ni", "ningun", "ningún", "ninguna", "ningunas", "ninguno", "ningunos", "no", "nos", "nosotras",
 "nosotros", "nuestra", "nuestras", "nuestro", "nuestros", "número", "nunca", "o", "obstante", "obviamente", "obvio", "oh", "ok", "ole", "olé", "os", "otra", "otras", "otro", "otros",
 "pa", "página", "para", "peor", "pero", "pi", "poca", "pocas", "poco", "pocos", "pom", "por", "porque", "pos", "posteriormente", "prácticamente", "pronto", "propio", "propios",
 "psch", "pues", "que", "qué", "quien", "quién", "quienes", "quiénes", "quienquiera", "quizá", "quizás", "rapida", "rápida", "rapidamente", "rápidamente", "rapidas", "rápidas",
 "rapido", "rápido", "rapidos", "rápidos", "realmente", "sabido", "sabría", "se", "sé", "sea", "seáis", "seamos", "sean", "seas", "seguida", "seguido", "según", "sentid", "sentida", "sentidas", "sentido", "sentidos", "sepa", "sepamos", "ser", "será", "serán", "serás", "seré", "seréis", "seremos", "sería", "seríais", "seríamos", "serían", "serías", "si", "sí",
 "siempre", "siguiente", "siguientemente", "siguientes", "sin", "sino", "siquiera", "so", "sobre", "sois", "sola", "solamente", "solas", "solo", "sólo", "solos", "somos", "son", "soy", "su", "súbitamente", "suficiente", "suficientes", "supe", "supieron", "sus", "suya", "suyas", "suyo", "suyos", "tac", "tal", "tales", "tambien", "también", "tampoco", "tan", "tanta", "tantas", "tanto", "tantos", "te", "tendrá", "tendrán", "tendrás", "tendré", "tendréis", "tendremos", "tendría", "tendríais", "tendríamos", "tendrían", "tendrías", "tened", "tenéis", "tenemos", "tenga", "tengáis", "tengamos", "tengan", "tengas", "tengo", "tenía", "teníais", "teníamos", "tenían", "tenías", "tenida", "tenidas", "tenido", "tenidos", "teniendo", "ti", "tic", "tiene", "tienen", "tienes", "tin", "toc", "toda", "todas", "todavía", "todo", "todos", "tras", "trás", "traves", "través", "tu", "tú", "tus", "tuve", "tuviera", "tuvierais", "tuviéramos", "tuvieran", "tuvieras", "tuvieron", "tuviese", "tuvieseis", "tuviésemos", "tuviesen", "tuvieses", "tuvimos", "tuviste", "tuvisteis", "tuvo",
"tuya", "tuyas", "tuyo", "tuyos", "u", "uf", "uh", "últimamente", "um", "umm", "un", "una", "unas", "única", "únicas", "único", "únicos", "uno", "unos", "url", "usted", "ustedes", "uy", "varias", "varios", "veces", "verdaderamente", "vez", "vos", "vosotras", "vosotros", "vuestra", "vuestras", "vuestro", "vuestros", "y", "ya", "yeah", "yo", "z", "zap", "zas"
);

###################################################
## Fr Mots fonctionels                             
# Version 1.2                                   
# Creada     : 10 Febrero de 2002               
# Modificada : 17 fevrier 2004                  # 
# Modificada : 3 juin 2012	                    # 
# Auteurs    : Juan Manuel Torres Moreno        #        
#              Patricia Velazquez Morales       	 #
###################################################
my @Fr=("à", "actuel", "actuels", "actuellement", "afin", "ah", "aïe", "ainsi", "ailleurs", "alors", "allô", "allo", "après", "assez", "au", "aucune", "aucunement", "aucun", 
"audit", "aujourd", "auparavant", "auprès", "auquel", "aussi", "aussitôt", "autant", "autour", "autre", "autrement", "autres", "autrefois", "autrui", "auxdits", "auxdites", 
"aux", "auxquels", "auxquelles", "avec", "avant", "b", "bah", "bang", "beaucoup", "bien", "bientôt", "bis", "bof", "bon", "bons", "bonnes", "bonne", "boum", "bravo", "bref", 
"brr", "c", "car", "ca", "ce", "ceci", "celle", "cela", "celles", "celui", "cependant", "certain", "certaine", "certainement", "certaines", "certains", "certes", "ces", "cet", 
"cette", "cettes", "ceux", "chez", "chut", "ci", "clic", "clac", "cocorico", "combien", "comme", "comment", "contre", "contrairement", "coucou", "crac", "cric", "ça", "çà", 
"chaque", "chacun", "chacune", "chapitre", "chez", "d", "dans", "de", "debout", "dedans", "dehors", "déjà", "del", "demain", "depuis", "dernier", "derniers", "dernière", 
"dernières", "dernièrement", "derrière", "des", "dès", "desdits", "desdites", "désormais", "desquels", "desquelles", "dessous", "dessus", "devant", "diantre", "différents", 
"différent", "divers", "donc", "dont", "dorénavant", "du", "dudit", "durant", "duquel", "e", "eh", "effectivement", "également", "elle", "elles", "en", "encore", "enfin", 
"ensemble", "ensuite", "entre", "envers", "environ", "et", "etc", "etcétera", "euh", "eux", "évidemment", "exprès", "f", "façon", "façons", "facilement", "finalement", "fois", 
"g", "grand", "grands", "grande", "grandes", "généralement", "grâce", "guère", "h", "halte", "h", "hein", "hélas", "hep", "hier", "hormis", "hors", "ho", "hop", "hourrah", 
"hui", "hue", "hum", "ici", "infiniment", "incessamment", "incessant", "incessante", "il", "ils", "issu", "j", "jadis", "jamais", "je", "jusqu", "jusque", "justement", "k", 
"l", "la", "là", "ladite", "laquelle", "le", "ledit", "les", "lesdits", "lesdites", "lequel", "lesquels", "lesquelles", "leur", "leurs", "loin", "longtemps", "lors", "lorsqu", 
"lorsque", "lui", "m", "ma", "maintenant", "maint", "mainte", "maintes", "mais", "mal", "malheureusement", "malgr", "me", "meilleure", "meilleures", "meilleur", "meilleurs", 
"même", "mêmes", "mes", "miaou", "mien", "miens", "mienne", "miennes", "mieux", "mlle", "mme", "moi", "moindre", "moins", "mon", "moyennant", "n", "naguère", "ne", "néanmoins", 
"ni", "non", "nonobstant", "nos", "notre", "notres", "nôtre", "nôtres", "nous", "nul", "nulle", "nullement", "o", "ô", "ò", "ok", "on", "ou", "où", "ouais", "oui", "or", "outre", 
"o", "ouf", "p", "paf", "par", "parbleu", "parce", "parfaitement", "parfois", "parmi", "particulièrement", "partout", "pas", "patatras", "pendant", "petit", "petits", "petite", 
"petites", "peu", "pif", "pis", "pire", "plouf", "plupart", "plus", "plusieurs", "plutôt", "pouah", "pour", "pourtant", "pourqui", "pourquoi", "practiquement", "près", "presque", 
"presqu", "priori", "probablement", "pst", "puis", "puisqu", "puisque", "qu", "quand", "quant", "que", "quel", "quelconque", "quelconques", "quelle", "quelles", "quelqu", 
"quelque", "quelques", "quelquefois", "quels", "qui", "quiconque", "quoi", "quoique", "quoiqu", "r", "rien", "relativement", "respectivement", "s", "si", "sa", "sauf", "se", 
"sans", "selon", "ses", "seul", "seule", "seulement", "sien", "siens", "sienne", "siennes", "simple", "simplement", "sinon", "sitôt", "soi", "son", "soudain", "soudainement", 
"sous", "souvent", "stop", "subit", "subite", "suivant", "suivante", "sur", "sûr", "sûre", "sûrement", "sûres", "sûrs", "surtout", "susdit", "susdite", "susdits", "susdites", 
"suite", "t", "ta", "tandis", "tantôt", "tant", "tard", "tas", "te", "tel", "telle", "telles", "tellement", "tels", "tes", "tic", "tac", "tien", "tiens", "tienne", "tiennes", 
"toi", "ton", "tôt", "totalement", "toujours", "tous", "tout", "toute", "toutefois", "toutes", "travers", "très", "trop", "tu", "u", "un", "une", "uniquement", "unes", "uns", 
"v", "vers", "via", "voici", "voilà", "voire", "votre", "votres", "vos", "vôtre", "vôtres", "vous", "vraiment", "vraisemblablement", "y", "youppie", "z", "zut",
"dire", "disait", "disons", "dit", "être", "été", "étée", "étées", "étés", "étant", "étante", "étants", "étantes", "suis", "es", "est", "sommes", "êtes", "sont", "serai", 
"seras", "sera", "serons", "serez", "seront", "serais", "serait", "serions", "seriez", "seraient", "étais", "était", "étions", "étiez", "étaient", "fus", "fut", "fûmes", 
"fûtes", "furent", "sois", "soit", "soyons", "soyez", "soient", "fusse", "fusses", "fût", "fussions", "fussiez", "fussent", "avoir", "a", "ayant", "ayante", "ayantes", 
"ayants", "eu", "eue", "eues", "eus", "ai", "as", "avons", "avez", "ont", "aurai", "auras", "aura", "aurons", "aurez", "auront", "aurais", "aurait", "aurions", "auriez", 
"auraient", "avais", "avait", "avions", "aviez", "avaient", "eut", "eûmes", "eûtes", "eurent", "aie", "aies", "ait", "ayons", "ayez", "aient", "eusse", "eusses", "eût", 
"eussions", "eussiez", "eussent", "falloir", "faut", "fallait", "fallut", "faudra", "fallu", "faille", "fallût", "faudrait", "devoir", "devaient", "devais", "devait", "devant", 
"devez", "deviez", "devions", "devons", "devra", "devrai", "devraient", "devrais", "devrait", "devras", "devrez", "devriez", "devrions", "devrons", "devront", "dois", "doit", 
"doive", "doivent", "doives", "dû", "dûmes", "durent", "dus", "dusse", "dussent", "dusses", "dussiez", "dussions", "dut", "dût", "dûtes", "peut", "peuvent", "peux", "pourra", 
"pourrai", "pourraient", "pourrais", "pourrait", "pourras", "pourrez", "pourriez", "pourrions", "pourrons", "pourront", "pouvaient", "pouvais", "pouvait", "pouvant", "pouvez", 
"pouviez", "pouvions", "pouvons", "pu", "puis", "puisse", "puissent", "puisses", "puissiez", "puissions", "pûmes", "purent", "pus", "pusse", "pussent", "pusses", "pussiez", "pussions", "put", "pût", "pûtes", "veuille", "veuillent", "veuilles", "veuillez  ", "veulent", "veut", "veux", "voudra", "voudrai", "voudraient", "voudrais", "voudrait", "voudras", "voudrez", "voudriez", "voudrions", "voudrons", "voudront", "voulaient", "voulais", "voulait", "voulant", "voulez", "vouliez", "vouliez", "voulions", "voulons", "voulu", "voulûmes", "voulurent", "voulus", "voulusse", "voulussent", "voulusses", "voulussiez", "voulussions", "voulut", "voulût", "voulûtes", "fais", "faisaient", "faisais", "faisait", "faisant", "faisiez", "faisions", "faisons", "fait", "faites", "fasse", "fassent", "fasses", "fassiez", "fassions", "fera", "ferai", "feraient", "ferais", "ferait", "feras", "ferez", "feriez", "ferions", "ferons", "feront", "fîmes", "firent", "fis", "fisse", "fissent", "fisses", "fissiez", "fissions", "fit", "fîtes", "font"
);

##################################################### English Functional words
my @En=("be","able to","can","could","dare","had better","have to","may","might","must","need to","ought","ought to","shall","should","used", "to","will","would","accordingly","after","albeit","although","and","as","because","before","both","but","consequently","either","for","hence","however","if","neither",
"nevertheless","nor","once","or","since","so","than","that","then","thence","therefore","tho'","though","thus","till","unless","until","when","whenever","where","whereas",
"wherever","whether","while","whilst","yet","a","all","an","another","any","both","each","either","every","her","his","its","my","neither","no","other","our","per","some",
"that","the","their","these","this","those","whatever","whichever","your","aboard","about","above","absent","according to","across","after","against","ahead","ahead of","all over","along","alongside","amid","amidst","among","amongst","anti","around","as","as of","as to","aside","astraddle","astride","at","away from","bar","barring","because of","before","behind","below","beneath","beside","besides","between","beyond","but","by","by the time of","circa","close by",
"close to","concerning","considering","despite","down","due to","during","except","except for","excepting","excluding","failing","following","for","for all","from",
"given","in","in between","in front of","in keeping with","in place of","in spite of","in view of","including","inside","instead of","into","less","like","minus",
"near","near to","next to","notwithstanding","of","off","on","on top of","onto","opposite","other than","out","out of","outside","over","past","pending","per",
"pertaining to","plus","regarding","respecting","round","save","saving","similar to","since","than", "thanks to","through","throughout","thru","till","to","toward","towards","under","underneath","unlike","until","unto","up",
"up to","upon","versus","via","wanting","with","within","without","all","another","any","anybody","anyone","anything","both",
"each","each other","either","everybody","everyone","everything","few","he","her","hers","herself","him","himself","his","I","it","its","itself","many",
"me","mine","myself","neither", "no_one","nobody","none","nothing","one","one another","other","ours","ourselves","several","she","some","somebody","someone","something","such",
"that","theirs","them","themselves", "these","they","this","those","us","we","what","whatever","which","whichever","who","whoever","whom","whomever","whose","you","yours","yourself",
"yourselves","a bit of","a couple of","a few","a good deal of","a good many","a great deal of","a great many","a lack of","a little","a little bit of","a majority of","a minority of","a number of","a plethora of", "a quantity of","all","an amount of","another","any","both","certain","each","either","enough","few","fewer","heaps of","less","little","loads","lots","many", "masses of","more","most","much","neither","no","none","numbers of","part","plenty of","quantities of","several","some","the lack of","the majority of","the minority of", "the number of","the plethora of","the remainder of","the rest of","the whole","tons of","various","is","are","was","were","had","will","would","ll","ld","could");

##################################################### Deutsch Functional words
my @De=("ab","aber","abermals","abgesehen","all","alle","allein","allem","allemal","allen","aller","allerdings","alles","allgemein","allgemeine","allgemeinem","allgemeinen",
"allgemeiner","allgemeinere","allgemeinerem","allgemeineren","allgemeinerer","allgemeineres","allgemeines","allgemeinste","allgemeinsten","allgemeinster","allgemeinstes",
"allmählich","allzu","als","alsdann","also","als","am","an","andere","anderem","anderen","anderer","andererseits","anderes","anderm","andern","ander","anderr",
"anders","anderseits","anfang","anfangs","ans","anstatt","auch","auf","aufs","aus","ausschliesslich","ausser","ausserdem","äußere","äußerem","äußeren","äußerer","äußeres",
"ausserhalb","äußerlich","äußerst","äußerste","äußerstem","äußersten","äußerster","äußerstes","bald","bei","beide","beidem","beiden","beider","beides","beim","bereit",
"bereits","besonders","bestimmt","bestimmte","bestimmten","bestimmter","bestimmtes","bestimmteste","bestimmtesten","bestimmtester","bestimmtestes","bevor","bisher",
"bisherige","bist","bis","bloss","bloß","da","dabei","dadurch","dafür","dagegen","daher","dahin","damals","damit","danach","dann","daran","darauf","daraus","darin",
"darüber","darum","darunter","das","daselbst","dasjenige","dass","dasselbe","daß","da","davon","dazu","dein","deine","deinem","deinen","deiner","deines","deins","dein",
"dem","demjenigen","demnach","demselben","den","denen","denjenigen","denn","dennoch","denselben","deren","derer","dergleichen","derjenige","derjenigen","derselbe","derselben",
"derselbe","der","des","deshalb","desselben","dessen","desto","deswegen","dich","die","diejenige","diejenigen","dies","diese","dieselbe","dieselben","diesem","diesen","dieser",
"dieses","dies","dir","doch","dorthin","dort","durchaus","durchschnittlich","durch","du","eben","ebenfalls","ebenso","ebensowenig","ehemaligen","eher","eigene","eigenem",
"eigenen","eigener","eigenes","eigentlich","eigentliche","eigentlichem","eigentlichen","eigentlicher","eigentliches","eigentlichsten","ein","einander","eine","einem",
"einen","einer","einerseits","eines","einige","einigem","einigen","einiger","einiges","einig","einmal","einst","einzeln","einzelne","einzelnen","einzelner","einzelnes",
"einzig","einzige","einzigen","einziger","einziges","endlich","entgegen","entweder","er","erst","es","etwa","etwas","euch","euer","eure","eurem","euren","eurer","eures",
"fast","fern","ferner","folgend","folgende","folgendem","folgenden","folgender","folgendes","fortan","freilich","früh","früh","frühe","frühem","frühen","früher","frühere",
"früherem","früheren","früherer","früheres","frühes","früheste","frühesten","frühestens","frühester","frühestes","für","ganz","ganze","ganze","ganzem","ganzen","ganzen",
"ganzer","ganzes","gänzlich","gegen","gegenüber","genug","gerade","gerade","gering","geringe","geringem","geringen","geringer","geringere","geringerem","geringeren",
"geringerer","geringeres","geringes","geringste","geringstem","geringsten","geringstens","geringster","geringstes","gesamt","gesamte","gesamten","gesamter","gesamtes",
"gewiss","gewisse","gewissem","gewissen","gewisser","gewissermaßen","gewisses","gewöhnlich","gleich","gleiche","gleichem","gleichen","gleicher","gleiches","gleichfalls",
"gleichsam","gleichzeitig","gleichzeitigen","großenteils","häufig","hauptsächlich","her","heran","hervor","heutige","heutzutage","hierher","hier","hierin","hiermit","hin",
"hinab","hinaus","hindurch","hinein","hinreichend","hinsichtlich","hinterbehind","hin","höchst","ich","ihm","ihn","ihnen","ihn","ihr","ihre","ihrem","ihren","ihrer","ihres",
"ihrs","ihr","im","immer","in","indem","indes","infolge","in","innen","innerhalb","innerlich","ins","insofern","irgend","irgendwie","irgendwo","ja","je","jede","jedem","jeden",
"jeder","jedes","jedoch","jene","jenem","jenen","jener","jenes","jene","jenseits","jetzt","kaum","kein","keine","keinem","keinen","keiner","keines","keineswegs","kein","keins",
"könnte","längst","lediglich","letzte","letztem","letzten","letztens","letzter","letztere","letzterem","letzteren","letzterer","letzteres","letztes","man","manch","manche",
"manchem","manchen","mancher","manches","manche","man","mehr","mein","meine","meinem","meinen","meiner","meines","mein","meins","meist","meiste","meisten","meistens","mich",
"mindestens","mir","mit","miteinander","mitten","mittleren","mit","möglich","möglichst","nach","nachdem","nachher","nächst","nächste","nächsten","nächstens","nächster",
"nächstes","nach","nahe","näher","natürlich","neben","nebst","nicht","nichtsdestoweniger","nichts","nie","niemals","niemand","nirgends","noch","nun","nur","oben","ob",
"obwohl","oder","offenbar","oft","ohne","paar","plötzlich","regelmäßig","sämtlich","sämtliche","sämtlichem","sämtlichen","sämtlicher","sämtliches","schlechterdings",
"schon","schwerlich","sehr","sein","seine","seinem","seinen","seiner","seines","sein","seins","seit","seitdem","selber","selbst","setzte","sich","sich","sie","sie","so",
"sodann","sofort","sogar","sogenannte","sogleich","solange","solch","solche","solchem","solchen","solcher","solches","solchesuch","sondernbut","sonst","so","soviel","soweit",
"sowie","sowohl","spät","späte","späten","später","spätere","späteren","späteren","späterer","späteres","späterhin","spätes","späteste","spätesten","spätestens","spätester",
"spätestes","stets","tatsächlich","teils","trotz","über","überall","überdies","überhaupt","über","übrigen","übrigens","um","und","ungefähr","ungehindert","unmittelbar",
"unmittelbare","unse","unsem","unsen","unser","unsere","unserem","unseren","unserer","unseres","unserm","unsern","unsers","unses","uns","unter","verglichen",
"verhaeltnismäßig","verhaeltnismäßig8","vermutlich","verschieden","verschiedene","verschiedenem","verschiedenen","verschiedener","verschiedenes","verschiedenste",
"verschiedensten","verschiedenstes","viel","viele","vielem","vielen","vieler","vieles","vielfach","vielleicht","vielmehr","viel","much","voll","völlig","vollkommen",
"vollständig","vom","von","voraus","vor","vorbei","vorher","vorläufig","vorwiegend","vorzugsweise","während","wann","warst","warum","was","weder","weg","wegen","weil",
"weiter","weitere","weiterem","weiteren","weiterer","weiteres","weiteres","weiter","welche","welchem","welchen","welcher","welches","welche","wenig","wenige","weniger",
"wenigeren","weniges","wenigste","wenigsten","wenigstens","wenngleich","wenn","wer","wesentliche","wesentlichem","wesentlichen","wesentlicher","wesentliches","wesentlichste",
"wesentlichsten","wesentlichster","wesentlichstes","weshalb","wie","wiederagain","wiederholt","wiederum","wie","how","wieso","wieviel","wieweit","wir","wirklich","wirkliche",
"wirklichem","wirklichen","wirklicher","wirkliches","wirst","wir","wo","wobei","wodurch","wogegen","wohin","wohl","womit","womöglich","worauf","worin","wovon","wo","ziemlich",
"zuerst","zugleich","zuletzt","zum","zunächst","zurück","zurück","zur","zusammen","zu","zuvor","zwar","zwischen","sein","bin","bist","ist","sind","seid","war","warst","war",
"waren","ward","wäre","wären","sei","seien","gewesen","haben","habe","hast","hat","habt","hatte","hattest","hatten","hättet","hättest","hätten","gehabt","wollen","will",
"willst","wollt","wollte","wolltest","wollten","woltet","wolle","gewollt","sollen","soll","sollst","sollt","sollte","solltest","sollten","soltet","solle","sollest",
"gesollt","müssen","muss","musst","müssen","müsst","musste","musstest","mussten","musstet","müsse","müsstest","müssten","müsstet","gemusst","können","kann","kannst","
können","könnt","konnte","konntest","konnten","könnte","könntest","könnten","gekonnt","lassen","lasse","lässt","lasst","ließ","ließt","ließen","gelassen","tun","tue",
"tust","tut","tun","tat","tatest","taten","tatet","tue","täte","tätest","täten","getan","werden","werde","wirst","wird","werdet","wurde","wurdest","wurde","wurden",
"wurdet","würde","würdest","würden","würdet","werde","werdest","geworden");

##################################################### Brazilian Functional words
my @Pt=("oi");

#----------------------------------- Minimal lingustic clean
sub clean {	
    my ($text, $lang) = @_ ; 	# Chaine de texte
	$text    =~ s/<[^>]+>/ /g;	# Eliminer balises pour textes balises type INEX  13.janv.2010
#    my $word_characters="a-záàâäâëéêèíîïöôóúùüûçñÑÀÄÉËÜÙÇ" ;
	$text =~ tr/-,.:¡!'"();¿?«»…“”`‘’·←—–→±_☻µ\\*¶[]{}=\/§£$€%&+#~²ª°ø∈∗|≤−/ / ; # Ponctuation étendue #  $mainText =~ s/[[:punct:]]/ /g; ; # Ponctuation normale
	$text =~ s/[<>]/ /g ;			# il ne veut pas eliminer <> en tr...
	$text =~ s/œ/oe/g ;				# Transformer ces caracteres LIGNE A LIGNE!!! en utf8
	$text =~ tr/ÂÁÀÉÊÔÓÍÇÚÜÑ/âàéêôóíçúüñ/ ; # Transformer ces caracteres 
	$text =~ s/\s+/ /g ;				# Transformer ces caracteres	
#    $text    =~ s/[^$word_characters]/ /g; 
	$text =~ s/ \w / /g ; $text =~ s/ +/ /g ; 	# Ponctuation

my  @fonctionnels = @Es if $lang eq "es";	# Espagnol
    @fonctionnels = @Fr if $lang eq "fr";	# Francais
    @fonctionnels = @En if $lang eq "en";	# Anglais
    @fonctionnels = @De if $lang eq "de";	# Allemand
    @fonctionnels = @Pt if $lang eq "pt";	# Portugais/Brésilien

   $text = " ".$text." ";
   for my $f (@fonctionnels){ $text =~s/ $f / /g } 
   $text =~ s/ +/ /g; $text =~ s/^ //; $text =~ s/ $//;
   my @text = split / +/,$text;
   return @text 
}

# ----------------------- stemming
sub stemming {			
	my ($fich_lang,@text) = @_ ;			# texte + langue
	my $stemmer = Lingua::Stem::Snowball->new(	# Initialiser stemer en fonction de la langue	
		lang     => $fich_lang, 
        	encoding => 'UTF-8',
    	); die $@ if $@;

  foreach my $mot (@text){
	next if $mot =~ /^$/;
      	$mot = $stemmer->stem($mot);
  }
  my @t = () ; foreach my $mot (@text) { push(@t,$mot) if $mot ne "" }; # Garder uniquement les elements non vides
  return @t
}

return 1;
