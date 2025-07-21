# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 邮箱数据模型
定义邮箱记录的数据结构和业务规则
"""

import json
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional


class VerificationStatus(Enum):
    """验证状态枚举"""

    PENDING = "pending"  # 待验证
    VERIFIED = "verified"  # 已验证
    FAILED = "failed"  # 验证失败
    EXPIRED = "expired"  # 已过期


class VerificationMethod(Enum):
    """验证方式枚举"""

    AUTO = "auto"  # 自动选择
    TEMPMAIL = "tempmail"  # tempmail.plus
    IMAP = "imap"  # IMAP协议
    POP3 = "pop3"  # POP3协议


@dataclass
class EmailModel:
    """
    邮箱数据模型

    包含邮箱记录的所有信息，包括基本信息、验证状态、标签等
    """

    # 基本信息
    id: Optional[int] = None
    email_address: str = ""
    domain: str = ""
    prefix: str = ""
    timestamp_suffix: str = ""

    # 时间信息
    created_at: Optional[datetime] = None
    last_used: Optional[datetime] = None
    last_activity_at: Optional[datetime] = None

    # 验证信息
    verification_status: VerificationStatus = VerificationStatus.PENDING
    verification_code: Optional[str] = None
    verification_method: Optional[VerificationMethod] = None
    verification_attempts: int = 0
    last_verification_at: Optional[datetime] = None

    # 标签和分类
    tags: List[str] = field(default_factory=list)

    # 备注和元数据
    notes: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    # 状态标识
    is_active: bool = True
    created_by: str = "system"
    updated_at: Optional[datetime] = None

    def __post_init__(self):
        """初始化后处理"""
        # 设置默认时间
        if self.created_at is None:
            self.created_at = datetime.now()

        if self.updated_at is None:
            self.updated_at = datetime.now()

        # 从邮箱地址解析域名和前缀
        if self.email_address and not self.domain:
            self._parse_email_address()

    def _parse_email_address(self):
        """从邮箱地址解析域名和前缀"""
        if "@" in self.email_address:
            prefix_part, domain_part = self.email_address.split("@", 1)
            self.domain = domain_part
            self.prefix = prefix_part

            # 尝试提取时间戳后缀
            import re

            timestamp_match = re.search(r"(\d+)$", prefix_part)
            if timestamp_match:
                self.timestamp_suffix = timestamp_match.group(1)

    @property
    def is_verified(self) -> bool:
        """是否已验证"""
        return self.verification_status == VerificationStatus.VERIFIED

    @property
    def is_expired(self) -> bool:
        """是否已过期"""
        return self.verification_status == VerificationStatus.EXPIRED

    @property
    def verification_status_display(self) -> str:
        """验证状态显示文本"""
        status_map = {
            VerificationStatus.PENDING: "待验证",
            VerificationStatus.VERIFIED: "已验证",
            VerificationStatus.FAILED: "验证失败",
            VerificationStatus.EXPIRED: "已过期",
        }
        return status_map.get(self.verification_status, "未知")

    @property
    def age_days(self) -> int:
        """创建天数"""
        if self.created_at:
            return (datetime.now() - self.created_at).days
        return 0

    def add_tag(self, tag: str) -> bool:
        """添加标签"""
        if tag and tag not in self.tags:
            self.tags.append(tag)
            self.updated_at = datetime.now()
            return True
        return False

    def remove_tag(self, tag: str) -> bool:
        """移除标签"""
        if tag in self.tags:
            self.tags.remove(tag)
            self.updated_at = datetime.now()
            return True
        return False

    def has_tag(self, tag: str) -> bool:
        """是否包含指定标签"""
        return tag in self.tags

    def update_verification_status(
        self,
        status: VerificationStatus,
        code: Optional[str] = None,
        method: Optional[VerificationMethod] = None,
    ):
        """更新验证状态"""
        self.verification_status = status
        self.last_verification_at = datetime.now()
        self.updated_at = datetime.now()

        if code:
            self.verification_code = code

        if method:
            self.verification_method = method

        # 增加验证尝试次数
        if status in [VerificationStatus.FAILED, VerificationStatus.VERIFIED]:
            self.verification_attempts += 1

    def update_last_used(self):
        """更新最后使用时间"""
        self.last_used = datetime.now()
        self.last_activity_at = datetime.now()
        self.updated_at = datetime.now()

    def add_metadata(self, key: str, value: Any):
        """添加元数据"""
        self.metadata[key] = value
        self.updated_at = datetime.now()

    def get_metadata(self, key: str, default: Any = None) -> Any:
        """获取元数据"""
        return self.metadata.get(key, default)

    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "email_address": self.email_address,
            "domain": self.domain,
            "prefix": self.prefix,
            "timestamp_suffix": self.timestamp_suffix,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_used": self.last_used.isoformat() if self.last_used else None,
            "last_activity_at": self.last_activity_at.isoformat()
            if self.last_activity_at
            else None,
            "verification_status": self.verification_status.value,
            "verification_code": self.verification_code,
            "verification_method": self.verification_method.value
            if self.verification_method
            else None,
            "verification_attempts": self.verification_attempts,
            "last_verification_at": self.last_verification_at.isoformat()
            if self.last_verification_at
            else None,
            "tags": self.tags.copy(),
            "notes": self.notes,
            "metadata": self.metadata.copy(),
            "is_active": self.is_active,
            "created_by": self.created_by,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "EmailModel":
        """从字典创建实例"""
        # 处理枚举类型
        verification_status = VerificationStatus.PENDING
        if "verification_status" in data and data["verification_status"]:
            try:
                verification_status = VerificationStatus(data["verification_status"])
            except ValueError:
                pass

        verification_method = None
        if "verification_method" in data and data["verification_method"]:
            try:
                verification_method = VerificationMethod(data["verification_method"])
            except ValueError:
                pass

        # 处理时间字段
        def parse_datetime(dt_str):
            if dt_str:
                try:
                    return datetime.fromisoformat(dt_str)
                except (ValueError, TypeError):
                    pass
            return None

        return cls(
            id=data.get("id"),
            email_address=data.get("email_address", ""),
            domain=data.get("domain", ""),
            prefix=data.get("prefix", ""),
            timestamp_suffix=data.get("timestamp_suffix", ""),
            created_at=parse_datetime(data.get("created_at")),
            last_used=parse_datetime(data.get("last_used")),
            last_activity_at=parse_datetime(data.get("last_activity_at")),
            verification_status=verification_status,
            verification_code=data.get("verification_code"),
            verification_method=verification_method,
            verification_attempts=data.get("verification_attempts", 0),
            last_verification_at=parse_datetime(data.get("last_verification_at")),
            tags=data.get("tags", []).copy() if data.get("tags") else [],
            notes=data.get("notes", ""),
            metadata=data.get("metadata", {}).copy() if data.get("metadata") else {},
            is_active=data.get("is_active", True),
            created_by=data.get("created_by", "system"),
            updated_at=parse_datetime(data.get("updated_at")),
        )

    def to_json(self) -> str:
        """转换为JSON字符串"""
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)

    @classmethod
    def from_json(cls, json_str: str) -> "EmailModel":
        """从JSON字符串创建实例"""
        data = json.loads(json_str)
        return cls.from_dict(data)

    def __str__(self) -> str:
        """字符串表示"""
        return f"EmailModel(email={self.email_address}, status={self.verification_status_display})"

    def __repr__(self) -> str:
        """详细字符串表示"""
        return (
            f"EmailModel(id={self.id}, email_address='{self.email_address}', "
            f"domain='{self.domain}', status={self.verification_status}, "
            f"created_at={self.created_at})"
        )


# 用于数据验证的辅助函数
def validate_email_address(email: str) -> bool:
    """验证邮箱地址格式"""
    import re

    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return bool(re.match(pattern, email))


def create_email_model(
    email_address: str, tags: Optional[List[str]] = None, notes: str = "", **kwargs
) -> EmailModel:
    """创建邮箱模型的便捷函数"""
    if not validate_email_address(email_address):
        raise ValueError(f"无效的邮箱地址: {email_address}")

    return EmailModel(
        email_address=email_address, tags=tags or [], notes=notes, **kwargs
    )
