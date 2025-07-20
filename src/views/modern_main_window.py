# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 现代化主窗口 (QML版本)
使用QML创建现代化的用户界面
"""

import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication
from PyQt6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl
from PyQt6.QtQuick import QQuickView

from utils.logger import get_logger
from utils.config_manager import ConfigManager


class EmailController(QObject):
    """邮箱控制器 - 连接QML和Python后端"""
    
    # 信号定义 - QML可以监听这些信号
    emailGenerated = pyqtSignal(str, str)  # email_address, status
    verificationCodeReceived = pyqtSignal(str)  # verification_code
    statusChanged = pyqtSignal(str)  # status_message
    progressChanged = pyqtSignal(int)  # progress_value
    
    def __init__(self, config_manager: ConfigManager, database_service):
        super().__init__()
        self.config_manager = config_manager
        self.database_service = database_service
        self.logger = get_logger(__name__)
    
    @pyqtSlot()
    def generateEmail(self):
        """生成新邮箱 - QML调用的方法"""
        try:
            self.statusChanged.emit("正在生成邮箱...")
            self.progressChanged.emit(25)
            
            # TODO: 实现邮箱生成逻辑
            # 这里是示例代码
            import time
            import random
            
            # 模拟生成过程
            time.sleep(1)
            self.progressChanged.emit(50)
            
            # 生成示例邮箱
            config = self.config_manager.get_config()
            domain = config.get_domain() or "example.com"
            timestamp = str(int(time.time()))[-4:]
            email_address = f"test{timestamp}@{domain}"
            
            self.progressChanged.emit(75)
            time.sleep(0.5)
            
            # 发送成功信号
            self.emailGenerated.emit(email_address, "success")
            self.statusChanged.emit(f"邮箱生成成功: {email_address}")
            self.progressChanged.emit(100)
            
            self.logger.info(f"邮箱生成成功: {email_address}")
            
        except Exception as e:
            self.logger.error(f"邮箱生成失败: {e}")
            self.emailGenerated.emit("", "error")
            self.statusChanged.emit(f"邮箱生成失败: {e}")
            self.progressChanged.emit(0)
    
    @pyqtSlot(str)
    def getVerificationCode(self, email_address: str):
        """获取验证码 - QML调用的方法"""
        try:
            self.statusChanged.emit(f"正在获取 {email_address} 的验证码...")
            
            # TODO: 实现验证码获取逻辑
            import time
            import random
            
            # 模拟获取过程
            time.sleep(2)
            
            # 生成示例验证码
            verification_code = f"{random.randint(100000, 999999)}"
            
            self.verificationCodeReceived.emit(verification_code)
            self.statusChanged.emit(f"验证码获取成功: {verification_code}")
            
            self.logger.info(f"验证码获取成功: {email_address} -> {verification_code}")
            
        except Exception as e:
            self.logger.error(f"验证码获取失败: {e}")
            self.statusChanged.emit(f"验证码获取失败: {e}")
    
    @pyqtSlot(result=str)
    def getCurrentDomain(self):
        """获取当前域名 - QML调用的方法"""
        config = self.config_manager.get_config()
        return config.get_domain() or "未配置"
    
    @pyqtSlot(result=bool)
    def isConfigured(self):
        """检查是否已配置 - QML调用的方法"""
        config = self.config_manager.get_config()
        return config.is_configured()


class ModernMainWindow:
    """现代化QML主窗口类"""

    def __init__(self, config_manager: ConfigManager, database_service):
        self.config_manager = config_manager
        self.database_service = database_service
        self.logger = get_logger(__name__)

        # QML引擎
        self.engine = QQmlApplicationEngine()

        # 控制器
        self.email_controller = EmailController(config_manager, database_service)

        # 注册QML类型
        self.register_qml_types()

        # 设置QML上下文
        self.setup_qml_context()

        # 加载QML文件
        self.load_qml()

        self.logger.info("🎨 现代化QML界面初始化完成")
    
    def register_qml_types(self):
        """注册QML类型"""
        # 注册EmailController到QML
        qmlRegisterType(EmailController, "EmailManager", 1, 0, "EmailController")
    
    def setup_qml_context(self):
        """设置QML上下文"""
        # 将Python对象暴露给QML
        context = self.engine.rootContext()
        context.setContextProperty("emailController", self.email_controller)
        context.setContextProperty("appVersion", "1.0.0")
    
    def load_qml(self):
        """加载QML文件"""
        try:
            # QML文件路径
            qml_file = Path(__file__).parent / "qml" / "main.qml"
            
            if not qml_file.exists():
                self.logger.warning(f"QML文件不存在: {qml_file}")
                # 创建基础QML文件
                self.create_basic_qml()
                
            # 加载QML
            self.engine.load(QUrl.fromLocalFile(str(qml_file)))
            
            # 检查是否加载成功
            if not self.engine.rootObjects():
                self.logger.error("QML文件加载失败")
                raise RuntimeError("QML文件加载失败")
            
            self.logger.info("QML界面加载成功")
            
        except Exception as e:
            self.logger.error(f"加载QML失败: {e}")
            raise
    
    def create_basic_qml(self):
        """创建基础QML文件"""
        qml_dir = Path(__file__).parent / "qml"
        qml_dir.mkdir(exist_ok=True)
        
        qml_content = '''
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "域名邮箱管理器"
    
    // Material Design主题
    Material.theme: Material.Light
    Material.primary: Material.Blue
    Material.accent: Material.Cyan
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        
        // 标签栏
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "🏠 邮箱申请"
                font.pixelSize: 14
            }
            TabButton {
                text: "📋 邮箱管理"
                font.pixelSize: 14
            }
            TabButton {
                text: "⚙️ 配置管理"
                font.pixelSize: 14
            }
        }
        
        // 页面内容
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // 邮箱申请页面
            Rectangle {
                color: "#f5f5f5"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    // 左侧配置信息
                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            
                            Label {
                                text: "📍 当前域名"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            Label {
                                id: domainLabel
                                text: emailController.getCurrentDomain()
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#e0e0e0"
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10
                            }
                            
                            Label {
                                text: "📊 统计信息"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            Label {
                                text: "今日生成: 0"
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Label {
                                text: "成功率: 100%"
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // 中央操作区域
                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20
                            
                            Button {
                                id: generateButton
                                text: "🎯 生成新邮箱"
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 50
                                font.pixelSize: 16
                                Material.background: Material.Blue
                                
                                onClicked: {
                                    generateButton.enabled = false
                                    emailController.generateEmail()
                                }
                            }
                            
                            ProgressBar {
                                id: progressBar
                                Layout.preferredWidth: 200
                                value: 0
                                visible: value > 0
                            }
                            
                            Button {
                                text: "📧 获取验证码"
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 40
                                enabled: false
                                
                                onClicked: {
                                    emailController.getVerificationCode("test@example.com")
                                }
                            }
                        }
                    }
                    
                    // 右侧日志区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            
                            Label {
                                text: "📝 实时日志"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                TextArea {
                                    id: logArea
                                    readOnly: true
                                    wrapMode: TextArea.Wrap
                                    font.family: "Consolas, Monaco, monospace"
                                    font.pixelSize: 12
                                    text: "[12:34:56] 应用程序启动\\n[12:34:57] 等待用户操作..."
                                }
                            }
                        }
                    }
                }
            }
            
            // 邮箱管理页面
            Rectangle {
                color: "#f5f5f5"
                
                Label {
                    anchors.centerIn: parent
                    text: "📋 邮箱管理页面\\n\\n功能开发中..."
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            // 配置管理页面
            Rectangle {
                color: "#f5f5f5"
                
                Label {
                    anchors.centerIn: parent
                    text: "⚙️ 配置管理页面\\n\\n功能开发中..."
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    // 状态栏
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 30
        color: "#f0f0f0"
        border.color: "#e0e0e0"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            
            Label {
                id: statusLabel
                text: "就绪"
                font.pixelSize: 12
            }
            
            Item { Layout.fillWidth: true }
            
            Label {
                text: new Date().toLocaleTimeString()
                font.pixelSize: 12
                color: "#666"
            }
        }
    }
    
    // 连接信号
    Connections {
        target: emailController
        
        function onEmailGenerated(email, status) {
            if (status === "success") {
                logArea.text += "\\n[" + new Date().toLocaleTimeString() + "] 邮箱生成成功: " + email
            } else {
                logArea.text += "\\n[" + new Date().toLocaleTimeString() + "] 邮箱生成失败"
            }
            generateButton.enabled = true
        }
        
        function onStatusChanged(message) {
            statusLabel.text = message
            logArea.text += "\\n[" + new Date().toLocaleTimeString() + "] " + message
        }
        
        function onProgressChanged(value) {
            progressBar.value = value / 100.0
        }
        
        function onVerificationCodeReceived(code) {
            logArea.text += "\\n[" + new Date().toLocaleTimeString() + "] 验证码: " + code
        }
    }
}
'''
        
        qml_file = qml_dir / "main.qml"
        with open(qml_file, 'w', encoding='utf-8') as f:
            f.write(qml_content.strip())
        
        self.logger.info(f"创建基础QML文件: {qml_file}")
    
    def show(self):
        """显示窗口"""
        # QML窗口会自动显示
        pass
    
    def close(self):
        """关闭窗口"""
        if self.engine:
            self.engine.quit()
