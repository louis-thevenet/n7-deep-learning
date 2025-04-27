import requests
from bs4 import BeautifulSoup
import os
import time
import re
import csv
import concurrent.futures

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
            response = requests.get(url, timeout=10)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error fetching {url}: {e}")
            break
        
        soup = BeautifulSoup(response.content, "html.parser")
        topic_links = soup.find_all("a", class_="custom_color_link", href=lambda href: href and "/topic/" in href)
        
        if not topic_links:
            break
        
        for link in topic_links:
            topic_name = link.get_text().strip()
            topic_url = link['href']
            all_topics.append((topic_name, topic_url))
        
        page_num += 1
    
    return all_topics

def scrape_proverbs_for_topic(topic_info):
    """Scrape proverbs for a specific topic."""
    topic_name, topic_url = topic_info
    page_num = 1
    all_proverbs = []
    
    while True:
        url = topic_url if page_num == 1 else f"{topic_url}/{page_num}"
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"Error fetching {url}: {e}")
            break
        
        soup = BeautifulSoup(response.content, "html.parser")
        proverb_elts = soup.find_all("span", class_="text")
        
        if not proverb_elts:
            break
        
        for proverb in proverb_elts:
            proverb_text = proverb.get_text().strip()
            if proverb_text:
                all_proverbs.append(proverb_text)
        
        page_num += 1
        time.sleep(0.2)  # Light rate limiting
    
    return topic_name, all_proverbs

def main():
    # Prepare CSV file
    output_file = "proverbs.csv"
    
    with open(output_file, "w", newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(['Topic', 'Proverb'])
        
        # Parallel processing of letters and topics
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as letter_executor:
            letter_futures = {letter_executor.submit(scrape_topics_for_letter, letter): letter for letter in 'abcdefghijklmnopqrstuvwxyz'}
            
            for letter_future in concurrent.futures.as_completed(letter_futures):
                topics = letter_future.result()
                
                # Process topics in parallel
                with concurrent.futures.ThreadPoolExecutor(max_workers=20) as topic_executor:
                    topic_futures = {topic_executor.submit(scrape_proverbs_for_topic, topic_info): topic_info for topic_info in topics}
                    
                    for topic_future in concurrent.futures.as_completed(topic_futures):
                        topic_name, proverbs = topic_future.result()
                        
                        if not proverbs:
                            continue
                        
                        for proverb in proverbs:
                            safe_topic = topic_name.replace('"', "'")
                            safe_proverb = proverb.replace('"', "'")
                            csv_writer.writerow([safe_topic, safe_proverb])
                        
                        print(f" Saved {len(proverbs)} proverbs for topic: {topic_name}")
    
    print(f"Completed scraping. Dataset saved to {output_file}")

if __name__ == "__main__":
    main()