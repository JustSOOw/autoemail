"""
标签管理页面修复验证测试

验证6个核心问题的修复情况：
1. 标签创建后显示异常
2. 标签创建功能失效
3. 输入框文字提示优化
4. 颜色和图标输入格式优化
5. 筛选功能重构
6. 页面布局整体优化
"""

import unittest
import os
import sys
import json
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "src"))

from controllers.tag_controller import TagController
from services.database_service import DatabaseService
from models.tag_model import TagModel, create_tag_model


class TestTagManagementFixes(unittest.TestCase):
    """标签管理页面修复验证测试类"""
    
    def setUp(self):
        """测试前准备"""
        # 创建临时数据库
        self.db_service = DatabaseService(":memory:")
        self.tag_controller = TagController(self.db_service)
        
        # 初始化数据库表
        self.db_service.init_database()
        
        print(f"\n{'='*60}")
        print(f"开始测试: {self._testMethodName}")
        print(f"{'='*60}")
    
    def tearDown(self):
        """测试后清理"""
        print(f"测试完成: {self._testMethodName}")
        print(f"{'='*60}\n")
    
    def test_1_tag_controller_integration(self):
        """测试1：TagController集成验证"""
        print("测试1：验证TagController是否正确集成")
        
        # 验证TagController实例化
        self.assertIsNotNone(self.tag_controller)
        self.assertIsNotNone(self.tag_controller.tag_service)
        
        # 验证数据库连接
        connection = self.db_service.get_connection()
        self.assertIsNotNone(connection)
        
        print("✅ TagController集成正确")
    
    def test_2_tag_creation_backend(self):
        """测试2：标签创建后端功能验证"""
        print("测试2：验证标签创建后端功能")
        
        # 准备测试数据
        tag_data = {
            "name": "测试标签",
            "description": "这是一个测试标签",
            "color": "#FF5722",
            "icon": "🧪"
        }
        
        # 调用创建标签接口
        result_json = self.tag_controller.createTag(json.dumps(tag_data))
        result = json.loads(result_json)
        
        # 验证创建结果
        self.assertTrue(result["success"])
        self.assertIn("tag", result)
        self.assertEqual(result["tag"]["name"], "测试标签")
        self.assertEqual(result["tag"]["color"], "#FF5722")
        self.assertEqual(result["tag"]["icon"], "🧪")
        
        print("✅ 标签创建后端功能正常")
    
    def test_3_tag_display_consistency(self):
        """测试3：标签显示一致性验证"""
        print("测试3：验证标签显示一致性")
        
        # 创建多个不同的标签
        test_tags = [
            {"name": "工作", "color": "#2196F3", "icon": "💼"},
            {"name": "个人", "color": "#4CAF50", "icon": "👤"},
            {"name": "测试", "color": "#FF9800", "icon": "🧪"}
        ]
        
        created_tags = []
        for tag_data in test_tags:
            result_json = self.tag_controller.createTag(json.dumps(tag_data))
            result = json.loads(result_json)
            self.assertTrue(result["success"])
            created_tags.append(result["tag"])
        
        # 获取所有标签
        all_tags_json = self.tag_controller.getAllTags()
        all_tags_result = json.loads(all_tags_json)
        
        self.assertTrue(all_tags_result["success"])
        # 可能包含系统预定义标签，所以至少应该有3个
        self.assertGreaterEqual(len(all_tags_result["tags"]), 3)
        
        # 验证创建的标签都在结果中
        created_tag_names = [tag["name"] for tag in all_tags_result["tags"]]
        for expected in test_tags:
            self.assertIn(expected["name"], created_tag_names)

        # 验证每个创建的标签的图标和颜色都正确保存
        for tag in all_tags_result["tags"]:
            if tag["name"] in [t["name"] for t in test_tags]:
                expected = next(t for t in test_tags if t["name"] == tag["name"])
                self.assertEqual(tag["color"], expected["color"])
                self.assertEqual(tag["icon"], expected["icon"])
        
        print("✅ 标签显示一致性正常")
    
    def test_4_search_functionality(self):
        """测试4：搜索筛选功能验证"""
        print("测试4：验证搜索筛选功能")
        
        # 创建测试标签
        test_tags = [
            {"name": "工作邮箱", "description": "用于工作相关", "color": "#2196F3", "icon": "💼"},
            {"name": "个人邮箱", "description": "个人使用", "color": "#4CAF50", "icon": "👤"},
            {"name": "测试邮箱", "description": "测试用途", "color": "#FF9800", "icon": "🧪"}
        ]
        
        for tag_data in test_tags:
            result_json = self.tag_controller.createTag(json.dumps(tag_data))
            result = json.loads(result_json)
            self.assertTrue(result["success"])
        
        # 测试按名称搜索
        search_result_json = self.tag_controller.searchTags("工作")
        search_result = json.loads(search_result_json)
        
        self.assertTrue(search_result["success"])
        self.assertEqual(len(search_result["tags"]), 1)
        self.assertEqual(search_result["tags"][0]["name"], "工作邮箱")
        
        # 测试按描述搜索
        search_result_json = self.tag_controller.searchTags("个人")
        search_result = json.loads(search_result_json)
        
        self.assertTrue(search_result["success"])
        self.assertEqual(len(search_result["tags"]), 1)
        self.assertEqual(search_result["tags"][0]["name"], "个人邮箱")
        
        print("✅ 搜索筛选功能正常")
    
    def test_5_input_validation(self):
        """测试5：输入验证功能"""
        print("测试5：验证输入验证功能")
        
        # 测试空名称
        empty_name_data = {"name": "", "color": "#2196F3", "icon": "🏷️"}
        result_json = self.tag_controller.createTag(json.dumps(empty_name_data))
        result = json.loads(result_json)
        
        self.assertFalse(result["success"])
        self.assertIn("不能为空", result["message"])
        
        # 测试重复名称
        valid_data = {"name": "重复测试", "color": "#2196F3", "icon": "🏷️"}
        result_json = self.tag_controller.createTag(json.dumps(valid_data))
        result = json.loads(result_json)
        self.assertTrue(result["success"])
        
        # 再次创建相同名称
        result_json = self.tag_controller.createTag(json.dumps(valid_data))
        result = json.loads(result_json)
        self.assertFalse(result["success"])
        self.assertIn("已存在", result["message"])
        
        print("✅ 输入验证功能正常")
    
    def test_6_qml_files_structure(self):
        """测试6：QML文件结构验证"""
        print("测试6：验证QML文件结构")
        
        # 检查主要QML文件是否存在
        qml_files = [
            "src/views/qml/main.qml",
            "src/views/qml/pages/TagManagementPage.qml"
        ]
        
        for qml_file in qml_files:
            file_path = project_root / qml_file
            self.assertTrue(file_path.exists(), f"QML文件不存在: {qml_file}")
        
        # 检查TagManagementPage.qml的关键功能
        tag_page_path = project_root / "src/views/qml/pages/TagManagementPage.qml"
        with open(tag_page_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 验证响应式设计属性
        responsive_features = [
            "property bool isMobile",
            "property bool isTablet", 
            "property bool isDesktop"
        ]
        
        for feature in responsive_features:
            self.assertIn(feature, content, f"缺少响应式设计功能: {feature}")
        
        # 验证筛选功能
        filter_features = [
            "property var filteredTagList",
            "property bool isFiltered",
            "function performSearch",
            "function clearSearch"
        ]
        
        for feature in filter_features:
            self.assertIn(feature, content, f"缺少筛选功能: {feature}")
        
        print("✅ QML文件结构正确")
    
    def test_7_main_qml_integration(self):
        """测试7：main.qml集成验证"""
        print("测试7：验证main.qml集成")
        
        main_qml_path = project_root / "src/views/qml/main.qml"
        with open(main_qml_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 验证TagController集成
        integration_features = [
            "tagController",
            "onCreateTag: function(tagData)",
            "tagController.createTag",
            "tagController.getAllTags",
            "tagController.searchTags"
        ]
        
        for feature in integration_features:
            self.assertIn(feature, content, f"缺少集成功能: {feature}")
        
        # 验证信号连接
        signal_connections = [
            "Connections",
            "target: tagController",
            "onTagCreated",
            "onTagUpdated",
            "onTagDeleted"
        ]
        
        for connection in signal_connections:
            self.assertIn(connection, content, f"缺少信号连接: {connection}")
        
        print("✅ main.qml集成正确")


def run_tests():
    """运行所有测试"""
    print("🧪 开始标签管理页面修复验证测试")
    print("="*80)
    
    # 创建测试套件
    suite = unittest.TestLoader().loadTestsFromTestCase(TestTagManagementFixes)
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 输出测试结果
    print("\n" + "="*80)
    if result.wasSuccessful():
        print("🎉 所有测试通过！标签管理页面修复验证成功！")
    else:
        print("❌ 部分测试失败，请检查修复内容")
        for failure in result.failures:
            print(f"失败: {failure[0]}")
            print(f"原因: {failure[1]}")
        for error in result.errors:
            print(f"错误: {error[0]}")
            print(f"原因: {error[1]}")
    
    print("="*80)
    return result.wasSuccessful()


if __name__ == "__main__":
    run_tests()
