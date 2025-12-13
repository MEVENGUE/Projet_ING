# IP Geolocation Lookup
"""
This Python code performs an IP geolocation lookup using the requests library. 
It sends an HTTP GET request to the "ipinfo.io" API, providing an IP address in the URL. 
The API responds with geolocation information in JSON format, and the script prints the obtained data.
"""

import requests

ip_address = "10.222.52.48"

try:
    response = requests.get(f"https://ipinfo.io/{ip_address}/json")
    data = response.json()
    print(f"IP Geolocation for {ip_address}:\n{data}")
except requests.RequestException as e:
    print(f"Error: {e}")