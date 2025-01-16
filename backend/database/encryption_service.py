from cryptography.fernet import Fernet
import base64
import os
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import json
from pathlib import Path

class EncryptionService:
    def __init__(self):
        self.key_file = Path(__file__).parent / 'encryption_key'
        self.salt_file = Path(__file__).parent / 'salt'
        self._initialize_encryption()

    def _initialize_encryption(self):
        """Initialize or load encryption key and salt"""
        if not self.salt_file.exists():
            salt = os.urandom(16)
            with open(self.salt_file, 'wb') as f:
                f.write(salt)
        else:
            with open(self.salt_file, 'rb') as f:
                salt = f.read()

        if not self.key_file.exists():
            # Generate a master key - in production, this should be securely stored
            master_key = os.urandom(32)
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=480000,
            )
            key = base64.urlsafe_b64encode(kdf.derive(master_key))
            with open(self.key_file, 'wb') as f:
                f.write(key)
        else:
            with open(self.key_file, 'rb') as f:
                key = f.read()

        self.fernet = Fernet(key)

    def encrypt_data(self, data: dict) -> bytes:
        """Encrypt dictionary data"""
        json_data = json.dumps(data)
        return self.fernet.encrypt(json_data.encode())

    def decrypt_data(self, encrypted_data: bytes) -> dict:
        """Decrypt data back to dictionary"""
        decrypted_data = self.fernet.decrypt(encrypted_data)
        return json.loads(decrypted_data.decode())
