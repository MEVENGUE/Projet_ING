
"""
Ce code démontre l'utilisation du HMAC (Hash-based Message Authentication Code) pour authentifier les données.
Les fonctions de hachage, y compris HMAC (Hash-based Message Authentication Code), sont conçues pour être des
fonctions unidirectionnelles.Cela signifie que le processus de hachage est irréversible et que vous ne 
pouvez pas récupérer directement les données originales à partir de la valeur de hachage.
"""


from Cryptodome.Hash import HMAC, SHA256

# Secret key for HMAC
key = b"secret_key"

# Data to be authenticated
data = b"ID1895 ECAM-EPMI!"

# Generate HMAC using the SHA-256 hash function and the secret key
hmac = HMAC.new(key, data, digestmod=SHA256).digest()

# Display the original data and the generated HMAC
print(f"Original Data: {data.decode('utf-8')}")
print(f"Hmac in Bytes: {hmac}")
print(f"HMAC: {hmac.hex()}")
