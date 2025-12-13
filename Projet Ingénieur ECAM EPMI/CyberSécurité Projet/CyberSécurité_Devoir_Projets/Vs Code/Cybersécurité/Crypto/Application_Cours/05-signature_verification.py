"""
Ce code illustre le processus de base de génération et de vérification de signatures numériques
à l'aide d'une paire de clés RSA. Il peut être utilisé dans des scénarios où l'intégrité et
l'authenticité des données sont cruciales, telles que la communication sécurisée ou
l'authentification des messages.
"""


from Cryptodome.Signature import pkcs1_15
from Cryptodome.Hash import SHA256
from Cryptodome.PublicKey import RSA

# Generate RSA key pair with a key length of 2048 bits
key = RSA.generate(2048)

# Data to be signed
data = b"Hello, Digital Signature!"
data2 = b"Hello, Digital Signature!"

# Hash the data using the SHA-256 hash function
hash_obj = SHA256.new(data)

# Sign the hashed data using the private key
signature = pkcs1_15.new(key).sign(hash_obj)

# Verify the signature using the public key
try:
    pkcs1_15.new(key.publickey()).verify(hash_obj, signature)
    print(f"\nSignature key: {key.export_key}")
    print(f"\nHashed data: {hash_obj}")
    print("\nSignature is valid.")
except (ValueError, TypeError):
    print("\nSignature is invalid.")
