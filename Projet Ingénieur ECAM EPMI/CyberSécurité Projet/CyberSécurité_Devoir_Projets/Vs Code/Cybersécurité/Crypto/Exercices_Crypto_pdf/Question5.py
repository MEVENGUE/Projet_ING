import sqlite3
import json
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

    def close_connection(self):
        self.connection.close()

def main():
    secure_message_handler = SecureMessageHandler()

    try:
        while True:
            user_input = input("Enter a message to secure (Ctrl + C to exit): ")
            secure_message_handler.handle_secure_message(user_input)

    except KeyboardInterrupt:
        print("Program terminated by user.")
    
    finally:
        secure_message_handler.close_connection()

if __name__ == "__main__":
    main()