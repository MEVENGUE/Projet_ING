"""
This Python code performs an HTTP GET request to the specified target URL (Wikipedia homepage). 
The primary purpose is to retrieve and print the HTTP headers analysis of the response.
"""

import requests

target_url = "https://www.nasa.gov/"

try:
    response = requests.get(target_url)
    headers = response.headers
    print(f"HTTP Headers from {target_url}:\n{headers}")
except requests.RequestException as e:
    print(f"Error: {e}")
