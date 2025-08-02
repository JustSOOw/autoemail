"""
标签控制器模块

负责处理QML界面与标签服务之间的交互
"""

import json
from typing import List, Dict, Any, Optional
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot
from PyQt6.QtQml import qmlRegisterType

from services.tag_service import TagService
from services.database_service import DatabaseService
from services.image_service import ImageService
from utils.logger import get_logger
from models.tag_model import TagModel


class TagController(QObject):
    """
    标签控制器类
    
    负责处理QML界面与标签服务之间的交互，
    提供标签的创建、更新、删除、查询等功能
    """
    
    # 信号定义
    tagCreated = pyqtSignal(dict)  # 标签创建成功信号
    tagUpdated = pyqtSignal(dict)  # 标签更新成功信号
    tagDeleted = pyqtSignal(int)   # 标签删除成功信号
    tagListRefreshed = pyqtSignal(list)  # 标签列表刷新信号
    errorOccurred = pyqtSignal(str)  # 错误发生信号
    operationCompleted = pyqtSignal(str, bool, str)  # 操作完成信号(操作类型, 是否成功, 消息)
    imageUploaded = pyqtSignal(str, dict)  # 图片上传成功信号
    
    def __init__(self, database_service: DatabaseService, parent=None):
        """
        初始化标签控制器
        
        Args:
            database_service: 数据库服务实例
            parent: 父对象
        """
        super().__init__(parent)
        self.database_service = database_service
        self.tag_service = TagService(database_service)
        self.image_service = ImageService(parent)
        self.logger = get_logger(__name__)
        
        # 连接图片服务信号
        self.image_service.imageProcessed.connect(self._on_image_processed)
        self.image_service.errorOccurred.connect(self.errorOccurred.emit)
        
        self.logger.info("🏷️ 标签控制器初始化完成")
    
    @pyqtSlot(str, result=str)
    def createTag(self, tag_data_json: str) -> str:
        """
        创建新标签
        
        Args:
            tag_data_json: 标签数据的JSON字符串
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            # 解析标签数据
            tag_data = json.loads(tag_data_json)
            
            # 验证必要字段
            if not tag_data.get('name', '').strip():
                error_msg = "标签名称不能为空"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("create", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
            
            # 调用标签服务创建标签
            tag_model = self.tag_service.create_tag(
                name=tag_data.get('name', '').strip(),
                description=tag_data.get('description', ''),
                color=tag_data.get('color', '#2196F3'),
                icon=tag_data.get('icon', '🏷️')
            )
            
            if tag_model:
                # 转换为字典格式
                tag_dict = tag_model.to_dict()
                
                # 发送成功信号
                self.tagCreated.emit(tag_dict)
                success_msg = f"标签 '{tag_model.name}' 创建成功"
                self.operationCompleted.emit("create", True, success_msg)
                
                self.logger.info(f"标签创建成功: {tag_model.name}")
                
                return json.dumps({
                    "success": True, 
                    "message": success_msg,
                    "tag": tag_dict
                })
            else:
                error_msg = "标签创建失败，可能名称已存在"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("create", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
                
        except json.JSONDecodeError:
            error_msg = "标签数据格式错误"
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("create", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
        except Exception as e:
            error_msg = f"创建标签时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("create", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(int, str, result=str)
    def updateTag(self, tag_id: int, tag_data_json: str) -> str:
        """
        更新标签
        
        Args:
            tag_id: 标签ID
            tag_data_json: 更新数据的JSON字符串
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            # 解析更新数据
            update_data = json.loads(tag_data_json)
            
            # 调用标签服务更新标签
            success = self.tag_service.update_tag(tag_id, update_data)
            
            if success:
                # 获取更新后的标签
                updated_tag = self.tag_service.get_tag_by_id(tag_id)
                if updated_tag:
                    tag_dict = updated_tag.to_dict()
                    self.tagUpdated.emit(tag_dict)
                    success_msg = f"标签更新成功"
                    self.operationCompleted.emit("update", True, success_msg)
                    
                    return json.dumps({
                        "success": True,
                        "message": success_msg,
                        "tag": tag_dict
                    })
            
            error_msg = "标签更新失败"
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("update", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
            
        except Exception as e:
            error_msg = f"更新标签时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("update", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(int, result=str)
    def deleteTag(self, tag_id: int) -> str:
        """
        删除标签
        
        Args:
            tag_id: 标签ID
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            # 调用标签服务删除标签
            success = self.tag_service.delete_tag(tag_id)
            
            if success:
                self.tagDeleted.emit(tag_id)
                success_msg = "标签删除成功"
                self.operationCompleted.emit("delete", True, success_msg)
                
                return json.dumps({
                    "success": True,
                    "message": success_msg
                })
            else:
                error_msg = "标签删除失败，可能正在被使用"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("delete", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
                
        except Exception as e:
            error_msg = f"删除标签时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("delete", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(result=str)
    def getAllTags(self) -> str:
        """
        获取所有标签
        
        Returns:
            标签列表的JSON字符串
        """
        try:
            # 调用标签服务获取所有标签
            tags = self.tag_service.get_all_tags()
            
            # 转换为字典列表
            tag_list = [tag.to_dict() for tag in tags]
            
            # 发送刷新信号
            self.tagListRefreshed.emit(tag_list)
            
            return json.dumps({
                "success": True,
                "tags": tag_list,
                "count": len(tag_list)
            })
            
        except Exception as e:
            error_msg = f"获取标签列表时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            return json.dumps({"success": False, "message": error_msg, "tags": []})
    
    @pyqtSlot(str, result=str)
    def searchTags(self, keyword: str) -> str:
        """
        搜索标签
        
        Args:
            keyword: 搜索关键词
            
        Returns:
            搜索结果的JSON字符串
        """
        try:
            # 调用标签服务搜索标签
            tags = self.tag_service.search_tags(keyword)
            
            # 转换为字典列表
            tag_list = [tag.to_dict() for tag in tags]
            
            return json.dumps({
                "success": True,
                "tags": tag_list,
                "count": len(tag_list),
                "keyword": keyword
            })
            
        except Exception as e:
            error_msg = f"搜索标签时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            return json.dumps({"success": False, "message": error_msg, "tags": []})
    
    @pyqtSlot(str, result=str)
    def batchDeleteTags(self, tag_ids_json: str) -> str:
        """
        批量删除标签
        
        Args:
            tag_ids_json: 标签ID列表的JSON字符串
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            tag_ids = json.loads(tag_ids_json)
            
            # 调用标签服务批量删除
            success_count = self.tag_service.batch_delete_tags(tag_ids)
            
            if success_count > 0:
                success_msg = f"成功删除 {success_count} 个标签"
                self.operationCompleted.emit("batch_delete", True, success_msg)
                
                return json.dumps({
                    "success": True,
                    "message": success_msg,
                    "deleted_count": success_count
                })
            else:
                error_msg = "批量删除失败"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("batch_delete", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
                
        except Exception as e:
            error_msg = f"批量删除标签时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("batch_delete", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(str, str, result=str)
    def uploadTagIcon(self, image_path: str, tag_name: str) -> str:
        """
        上传标签图标
        
        Args:
            image_path: 图片文件路径
            tag_name: 标签名称（用于生成文件名）
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            # 验证图片
            validation = self.image_service.validate_image(image_path)
            if not validation["valid"]:
                error_msg = f"图片验证失败: {validation['error']}"
                self.errorOccurred.emit(error_msg)
                return json.dumps({"success": False, "message": error_msg})
            
            # 处理图片
            result = self.image_service.process_icon_image(image_path, tag_name)
            if result:
                success_msg = "图标上传成功"
                self.operationCompleted.emit("upload_icon", True, success_msg)
                
                return json.dumps({
                    "success": True,
                    "message": success_msg,
                    "icon_path": result["relative_path"],
                    "icon_url": self.image_service.get_icon_url(result["relative_path"]),
                    "processed_info": result["processed_info"]
                })
            else:
                error_msg = "图标处理失败"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("upload_icon", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
                
        except Exception as e:
            error_msg = f"上传图标时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("upload_icon", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(str, result=str)
    def validateImage(self, image_path: str) -> str:
        """
        验证图片文件
        
        Args:
            image_path: 图片文件路径
            
        Returns:
            验证结果的JSON字符串
        """
        try:
            validation = self.image_service.validate_image(image_path)
            return json.dumps(validation)
        except Exception as e:
            error_msg = f"验证图片时发生错误: {str(e)}"
            self.logger.error(error_msg)
            return json.dumps({"valid": False, "error": error_msg})
    
    @pyqtSlot(str, result=str)
    def deleteTagIcon(self, icon_path: str) -> str:
        """
        删除标签图标文件
        
        Args:
            icon_path: 图标路径
            
        Returns:
            操作结果的JSON字符串
        """
        try:
            success = self.image_service.delete_icon(icon_path)
            if success:
                success_msg = "图标删除成功"
                self.operationCompleted.emit("delete_icon", True, success_msg)
                return json.dumps({"success": True, "message": success_msg})
            else:
                error_msg = "图标删除失败"
                self.errorOccurred.emit(error_msg)
                self.operationCompleted.emit("delete_icon", False, error_msg)
                return json.dumps({"success": False, "message": error_msg})
                
        except Exception as e:
            error_msg = f"删除图标时发生错误: {str(e)}"
            self.logger.error(error_msg)
            self.errorOccurred.emit(error_msg)
            self.operationCompleted.emit("delete_icon", False, error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    @pyqtSlot(result=str)
    def getImageStorageInfo(self) -> str:
        """
        获取图片存储信息
        
        Returns:
            存储信息的JSON字符串
        """
        try:
            info = self.image_service.get_storage_info()
            return json.dumps({"success": True, "info": info})
        except Exception as e:
            error_msg = f"获取存储信息时发生错误: {str(e)}"
            self.logger.error(error_msg)
            return json.dumps({"success": False, "message": error_msg})
    
    def _on_image_processed(self, image_path: str, result: dict):
        """图片处理完成回调"""
        self.imageUploaded.emit(image_path, result)
    
    @staticmethod
    def register_qml_type():
        """注册QML类型"""
        qmlRegisterType(TagController, "TagController", 1, 0, "TagController")
