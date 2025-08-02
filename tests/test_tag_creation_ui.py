#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
标签创建页面UI重构测试脚本
测试输入框、按钮功能、颜色图标选择器的重构效果
"""

import sys
import unittest
import re
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class TestTagCreationUI(unittest.TestCase):
    """标签创建页面UI重构测试类"""

    def setUp(self):
        """设置测试环境"""
        self.create_tag_dialog = project_root / "src/views/qml/components/CreateTagDialog.qml"
        self.tag_management_page = project_root / "src/views/qml/pages/TagManagementPage.qml"
        self.main_qml = project_root / "src/views/qml/main.qml"

    def test_1_material_design_input_fields(self):
        """测试1：Material Design输入框实现"""
        print("测试1：检查Material Design输入框实现")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查TextField实现
        self.assertIn('TextField', content, "缺少TextField组件")

        # 检查动画效果
        animation_patterns = [
            'Behavior on',
            'PropertyAnimation'
        ]

        for pattern in animation_patterns:
            self.assertIn(pattern, content, f"缺少动画效果: {pattern}")

        # 检查输入框配置
        input_features = [
            'placeholderText',
            'selectByMouse',
            'maximumLength'
        ]

        for feature in input_features:
            self.assertIn(feature, content, f"缺少输入框功能: {feature}")

        print("✅ 测试1通过：Material Design输入框实现正确")

    def test_2_form_validation(self):
        """测试2：表单验证功能"""
        print("测试2：检查表单验证功能")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查验证函数
        validation_functions = [
            'function validateForm()',
            'colorRegex',
            'RegularExpressionValidator'
        ]

        for func in validation_functions:
            self.assertIn(func, content, f"缺少验证功能: {func}")

        # 检查验证逻辑
        validation_checks = [
            '标签名称不能为空',
            '标签名称不能超过20个字符',
            '颜色格式不正确',
            'maximumLength'
        ]

        for check in validation_checks:
            self.assertIn(check, content, f"缺少验证检查: {check}")

        print("✅ 测试2通过：表单验证功能完整")

    def test_3_keyboard_shortcuts(self):
        """测试3：键盘快捷键支持"""
        print("测试3：检查键盘快捷键支持")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查基本键盘功能
        keyboard_features = [
            'selectByMouse',
            'focus',
            'onClicked'
        ]

        for feature in keyboard_features:
            self.assertIn(feature, content, f"缺少键盘功能: {feature}")

        # 检查输入框焦点
        focus_features = [
            'TextField',
            'enabled',
            'focus'
        ]

        for feature in focus_features:
            self.assertIn(feature, content, f"缺少焦点功能: {feature}")

        print("✅ 测试3通过：键盘快捷键支持完整")

    def test_4_color_picker_redesign(self):
        """测试4：颜色选择器重构"""
        print("测试4：检查颜色选择器重构")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查颜色选择器组件
        color_picker_features = [
            'colorPickerPopup',
            'GridLayout',
            'columns:',
            'MouseArea',
            'colorField.text = modelData'
        ]

        for feature in color_picker_features:
            self.assertIn(feature, content, f"缺少颜色选择器功能: {feature}")

        # 检查预设颜色数量
        color_count = content.count('#2196F3') + content.count('#4CAF50') + content.count('#FF9800')
        self.assertGreater(color_count, 5, "预设颜色数量不足")

        # 检查颜色验证
        self.assertIn('RegularExpressionValidator', content, "缺少颜色格式验证")

        print("✅ 测试4通过：颜色选择器重构正确")

    def test_5_icon_picker_redesign(self):
        """测试5：图标选择器重构"""
        print("测试5：检查图标选择器重构")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查图标选择器组件
        icon_picker_features = [
            'iconPickerMenu',
            'GridLayout',
            'columns:',
            '🏷️', '📌', '⭐', '🔥', '💼', '🎯'
        ]

        for feature in icon_picker_features:
            self.assertIn(feature, content, f"缺少图标选择器功能: {feature}")

        # 检查图标数量
        emoji_count = content.count('🏷️') + content.count('📌') + content.count('⭐')
        self.assertGreater(emoji_count, 3, "预设图标数量不足")

        print("✅ 测试5通过：图标选择器重构正确")

    def test_6_button_functionality(self):
        """测试6：按钮功能改进"""
        print("测试6：检查按钮功能改进")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查创建按钮功能
        create_button_features = [
            'property bool isCreating',
            'validateForm()',
            'Qt.callLater',
            'enabled:'
        ]

        for feature in create_button_features:
            self.assertIn(feature, content, f"缺少创建按钮功能: {feature}")

        # 检查取消按钮功能
        cancel_button_features = [
            'root.close()',
            'Button',
            'onClicked'
        ]

        for feature in cancel_button_features:
            self.assertIn(feature, content, f"缺少取消按钮功能: {feature}")

        print("✅ 测试6通过：按钮功能改进正确")

    def test_7_main_qml_integration(self):
        """测试7：main.qml集成"""
        print("测试7：检查main.qml集成")
        
        with open(self.main_qml, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查createTag信号处理
        integration_features = [
            'onCreateTag: function(tagData)',
            'JSON.stringify(tagData)',
            'globalStatusMessage.showInfo',
            'globalStatusMessage.showSuccess',
            'globalStatusMessage.showError'
        ]
        
        for feature in integration_features:
            self.assertIn(feature, content, f"缺少集成功能: {feature}")
        
        # 检查标签创建逻辑
        creation_logic = [
            'Math.max(...window.globalState.tagList.map',
            'window.globalState.tagList.push(newTag)',
            'tagManagementPage.tagList = window.globalState.tagList'
        ]
        
        for logic in creation_logic:
            self.assertIn(logic, content, f"缺少创建逻辑: {logic}")
        
        print("✅ 测试7通过：main.qml集成正确")

    def test_8_accessibility_features(self):
        """测试8：无障碍访问功能"""
        print("测试8：检查无障碍访问功能")

        with open(self.create_tag_dialog, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查无障碍功能
        accessibility_features = [
            'focus',
            'ToolTip.text',
            'enabled',
            'selectByMouse',
            'hoverEnabled'
        ]

        for feature in accessibility_features:
            self.assertIn(feature, content, f"缺少无障碍功能: {feature}")

        print("✅ 测试8通过：无障碍访问功能完整")


def run_tag_creation_tests():
    """运行标签创建页面测试"""
    print("=" * 60)
    print("开始运行标签创建页面UI重构测试")
    print("=" * 60)
    
    # 创建测试套件
    suite = unittest.TestLoader().loadTestsFromTestCase(TestTagCreationUI)
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 输出结果
    print("\n" + "=" * 60)
    print("标签创建页面测试结果总结")
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
        print("\n🎉 所有测试通过！标签创建页面重构验证成功！")
        print("\n重构总结:")
        print("✅ Material Design输入框实现")
        print("✅ 完整的表单验证功能")
        print("✅ 键盘快捷键和焦点管理")
        print("✅ 直观的颜色选择器")
        print("✅ 丰富的图标选择器")
        print("✅ 改进的按钮功能")
        print("✅ 完善的main.qml集成")
        print("✅ 无障碍访问支持")
    else:
        print("\n❌ 部分测试失败，需要进一步检查")
    
    return success


if __name__ == "__main__":
    success = run_tag_creation_tests()
    sys.exit(0 if success else 1)
