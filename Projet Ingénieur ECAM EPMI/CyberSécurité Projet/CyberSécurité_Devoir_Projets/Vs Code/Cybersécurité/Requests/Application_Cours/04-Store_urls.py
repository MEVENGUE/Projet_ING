"""
To list out all URLs of a website using the requests library, you can combine it with a parsing 
library like BeautifulSoup to extract URLs from the HTML content. 
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

target_url = "https://www.nasa.gov/"
output_file = "store_urls.txt"

try:
    response = requests.get(target_url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find all <a> tags with href attribute
    links = soup.find_all('a', href=True)

    # Extract and save the URLs to a text file
    with open(output_file, "w") as file:
        for link in links:
            full_url = urljoin(target_url, link['href'])
            file.write(full_url + '\n')

    print(f"URLs saved to '{output_file}'")
except requests.RequestException as e:
    print(f"Error: {e}")
