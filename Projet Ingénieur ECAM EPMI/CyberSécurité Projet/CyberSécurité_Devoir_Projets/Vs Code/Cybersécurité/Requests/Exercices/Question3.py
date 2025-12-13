import requests

def ip_geolocation_lookup(ip_address):
    try:
        response = requests.get(f"https://ipinfo.io/{ip_address}/json")
        response.raise_for_status()  # Raise an HTTPError for bad responses

        data = response.json()

        print("IP Geolocation Information:")
        print(f"IP Address: {ip_address}")
        print(f"City: {data.get('city', 'N/A')}")
        print(f"Region: {data.get('region', 'N/A')}")
        print(f"Country: {data.get('country', 'N/A')}")
        print(f"Location: {data.get('loc', 'N/A')}")
        print(f"Organization: {data.get('org', 'N/A')}")
        print(f"Timezone: {data.get('timezone', 'N/A')}")
        print(f"AS (Autonomous System): {data.get('asn', 'N/A')}")
        print()

    except requests.RequestException as e:
        print(f"Error: {e}\n")

if __name__ == "__main__":
    while True:
        try:
            ip_address = input("Enter an IP address (Ctrl + C to exit): ")
            ip_geolocation_lookup(ip_address)
        except KeyboardInterrupt:
            print("\nProgram terminated.")
            break
