import pandas as pd
import json

def clean_dataset_to_json(csv_file, output_json_file='proverbs.jsonl'):
    df = pd.read_csv(csv_file)
    
    # Compter les proverbes sans topic (NaN) dans le fichier original
    proverbs_without_topic = df[df['Topic'].isna()].shape[0]
    print(f"Nombre de proverbes sans topic (NaN) dans le fichier original: {proverbs_without_topic}")
    
    # Supprimer les entrées sans topic
    df_filtered = df.dropna(subset=['Topic'])
    print(f"Nombre de proverbes supprimés car sans topic: {len(df) - len(df_filtered)}")
    
    # Utiliser le DataFrame filtré pour la suite
    df = df_filtered
    
    # Élimination des doublons complets
    print(f"Nombre de proverbes avant nettoyage: {len(df)}")
    df = df.drop_duplicates()
    print(f"Nombre de proverbes après suppression des doublons exacts: {len(df)}")
    
    # Suppression des guillemets au début et à la fin des proverbes pour une homogéneité totale
    # df.loc[:, 'Proverb'] = df['Proverb'].apply(lambda x: x[1:-1] if (x.startswith('"') and x.endswith('"')) else x)
    #   # La colonne Proverb_clean contient les proverbes en minuscules et sans espaces au début ou à la fin
    # df.loc[:, 'Proverb_clean']= df['Proverb'].apply(lambda x: x.strip().lower())
    df = df.assign(
        Proverb=df['Proverb'].apply(lambda x: x[1:-1] if (x.startswith('"') and x.endswith('"')) else x),
        Proverb_clean=lambda x: x['Proverb'].str.strip().str.lower()
    )
    
  
    
    # Dictionnaire pour regrouper les thèmes par proverbe
    proverb_topics = {}
    
    for _, row in df.iterrows():
        proverb = row['Proverb_clean']
        topic = row['Topic']
        
        if proverb in proverb_topics:
            # Si le proverbe existe déjà, on ajoute le nouveau thème s'il n'est pas déjà présent
            if topic not in proverb_topics[proverb]['topics']:
                proverb_topics[proverb]['topics'].append(topic)
        else:
            # Si le proverbe n'existe pas encore
            proverb_topics[proverb] = {
                'original_proverb': row['Proverb'],
                'topics': [topic]
            }
    
    # Conversion au format JSON souhaité
    json_data = []
    for proverb, data in proverb_topics.items():
        json_data.append({
            "### topics": data['topics'], 
            "### proverb": data['original_proverb']
        })
    
    print(f"Nombre de proverbes après regroupement des thèmes: {len(json_data)}")
    
    # Écriture au format JSON 
    with open(output_json_file, 'w', encoding='utf-8') as f:
        for item in json_data:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')
    
    print(f"Fichier JSON créé : {output_json_file}")
    
    # Statistiques sur les thèmes
    theme_stats = {}
    for item in json_data:
        num_topics = len(item['topics'])
        theme_stats[num_topics] = theme_stats.get(num_topics, 0) + 1
        
        # Compteur pour chaque thème individuel
        for topic in item['topics']:
            if topic not in theme_stats:
                theme_stats[topic] = 0
            theme_stats[topic] += 1
    
    print(f"Répartition des proverbes par nombre de thèmes:")
    for num, count in sorted({k: v for k, v in theme_stats.items() if isinstance(k, int)}.items()):
        print(f"{num} thème(s): {count} proverbes")
    
    return json_data

# Exécuter le nettoyage et conversion en JSON
json_data = clean_dataset_to_json('proverbs.csv')

# Afficher les deux premiers éléments pour vérification
for i in range(min(2, len(json_data))):
    print(json.dumps(json_data[i], ensure_ascii=False))