"""
This code fetches the "robots.txt" file from the Wikipedia website and saves it locally as "example-5-robots.txt".
It demonstrates a common use case of using the requests library to download a file from the web.
"""
import requests

file_url = "https://www.nasa.gov/robots.txt"

try:
    response = requests.get(file_url)
    with open("store-robots.txt", 'wb') as file:
        file.write(response.content)
    print("File downloaded successfully.")
except requests.RequestException as e:
    print(f"Error: {e}")
