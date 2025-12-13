import requests
import json

def save_to_json(data, filename):
    with open(filename, 'w') as json_file:
        json.dump(data, json_file, indent=4)

def http_info_gathering(target_url):
    try:
        response = requests.get(target_url)
        response.raise_for_status()  # Raise an HTTPError for bad responses

        gathered_info = {
            'url': target_url,
            'html_content': response.text
        }

        # Saving information to a JSON file
        filename = "gathered_info.json"
        save_to_json(gathered_info, filename)

        print(f"Information gathered from {target_url}.")
        print(f"Data saved to {filename}.\n")

    except requests.RequestException as e:
        print(f"Error: {e}\n")

if __name__ == "__main__":
    while True:
        try:
            target_url = input("Enter a target URL (Ctrl + C to exit): ")
            http_info_gathering(target_url)
        except KeyboardInterrupt:
            print("\nProgram terminated.")
            break

