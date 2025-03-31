import scrapping.scrapProverbsdbEnglish
import scrapping.scrapTheenglisdigest
import scrapping.test
import scrapping.clean
import os

def load_data():
    if not os.path.exists("data"):
        os.makedirs("data")
    proverbs_db_file = "data/proverbs_db.txt"
    proverbs_digest_file = "data/proverbs_digest.txt"
    scrapping.scrapProverbsdbEnglish.save_to_file(proverbs_db_file)
    scrapping.clean.clean(proverbs_db_file)

    scrapping.scrapTheenglisdigest.save_to_file(proverbs_digest_file)
    scrapping.clean.clean(proverbs_digest_file)

    proverbs = []
    with open(proverbs_db_file, "r") as f:
        for line in f:
            proverbs.append(line.strip())
    with open(proverbs_digest_file, "r") as f:
        for line in f:
            proverbs.append(line.strip())
    return proverbs