"""
导入服务测试用例
测试邮箱数据导入功能的各种场景
"""

import os
import json
import csv
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

# 添加项目根目录到Python路径
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from services.import_service import ImportService
from services.database_service import DatabaseService
from services.batch_service import BatchService


class TestImportService(unittest.TestCase):
    """导入服务测试类"""
    
    def setUp(self):
        """测试前准备"""
        # 创建模拟的数据库服务
        self.mock_db_service = Mock(spec=DatabaseService)
        self.mock_batch_service = Mock(spec=BatchService)
        
        # 创建导入服务实例
        self.import_service = ImportService(
            db_service=self.mock_db_service,
            batch_service=self.mock_batch_service
        )
        
        # 创建临时目录用于测试文件
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        """测试后清理"""
        # 清理临时文件
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_detect_file_format(self):
        """测试文件格式检测"""
        # 测试JSON格式
        self.assertEqual(
            self.import_service._detect_file_format("test.json"),
            "json"
        )
        
        # 测试CSV格式
        self.assertEqual(
            self.import_service._detect_file_format("test.csv"),
            "csv"
        )
        
        # 测试Excel格式
        self.assertEqual(
            self.import_service._detect_file_format("test.xlsx"),
            "xlsx"
        )
        
        # 测试未知格式
        self.assertEqual(
            self.import_service._detect_file_format("test.txt"),
            "unknown"
        )
    
    def test_parse_json_file(self):
        """测试JSON文件解析"""
        # 创建测试JSON文件
        test_data = [
            {
                "email_address": "test1@example.com",
                "tags": ["tag1", "tag2"],
                "notes": "测试邮箱1"
            },
            {
                "email_address": "test2@example.com",
                "tags": ["tag3"],
                "notes": "测试邮箱2"
            }
        ]
        
        json_file = os.path.join(self.temp_dir, "test.json")
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(test_data, f, ensure_ascii=False, indent=2)
        
        # 解析文件
        result = self.import_service._parse_json_file(json_file)
        
        # 验证结果
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["email_address"], "test1@example.com")
        self.assertEqual(result[1]["email_address"], "test2@example.com")
    
    def test_parse_json_file_with_wrapper(self):
        """测试带包装对象的JSON文件解析"""
        # 创建带包装的JSON文件
        test_data = {
            "export_info": {
                "timestamp": "2024-01-01T00:00:00",
                "format": "json"
            },
            "emails": [
                {
                    "email_address": "wrapped1@example.com",
                    "notes": "包装测试1"
                },
                {
                    "email_address": "wrapped2@example.com",
                    "notes": "包装测试2"
                }
            ]
        }
        
        json_file = os.path.join(self.temp_dir, "wrapped.json")
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(test_data, f, ensure_ascii=False, indent=2)
        
        # 解析文件
        result = self.import_service._parse_json_file(json_file)
        
        # 验证结果
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["email_address"], "wrapped1@example.com")
    
    def test_parse_csv_file(self):
        """测试CSV文件解析"""
        # 创建测试CSV文件
        csv_file = os.path.join(self.temp_dir, "test.csv")
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(["email_address", "tags", "notes"])
            writer.writerow(["csv1@example.com", "tag1,tag2", "CSV测试1"])
            writer.writerow(["csv2@example.com", "tag3", "CSV测试2"])
        
        # 解析文件
        result = self.import_service._parse_csv_file(csv_file)
        
        # 验证结果
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["email_address"], "csv1@example.com")
        self.assertEqual(result[1]["email_address"], "csv2@example.com")
    
    def test_validate_and_convert_data(self):
        """测试数据验证和转换"""
        # 准备测试数据
        raw_data = [
            {
                "email_address": "valid@example.com",
                "tags": ["tag1", "tag2"],
                "notes": "有效邮箱",
                "status": "active"
            },
            {
                "email_address": "invalid-email",  # 无效邮箱格式
                "notes": "无效邮箱"
            },
            {
                "email_address": "",  # 空邮箱地址
                "notes": "空邮箱"
            },
            {
                "email_address": "valid2@example.com",
                "tags": "tag3,tag4",  # 字符串格式的标签
                "notes": "标签字符串测试"
            }
        ]
        
        # 验证和转换数据
        result = self.import_service._validate_and_convert_data(
            raw_data,
            validate_emails=True,
            import_tags=True,
            import_metadata=False
        )
        
        # 验证结果
        self.assertEqual(len(result), 2)  # 只有2个有效邮箱
        self.assertEqual(result[0]["email_address"], "valid@example.com")
        self.assertEqual(result[1]["email_address"], "valid2@example.com")
        
        # 验证标签转换
        self.assertEqual(result[1]["tags"], ["tag3", "tag4"])
    
    def test_validate_file_format(self):
        """测试文件格式验证"""
        # 创建有效的JSON文件
        valid_data = [{"email_address": "test@example.com"}]
        valid_file = os.path.join(self.temp_dir, "valid.json")
        with open(valid_file, 'w', encoding='utf-8') as f:
            json.dump(valid_data, f)
        
        # 验证有效文件
        result = self.import_service.validate_file_format(valid_file)
        self.assertTrue(result["valid"])
        self.assertEqual(result["format"], "json")
        
        # 测试不存在的文件
        result = self.import_service.validate_file_format("nonexistent.json")
        self.assertFalse(result["valid"])
        self.assertIn("文件不存在", result["error"])
    
    def test_preview_file(self):
        """测试文件预览功能"""
        # 创建测试文件
        test_data = [
            {"email_address": f"preview{i}@example.com", "notes": f"预览测试{i}"}
            for i in range(15)  # 创建15条记录
        ]
        
        preview_file = os.path.join(self.temp_dir, "preview.json")
        with open(preview_file, 'w', encoding='utf-8') as f:
            json.dump(test_data, f, ensure_ascii=False)
        
        # 预览文件（限制10条）
        result = self.import_service.preview_file(preview_file, limit=10)
        
        # 验证结果
        self.assertTrue(result["success"])
        self.assertEqual(len(result["preview_data"]), 10)
        self.assertEqual(result["total_rows"], 10)  # 因为限制了10条
        self.assertIn("email_address", result["columns"])
    
    def test_import_from_file_success(self):
        """测试成功导入文件"""
        # 创建测试文件
        test_data = [
            {
                "email_address": "import1@example.com",
                "tags": ["import", "test"],
                "notes": "导入测试1"
            },
            {
                "email_address": "import2@example.com",
                "tags": ["import"],
                "notes": "导入测试2"
            }
        ]
        
        import_file = os.path.join(self.temp_dir, "import.json")
        with open(import_file, 'w', encoding='utf-8') as f:
            json.dump(test_data, f, ensure_ascii=False)
        
        # 模拟批量服务返回成功结果
        self.mock_batch_service.batch_import_emails_from_data.return_value = {
            "total": 2,
            "success": 2,
            "failed": 0,
            "skipped": 0,
            "updated": 0,
            "emails": [],
            "errors": []
        }
        
        # 执行导入
        result = self.import_service.import_from_file(
            file_path=import_file,
            format_type="json",
            options={"conflictStrategy": "skip"}
        )
        
        # 验证结果
        self.assertEqual(result["success"], 2)
        self.assertEqual(result["failed"], 0)
        self.assertEqual(result["file_format"], "json")
        
        # 验证批量服务被调用
        self.mock_batch_service.batch_import_emails_from_data.assert_called_once()
    
    def test_import_from_file_with_invalid_file(self):
        """测试导入不存在的文件"""
        result = self.import_service.import_from_file(
            file_path="nonexistent.json",
            format_type="json"
        )
        
        # 验证错误结果
        self.assertEqual(result["success"], 0)
        self.assertEqual(result["failed"], 1)
        self.assertTrue(len(result["errors"]) > 0)
    
    def test_format_file_size(self):
        """测试文件大小格式化"""
        # 测试字节
        self.assertEqual(self.import_service._format_file_size(500), "500 B")
        
        # 测试KB
        self.assertEqual(self.import_service._format_file_size(1536), "1.5 KB")
        
        # 测试MB
        self.assertEqual(self.import_service._format_file_size(2097152), "2.0 MB")
        
        # 测试GB
        self.assertEqual(self.import_service._format_file_size(2147483648), "2.0 GB")


class TestImportServiceIntegration(unittest.TestCase):
    """导入服务集成测试"""
    
    def setUp(self):
        """集成测试准备"""
        # 这里可以设置真实的数据库连接进行集成测试
        # 暂时跳过，因为需要真实的数据库环境
        self.skipTest("集成测试需要真实数据库环境")
    
    def test_full_import_workflow(self):
        """测试完整的导入工作流程"""
        # 这里可以测试完整的导入流程
        # 包括文件解析、数据验证、数据库保存等
        pass


if __name__ == '__main__':
    # 运行测试
    unittest.main(verbosity=2)
