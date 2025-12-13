from Cryptodome.Cipher import AES
from Cryptodome.Random import get_random_bytes
from Cryptodome.Util.Padding import pad, unpad

class AESCipher:
    def __init__(self, key):
        self.key = key

    def encrypt(self, data):
        cipher = AES.new(self.key, AES.MODE_CBC)
        ciphertext = cipher.encrypt(pad(data, AES.block_size))
        return ciphertext, cipher.iv
    
    def decrypt(self, ciphertext, iv):
        decipher = AES.new(self.key, AES.MODE_CBC, iv=iv)
        decrypted_data = unpad(decipher.decrypt(ciphertext), AES.block_size)
        return decrypted_data
    
# Generate a random 128-bit key for AES encryption
key = get_random_bytes(16)

aes_cipher = AESCipher(key) 

# User_message to be encrypted
user_input = input("Enter a message to encrypt: ").encode('utf-8')

encrypted_data, iv = aes_cipher.encrypt(user_input)
decrypted_data = aes_cipher.decrypt(encrypted_data, iv)

# Display the original, encrypted, and decrypted data
print(f"Original Message: : {user_input.decode('utf-8') }")
print(f"Encrypted Message: : {encrypted_data}")
print(f"Decrypted Message: : {decrypted_data.decode('utf-8')}")