# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 简化邮箱数据模型
定义邮箱记录的数据结构，专注于存储和管理功能
"""

import json
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional


class EmailStatus(Enum):
    """邮箱状态枚举"""
    ACTIVE = "active"        # 活跃
    INACTIVE = "inactive"    # 非活跃
    ARCHIVED = "archived"    # 已归档


@dataclass
class EmailModel:
    """
    简化邮箱数据模型
    
    专注于邮箱地址的生成、存储和管理功能
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
    updated_at: Optional[datetime] = None

    # 状态和分类
    status: EmailStatus = EmailStatus.ACTIVE
    tags: List[str] = field(default_factory=list)
    notes: str = ""

    # 元数据
    metadata: Dict[str, Any] = field(default_factory=dict)
    is_active: bool = True
    created_by: str = "system"

    def __post_init__(self):
        """初始化后处理"""
        if not self.created_at:
            self.created_at = datetime.now()
        
        if not self.updated_at:
            self.updated_at = datetime.now()
        
        # 从邮箱地址解析域名和前缀
        if self.email_address and not self.domain:
            self._parse_email_address()

    def _parse_email_address(self):
        """从邮箱地址解析域名和前缀"""
        if "@" in self.email_address:
            parts = self.email_address.split("@")
            if len(parts) == 2:
                self.prefix = parts[0]
                self.domain = parts[1]

    def update_last_used(self):
        """更新最后使用时间"""
        self.last_used = datetime.now()
        self.updated_at = datetime.now()

    def add_tag(self, tag: str) -> bool:
        """
        添加标签

        Args:
            tag: 标签名称

        Returns:
            是否添加成功（如果标签已存在则返回False）
        """
        if tag and tag not in self.tags:
            self.tags.append(tag)
            self.updated_at = datetime.now()
            return True
        return False

    def remove_tag(self, tag: str) -> bool:
        """
        移除标签

        Args:
            tag: 标签名称

        Returns:
            是否移除成功
        """
        if tag in self.tags:
            self.tags.remove(tag)
            self.updated_at = datetime.now()
            return True
        return False

    def has_tag(self, tag: str) -> bool:
        """
        检查是否有指定标签

        Args:
            tag: 标签名称

        Returns:
            是否包含该标签
        """
        return tag in self.tags

    def set_status(self, status: EmailStatus):
        """设置状态"""
        self.status = status
        self.updated_at = datetime.now()

    def archive(self):
        """归档邮箱"""
        self.set_status(EmailStatus.ARCHIVED)

    def activate(self):
        """激活邮箱"""
        self.set_status(EmailStatus.ACTIVE)

    def deactivate(self):
        """停用邮箱"""
        self.set_status(EmailStatus.INACTIVE)

    def soft_delete(self):
        """软删除"""
        self.is_active = False
        self.updated_at = datetime.now()

    def restore(self):
        """恢复"""
        self.is_active = True
        self.updated_at = datetime.now()

    @property
    def status_display(self) -> str:
        """状态显示名称"""
        status_map = {
            EmailStatus.ACTIVE: "活跃",
            EmailStatus.INACTIVE: "非活跃",
            EmailStatus.ARCHIVED: "已归档"
        }
        return status_map.get(self.status, "未知")

    @property
    def age_days(self) -> int:
        """邮箱创建天数"""
        if self.created_at:
            return (datetime.now() - self.created_at).days
        return 0

    @property
    def has_tags(self) -> bool:
        """是否有标签"""
        return len(self.tags) > 0

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
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "status": self.status.value,
            "tags": self.tags.copy(),
            "notes": self.notes,
            "metadata": self.metadata.copy(),
            "is_active": self.is_active,
            "created_by": self.created_by,
            "status_display": self.status_display,
            "age_days": self.age_days,
            "has_tags": self.has_tags
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'EmailModel':
        """从字典创建实例"""
        # 解析时间字段
        def parse_datetime(dt_str):
            if dt_str:
                try:
                    return datetime.fromisoformat(dt_str)
                except (ValueError, TypeError):
                    pass
            return None

        # 解析状态
        status = EmailStatus.ACTIVE
        if data.get("status"):
            try:
                status = EmailStatus(data["status"])
            except ValueError:
                pass

        return cls(
            id=data.get("id"),
            email_address=data.get("email_address", ""),
            domain=data.get("domain", ""),
            prefix=data.get("prefix", ""),
            timestamp_suffix=data.get("timestamp_suffix", ""),
            created_at=parse_datetime(data.get("created_at")),
            last_used=parse_datetime(data.get("last_used")),
            updated_at=parse_datetime(data.get("updated_at")),
            status=status,
            tags=data.get("tags", []).copy() if data.get("tags") else [],
            notes=data.get("notes", ""),
            metadata=data.get("metadata", {}).copy() if data.get("metadata") else {},
            is_active=data.get("is_active", True),
            created_by=data.get("created_by", "system")
        )

    def to_json(self) -> str:
        """转换为JSON字符串"""
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)

    @classmethod
    def from_json(cls, json_str: str) -> 'EmailModel':
        """从JSON字符串创建实例"""
        data = json.loads(json_str)
        return cls.from_dict(data)

    def __str__(self) -> str:
        """字符串表示"""
        return f"EmailModel(id={self.id}, email={self.email_address}, status={self.status_display})"

    def __repr__(self) -> str:
        """详细字符串表示"""
        return (f"EmailModel(id={self.id}, email_address='{self.email_address}', "
                f"domain='{self.domain}', status={self.status.value}, "
                f"tags={self.tags}, created_at={self.created_at})")


def create_email_model(email_address: str,
                      tags: Optional[List[str]] = None,
                      notes: str = "",
                      status: EmailStatus = EmailStatus.ACTIVE,
                      metadata: Optional[Dict[str, Any]] = None,
                      created_by: str = "system") -> EmailModel:
    """
    创建邮箱模型的便捷函数

    Args:
        email_address: 邮箱地址
        tags: 标签列表
        notes: 备注
        status: 状态
        metadata: 元数据
        created_by: 创建者

    Returns:
        邮箱模型实例
    """
    return EmailModel(
        email_address=email_address,
        tags=tags or [],
        notes=notes,
        status=status,
        metadata=metadata or {},
        created_by=created_by
    )


def create_email_from_generation(domain: str,
                                prefix: str,
                                timestamp_suffix: str = "",
                                tags: Optional[List[str]] = None,
                                notes: str = "") -> EmailModel:
    """
    从生成参数创建邮箱模型
    
    Args:
        domain: 域名
        prefix: 前缀
        timestamp_suffix: 时间戳后缀
        tags: 标签列表
        notes: 备注
        
    Returns:
        邮箱模型实例
    """
    email_address = f"{prefix}{timestamp_suffix}@{domain}"
    
    return EmailModel(
        email_address=email_address,
        domain=domain,
        prefix=prefix,
        timestamp_suffix=timestamp_suffix,
        tags=tags or [],
        notes=notes
    )
