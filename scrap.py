# Basic scrping for https://www.proverbsdb.com/proverb-nation/991880/english-proverb
# This script need to be adapted on each site
# We need to find a way to erase same proverbs after

import requests
from bs4 import BeautifulSoup
import time
import os

fileName = "theenglishdigest.txt"

# Preventive to do not scrap twice the website above
if os.path.exists( f"./{fileName}"):
    print(f"File exists : {fileName}")
    exit(1)

# Change this url to change website
base_url = "https://theenglishdigest.com/a-list-of-1000-proverbs-in-english-with-their-meaning/"
page = requests.get(base_url)
soup = BeautifulSoup(page.content, "html.parser")

# Recherche des proverbes 
proverb_elts = soup.find_all("h4")

# Use mode 'a' to append to the database
with open(fileName, "a") as f:

    for title in proverb_elts:
        f.write(title.get_text()+"\n")
        print(title.get_text())
    f.close()



# If website contains multiple pages following the same patern
for page in range(2, 1):
    print(f"ON PAGE : {page}\n")
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
            print(title.get_text())
        f.close()
    
    time.sleep(1)
