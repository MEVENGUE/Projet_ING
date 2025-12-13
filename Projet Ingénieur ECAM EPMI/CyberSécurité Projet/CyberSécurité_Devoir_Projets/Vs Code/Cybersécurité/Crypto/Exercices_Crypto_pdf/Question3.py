from Cryptodome.PublicKey import RSA
from Cryptodome.Cipher import PKCS1_OAEP

class RSACipher:
    def __init__(self):
        self.key = RSA.generate(2048)

    def encrypt(self, data):
        cipher = PKCS1_OAEP.new(self.key)
        ciphertext = cipher.encrypt(data)
        return ciphertext
    
    def decrypt(self, ciphertext):
        cipher = PKCS1_OAEP.new(self.key)
        decrypted_data = cipher.decrypt(ciphertext)
        return decrypted_data

rsa_cipher = RSACipher() 

# User_message to be encrypted
user_input = input("Enter a message to encrypt: ").encode('utf-8')

encrypted_data = rsa_cipher.encrypt(user_input)
decrypted_data = rsa_cipher.decrypt(encrypted_data)

# Display the original, encrypted, and decrypted data
print(f"Original Message: : {user_input.decode('utf-8') }")
print(f"Encrypted Message: : {encrypted_data}")
print(f"Decrypted Message: : {decrypted_data.decode('utf-8')}")