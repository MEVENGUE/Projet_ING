"""
This code demonstrates how to make an HTTP GET request using the requests library to 
gather information from a target URL.If the request is successful (status code 200), 
it prints the gathered information (HTML content of the web page).
"""
import requests

target_url = "https://www.nasa.gov/"

try:
    response = requests.get(target_url)
    if response.status_code == 200:
        print(f"Information gathered from {target_url}:\n{response.text}")
    else:
        print(f"Failed to retrieve information. Status code: {response.status_code}")
except requests.RequestException as e:
    print(f"Error: {e}")
