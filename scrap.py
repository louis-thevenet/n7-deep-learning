import requests
from bs4 import BeautifulSoup

# Récupération du contenu HTML de la page web
url = "https://www.proverbsdb.com/proverb-nation/991890/french-proverb/2"
page = requests.get(url)
soup = BeautifulSoup(page.content, "html.parser")

# Recherche des titres de produits
proverb_elts = soup.find_all("span", class_="text")
with open("scrap_res.txt", "a") as f:

    for title in proverb_elts:
        f.write(title.get_text()+"\n")
        print(title.get_text())
    f.close()


