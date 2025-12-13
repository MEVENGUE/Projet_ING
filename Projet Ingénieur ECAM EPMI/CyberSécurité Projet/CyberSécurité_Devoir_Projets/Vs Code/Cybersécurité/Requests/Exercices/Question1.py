import requests
import json

try:
    while True:
        target_url = "https://www.nasa.gov/news/all-news/"
        if not target_url:
            break

        response = requests.get(target_url)
        data = {
            "url": target_url,
            "content": response.text
        }

        with open("output.json", "a") as json_file:
            json.dump(data, json_file)
            json_file.write("\n")

        print(f"Informations collectées depuis {target_url}.")

except KeyboardInterrupt:
    print("\nProgramme terminé.")
except Exception as e:
    print(f"Erreur : {e}")

