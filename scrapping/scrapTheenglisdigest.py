# Basic scrping for https://www.proverbsdb.com/proverb-nation/991880/english-proverb
# This script need to be adapted on each site
# We need to find a way to erase same proverbs after

import requests
from bs4 import BeautifulSoup
import os
def save_to_file(fileName):
    if os.path.exists( f"./{fileName}"):
        os.remove(fileName)


    #Scraping du site web
    # Change this url to change website
    base_url = "https://theenglishdigest.com/a-list-of-1000-proverbs-in-english-with-their-meaning/"
    page = requests.get(base_url)
    soup = BeautifulSoup(page.content, "html.parser")

    # Recherche des proverbes ,Extraction des proverbes
    proverb_elts = soup.find_all("h4")

    # Use mode 'a' to append to the database,. Enregistrement des proverbes dans un fichier
    with open(fileName, "a") as f:

        for title in proverb_elts:
            f.write(title.get_text()+"\n")
        f.close()

    #Suppression des lignes contenant "1000"
    with open(fileName, "r") as fp:
        lines = fp.readlines()
    fp.close()
    with open(fileName, "w") as fp:
        for line in lines:
            if line.strip("\n") != "1000":
                fp.write(line)
    fp.close()
