import json

# Charger les proverbes du fichier JSONL
def load_proverbs(jsonl_file):
    proverbs_set = set()
    with open(jsonl_file, 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line.strip())
            proverb = data.get("proverb", "").strip().lower()
            if proverb:
                proverbs_set.add(proverb)
    return proverbs_set

# Vérifier les phrases du fichier texte
def check_phrases(txt_file, jsonl_file, output_not_found):
    proverbs = load_proverbs(jsonl_file)
    found_count = 0
    not_found_phrases = []

    with open(txt_file, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    for phrase in lines:
        if phrase.lower() in proverbs:
            found_count += 1
        else:
            not_found_phrases.append(phrase)
    
    # Sauvegarde des phrases non trouvées
    with open(output_not_found, 'w', encoding='utf-8') as f:
        f.write("\n".join(not_found_phrases))
    
    print(f"Nombre de phrases trouvées dans le JSONL : {found_count}")
    print(f"Nombre de phrases non trouvées : {len(not_found_phrases)} (stockées dans {output_not_found})")

# Exemple d'utilisation
check_phrases("theenglishdigest.txt", "proverbs.jsonl", "not_found_phrases.txt")
