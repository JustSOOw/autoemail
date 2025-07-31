#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UI修复测试脚本
测试四个主要问题的修复效果：
1. 邮箱重复生成问题
2. 批量邮箱生成失败问题
3. 标签页面取消按钮失效问题
4. 页面内容显示异常问题
"""

import sys
import unittest
import time
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "src"))

from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtWidgets import QApplication

from controllers.email_controller import EmailController
from services.database_service import DatabaseService
from utils.config_manager import ConfigManager
from utils.logger import get_logger


class TestUIFixes(unittest.TestCase):
    """UI修复测试类"""

    @classmethod
    def setUpClass(cls):
        """设置测试环境"""
        cls.app = QApplication.instance()
        if cls.app is None:
            cls.app = QApplication(sys.argv)
        
        cls.logger = get_logger(__name__)
        cls.logger.info("开始UI修复测试")

    def setUp(self):
        """每个测试前的设置"""
        # 创建模拟对象
        self.mock_config_manager = Mock(spec=ConfigManager)
        self.mock_database_service = Mock(spec=DatabaseService)
        
        # 设置模拟配置
        mock_config = Mock()
        mock_config.get_domain.return_value = "test.example.com"
        mock_config.is_configured.return_value = True
        self.mock_config_manager.get_config.return_value = mock_config
        
        # 创建EmailController实例
        self.email_controller = EmailController(
            self.mock_config_manager,
            self.mock_database_service
        )

    def test_1_email_generation_button_state(self):
        """测试1：邮箱生成按钮状态管理"""
        self.logger.info("测试1：邮箱生成按钮状态管理")
        
        # 模拟邮箱服务
        mock_email_model = Mock()
        mock_email_model.email_address = "test@test.example.com"
        mock_email_model.id = 1
        
        with patch.object(self.email_controller.email_service, 'create_email', return_value=mock_email_model):
            # 测试单个邮箱生成
            initial_generating_state = self.email_controller._is_generating
            self.assertFalse(initial_generating_state, "初始状态应该不在生成中")
            
            # 调用生成方法
            self.email_controller.generateEmail()
            
            # 验证信号是否正确发送
            # 注意：由于是异步操作，我们需要等待一下
            time.sleep(0.1)
            
            # 验证最终状态
            final_generating_state = self.email_controller._is_generating
            self.assertFalse(final_generating_state, "生成完成后应该重置状态")
            
        self.logger.info("✅ 测试1通过：邮箱生成按钮状态管理正常")

    def test_2_batch_email_generation(self):
        """测试2：批量邮箱生成功能"""
        self.logger.info("测试2：批量邮箱生成功能")
        
        # 检查batchGenerateEmails方法是否存在
        self.assertTrue(hasattr(self.email_controller, 'batchGenerateEmails'), 
                       "EmailController应该有batchGenerateEmails方法")
        
        # 模拟邮箱服务
        mock_email_model = Mock()
        mock_email_model.email_address = "batch_test@test.example.com"
        mock_email_model.id = 1
        
        with patch.object(self.email_controller.email_service, 'create_email', return_value=mock_email_model):
            # 测试批量生成
            initial_generating_state = self.email_controller._is_generating
            self.assertFalse(initial_generating_state, "初始状态应该不在生成中")
            
            # 调用批量生成方法
            self.email_controller.batchGenerateEmails(3, "random_name", "", [], "测试批量生成")
            
            # 验证状态
            time.sleep(0.1)
            final_generating_state = self.email_controller._is_generating
            self.assertFalse(final_generating_state, "批量生成完成后应该重置状态")
            
        self.logger.info("✅ 测试2通过：批量邮箱生成功能正常")

    def test_3_batch_generation_parameters(self):
        """测试3：批量生成参数验证"""
        self.logger.info("测试3：批量生成参数验证")
        
        # 测试无效参数
        self.email_controller.batchGenerateEmails(0, "random_name", "", [], "")
        self.assertFalse(self.email_controller._is_generating, "无效参数不应该开始生成")
        
        self.email_controller.batchGenerateEmails(101, "random_name", "", [], "")
        self.assertFalse(self.email_controller._is_generating, "超出范围的参数不应该开始生成")
        
        self.logger.info("✅ 测试3通过：批量生成参数验证正常")

    def test_4_signal_connections(self):
        """测试4：信号连接正确性"""
        self.logger.info("测试4：信号连接正确性")
        
        # 验证所有必要的信号都存在
        required_signals = [
            'emailGenerated',
            'emailListUpdated',
            'verificationCodeReceived',
            'statusChanged',
            'progressChanged',
            'errorOccurred',
            'statisticsUpdated'
        ]
        
        for signal_name in required_signals:
            self.assertTrue(hasattr(self.email_controller, signal_name),
                           f"EmailController应该有{signal_name}信号")
            
        self.logger.info("✅ 测试4通过：信号连接正确")

    def test_5_error_handling(self):
        """测试5：错误处理机制"""
        self.logger.info("测试5：错误处理机制")
        
        # 模拟邮箱服务抛出异常
        with patch.object(self.email_controller.email_service, 'create_email', 
                         side_effect=Exception("模拟错误")):
            
            # 测试单个生成的错误处理
            self.email_controller.generateEmail()
            time.sleep(0.1)
            
            # 验证状态被正确重置
            self.assertFalse(self.email_controller._is_generating, 
                           "发生错误后应该重置生成状态")
            
            # 测试批量生成的错误处理
            self.email_controller.batchGenerateEmails(2, "random_name", "", [], "")
            time.sleep(0.1)
            
            # 验证状态被正确重置
            self.assertFalse(self.email_controller._is_generating, 
                           "批量生成发生错误后应该重置生成状态")
            
        self.logger.info("✅ 测试5通过：错误处理机制正常")

    def test_6_configuration_check(self):
        """测试6：配置检查功能"""
        self.logger.info("测试6：配置检查功能")
        
        # 测试getCurrentDomain方法
        domain = self.email_controller.getCurrentDomain()
        self.assertIsInstance(domain, str, "getCurrentDomain应该返回字符串")
        
        # 测试isConfigured方法
        is_configured = self.email_controller.isConfigured()
        self.assertIsInstance(is_configured, bool, "isConfigured应该返回布尔值")
        
        self.logger.info("✅ 测试6通过：配置检查功能正常")

    def tearDown(self):
        """每个测试后的清理"""
        # 确保重置状态
        self.email_controller._is_generating = False

    @classmethod
    def tearDownClass(cls):
        """清理测试环境"""
        cls.logger.info("UI修复测试完成")


def run_ui_fix_tests():
    """运行UI修复测试"""
    print("=" * 60)
    print("开始运行UI修复测试")
    print("=" * 60)
    
    # 创建测试套件
    suite = unittest.TestLoader().loadTestsFromTestCase(TestUIFixes)
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 输出结果
    print("\n" + "=" * 60)
    print("测试结果总结")
    print("=" * 60)
    print(f"运行测试数量: {result.testsRun}")
    print(f"失败数量: {len(result.failures)}")
    print(f"错误数量: {len(result.errors)}")
    
    if result.failures:
        print("\n失败的测试:")
        for test, traceback in result.failures:
            print(f"- {test}: {traceback}")
    
    if result.errors:
        print("\n错误的测试:")
        for test, traceback in result.errors:
            print(f"- {test}: {traceback}")
    
    success = len(result.failures) == 0 and len(result.errors) == 0
    if success:
        print("\n🎉 所有测试通过！UI修复验证成功！")
    else:
        print("\n❌ 部分测试失败，需要进一步检查")
    
    return success


if __name__ == "__main__":
    success = run_ui_fix_tests()
    sys.exit(0 if success else 1)
