#exemple de projet qui combine les bibliothèques Crypto, Nmap et Requests pour créer un outil de gestion de mots de passe sécurisé. 
# Ce programme permet à l'utilisateur de stocker, récupérer et générer des mots de passe de manière sécurisée.
# Ce programme vous permet de stocker et récupérer des mots de passe de manière sécurisée, d'effectuer une analyse TCP SYN sur une cible, de télécharger des fichiers à partir d'URL spécifiées, et de quitter le programme selon le choix de l'utilisateur.

import nmap
import json
import requests
import sqlite3
import hashlib
import hmac
import os
from Cryptodome.Cipher import AES
from Cryptodome.Random import get_random_bytes
from Cryptodome.Util.Padding import pad, unpad

class SecureMessageHandler:
    def __init__(self):
        self.connection = sqlite3.connect('secure_data.db')
        self.cursor = self.connection.cursor()
        self.setup_database()

    def setup_database(self):
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                original_message TEXT,
                sha256_hash TEXT,
                hmac TEXT,
                encrypted_message TEXT,
                iv TEXT
            )
        ''')
        self.connection.commit()

    def generate_random_key(self):
        return get_random_bytes(16)

    def calculate_sha256_hash(self, message):
        return hashlib.sha256(message.encode('utf-8')).hexdigest()

    def generate_hmac(self, key, message):
        return hmac.new(key, message.encode('utf-8'), hashlib.sha256).hexdigest()

    def encrypt_message(self, key, message):
        cipher = AES.new(key, AES.MODE_CBC)
        ciphertext = cipher.encrypt(pad(message.encode('utf-8'), AES.block_size))
        return {'encrypted_message': ciphertext.hex(), 'iv': cipher.iv.hex()}

    def decrypt_message(self, key, encrypted_data):
        iv = bytes.fromhex(encrypted_data['iv'])
        ciphertext = bytes.fromhex(encrypted_data['encrypted_message'])
        cipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted_message = unpad(cipher.decrypt(ciphertext), AES.block_size)
        return decrypted_message.decode('utf-8')

    def store_message_in_database(self, original_message, sha256_hash, hmac_value, encrypted_message, iv):
        self.cursor.execute('''
            INSERT INTO messages (original_message, sha256_hash, hmac, encrypted_message, iv)
            VALUES (?, ?, ?, ?, ?)
        ''', (original_message, sha256_hash, hmac_value, encrypted_message, iv))
        self.connection.commit()

    def handle_secure_message(self, message):
        key = self.generate_random_key()
        sha256_hash = self.calculate_sha256_hash(message)
        hmac_value = self.generate_hmac(key, message)
        encrypted_data = self.encrypt_message(key, message)

        print(f'Original Message: {message}')
        print(f'SHA-256 Hash: {sha256_hash}')
        print(f'HMAC: {hmac_value}')

        decrypted_message = self.decrypt_message(key, encrypted_data)
        print(f'Encrypted Message: {encrypted_data["encrypted_message"]}')
        print(f'Decrypted Message: {decrypted_message}\n')

        self.store_message_in_database(message, sha256_hash, hmac_value, encrypted_data['encrypted_message'], encrypted_data['iv'])

class NetworkAnalyzer:
    def __init__(self):
        pass

    def perform_tcp_syn_analysis(self, target):
        nm = nmap.PortScanner()

        try:
            # Perform TCP SYN scan to identify open ports
            nm.scan(hosts=target, arguments='-sS')

            # Get the first IP address from the list of scanned hosts
            host = list(nm.all_hosts())[0]

            # Initialize a dictionary to store port status
            port_status = {'Host': host, 'Port Status': {}}

            # Iterate through all TCP ports and determine their status (open/closed)
            for port, protocol in nm[host].all_tcp().items():
                port_status['Port Status'][f"Port {port}"] = 'open'

            # Print port status
            print("Port Status:")
            print(json.dumps(port_status, indent=2))

            # Save scan results to a JSON file
            filename = f"scan_results_{host}.json"
            with open(filename, 'w') as json_file:
                json.dump(port_status, json_file, indent=2)
            print(f"Scan results saved to: {filename}")

        except KeyboardInterrupt:
            print("\nScan canceled. Exiting...")

class FileDownloader:
    def __init__(self):
        pass

    def download_file(self, url, local_filename):
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

def main():
    secure_message_handler = SecureMessageHandler()
    network_analyzer = NetworkAnalyzer()
    file_downloader = FileDownloader()

    try:
        while True:
            print("1. Secure a message")
            print("2. Perform TCP SYN analysis")
            print("3. Download a file")
            print("4. Exit")

            choice = input("Enter your choice: ")

            if choice == '1':
                user_input = input("Enter a message to secure: ")
                secure_message_handler.handle_secure_message(user_input)
            elif choice == '2':
                target = input("Enter target IP address or range: ")
                network_analyzer.perform_tcp_syn_analysis(target)
            elif choice == '3':
                url = input("Enter the URL of the file to download: ")
                local_filename = input("Enter the local filename to save the file as: ")
                file_downloader.download_file(url, local_filename)
            elif choice == '4':
                break
            else:
                print("Invalid choice. Please enter a number between 1 and 4.")

    except KeyboardInterrupt:
        print("Program terminated by user.")
    
    finally:
        secure_message_handler.close_connection()

if __name__ == "__main__":
    main()

