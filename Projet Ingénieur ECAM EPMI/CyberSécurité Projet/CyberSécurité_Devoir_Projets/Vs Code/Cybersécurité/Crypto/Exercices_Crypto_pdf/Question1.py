from Cryptodome.Hash import HMAC, SHA256
import secrets

class SecretAuthenticator:
    def __init__(self, secret_key):
        self.secret_key = secret_key

    def generate_hmac(self, message):
        hmac_obj = HMAC.new(self.secret_key, message.encode(), SHA256)
        hmac_digest = hmac_obj.digest()
        return hmac_digest

    def authenticate_message(self, user_message):
        print(f"Enter a message to authenticate: {user_message}")
        print(f"Original Message: {user_message}")
        
        sha256_hash = SHA256.new(user_message.encode()).hexdigest()
        hmac_result = self.generate_hmac(user_message)
        
        print(f"SHA-256 Hash: {sha256_hash}")
        print(f"HMAC: {hmac_result.hex()}")

# Interaction utilisateur pour saisir le message
user_message = input("Enter a message: ")

# Génération d'une clé secrète aléatoire
secret_key = secrets.token_bytes(32)
authenticator = SecretAuthenticator(secret_key)
authenticator.authenticate_message(user_message)
