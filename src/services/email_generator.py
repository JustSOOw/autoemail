# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 邮箱生成器
负责生成唯一的邮箱地址
"""

import random
import string
import time
from datetime import datetime
from typing import List, Optional, Dict, Any
from pathlib import Path

from models.config_model import ConfigModel
from utils.logger import get_logger


class EmailGenerator:
    """
    邮箱生成器
    
    根据配置的域名和规则生成唯一的邮箱地址
    """

    def __init__(self, config: ConfigModel):
        """
        初始化邮箱生成器
        
        Args:
            config: 配置模型实例
        """
        self.config = config
        self.logger = get_logger(__name__)
        
        # 加载名字数据集
        self._load_names_dataset()
        
        self.logger.info("邮箱生成器初始化完成")

    def _load_names_dataset(self):
        """加载名字数据集"""
        try:
            # 尝试从多个位置加载名字数据集
            possible_paths = [
                Path("cursor-auto-free/names-dataset.txt"),
                Path("cursor-auto-free-core/names-dataset.txt"),
                Path("data/names-dataset.txt"),
                Path("resources/names-dataset.txt")
            ]
            
            self.names_dataset = []
            
            for path in possible_paths:
                if path.exists():
                    with open(path, 'r', encoding='utf-8') as f:
                        self.names_dataset = [line.strip() for line in f if line.strip()]
                    self.logger.info(f"成功加载名字数据集: {path}, 共 {len(self.names_dataset)} 个名字")
                    break
            
            # 如果没有找到数据集文件，使用默认名字列表
            if not self.names_dataset:
                self.names_dataset = [
                    "alex", "bob", "charlie", "david", "emma", "frank", "grace", "henry",
                    "ivy", "jack", "kate", "leo", "mary", "nick", "olivia", "peter",
                    "queen", "ryan", "sara", "tom", "uma", "victor", "wendy", "xavier",
                    "yuki", "zoe", "alice", "ben", "cathy", "daniel", "eva", "felix",
                    "gina", "harry", "iris", "james", "kelly", "lucas", "mia", "noah",
                    "oscar", "penny", "quinn", "ruby", "sam", "tina", "ulrich", "vera",
                    "will", "xara", "yale", "zara"
                ]
                self.logger.warning("未找到名字数据集文件，使用默认名字列表")
                
        except Exception as e:
            self.logger.error(f"加载名字数据集失败: {e}")
            # 使用最小默认集合
            self.names_dataset = ["user", "test", "demo", "temp"]

    def generate_email(self, 
                      prefix_type: str = "random_name", 
                      custom_prefix: Optional[str] = None,
                      add_timestamp: bool = True,
                      timestamp_format: str = "unix") -> str:
        """
        生成邮箱地址
        
        Args:
            prefix_type: 前缀类型 ("random_name", "random_string", "custom")
            custom_prefix: 自定义前缀（当prefix_type为"custom"时使用）
            add_timestamp: 是否添加时间戳
            timestamp_format: 时间戳格式 ("unix", "datetime", "short")
            
        Returns:
            生成的邮箱地址
        """
        try:
            domain = self.config.get_domain()
            if not domain:
                raise ValueError("域名未配置")
            
            # 生成前缀
            if prefix_type == "custom" and custom_prefix:
                prefix = self._sanitize_prefix(custom_prefix)
            elif prefix_type == "random_string":
                prefix = self._generate_random_string()
            else:  # random_name
                prefix = self._generate_random_name()
            
            # 添加时间戳
            if add_timestamp:
                timestamp = self._generate_timestamp(timestamp_format)
                prefix = f"{prefix}{timestamp}"
            
            # 生成完整邮箱地址
            email_address = f"{prefix}@{domain}"
            
            self.logger.info(f"生成邮箱地址: {email_address}")
            return email_address
            
        except Exception as e:
            self.logger.error(f"生成邮箱地址失败: {e}")
            raise

    def _generate_random_name(self) -> str:
        """生成随机名字前缀"""
        if not self.names_dataset:
            return "user"
        
        base_name = random.choice(self.names_dataset)
        
        # 有30%的概率添加数字后缀
        if random.random() < 0.3:
            suffix = random.randint(1, 999)
            return f"{base_name}{suffix}"
        
        return base_name

    def _generate_random_string(self, length: int = 8) -> str:
        """
        生成随机字符串前缀
        
        Args:
            length: 字符串长度
            
        Returns:
            随机字符串
        """
        # 使用字母和数字，但避免容易混淆的字符
        chars = string.ascii_lowercase + string.digits
        chars = chars.replace('0', '').replace('o', '').replace('1', '').replace('l', '')
        
        return ''.join(random.choice(chars) for _ in range(length))

    def _sanitize_prefix(self, prefix: str) -> str:
        """
        清理和验证前缀
        
        Args:
            prefix: 原始前缀
            
        Returns:
            清理后的前缀
        """
        # 移除非法字符，只保留字母、数字、点、连字符、下划线
        import re
        sanitized = re.sub(r'[^a-zA-Z0-9._-]', '', prefix)
        
        # 确保不以点或连字符开头/结尾
        sanitized = sanitized.strip('.-')
        
        # 确保长度合理
        if len(sanitized) > 50:
            sanitized = sanitized[:50]
        
        # 如果清理后为空，使用默认值
        if not sanitized:
            sanitized = "user"
        
        return sanitized.lower()

    def _generate_timestamp(self, format_type: str = "unix") -> str:
        """
        生成时间戳
        
        Args:
            format_type: 时间戳格式类型
            
        Returns:
            时间戳字符串
        """
        now = datetime.now()
        
        if format_type == "unix":
            return str(int(time.time()))
        elif format_type == "datetime":
            return now.strftime("%Y%m%d%H%M%S")
        elif format_type == "short":
            return now.strftime("%m%d%H%M")
        else:
            return str(int(time.time()))

    def generate_batch_emails(self, 
                             count: int, 
                             prefix_type: str = "random_name",
                             add_timestamp: bool = True) -> List[str]:
        """
        批量生成邮箱地址
        
        Args:
            count: 生成数量
            prefix_type: 前缀类型
            add_timestamp: 是否添加时间戳
            
        Returns:
            邮箱地址列表
        """
        if count <= 0:
            return []
        
        if count > 100:
            self.logger.warning(f"批量生成数量过大: {count}，限制为100")
            count = 100
        
        emails = []
        for i in range(count):
            try:
                email = self.generate_email(
                    prefix_type=prefix_type,
                    add_timestamp=add_timestamp
                )
                emails.append(email)
                
                # 添加小延迟确保时间戳唯一性
                if add_timestamp and i < count - 1:
                    time.sleep(0.01)
                    
            except Exception as e:
                self.logger.error(f"批量生成第 {i+1} 个邮箱失败: {e}")
                continue
        
        self.logger.info(f"批量生成完成，成功生成 {len(emails)} 个邮箱地址")
        return emails

    def validate_email_format(self, email: str) -> bool:
        """
        验证邮箱格式
        
        Args:
            email: 邮箱地址
            
        Returns:
            是否格式正确
        """
        import re
        
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))

    def get_generation_stats(self) -> Dict[str, Any]:
        """
        获取生成统计信息
        
        Returns:
            统计信息字典
        """
        return {
            "domain": self.config.get_domain(),
            "names_dataset_size": len(self.names_dataset),
            "domain_configured": self.config.is_domain_configured(),
            "verification_method": self.config.get_verification_method(),
            "generator_ready": self.config.is_domain_configured()
        }

    def suggest_prefixes(self, count: int = 10) -> List[str]:
        """
        建议前缀列表
        
        Args:
            count: 建议数量
            
        Returns:
            前缀建议列表
        """
        suggestions = []
        
        # 添加一些随机名字
        for _ in range(count // 2):
            suggestions.append(self._generate_random_name())
        
        # 添加一些随机字符串
        for _ in range(count - len(suggestions)):
            suggestions.append(self._generate_random_string())
        
        return list(set(suggestions))  # 去重
