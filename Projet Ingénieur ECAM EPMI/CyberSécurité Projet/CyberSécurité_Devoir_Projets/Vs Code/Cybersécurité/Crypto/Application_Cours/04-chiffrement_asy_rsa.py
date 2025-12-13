
"""
Le processus de génération d'une paire de clés RSA, chiffrant un message avec la clé publique,
puis le déchiffrer avec la clé privée correspondante. L'utilisation du PKCS1_OAEP
Ce schéma améliore la sécurité du cryptage RSA.
"""

from Cryptodome.PublicKey import RSA
from Cryptodome.Cipher import PKCS1_OAEP
from Cryptodome.Random import get_random_bytes

# Generate RSA key pair with a key length of 2048 bits
key = RSA.generate(2048)

# Data to be encrypted
data = b"Secret Text, RSA!"

# Initialize an RSA cipher object with the PKCS1_OAEP padding scheme
cipher = PKCS1_OAEP.new(key)

# RSA encryption using the public key
ciphertext = cipher.encrypt(data)

# RSA decryption using the private key
decrypted_data = cipher.decrypt(ciphertext)

RSA_public_key = key.publickey()

# Display the original, encrypted, and decrypted data
print(f"\nOriginal Data: {data}")
print(f"\nEncrypted Data: {ciphertext}")
print(f"\nPrivate key: {key.export_key()}")
#print(f"\nPublic key: {RSA_public_key.export_key().decode('utf-8')}")
print(f"\nDecrypted Data: {decrypted_data.decode('utf-8')}")
