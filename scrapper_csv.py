import requests
from bs4 import BeautifulSoup
import os
import time
import re
import csv

def create_safe_filename(name):
    """Create a safe filename by removing invalid characters."""
    return re.sub(r'[^\w\-_\.]', '_', name.lower().strip())

def scrape_topics_for_letter(letter):
    """Scrape topics for a specific letter."""
    base_url = f"https://www.proverbsdb.com/all_topics/{letter}"
    page_num = 1
    all_topics = []

    while True:
        url = base_url if page_num == 1 else f"{base_url}/{page_num}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error fetching {url}: {e}")
            break

        soup = BeautifulSoup(response.content, "html.parser")
        
        # Find all topic links
        topic_links = soup.find_all("a", class_="custom_color_link", href=lambda href: href and "/topic/" in href)
        
        # If no topics found, we've reached the end
        if not topic_links:
            break

        # Extract and store topics
        for link in topic_links:
            topic_name = link.get_text().strip()
            topic_url = link['href']
            all_topics.append((topic_name, topic_url))
        
        page_num += 1

    return all_topics

def scrape_proverbs_for_topic(topic_name, topic_url):
    """Scrape proverbs for a specific topic."""
    page_num = 1
    all_proverbs = []

    while True:
        url = topic_url if page_num == 1 else f"{topic_url}/{page_num}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error fetching {url}: {e}")
            break

        soup = BeautifulSoup(response.content, "html.parser")
        
        # Find proverb text elements
        proverb_elts = soup.find_all("span", class_="text")
        
        # If no proverbs found, we've reached the end
        if not proverb_elts:
            break

        # Extract and store proverbs
        for proverb in proverb_elts:
            proverb_text = proverb.get_text().strip()
            if proverb_text:
                all_proverbs.append(proverb_text)
        
        page_num += 1
        
        # Delay to be respectful to the server
        time.sleep(0.5)

    return all_proverbs

def main():
    # Prepare CSV file
    output_file = "proverbs_dataset.csv"
    
    # Use 'w' mode to overwrite, 'a' if you want to append
    with open(output_file, "w", newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)
        
        # Write header
        csv_writer.writerow(['Topic', 'Proverb'])

        # Iterate through letters
        for letter in 'abcdefghijklmnopqrstuvwxyz':
            print(f"Processing letter: {letter}")
            
            # Get topics for this letter
            topics = scrape_topics_for_letter(letter)

            # Process each topic
            for topic_name, topic_url in topics:
                print(f"  Scraping topic: {topic_name}")
                
                # Scrape proverbs for this topic
                proverbs = scrape_proverbs_for_topic(topic_name, topic_url)
                
                # Skip if no proverbs found
                if not proverbs:
                    continue

                # Write proverbs to CSV
                for proverb in proverbs:
                    # Escape any potential CSV-breaking characters
                    safe_topic = topic_name.replace('"', "'")
                    safe_proverb = proverb.replace('"', "'")
                    csv_writer.writerow([safe_topic, safe_proverb])

                print(f"    Saved {len(proverbs)} proverbs for topic: {topic_name}")

                # Delay between topics
                time.sleep(1)

        print(f"Completed scraping. Dataset saved to {output_file}")

if __name__ == "__main__":
    main()