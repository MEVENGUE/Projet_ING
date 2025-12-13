import requests

class HTTPHeaderAnalyzer:
    def analyze_headers(self, url):
        try:
            response = requests.get(url)
            response.raise_for_status()

            headers = response.headers

            print("HTTP Headers Information:")
            print(f"Content Type: {headers.get('Content-Type', 'N/A')}")
            print(f"Server: {headers.get('Server', 'N/A')}")
            print(f"Date: {headers.get('Date', 'N/A')}")

        except requests.RequestException as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    analyzer = HTTPHeaderAnalyzer()

    while True:
        try:
            target_url = input("Enter a target URL (Ctrl + C to exit): ")
            if not target_url:
                break
            analyzer.analyze_headers(target_url)
        except KeyboardInterrupt:
            print("\nProgram terminated.")
            break
