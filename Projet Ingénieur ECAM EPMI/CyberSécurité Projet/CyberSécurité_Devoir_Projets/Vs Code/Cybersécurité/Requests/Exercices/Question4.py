import requests
from bs4 import BeautifulSoup

def scrape_webpage(url):
    try:
        # Faire une requête HTTP GET à l'URL spécifiée
        response = requests.get(url)
        response.raise_for_status()  # Lever une exception pour les réponses HTTP erronées

        # Utiliser BeautifulSoup pour analyser le contenu HTML de la page
        soup = BeautifulSoup(response.text, 'html.parser')

        # Extraire le nombre de chaque balise de titre (h1, h2, etc.)
        headings_count = {f'h{i}': len(soup.find_all(f'h{i}')) for i in range(1, 7)}

        # Afficher le nombre de chaque balise de titre
        print("Headings Count:")
        for heading, count in headings_count.items():
            print(f"{heading}: {count}")

        print("\nFirst 3 Paragraphs:")
        # Extraire et afficher les trois premiers paragraphes
        paragraphs = soup.find_all('p')[:3]
        for index, paragraph in enumerate(paragraphs, start=1):
            print(f"Paragraph {index}:\n{paragraph.text}\n")

    except requests.RequestException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # URL de l'exemple
    example_url = "https://en.wikipedia.org/wiki/Computer_security"
    
    # Appeler la fonction de scraping avec l'URL spécifié
    scrape_webpage(example_url)