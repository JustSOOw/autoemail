# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 加密工具
提供配置数据的加密和解密功能
"""

import base64
import hashlib
import os
from typing import Optional, Union

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from utils.logger import get_logger


class EncryptionManager:
    """
    加密管理器
    
    负责敏感配置数据的加密和解密
    """

    def __init__(self, master_password: Optional[str] = None):
        """
        初始化加密管理器
        
        Args:
            master_password: 主密码，如果为None则使用默认密钥
        """
        self.logger = get_logger(__name__)
        self._fernet = None
        
        if master_password:
            self._init_with_password(master_password)
        else:
            self._init_with_default_key()

    def _init_with_password(self, password: str):
        """使用密码初始化加密器"""
        try:
            # 生成盐值（在实际应用中应该存储这个盐值）
            salt = b'email_domain_manager_salt_2024'  # 固定盐值，实际应用中应该随机生成并存储
            
            # 使用PBKDF2从密码生成密钥
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
            self._fernet = Fernet(key)
            
            self.logger.debug("使用密码初始化加密器成功")
            
        except Exception as e:
            self.logger.error(f"使用密码初始化加密器失败: {e}")
            raise

    def _init_with_default_key(self):
        """使用默认密钥初始化加密器"""
        try:
            # 生成或加载默认密钥
            key_file = "data/encryption.key"
            
            if os.path.exists(key_file):
                # 加载现有密钥
                with open(key_file, 'rb') as f:
                    key = f.read()
            else:
                # 生成新密钥
                key = Fernet.generate_key()
                
                # 确保目录存在
                os.makedirs(os.path.dirname(key_file), exist_ok=True)
                
                # 保存密钥
                with open(key_file, 'wb') as f:
                    f.write(key)
                
                self.logger.info(f"生成新的加密密钥: {key_file}")
            
            self._fernet = Fernet(key)
            self.logger.debug("使用默认密钥初始化加密器成功")
            
        except Exception as e:
            self.logger.error(f"使用默认密钥初始化加密器失败: {e}")
            raise

    def encrypt(self, data: Union[str, bytes]) -> str:
        """
        加密数据
        
        Args:
            data: 要加密的数据
            
        Returns:
            加密后的base64编码字符串
        """
        try:
            if isinstance(data, str):
                data = data.encode('utf-8')
            
            encrypted_data = self._fernet.encrypt(data)
            return base64.urlsafe_b64encode(encrypted_data).decode('utf-8')
            
        except Exception as e:
            self.logger.error(f"加密数据失败: {e}")
            raise

    def decrypt(self, encrypted_data: str) -> str:
        """
        解密数据
        
        Args:
            encrypted_data: 加密的base64编码字符串
            
        Returns:
            解密后的字符串
        """
        try:
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_data.encode('utf-8'))
            decrypted_data = self._fernet.decrypt(encrypted_bytes)
            return decrypted_data.decode('utf-8')
            
        except Exception as e:
            self.logger.error(f"解密数据失败: {e}")
            raise

    def encrypt_dict(self, data_dict: dict, keys_to_encrypt: list) -> dict:
        """
        加密字典中的指定键值
        
        Args:
            data_dict: 数据字典
            keys_to_encrypt: 需要加密的键列表
            
        Returns:
            加密后的字典
        """
        try:
            result = data_dict.copy()
            
            for key in keys_to_encrypt:
                if key in result and result[key]:
                    result[key] = self.encrypt(str(result[key]))
                    
            return result
            
        except Exception as e:
            self.logger.error(f"加密字典失败: {e}")
            raise

    def decrypt_dict(self, data_dict: dict, keys_to_decrypt: list) -> dict:
        """
        解密字典中的指定键值
        
        Args:
            data_dict: 数据字典
            keys_to_decrypt: 需要解密的键列表
            
        Returns:
            解密后的字典
        """
        try:
            result = data_dict.copy()
            
            for key in keys_to_decrypt:
                if key in result and result[key]:
                    try:
                        result[key] = self.decrypt(result[key])
                    except Exception:
                        # 如果解密失败，可能是未加密的数据，保持原值
                        self.logger.warning(f"解密键 {key} 失败，可能是未加密数据")
                        
            return result
            
        except Exception as e:
            self.logger.error(f"解密字典失败: {e}")
            raise

    @staticmethod
    def hash_password(password: str, salt: Optional[str] = None) -> tuple:
        """
        哈希密码
        
        Args:
            password: 密码
            salt: 盐值，如果为None则生成新的
            
        Returns:
            (哈希值, 盐值) 的元组
        """
        if salt is None:
            salt = base64.urlsafe_b64encode(os.urandom(32)).decode('utf-8')
        
        # 使用PBKDF2进行密码哈希
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt.encode('utf-8'),
            iterations=100000,
        )
        
        password_hash = base64.urlsafe_b64encode(
            kdf.derive(password.encode('utf-8'))
        ).decode('utf-8')
        
        return password_hash, salt

    @staticmethod
    def verify_password(password: str, password_hash: str, salt: str) -> bool:
        """
        验证密码
        
        Args:
            password: 输入的密码
            password_hash: 存储的密码哈希
            salt: 盐值
            
        Returns:
            密码是否正确
        """
        try:
            computed_hash, _ = EncryptionManager.hash_password(password, salt)
            return computed_hash == password_hash
            
        except Exception:
            return False

    def is_encrypted(self, data: str) -> bool:
        """
        检查数据是否已加密
        
        Args:
            data: 数据字符串
            
        Returns:
            是否已加密
        """
        try:
            # 尝试解密，如果成功说明是加密数据
            self.decrypt(data)
            return True
        except:
            return False

    def get_encryption_info(self) -> dict:
        """
        获取加密信息
        
        Returns:
            加密信息字典
        """
        return {
            "encryption_enabled": self._fernet is not None,
            "algorithm": "Fernet (AES 128)",
            "key_derivation": "PBKDF2-HMAC-SHA256",
            "iterations": 100000
        }


# 全局加密管理器实例
_encryption_manager = None


def get_encryption_manager(master_password: Optional[str] = None) -> EncryptionManager:
    """
    获取全局加密管理器实例
    
    Args:
        master_password: 主密码
        
    Returns:
        加密管理器实例
    """
    global _encryption_manager
    
    if _encryption_manager is None:
        _encryption_manager = EncryptionManager(master_password)
    
    return _encryption_manager


def reset_encryption_manager():
    """重置全局加密管理器"""
    global _encryption_manager
    _encryption_manager = None


# 便捷函数
def encrypt_sensitive_data(data: str) -> str:
    """加密敏感数据"""
    return get_encryption_manager().encrypt(data)


def decrypt_sensitive_data(encrypted_data: str) -> str:
    """解密敏感数据"""
    return get_encryption_manager().decrypt(encrypted_data)


def hash_master_password(password: str) -> tuple:
    """哈希主密码"""
    return EncryptionManager.hash_password(password)


def verify_master_password(password: str, password_hash: str, salt: str) -> bool:
    """验证主密码"""
    return EncryptionManager.verify_password(password, password_hash, salt)
