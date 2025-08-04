# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 图片服务
负责图片的上传、处理、存储和管理
"""

import os
import shutil
import hashlib
from datetime import datetime
from typing import Optional, Dict, Any, Tuple
from pathlib import Path

from PIL import Image, ImageOps
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QPixmap

from utils.logger import get_logger


class ImageService(QObject):
    """
    图片服务类
    
    提供图片上传、处理、存储和管理功能
    """
    
    # 信号定义
    imageProcessed = pyqtSignal(str, dict)  # 图片处理完成信号
    errorOccurred = pyqtSignal(str)  # 错误发生信号
    
    # 配置常量
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
    ALLOWED_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'}
    ICON_SIZE = (64, 64)  # 标准图标尺寸
    QUALITY = 85  # JPEG质量
    
    def __init__(self, parent=None):
        """
        初始化图片服务

        Args:
            parent: 父对象
        """
        super().__init__(parent)
        self.logger = get_logger(__name__)

        # 设置存储路径 - 使用用户数据目录
        import tempfile
        app_data_dir = Path(tempfile.gettempdir()) / "EmailDomainManager"
        self.base_storage_path = app_data_dir / "data" / "images"
        self.icons_path = self.base_storage_path / "icons"
        
        # 创建存储目录
        self._ensure_storage_directories()
        
        self.logger.info("🖼️ 图片服务初始化完成")
    
    def _ensure_storage_directories(self):
        """确保存储目录存在"""
        try:
            self.icons_path.mkdir(parents=True, exist_ok=True)
            self.logger.info(f"图片存储目录已准备: {self.icons_path}")
        except Exception as e:
            self.logger.error(f"创建存储目录失败: {e}")
            raise
    
    def validate_image(self, file_path: str) -> Dict[str, Any]:
        """
        验证图片文件
        
        Args:
            file_path: 图片文件路径
            
        Returns:
            验证结果字典
        """
        try:
            file_path = Path(file_path)
            
            # 检查文件是否存在
            if not file_path.exists():
                return {
                    "valid": False,
                    "error": "文件不存在"
                }
            
            # 检查文件扩展名
            if file_path.suffix.lower() not in self.ALLOWED_EXTENSIONS:
                return {
                    "valid": False,
                    "error": f"不支持的文件格式。支持的格式: {', '.join(self.ALLOWED_EXTENSIONS)}"
                }
            
            # 检查文件大小
            file_size = file_path.stat().st_size
            if file_size > self.MAX_FILE_SIZE:
                size_mb = file_size / (1024 * 1024)
                return {
                    "valid": False,
                    "error": f"文件过大 ({size_mb:.1f}MB)。最大允许 {self.MAX_FILE_SIZE / (1024 * 1024):.0f}MB"
                }
            
            # 尝试打开并验证图片
            try:
                with Image.open(file_path) as img:
                    width, height = img.size
                    format_name = img.format
                    
                    # 检查图片尺寸（可选的合理性检查）
                    if width < 16 or height < 16:
                        return {
                            "valid": False,
                            "error": "图片尺寸过小，最小支持 16x16 像素"
                        }
                    
                    if width > 1024 or height > 1024:
                        return {
                            "valid": False,
                            "error": "图片尺寸过大，最大支持 1024x1024 像素"
                        }
                    
                    return {
                        "valid": True,
                        "info": {
                            "width": width,
                            "height": height,
                            "format": format_name,
                            "size": file_size,
                            "size_mb": round(file_size / (1024 * 1024), 2)
                        }
                    }
                    
            except Exception as e:
                return {
                    "valid": False,
                    "error": f"无效的图片文件: {str(e)}"
                }
                
        except Exception as e:
            self.logger.error(f"验证图片文件失败: {e}")
            return {
                "valid": False,
                "error": f"验证失败: {str(e)}"
            }
    
    def process_icon_image(self, source_path: str, tag_name: str) -> Optional[Dict[str, Any]]:
        """
        处理标签图标图片
        
        Args:
            source_path: 源图片路径
            tag_name: 标签名称（用于生成文件名）
            
        Returns:
            处理结果字典或None
        """
        try:
            source_path = Path(source_path)
            
            # 先验证图片
            validation = self.validate_image(source_path)
            if not validation["valid"]:
                self.errorOccurred.emit(validation["error"])
                return None
            
            # 生成唯一文件名
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            file_hash = self._generate_file_hash(source_path)[:8]
            safe_tag_name = self._sanitize_filename(tag_name)
            filename = f"icon_{safe_tag_name}_{timestamp}_{file_hash}.png"
            
            target_path = self.icons_path / filename
            
            # 处理图片
            processed_info = self._process_and_save_icon(source_path, target_path)
            if not processed_info:
                return None
            
            result = {
                "success": True,
                "filename": filename,
                "relative_path": f"data/images/icons/{filename}",
                "absolute_path": str(target_path),
                "processed_info": processed_info,
                "original_info": validation["info"]
            }
            
            # 发送处理完成信号
            self.imageProcessed.emit(str(target_path), result)
            
            self.logger.info(f"成功处理标签图标: {filename}")
            return result
            
        except Exception as e:
            error_msg = f"处理图标失败: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            return None
    
    def _process_and_save_icon(self, source_path: Path, target_path: Path) -> Optional[Dict[str, Any]]:
        """处理并保存图标"""
        try:
            with Image.open(source_path) as img:
                # 转换为RGBA模式以支持透明度
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # 调整尺寸，保持宽高比
                img.thumbnail(self.ICON_SIZE, Image.Resampling.LANCZOS)
                
                # 创建透明背景的正方形图像
                icon_img = Image.new('RGBA', self.ICON_SIZE, (0, 0, 0, 0))
                
                # 计算居中位置
                x = (self.ICON_SIZE[0] - img.width) // 2
                y = (self.ICON_SIZE[1] - img.height) // 2
                
                # 粘贴图像到中心
                icon_img.paste(img, (x, y), img if img.mode == 'RGBA' else None)
                
                # 保存为PNG格式以保持透明度
                icon_img.save(target_path, 'PNG', optimize=True)
                
                return {
                    "final_size": self.ICON_SIZE,
                    "original_size": img.size,
                    "file_size": target_path.stat().st_size,
                    "format": "PNG"
                }
                
        except Exception as e:
            self.logger.error(f"处理图标图片失败: {e}")
            return None
    
    def _generate_file_hash(self, file_path: Path) -> str:
        """生成文件哈希值"""
        try:
            hash_md5 = hashlib.md5()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
            return hash_md5.hexdigest()
        except Exception as e:
            self.logger.error(f"生成文件哈希失败: {e}")
            return datetime.now().strftime("%Y%m%d%H%M%S")
    
    def _sanitize_filename(self, filename: str) -> str:
        """清理文件名，移除特殊字符"""
        import re
        # 只保留字母、数字、下划线和连字符
        sanitized = re.sub(r'[^\w\-_]', '_', filename)
        # 限制长度
        return sanitized[:20] if len(sanitized) > 20 else sanitized
    
    def delete_icon(self, icon_path: str) -> bool:
        """
        删除图标文件
        
        Args:
            icon_path: 图标路径（可以是相对路径或绝对路径）
            
        Returns:
            是否删除成功
        """
        try:
            # 处理路径
            if icon_path.startswith("data/images/icons/"):
                # 相对路径
                file_path = Path(icon_path)
            else:
                # 可能是绝对路径或仅文件名
                file_path = Path(icon_path)
                if not file_path.is_absolute():
                    file_path = self.icons_path / file_path.name
            
            if file_path.exists():
                file_path.unlink()
                self.logger.info(f"成功删除图标文件: {file_path}")
                return True
            else:
                self.logger.warning(f"要删除的图标文件不存在: {file_path}")
                return False
                
        except Exception as e:
            self.logger.error(f"删除图标文件失败: {e}")
            return False
    
    def get_icon_url(self, icon_path: str) -> str:
        """
        获取图标的URL路径（用于QML显示）
        
        Args:
            icon_path: 图标路径
            
        Returns:
            图标URL
        """
        try:
            if icon_path.startswith("data/images/icons/"):
                # 相对路径，转换为文件URL
                abs_path = Path(icon_path).resolve()
                return f"file:///{abs_path.as_posix()}"
            elif Path(icon_path).is_absolute():
                # 绝对路径
                return f"file:///{Path(icon_path).as_posix()}"
            else:
                # 文件名，构建完整路径
                abs_path = (self.icons_path / icon_path).resolve()
                return f"file:///{abs_path.as_posix()}"
                
        except Exception as e:
            self.logger.error(f"生成图标URL失败: {e}")
            return ""
    
    def cleanup_unused_icons(self, used_icon_paths: list) -> Dict[str, Any]:
        """
        清理未使用的图标文件
        
        Args:
            used_icon_paths: 正在使用的图标路径列表
            
        Returns:
            清理结果统计
        """
        try:
            result = {
                "total_files": 0,
                "deleted_files": 0,
                "failed_deletions": 0,
                "deleted_paths": [],
                "errors": []
            }
            
            # 获取所有图标文件
            all_icon_files = list(self.icons_path.glob("*.png"))
            result["total_files"] = len(all_icon_files)
            
            # 构建使用中的文件集合
            used_files = set()
            for path in used_icon_paths:
                if path and path.startswith("data/images/icons/"):
                    filename = Path(path).name
                    used_files.add(filename)
            
            # 删除未使用的文件
            for file_path in all_icon_files:
                if file_path.name not in used_files:
                    try:
                        file_path.unlink()
                        result["deleted_files"] += 1
                        result["deleted_paths"].append(str(file_path))
                        self.logger.info(f"清理未使用图标: {file_path}")
                    except Exception as e:
                        result["failed_deletions"] += 1
                        result["errors"].append(f"删除 {file_path} 失败: {str(e)}")
            
            self.logger.info(f"图标清理完成: 删除 {result['deleted_files']} 个文件")
            return result
            
        except Exception as e:
            self.logger.error(f"清理图标失败: {e}")
            return {
                "total_files": 0,
                "deleted_files": 0,
                "failed_deletions": 0,
                "deleted_paths": [],
                "errors": [str(e)]
            }
    
    def get_storage_info(self) -> Dict[str, Any]:
        """
        获取存储信息统计
        
        Returns:
            存储信息字典
        """
        try:
            icon_files = list(self.icons_path.glob("*.png"))
            total_size = sum(f.stat().st_size for f in icon_files)
            
            return {
                "icons_count": len(icon_files),
                "total_size_bytes": total_size,
                "total_size_mb": round(total_size / (1024 * 1024), 2),
                "storage_path": str(self.icons_path),
                "max_file_size_mb": self.MAX_FILE_SIZE / (1024 * 1024),
                "allowed_extensions": list(self.ALLOWED_EXTENSIONS)
            }
            
        except Exception as e:
            self.logger.error(f"获取存储信息失败: {e}")
            return {}