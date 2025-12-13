import json
from Cryptodome.Cipher import AES
from Cryptodome.Random import get_random_bytes
from Cryptodome.Util.Padding import pad, unpad

class MessageEncryptor:
    def init(self, key):
        self.key = key

    def encrypt_message(self, message):
        cipher = AES.new(self.key, AES.MODE_CBC)
        ciphertext = cipher.encrypt(pad(message.encode('utf-8'), AES.block_size))
        iv = cipher.iv
        return {'iv': iv.hex(), 'encrypted_message': ciphertext.hex(), 'original_message': message}

    def decrypt_message(self, encrypted_data):
        iv = bytes.fromhex(encrypted_data['iv'])
        ciphertext = bytes.fromhex(encrypted_data['encrypted_message'])
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        decrypted_message = unpad(cipher.decrypt(ciphertext), AES.block_size)
        return decrypted_message.decode('utf-8')

def main():
    key = get_random_bytes(16)
    encryptor = MessageEncryptor(key)

    try:
        while True:
            user_input = input("Enter a message to encrypt (Ctrl + C to exit): ")
            encrypted_data = encryptor.encrypt_message(user_input)

            print(f'Encrypted Message: {encrypted_data["encrypted_message"]}')
            decrypted_message = encryptor.decrypt_message(encrypted_data)
            print(f'Decrypted Message: {decrypted_message}\n')

            with open('encrypted_messages.json', 'a') as file:
                json.dump(encrypted_data, file)
                file.write('\n')

    except KeyboardInterrupt:
        print("Program terminated.")

if name == "main":
    main()