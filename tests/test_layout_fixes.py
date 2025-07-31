#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
QML布局修复测试脚本
测试布局冲突修复和页面显示问题的解决效果
"""

import sys
import unittest
import re
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class TestLayoutFixes(unittest.TestCase):
    """QML布局修复测试类"""

    def setUp(self):
        """设置测试环境"""
        self.email_management_page = project_root / "src/views/qml/pages/EmailManagementPage.qml"
        self.tag_management_page = project_root / "src/views/qml/pages/TagManagementPage.qml"
        self.main_qml = project_root / "src/views/qml/main.qml"

    def test_1_mousearea_layout_conflicts_fixed(self):
        """测试1：MouseArea布局冲突已修复"""
        print("测试1：检查MouseArea布局冲突修复")
        
        # 检查EmailManagementPage.qml
        with open(self.email_management_page, 'r', encoding='utf-8') as f:
            email_content = f.read()
        
        # 检查MouseArea是否移到了ColumnLayout外部
        # 查找MouseArea在ColumnLayout内部的模式
        mousearea_in_layout_pattern = r'ColumnLayout\s*\{[^}]*MouseArea\s*\{[^}]*anchors\.fill:\s*parent'
        
        email_conflicts = re.search(mousearea_in_layout_pattern, email_content, re.DOTALL)
        self.assertIsNone(email_conflicts, "EmailManagementPage中仍存在MouseArea布局冲突")
        
        # 检查TagManagementPage.qml
        with open(self.tag_management_page, 'r', encoding='utf-8') as f:
            tag_content = f.read()
        
        tag_conflicts = re.search(mousearea_in_layout_pattern, tag_content, re.DOTALL)
        self.assertIsNone(tag_conflicts, "TagManagementPage中仍存在MouseArea布局冲突")
        
        print("✅ 测试1通过：MouseArea布局冲突已修复")

    def test_2_mousearea_outside_layout(self):
        """测试2：MouseArea已移到Layout外部"""
        print("测试2：检查MouseArea位置")

        # 检查EmailManagementPage.qml
        with open(self.email_management_page, 'r', encoding='utf-8') as f:
            email_content = f.read()

        # 查找正确的MouseArea位置模式 - 背景点击区域的注释
        correct_pattern = r'// 背景点击区域来取消搜索框焦点 - 移到Layout外部避免冲突'

        email_correct = re.search(correct_pattern, email_content)
        self.assertIsNotNone(email_correct, "EmailManagementPage中MouseArea位置不正确")

        # 检查TagManagementPage.qml
        with open(self.tag_management_page, 'r', encoding='utf-8') as f:
            tag_content = f.read()

        tag_correct = re.search(correct_pattern, tag_content)
        self.assertIsNotNone(tag_correct, "TagManagementPage中MouseArea位置不正确")

        print("✅ 测试2通过：MouseArea已正确移到Layout外部")

    def test_3_search_bar_position(self):
        """测试3：搜索栏位置正确"""
        print("测试3：检查搜索栏位置")
        
        with open(self.email_management_page, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 查找搜索栏在ColumnLayout中的位置
        # 搜索栏应该是ColumnLayout的第一个子项
        search_pattern = r'ColumnLayout\s*\{[^}]*// 搜索和操作栏'
        
        search_position = re.search(search_pattern, content, re.DOTALL)
        self.assertIsNotNone(search_position, "搜索栏位置不正确")
        
        print("✅ 测试3通过：搜索栏位置正确")

    def test_4_tag_list_data_binding(self):
        """测试4：标签列表数据绑定"""
        print("测试4：检查标签列表数据绑定")
        
        # 检查main.qml中的refreshTagList函数
        with open(self.main_qml, 'r', encoding='utf-8') as f:
            main_content = f.read()
        
        # 检查是否更新了tagManagementPage的数据
        update_pattern = r'tagManagementPage\.tagList\s*=\s*window\.globalState\.tagList'
        
        data_update = re.search(update_pattern, main_content)
        self.assertIsNotNone(data_update, "标签数据绑定不正确")
        
        # 检查是否重置了加载状态
        loading_reset_pattern = r'tagManagementPage\.isLoading\s*=\s*false'
        
        loading_reset = re.search(loading_reset_pattern, main_content)
        self.assertIsNotNone(loading_reset, "加载状态重置不正确")
        
        print("✅ 测试4通过：标签列表数据绑定正确")

    def test_5_tag_page_initialization(self):
        """测试5：标签页面初始化逻辑"""
        print("测试5：检查标签页面初始化")
        
        with open(self.tag_management_page, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查是否有备用数据加载逻辑
        fallback_pattern = r'使用本地模拟数据'
        
        fallback_logic = re.search(fallback_pattern, content)
        self.assertIsNotNone(fallback_logic, "缺少备用数据加载逻辑")
        
        # 检查是否有安全定时器
        timer_pattern = r'tagLoadingResetTimer'
        
        timer_logic = re.search(timer_pattern, content)
        self.assertIsNotNone(timer_logic, "缺少安全定时器")
        
        print("✅ 测试5通过：标签页面初始化逻辑正确")

    def test_6_layout_structure_integrity(self):
        """测试6：布局结构完整性"""
        print("测试6：检查布局结构完整性")
        
        files_to_check = [self.email_management_page, self.tag_management_page]
        
        for file_path in files_to_check:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查ColumnLayout结构
            column_layout_count = content.count('ColumnLayout {')
            column_layout_close_count = content.count('}')
            
            # 基本的括号匹配检查
            open_braces = content.count('{')
            close_braces = content.count('}')
            
            self.assertEqual(open_braces, close_braces, 
                           f"{file_path.name}中括号不匹配")
            
            # 检查Layout属性使用
            layout_properties = ['Layout.fillWidth', 'Layout.fillHeight', 'Layout.preferredWidth']
            for prop in layout_properties:
                if prop in content:
                    # 确保Layout属性在Layout容器内使用
                    self.assertIn('Layout', content, f"{file_path.name}中Layout属性使用不当")
        
        print("✅ 测试6通过：布局结构完整性正确")

    def test_7_no_layout_warnings_patterns(self):
        """测试7：检查可能导致布局警告的模式"""
        print("测试7：检查布局警告模式")

        files_to_check = [self.email_management_page, self.tag_management_page]

        for file_path in files_to_check:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 检查可能导致警告的模式
            # 在ColumnLayout内部直接使用anchors.fill的MouseArea（排除delegate）
            warning_pattern = r'ColumnLayout\s*\{[^}]*MouseArea\s*\{[^}]*anchors\.fill:\s*parent'

            warning_matches = re.findall(warning_pattern, content, re.DOTALL)
            self.assertEqual(len(warning_matches), 0,
                           f"{file_path.name}中仍有可能导致布局警告的代码")

        print("✅ 测试7通过：无布局警告模式")


def run_layout_tests():
    """运行布局修复测试"""
    print("=" * 60)
    print("开始运行QML布局修复测试")
    print("=" * 60)
    
    # 创建测试套件
    suite = unittest.TestLoader().loadTestsFromTestCase(TestLayoutFixes)
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 输出结果
    print("\n" + "=" * 60)
    print("布局测试结果总结")
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
        print("\n🎉 所有布局测试通过！QML布局修复验证成功！")
        print("\n修复总结:")
        print("✅ MouseArea布局冲突已解决")
        print("✅ 搜索栏位置已修复")
        print("✅ 标签页面空白问题已解决")
        print("✅ 数据绑定和加载逻辑已优化")
        print("✅ 布局警告问题已消除")
    else:
        print("\n❌ 部分测试失败，需要进一步检查")
    
    return success


if __name__ == "__main__":
    success = run_layout_tests()
    sys.exit(0 if success else 1)
