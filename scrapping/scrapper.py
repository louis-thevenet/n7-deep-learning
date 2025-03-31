import requests
from bs4 import BeautifulSoup
import os
import time
import re

def create_safe_filename(name):
    #Crée un nom de fichier sûr en supprimant les caractères invalides. (juste par precaution)
    return re.sub(r'[^\w\-_\.]', '_', name.lower().strip())

def scrape_topics_for_letter(letter):
    #Récupère la liste des topics (thèmes de proverbes) pour une lettre donnée.
    base_url = f"https://www.proverbsdb.com/all_topics/{letter}"
    page_num = 1    # Numéro de page pour la pagination
    all_topics = [] # Liste pour stocker les topics

    while True:
         # Gestion de la pagination, inspiré de la boucle for de scrapProverbsdbEnglish.py (merci)
        url = base_url if page_num == 1 else f"{base_url}/{page_num}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error while fetching {url}: {e}")
            break

        soup = BeautifulSoup(response.content, "html.parser")
        
        # Trouve les liens des topics
        topic_links = soup.find_all("a", class_="custom_color_link", href=lambda href: href and "/topic/" in href)
        
        # Si aucun topic n'a été trouvé, on a atteint la fin
        if not topic_links:
            break
  
        # Extrait et stocke les topics (nom + URL)
        for link in topic_links:
            topic_name = link.get_text().strip()
            topic_url = link['href']
            all_topics.append((topic_name, topic_url))
        
        page_num += 1

    return all_topics

def scrape_proverbs_for_topic(topic_name, topic_url):
    #Récupère les proverbes associés à un topic donné.
    page_num = 1  # On passe à la page suivante pour la pagination
    all_proverbs = []

    while True:

        url = topic_url if page_num == 1 else f"{topic_url}/{page_num}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error while fetching {url}: {e}")
            break

        soup = BeautifulSoup(response.content, "html.parser")
        
        # Trouve les éléments contenant les proverbes
        proverb_elts = soup.find_all("span", class_="text")
        
    
        if not proverb_elts:
            break

       # Extrait et stocke les proverbes
        for proverb in proverb_elts:
            proverb_text = proverb.get_text().strip()
            if proverb_text:
                all_proverbs.append(proverb_text)
        
        page_num += 1
        
        # pause pour éviter de surcharger le serveur( en vrai optionnel mais bon copié collé)
        time.sleep(0.5)

    return all_proverbs

def main():
    # Création du dossier de sortie principal
    os.makedirs("proverbs", exist_ok=True)

    # Parcours de chaque lettre de l'alphabet, pas très esthétique mais bon
    for letter in 'abcdefghijklmnopqrstuvwxyz':
        print(f"Processing letter: {letter}")
        
        # Récupère les topics correspondant à la lettre
        topics = scrape_topics_for_letter(letter)
        
        # Création d'un dossier spécifique pour la lettre
        letter_dir = os.path.join("proverbs_output", letter)
        os.makedirs(letter_dir, exist_ok=True)

        # Parcours de chaque topic,topic apres topic
        for topic_name, topic_url in topics:
            print(f"  Scraping topic: {topic_name}")
            
            # Scrape des proverbes du topic
            proverbs = scrape_proverbs_for_topic(topic_name, topic_url)
            
           # Si aucun proverbe n'est trouvé, on passe au suivant
            if not proverbs:
                continue

            # Création d'un nom de fichier
            safe_filename = create_safe_filename(topic_name)
            file_path = os.path.join(letter_dir, f"{safe_filename}_proverbs.txt")

            # Écriture des proverbes dans un fichier
            with open(file_path, "w", encoding="utf-8") as f:
                for proverb in proverbs:
                    f.write(f"{proverb}\n")

            print(f"    Saved {len(proverbs)} proverbs to {file_path}")

         
            time.sleep(1)

if __name__ == "__main__":
    main()