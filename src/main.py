#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 应用程序入口
主要功能：
1. 初始化应用程序
2. 设置日志系统
3. 启动GUI界面
4. 处理异常和退出
"""

import asyncio
import os
import signal
import sys
from pathlib import Path
from typing import Optional

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(Path(__file__).parent))  # 添加src目录

from PyQt6.QtCore import QThread, QTimer, pyqtSignal
from PyQt6.QtGui import QIcon

# PyQt6导入
from PyQt6.QtWidgets import QApplication, QMessageBox

# 异步Qt支持
try:
    import asyncqt
except ImportError:
    print("警告: asyncqt未安装，某些异步功能可能不可用")
    asyncqt = None

# 项目模块导入
try:
    from services.database_service import DatabaseService
    from utils.config_manager import ConfigManager
    from utils.logger import get_logger, setup_logger
    from views.modern_main_window import ModernMainWindow
except ImportError as e:
    print(f"模块导入失败: {e}")
    print("请确保所有依赖已正确安装")
    print("特别需要确保PyQt6完整安装: pip install PyQt6")
    sys.exit(1)


class ApplicationManager:
    """应用程序管理器"""

    def __init__(self):
        self.app: Optional[QApplication] = None
        self.main_window: Optional[ModernMainWindow] = None
        self.logger = None
        self.config_manager: Optional[ConfigManager] = None
        self.database_service: Optional[DatabaseService] = None

    def setup_logging(self) -> bool:
        """设置日志系统"""
        try:
            # 创建日志目录 - 使用用户数据目录
            import tempfile
            app_data_dir = Path(tempfile.gettempdir()) / "EmailDomainManager"
            log_dir = app_data_dir / "logs"
            log_dir.mkdir(parents=True, exist_ok=True)

            # 初始化日志
            setup_logger(
                log_file=log_dir / "app.log",
                level="INFO",
                max_size="10MB",
                backup_count=5,
            )

            self.logger = get_logger(__name__)
            self.logger.info("日志系统初始化完成")
            return True

        except Exception as e:
            print(f"日志系统初始化失败: {e}")
            return False

    def setup_config(self) -> bool:
        """设置配置管理器"""
        try:
            # 使用用户数据目录
            import tempfile
            app_data_dir = Path(tempfile.gettempdir()) / "EmailDomainManager"
            config_dir = app_data_dir / "config"
            config_dir.mkdir(parents=True, exist_ok=True)

            self.config_manager = ConfigManager(config_dir / "app.conf")
            self.logger.info("配置管理器初始化完成")
            return True

        except Exception as e:
            self.logger.error(f"配置管理器初始化失败: {e}")
            return False

    def setup_database(self) -> bool:
        """设置数据库服务"""
        try:
            # 使用用户数据目录
            import tempfile
            app_data_dir = Path(tempfile.gettempdir()) / "EmailDomainManager"
            db_dir = app_data_dir / "data"
            db_dir.mkdir(parents=True, exist_ok=True)

            self.database_service = DatabaseService(db_dir / "email_manager.db")
            self.database_service.init_database()
            self.logger.info("数据库服务初始化完成")
            return True

        except Exception as e:
            self.logger.error(f"数据库服务初始化失败: {e}")
            return False

    def setup_application(self) -> bool:
        """设置Qt应用程序"""
        try:
            # 创建应用程序实例
            self.app = QApplication(sys.argv)

            # 设置应用程序信息
            self.app.setApplicationName("域名邮箱管理器")
            self.app.setApplicationVersion("1.0.0")
            self.app.setOrganizationName("Email Domain Manager Team")

            # 设置应用程序图标
            icon_path = project_root / "src" / "resources" / "icons" / "app.ico"
            if icon_path.exists():
                self.app.setWindowIcon(QIcon(str(icon_path)))

            # 设置样式
            self.app.setStyle("Fusion")  # 使用现代化样式

            self.logger.info("Qt应用程序初始化完成")
            return True

        except Exception as e:
            if self.logger:
                self.logger.error(f"Qt应用程序初始化失败: {e}")
            else:
                print(f"Qt应用程序初始化失败: {e}")
            return False

    def setup_main_window(self) -> bool:
        """设置主窗口"""
        try:
            # 检查QML支持
            if not self._check_qml_support():
                self.show_error_dialog(
                    "QML支持检查失败",
                    "应用程序需要完整的PyQt6支持，包括QML模块。\n\n"
                    "请运行以下命令安装完整版本：\n"
                    "pip install PyQt6\n\n"
                    "如果问题仍然存在，请检查PyQt6安装是否完整。",
                )
                return False

            self.logger.info("🎨 启动现代化QML界面")
            self.main_window = ModernMainWindow(
                config_manager=self.config_manager,
                database_service=self.database_service,
            )

            # 显示主窗口
            self.main_window.show()

            self.logger.info("QML主窗口创建完成")
            return True

        except Exception as e:
            self.logger.error(f"QML主窗口创建失败: {e}")
            self.show_error_dialog("界面创建失败", f"无法创建QML界面：{e}\n\n" "请检查PyQt6是否正确安装。")
            return False

    def _check_qml_support(self) -> bool:
        """检查QML支持"""
        try:
            from PyQt6.QtCore import QUrl
            from PyQt6.QtQml import QQmlApplicationEngine
            from PyQt6.QtQuick import QQuickView

            self.logger.debug("✅ QML模块检查通过")
            return True
        except ImportError as e:
            self.logger.error(f"❌ QML模块不可用: {e}")
            return False

    def setup_signal_handlers(self):
        """设置信号处理器"""

        def signal_handler(signum, frame):
            self.logger.info(f"接收到信号 {signum}，准备退出应用程序")
            self.cleanup_and_exit()

        # 注册信号处理器
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        # 设置定时器处理Ctrl+C
        timer = QTimer()
        timer.start(500)  # 每500ms检查一次
        timer.timeout.connect(lambda: None)  # 允许Python处理信号

    def show_error_dialog(self, title: str, message: str):
        """显示错误对话框"""
        if self.app:
            msg_box = QMessageBox()
            msg_box.setIcon(QMessageBox.Icon.Critical)
            msg_box.setWindowTitle(title)
            msg_box.setText(message)
            msg_box.setStandardButtons(QMessageBox.StandardButton.Ok)
            msg_box.exec()
        else:
            print(f"错误: {title} - {message}")

    def cleanup_and_exit(self, exit_code: int = 0):
        """清理资源并退出"""
        try:
            if self.logger:
                self.logger.info("开始清理应用程序资源")

            # 关闭主窗口
            if self.main_window:
                self.main_window.close()

            # 关闭数据库连接
            if self.database_service:
                self.database_service.close()

            # 退出应用程序
            if self.app:
                self.app.quit()

            if self.logger:
                self.logger.info("应用程序退出完成")

        except Exception as e:
            print(f"清理资源时发生错误: {e}")

        sys.exit(exit_code)

    def run(self) -> int:
        """运行应用程序"""
        try:
            # 1. 设置日志系统
            if not self.setup_logging():
                self.show_error_dialog("初始化错误", "日志系统初始化失败")
                return 1

            self.logger.info("=" * 60)
            self.logger.info("域名邮箱管理器启动")
            self.logger.info("=" * 60)

            # 2. 设置配置管理器
            if not self.setup_config():
                self.show_error_dialog("初始化错误", "配置管理器初始化失败")
                return 1

            # 3. 设置数据库服务
            if not self.setup_database():
                self.show_error_dialog("初始化错误", "数据库服务初始化失败")
                return 1

            # 4. 设置Qt应用程序
            if not self.setup_application():
                self.show_error_dialog("初始化错误", "Qt应用程序初始化失败")
                return 1

            # 5. 设置信号处理器
            self.setup_signal_handlers()

            # 6. 设置主窗口
            if not self.setup_main_window():
                self.show_error_dialog("初始化错误", "主窗口创建失败")
                return 1

            self.logger.info("应用程序初始化完成，开始运行主循环")

            # 7. 运行应用程序主循环
            if asyncqt:
                # 使用异步事件循环
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)

                with asyncqt.QEventLoop(self.app) as event_loop:
                    exit_code = event_loop.run_forever()
            else:
                # 使用标准事件循环
                exit_code = self.app.exec()

            self.logger.info(f"应用程序主循环结束，退出代码: {exit_code}")
            return exit_code

        except KeyboardInterrupt:
            if self.logger:
                self.logger.info("用户中断应用程序")
            else:
                print("用户中断应用程序")
            return 0

        except Exception as e:
            error_msg = f"应用程序运行时发生未处理的异常: {e}"
            if self.logger:
                self.logger.critical(error_msg, exc_info=True)
            else:
                print(error_msg)
                import traceback

                traceback.print_exc()

            self.show_error_dialog("严重错误", error_msg)
            return 1

        finally:
            # 确保资源被清理
            self.cleanup_and_exit()


def main():
    """主函数"""

    # 设置异常钩子
    def exception_hook(exc_type, exc_value, exc_traceback):
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return

        error_msg = f"未处理的异常: {exc_type.__name__}: {exc_value}"
        print(error_msg)

        # 尝试记录到日志
        try:
            logger = get_logger(__name__)
            logger.critical(error_msg, exc_info=(exc_type, exc_value, exc_traceback))
        except Exception:  # nosec B110
            # 如果日志记录失败，静默忽略，因为错误信息已经打印到控制台
            pass

    sys.excepthook = exception_hook

    # 创建并运行应用程序管理器
    app_manager = ApplicationManager()
    return app_manager.run()


if __name__ == "__main__":
    sys.exit(main())
