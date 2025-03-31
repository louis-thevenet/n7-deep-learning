# Basic scrping for https://www.proverbsdb.com/proverb-nation/991880/english-proverb
# This script need to be adapted on each site
# We need to find a way to erase same proverbs after

import requests
from bs4 import BeautifulSoup
import time
import os

def save_to_file(fileName):
    if os.path.exists( f"./{fileName}"):
        print(f"File already exists : {fileName}")
        return

    # Change this url to change website
    base_url = "https://www.proverbsdb.com/proverb-nation/991880/english-proverb"
    page = requests.get(base_url)
    soup = BeautifulSoup(page.content, "html.parser")

    # Recherche des proverbes 
    proverb_elts = soup.find_all("span", class_="text")

    # Use mode 'a' to append to the database
    with open(fileName, "a") as f:

        for title in proverb_elts:
            f.write(title.get_text()+"\n")
        f.close()



    # If website contains multiple pages following the same patern
    for page in range(2, 101):
        url = base_url + f"/{page}"
        try:
            page = requests.get(url)
        except RequestException as e:
            print(f"Request failed on page {page} : {e}")
            break

        soup = BeautifulSoup(page.content, "html.parser")
        # Recherche des proverbes 
        proverb_elts = soup.find_all("span", class_="text")
        
        with open(fileName, "a") as f:
            for title in proverb_elts:
                f.write(title.get_text()+"\n")
            f.close()
        
        time.sleep(1)
