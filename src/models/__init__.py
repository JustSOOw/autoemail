# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 数据模型包
包含所有数据模型定义
"""

from .email_model import EmailModel
from .config_model import ConfigModel
from .tag_model import TagModel

__all__ = [
    'EmailModel',
    'ConfigModel', 
    'TagModel'
]
