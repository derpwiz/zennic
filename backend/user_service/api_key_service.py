from pathlib import Path
import json
from typing import Optional, Dict
from database.encryption_service import EncryptionService

class APIKeyService:
    def __init__(self):
        self.encryption_service = EncryptionService()
        self.keys_file = Path(__file__).parent / 'encrypted_keys'
        self._initialize_storage()

    def _initialize_storage(self):
        """Initialize storage file if it doesn't exist"""
        if not self.keys_file.exists():
            self.keys_file.write_bytes(self.encryption_service.encrypt_data({}))

    def save_alpaca_keys(self, user_id: str, api_key: str, secret_key: str, is_paper: bool) -> bool:
        """Save encrypted Alpaca API keys for a user"""
        try:
            # Read existing data
            encrypted_data = self.keys_file.read_bytes()
            data = self.encryption_service.decrypt_data(encrypted_data)
            
            # Update with new keys
            data[user_id] = {
                'alpaca': {
                    'api_key': api_key,
                    'secret_key': secret_key,
                    'is_paper': is_paper
                }
            }
            
            # Encrypt and save
            encrypted_new_data = self.encryption_service.encrypt_data(data)
            self.keys_file.write_bytes(encrypted_new_data)
            return True
        except Exception as e:
            print(f"Error saving keys: {e}")
            return False

    def get_alpaca_keys(self, user_id: str) -> Optional[Dict]:
        """Retrieve Alpaca API keys for a user"""
        try:
            encrypted_data = self.keys_file.read_bytes()
            data = self.encryption_service.decrypt_data(encrypted_data)
            return data.get(user_id, {}).get('alpaca')
        except Exception as e:
            print(f"Error retrieving keys: {e}")
            return None

    def delete_alpaca_keys(self, user_id: str) -> bool:
        """Delete Alpaca API keys for a user"""
        try:
            encrypted_data = self.keys_file.read_bytes()
            data = self.encryption_service.decrypt_data(encrypted_data)
            
            if user_id in data and 'alpaca' in data[user_id]:
                del data[user_id]['alpaca']
                if not data[user_id]:  # If no other keys, remove user entirely
                    del data[user_id]
                
                encrypted_new_data = self.encryption_service.encrypt_data(data)
                self.keys_file.write_bytes(encrypted_new_data)
            return True
        except Exception as e:
            print(f"Error deleting keys: {e}")
            return False
