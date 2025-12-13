import requests

def download_file(url, local_filename):
    try:
        # Faire une requête HTTP GET pour télécharger le fichier
        response = requests.get(url)
        response.raise_for_status()  # Lever une exception pour les réponses HTTP erronées

        # Enregistrer le contenu du fichier localement
        with open(local_filename, 'wb') as file:
            file.write(response.content)

        print(f"File '{local_filename}' downloaded successfully.")

    except requests.RequestException as e:
        print(f"Error downloading file '{local_filename}': {e}")

if __name__ == "__main__":
    # Spécifier les URL des fichiers à télécharger et les noms de fichiers locaux
    files_to_download = [
        {"url": "https://example.com/amazon01.jpg", "local_filename": "amazon01.jpg"},
        {"url": "https://example.com/downloaded_document.pdf", "local_filename": "downloaded_document.pdf"},
        # Ajouter d'autres fichiers avec leurs URL et noms de fichiers locaux
    ]

    # Télécharger chaque fichier de la liste
    for file_info in files_to_download:
        download_file(file_info["url"], file_info["local_filename"])

    print("Downloaded files.")
