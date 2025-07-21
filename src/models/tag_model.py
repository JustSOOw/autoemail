# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 标签数据模型
定义标签的数据结构和业务规则
"""

import json
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional


@dataclass
class TagModel:
    """
    标签数据模型

    用于邮箱分类和管理的标签系统
    """

    # 基本信息
    id: Optional[int] = None
    name: str = ""
    color: str = "#3498db"  # 默认蓝色
    icon: str = ""  # 图标名称或Unicode
    description: str = ""

    # 时间信息
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    # 系统标识
    is_system: bool = False  # 是否为系统预定义标签
    sort_order: int = 0  # 排序顺序

    # 使用统计
    usage_count: int = 0  # 使用次数

    def __post_init__(self):
        """初始化后处理"""
        if self.created_at is None:
            self.created_at = datetime.now()

        if self.updated_at is None:
            self.updated_at = datetime.now()

        # 验证颜色格式
        if not self._is_valid_color(self.color):
            self.color = "#3498db"  # 默认颜色

    def _is_valid_color(self, color: str) -> bool:
        """验证颜色格式"""
        import re

        # 支持十六进制颜色格式
        pattern = r"^#[0-9A-Fa-f]{6}$"
        return bool(re.match(pattern, color))

    @property
    def display_name(self) -> str:
        """显示名称（包含图标）"""
        if self.icon:
            return f"{self.icon} {self.name}"
        return self.name

    def update_usage_count(self, increment: int = 1):
        """更新使用次数"""
        self.usage_count += increment
        self.updated_at = datetime.now()

    def set_color(self, color: str) -> bool:
        """设置颜色"""
        if self._is_valid_color(color):
            self.color = color
            self.updated_at = datetime.now()
            return True
        return False

    def set_icon(self, icon: str):
        """设置图标"""
        self.icon = icon
        self.updated_at = datetime.now()

    def update_description(self, description: str):
        """更新描述"""
        self.description = description
        self.updated_at = datetime.now()

    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "name": self.name,
            "color": self.color,
            "icon": self.icon,
            "description": self.description,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_system": self.is_system,
            "sort_order": self.sort_order,
            "usage_count": self.usage_count,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TagModel":
        """从字典创建实例"""

        def parse_datetime(dt_str):
            if dt_str:
                try:
                    return datetime.fromisoformat(dt_str)
                except (ValueError, TypeError):
                    pass
            return None

        return cls(
            id=data.get("id"),
            name=data.get("name", ""),
            color=data.get("color", "#3498db"),
            icon=data.get("icon", ""),
            description=data.get("description", ""),
            created_at=parse_datetime(data.get("created_at")),
            updated_at=parse_datetime(data.get("updated_at")),
            is_system=data.get("is_system", False),
            sort_order=data.get("sort_order", 0),
            usage_count=data.get("usage_count", 0),
        )

    def to_json(self) -> str:
        """转换为JSON字符串"""
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)

    @classmethod
    def from_json(cls, json_str: str) -> "TagModel":
        """从JSON字符串创建实例"""
        data = json.loads(json_str)
        return cls.from_dict(data)

    def __str__(self) -> str:
        """字符串表示"""
        return f"TagModel(name={self.name}, color={self.color})"

    def __repr__(self) -> str:
        """详细字符串表示"""
        return (
            f"TagModel(id={self.id}, name='{self.name}', "
            f"color='{self.color}', is_system={self.is_system})"
        )


# 预定义系统标签
SYSTEM_TAGS = [
    TagModel(
        name="测试用",
        color="#e74c3c",
        icon="🧪",
        description="用于测试目的的邮箱",
        is_system=True,
        sort_order=1,
    ),
    TagModel(
        name="开发用",
        color="#3498db",
        icon="💻",
        description="开发环境使用的邮箱",
        is_system=True,
        sort_order=2,
    ),
    TagModel(
        name="生产用",
        color="#27ae60",
        icon="🚀",
        description="生产环境使用的邮箱",
        is_system=True,
        sort_order=3,
    ),
    TagModel(
        name="临时用",
        color="#f39c12",
        icon="⏰",
        description="临时使用的邮箱",
        is_system=True,
        sort_order=4,
    ),
    TagModel(
        name="重要",
        color="#9b59b6",
        icon="⭐",
        description="重要的邮箱记录",
        is_system=True,
        sort_order=5,
    ),
]


def create_tag_model(
    name: str,
    color: str = "#3498db",
    icon: str = "",
    description: str = "",
    is_system: bool = False,
) -> TagModel:
    """创建标签模型的便捷函数"""
    if not name.strip():
        raise ValueError("标签名称不能为空")

    return TagModel(
        name=name.strip(),
        color=color,
        icon=icon,
        description=description,
        is_system=is_system,
    )


def get_system_tags() -> list:
    """获取系统预定义标签"""
    return [tag for tag in SYSTEM_TAGS]


def validate_tag_name(name: str) -> bool:
    """验证标签名称"""
    if not name or not name.strip():
        return False

    # 检查长度
    if len(name.strip()) > 50:
        return False

    # 检查特殊字符
    import re

    pattern = r"^[a-zA-Z0-9\u4e00-\u9fff\s\-_]+$"
    return bool(re.match(pattern, name.strip()))


def get_color_palette() -> list:
    """获取推荐的颜色调色板"""
    return [
        "#e74c3c",  # 红色
        "#3498db",  # 蓝色
        "#27ae60",  # 绿色
        "#f39c12",  # 橙色
        "#9b59b6",  # 紫色
        "#1abc9c",  # 青色
        "#34495e",  # 深灰色
        "#e67e22",  # 深橙色
        "#2ecc71",  # 浅绿色
        "#8e44ad",  # 深紫色
        "#16a085",  # 深青色
        "#2c3e50",  # 深蓝灰色
    ]
