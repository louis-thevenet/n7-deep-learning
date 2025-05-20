import scrapping.scrapProverbsdb
import scrapping.scrapTheenglisdigest
import scrapping.test
import scrapping.clean
import os

def download_data():
    """"
    Download data from the internet and save it to files.
    """
    if not os.path.exists("raw_data"):
        os.makedirs("raw_data")
    proverbs_db_only_english_file = "raw_data/proverbs_db_only_english.txt"
    scrapping.scrapProverbsdb.save_to_file_english(proverbs_db_only_english_file)
    #scrapping.clean.clean(proverbs_db_only_english_file)

    proverbs_db_file = "raw_data/proverbs_db.txt"
    scrapping.scrapProverbsdb.save_to_file_all(proverbs_db_file)
    #scrapping.clean.clean(proverbs_db_file)
    
    proverbs_digest_file = "raw_data/proverbs_digest.txt"
    scrapping.scrapTheenglisdigest.save_to_file(proverbs_digest_file)
    #scrapping.clean.clean(proverbs_digest_file)

    return [proverbs_db_only_english_file, proverbs_db_file, proverbs_digest_file]

def clean_data(files):
    """
    Applies fixes to the data.
    - Remove duplicates
    """
    if not os.path.exists("clean_data"):
        os.makedirs("clean_data")

    # Duplicate removal
    for file in files:
        clean_file = os.path.join("clean_data", os.path.basename(file))
        with open(file, "r") as f:
            lines = f.readlines()
        f.close()
        unique_lines = list(set(lines))
        with open(clean_file, "w") as f:
            f.writelines(unique_lines)
        f.close()

    # Remove "Transliteration"
    for file in files:
        clean_file = os.path.join("clean_data", os.path.basename(file))
        with open(clean_file, "r") as f:
            lines = f.readlines()
        f.close()
        with open(clean_file, "w") as f:
            for line in lines:
                if "Transliteration" not in line:
                    f.write(line)
            f.close()
    # Remove empty lines
    for file in files:
        clean_file = os.path.join("clean_data", os.path.basename(file))
        with open(clean_file, "r") as f:
            lines = f.readlines()
        f.close()
        with open(clean_file, "w") as f:
            for line in lines:
                if line.strip():
                    f.write(line)
            f.close()
    
def load_data():
    """
    Load data from the cleaned files.
    """
    if not os.path.exists("clean_data"):
        clean_data(download_data())

    files = os.listdir("clean_data")
    data = {}
    for file in files:
        with open(os.path.join("clean_data", file), "r") as f:
            lines = f.readlines()
        f.close()
        data[file] = [line.strip() for line in lines]
    return data

def load_datawith_topics():
    """
    Load data from the cleaned files with topics.
    """
    if not os.path.exists("proverbs.jsonl"):
        clean_data(download_data())

    file = "proverbs.jsonl"
    data = {}
    with open(file, "r") as f:
        lines = f.readlines()
    f.close()
    data[file] = ["### : " + line.replace("{", "").replace("}", "").replace('"', "").replace("proverb:", "\n\n### proverb: ").strip() for line in lines]
    return data