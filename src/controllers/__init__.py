# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 控制器包
包含所有控制器类，负责QML与Python后端的交互
"""

from .email_controller import EmailController
from .config_controller import ConfigController

__all__ = ["EmailController", "ConfigController"]
