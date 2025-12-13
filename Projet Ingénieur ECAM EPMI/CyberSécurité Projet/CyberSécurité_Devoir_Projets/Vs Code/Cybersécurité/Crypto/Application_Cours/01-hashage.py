from Cryptodome.Hash import SHA256

# Data to be hashed
data = b"ID296595 EPMI!"

# Create a new SHA-256 hash object
hash_object = SHA256.new(data)

# Compute the SHA-256 hash of the provided data
hashed_data = hash_object.digest()

# Display the original data and the resulting SHA-256 hash
print(f"Original Data: {data.decode('utf-8')}")
print(f"SHA-256 Hash in Bytes: {hashed_data}")
print(f"SHA-256 Hash: {hash_object.hexdigest()}")


