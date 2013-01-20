# http://cran.r-project.org/web/packages/tm/tm.pdf

# imports
library("tm")

# Chargement du corpus
text <- Corpus(DirSource("/home/nia/TALNE/automatic-summarization/TEXTES/"), readerControl = list(language = "lat"))

##### Pré-traitement #####
corpus <- tm_map(text, removePunctuation) # Suppression de la ponctuation
corpus <- tm_map(corpus, stripWhitespace) # Suppression des espaces en trop
corpus <- tm_map(corpus, tolower) # Met le texte en minuscules
corpus <- tm_map(corpus, removeWords, stopwords("french")) # Suppression des stopwords
corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, stemDocument, language = "french") # Stem les mots, en se basant sur l'algorithme de Porter

##### Vectorisation #####
matrice <- DocumentTermMatrix(corpus, control = list(weighting = weightTf)) # Génère la matrice des term/document
matrice <- removeSparseTerms(matrice, 0.75) # Supprimer les termes isolés de la matrice
dictionnaire <- Dictionary(matrice)

##### Calculs et traitement #####
