# n7-deep-learning

## Présentation

Ce répertoire est donne accès à une basse de donnée contenant des proverbs en anglais.




## Scrapping


Dans le repertoire scrapping, se trouve 4 fichiers, les versions simples pour le scrapping :
 - `scrap[nomDuSite].py` : version pour scrapper les proverbs du site en les ajoutants à la fin du fichier indiqué (voir commentaire si besoin).
        ( éxécution d'environ 5-7min voir moins en fonction de votre debit )


 - `clean.py` : fichier pour nettoyer et elimner les doublons depuis le fichier csv obtenu par `scrap[nomDuSite].py`.
 - `test.py` : pour lire le fichier scrappé "the theenglishdigest.txt" et regarder les proverbes qui sont déjà dans proverbs.jsonl, ceux qui ne le sont pas
seront mis dans un fichier not_found.phrases.txt (difficilement exploitable)


## Scenario
Lancer `scrap_parallel.py`
Puis attendre la fin (5min environ max)
Puis lancer `clean.py` --> sortie `proverbs.jsonl`
