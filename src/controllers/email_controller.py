# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 邮箱控制器
负责邮箱相关的业务逻辑控制和QML交互
"""

import asyncio
import json
from datetime import datetime
from typing import List, Optional, Dict, Any

from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from PyQt6.QtQml import qmlRegisterType

from models.email_model import EmailModel, EmailStatus
from services.email_service import EmailService
from services.database_service import DatabaseService
from utils.config_manager import ConfigManager
from utils.logger import get_logger


class EmailController(QObject):
    """
    邮箱控制器 - 连接QML和Python后端
    负责处理所有邮箱相关的操作和状态管理
    """

    # 信号定义 - QML可以监听这些信号
    emailGenerated = pyqtSignal(str, str, str)  # email_address, status, message
    emailListUpdated = pyqtSignal('QVariantList')  # email_list
    verificationCodeReceived = pyqtSignal(str, str)  # email_address, verification_code
    statusChanged = pyqtSignal(str)  # status_message
    progressChanged = pyqtSignal(int)  # progress_value (0-100)
    errorOccurred = pyqtSignal(str, str)  # error_type, error_message
    statisticsUpdated = pyqtSignal('QVariantMap')  # statistics_data

    def __init__(self, config_manager: ConfigManager, database_service: DatabaseService):
        """
        初始化邮箱控制器
        
        Args:
            config_manager: 配置管理器
            database_service: 数据库服务
        """
        super().__init__()
        self.config_manager = config_manager
        self.database_service = database_service
        self.logger = get_logger(__name__)
        
        # 初始化邮箱服务
        config = config_manager.get_config()
        self.email_service = EmailService(
            config=config,
            db_service=database_service
        )
        
        # 内部状态
        self._current_emails: List[EmailModel] = []
        self._is_generating = False
        self._statistics = {}
        
        # 定时器用于更新统计信息
        self._stats_timer = QTimer()
        self._stats_timer.timeout.connect(self._update_statistics)
        self._stats_timer.start(30000)  # 每30秒更新一次统计信息

        # 初始化时加载邮箱列表
        try:
            self.logger.info("EmailController初始化，开始加载邮箱列表...")
            self._refresh_email_list()
        except Exception as e:
            self.logger.error(f"初始化加载邮箱列表失败: {e}")

        self.logger.info("邮箱控制器初始化完成")

    @pyqtSlot()
    def generateEmail(self):
        """生成新邮箱 - QML调用的方法"""
        if self._is_generating:
            self.statusChanged.emit("正在生成邮箱，请稍候...")
            return
            
        try:
            self._is_generating = True
            self.statusChanged.emit("正在生成邮箱...")
            self.progressChanged.emit(10)
            
            # 获取配置
            config = self.config_manager.get_config()
            if not config or not config.get_domain():
                self.errorOccurred.emit("配置错误", "请先配置域名")
                return
            
            self.progressChanged.emit(30)
            
            # 生成邮箱
            email_model = self.email_service.create_email(
                prefix_type="random_name",
                tags=["自动生成"],
                notes="通过界面生成"
            )
            
            self.progressChanged.emit(70)
            
            # 发送成功信号
            self.emailGenerated.emit(
                email_model.email_address,
                "success",
                f"邮箱生成成功: {email_model.email_address}"
            )
            
            self.statusChanged.emit(f"邮箱生成成功: {email_model.email_address}")
            self.progressChanged.emit(100)
            
            # 更新邮箱列表
            self._refresh_email_list()
            
            self.logger.info(f"邮箱生成成功: {email_model.email_address}")
            
        except Exception as e:
            self.logger.error(f"邮箱生成失败: {e}")
            self.emailGenerated.emit("", "error", f"邮箱生成失败: {e}")
            self.errorOccurred.emit("生成失败", str(e))
            self.statusChanged.emit(f"邮箱生成失败: {e}")
            
        finally:
            self._is_generating = False
            self.progressChanged.emit(0)

    @pyqtSlot(str, str, str)
    def generateCustomEmail(self, prefix_type: str, custom_prefix: str = "", tags: str = ""):
        """
        生成自定义邮箱 - QML调用的方法
        
        Args:
            prefix_type: 前缀类型 (random_name, random_string, custom)
            custom_prefix: 自定义前缀
            tags: 标签字符串，用逗号分隔
        """
        if self._is_generating:
            self.statusChanged.emit("正在生成邮箱，请稍候...")
            return
            
        try:
            self._is_generating = True
            self.statusChanged.emit("正在生成自定义邮箱...")
            self.progressChanged.emit(10)
            
            # 解析标签
            tag_list = [tag.strip() for tag in tags.split(",") if tag.strip()] if tags else []
            
            self.progressChanged.emit(30)
            
            # 生成邮箱
            email_model = self.email_service.create_email(
                prefix_type=prefix_type,
                custom_prefix=custom_prefix if custom_prefix else None,
                tags=tag_list,
                notes="通过界面自定义生成"
            )
            
            self.progressChanged.emit(70)
            
            # 发送成功信号
            self.emailGenerated.emit(
                email_model.email_address,
                "success",
                f"自定义邮箱生成成功: {email_model.email_address}"
            )
            
            self.statusChanged.emit(f"自定义邮箱生成成功: {email_model.email_address}")
            self.progressChanged.emit(100)
            
            # 更新邮箱列表
            self._refresh_email_list()
            
            self.logger.info(f"自定义邮箱生成成功: {email_model.email_address}")
            
        except Exception as e:
            self.logger.error(f"自定义邮箱生成失败: {e}")
            self.emailGenerated.emit("", "error", f"自定义邮箱生成失败: {e}")
            self.errorOccurred.emit("生成失败", str(e))
            self.statusChanged.emit(f"自定义邮箱生成失败: {e}")
            
        finally:
            self._is_generating = False
            self.progressChanged.emit(0)

    @pyqtSlot(str)
    def getVerificationCode(self, email_address: str):
        """
        获取验证码 - QML调用的方法
        注意：这是简化版本，实际验证码获取功能已移除
        
        Args:
            email_address: 邮箱地址
        """
        try:
            self.statusChanged.emit(f"正在获取 {email_address} 的验证码...")
            
            # 模拟验证码获取过程（简化版本）
            import random
            import time
            
            # 模拟延迟
            QTimer.singleShot(2000, lambda: self._simulate_verification_code(email_address))
            
        except Exception as e:
            self.logger.error(f"验证码获取失败: {e}")
            self.errorOccurred.emit("验证码获取失败", str(e))
            self.statusChanged.emit(f"验证码获取失败: {e}")

    def _simulate_verification_code(self, email_address: str):
        """模拟验证码获取（仅用于演示）"""
        try:
            import random
            verification_code = f"{random.randint(100000, 999999)}"  # nosec B311
            
            self.verificationCodeReceived.emit(email_address, verification_code)
            self.statusChanged.emit(f"验证码获取成功: {verification_code}")
            
            self.logger.info(f"模拟验证码获取: {email_address} -> {verification_code}")
            
        except Exception as e:
            self.logger.error(f"模拟验证码获取失败: {e}")

    @pyqtSlot(result=str)
    def getCurrentDomain(self):
        """获取当前域名 - QML调用的方法"""
        try:
            config = self.config_manager.get_config()
            domain = config.get_domain() if config else None
            return domain or "未配置"
        except Exception as e:
            self.logger.error(f"获取当前域名失败: {e}")
            return "获取失败"

    @pyqtSlot(result=bool)
    def isConfigured(self):
        """检查是否已配置 - QML调用的方法"""
        try:
            config = self.config_manager.get_config()
            return config.is_configured() if config else False
        except Exception as e:
            self.logger.error(f"检查配置状态失败: {e}")
            return False

    @pyqtSlot()
    def refreshEmailList(self):
        """刷新邮箱列表 - QML调用的方法"""
        try:
            self.statusChanged.emit("正在刷新邮箱列表...")
            self._refresh_email_list()
            self.statusChanged.emit("邮箱列表刷新完成")
        except Exception as e:
            self.logger.error(f"刷新邮箱列表失败: {e}")
            self.errorOccurred.emit("刷新失败", str(e))

    @pyqtSlot(result='QVariantMap')
    def getStatistics(self):
        """获取统计信息 - QML调用的方法"""
        try:
            stats = self.email_service.get_statistics()
            return {
                "total_emails": stats.get("total_emails", 0),
                "active_emails": stats.get("active_emails", 0),
                "today_created": stats.get("today_created", 0),
                "success_rate": stats.get("success_rate", 100.0)
            }
        except Exception as e:
            self.logger.error(f"获取统计信息失败: {e}")
            return {
                "total_emails": 0,
                "active_emails": 0,
                "today_created": 0,
                "success_rate": 0.0
            }

    def _refresh_email_list(self):
        """刷新邮箱列表（内部方法）"""
        try:
            self.logger.info("开始刷新邮箱列表...")

            # 方法1：获取所有活跃邮箱
            from models.email_model import EmailStatus
            emails = self.email_service.get_emails_by_status(EmailStatus.ACTIVE, limit=100)

            # 方法2：如果没有活跃邮箱，尝试获取所有邮箱
            if not emails:
                self.logger.info("未找到活跃邮箱，尝试获取所有邮箱...")
                emails = self.email_service.search_emails(limit=100)

            # 方法3：直接从数据库查询
            if not emails:
                self.logger.info("尝试直接从数据库查询邮箱...")
                try:
                    query = "SELECT * FROM emails WHERE is_active = 1 ORDER BY created_at DESC LIMIT 100"
                    results = self.email_service.db_service.execute_query(query)
                    if results:
                        emails = [self.email_service._row_to_email_model(row) for row in results]
                        self.logger.info(f"从数据库直接查询到 {len(emails)} 个邮箱")
                except Exception as db_e:
                    self.logger.error(f"直接数据库查询失败: {db_e}")

            self._current_emails = emails
            self.logger.info(f"获取到 {len(emails)} 个邮箱")

            # 转换为QML可用的格式
            email_list = []
            for email in emails:
                try:
                    email_dict = {
                        "id": email.id or 0,
                        "email_address": email.email_address or "",
                        "domain": email.domain or "",
                        "status": email.status.value if hasattr(email.status, 'value') else str(email.status),
                        "created_at": email.created_at.isoformat() if email.created_at else "",
                        "tags": email.tags or [],
                        "notes": email.notes or "",
                        "is_active": email.is_active
                    }
                    email_list.append(email_dict)
                except Exception as convert_e:
                    self.logger.error(f"转换邮箱数据失败: {convert_e}, 邮箱: {email}")

            self.logger.info(f"成功转换 {len(email_list)} 个邮箱数据")

            # 发送信号
            self.emailListUpdated.emit(email_list)

        except Exception as e:
            self.logger.error(f"刷新邮箱列表失败: {e}")
            import traceback
            self.logger.error(f"详细错误信息: {traceback.format_exc()}")
            self.emailListUpdated.emit([])

    def _update_statistics(self):
        """更新统计信息（内部方法）"""
        try:
            stats = self.getStatistics()
            self._statistics = stats
            self.statisticsUpdated.emit(stats)
        except Exception as e:
            self.logger.error(f"更新统计信息失败: {e}")

    @staticmethod
    def register_qml_type():
        """注册QML类型"""
        qmlRegisterType(EmailController, "EmailManager", 1, 0, "EmailController")
