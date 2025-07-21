# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 日志工具
提供统一的日志记录功能
"""

import datetime
import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Optional


class ColoredFormatter(logging.Formatter):
    """彩色日志格式化器"""

    # 颜色代码
    COLORS = {
        "DEBUG": "\033[36m",  # 青色
        "INFO": "\033[32m",  # 绿色
        "WARNING": "\033[33m",  # 黄色
        "ERROR": "\033[31m",  # 红色
        "CRITICAL": "\033[35m",  # 紫色
        "RESET": "\033[0m",  # 重置
    }

    def format(self, record):
        # 添加颜色
        if record.levelname in self.COLORS:
            record.levelname = (
                f"{self.COLORS[record.levelname]}"
                f"{record.levelname}"
                f"{self.COLORS['RESET']}"
            )

        return super().format(record)


class SensitiveDataFilter(logging.Filter):
    """敏感数据过滤器"""

    SENSITIVE_PATTERNS = [
        "password",
        "passwd",
        "pwd",
        "secret",
        "token",
        "key",
        "epin",
        "auth",
    ]

    def filter(self, record):
        """过滤敏感数据"""
        if hasattr(record, "msg"):
            msg = str(record.msg)

            # 简单的敏感数据脱敏
            for pattern in self.SENSITIVE_PATTERNS:
                if pattern in msg.lower():
                    # 替换可能的敏感信息
                    import re

                    # 匹配类似 password=xxx 的模式
                    pattern_regex = rf"{pattern}[=:]\s*[^\s,}}\]]+"
                    msg = re.sub(
                        pattern_regex, f"{pattern}=***", msg, flags=re.IGNORECASE
                    )

            record.msg = msg

        return True


def setup_logger(
    log_file: Optional[Path] = None,
    level: str = "INFO",
    max_size: str = "10MB",
    backup_count: int = 5,
    console_output: bool = True,
) -> logging.Logger:
    """
    设置日志系统

    Args:
        log_file: 日志文件路径
        level: 日志级别
        max_size: 单个日志文件最大大小
        backup_count: 备份文件数量
        console_output: 是否输出到控制台

    Returns:
        配置好的日志记录器
    """

    # 创建根日志记录器
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, level.upper()))

    # 清除现有的处理器
    logger.handlers.clear()

    # 日志格式
    file_formatter = logging.Formatter(
        fmt="%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    console_formatter = ColoredFormatter(
        fmt="%(asctime)s - %(levelname)s - %(message)s", datefmt="%H:%M:%S"
    )

    # 添加敏感数据过滤器
    sensitive_filter = SensitiveDataFilter()

    # 文件处理器
    if log_file:
        # 确保日志目录存在
        log_file.parent.mkdir(parents=True, exist_ok=True)

        # 解析文件大小
        size_bytes = _parse_size(max_size)

        file_handler = RotatingFileHandler(
            filename=log_file,
            maxBytes=size_bytes,
            backupCount=backup_count,
            encoding="utf-8",
        )
        file_handler.setFormatter(file_formatter)
        file_handler.addFilter(sensitive_filter)
        logger.addHandler(file_handler)

    # 控制台处理器
    if console_output:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(console_formatter)
        console_handler.addFilter(sensitive_filter)
        logger.addHandler(console_handler)

    # 记录初始化信息
    logger.info("日志系统初始化完成")
    logger.info(f"日志级别: {level}")
    if log_file:
        logger.info(f"日志文件: {log_file}")

    return logger


def get_logger(name: str) -> logging.Logger:
    """
    获取指定名称的日志记录器

    Args:
        name: 日志记录器名称

    Returns:
        日志记录器实例
    """
    return logging.getLogger(name)


def _parse_size(size_str: str) -> int:
    """
    解析大小字符串为字节数

    Args:
        size_str: 大小字符串，如 "10MB", "1GB"

    Returns:
        字节数
    """
    size_str = size_str.upper().strip()

    # 单位映射
    units = {"B": 1, "KB": 1024, "MB": 1024 * 1024, "GB": 1024 * 1024 * 1024}

    # 提取数字和单位
    import re

    match = re.match(r"^(\d+(?:\.\d+)?)\s*([KMGT]?B)$", size_str)

    if not match:
        # 默认为字节
        try:
            return int(size_str)
        except ValueError:
            return 10 * 1024 * 1024  # 默认10MB

    number, unit = match.groups()
    return int(float(number) * units.get(unit, 1))


class LogContext:
    """日志上下文管理器"""

    def __init__(self, logger: logging.Logger, operation: str):
        self.logger = logger
        self.operation = operation
        self.start_time = None

    def __enter__(self):
        self.start_time = datetime.datetime.now()
        self.logger.info(f"开始执行: {self.operation}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = datetime.datetime.now() - self.start_time

        if exc_type is None:
            self.logger.info(
                f"完成执行: {self.operation} (耗时: {duration.total_seconds():.2f}秒)"
            )
        else:
            self.logger.error(
                f"执行失败: {self.operation} (耗时: {duration.total_seconds():.2f}秒) - {exc_val}"
            )

        return False  # 不抑制异常


def log_operation(operation: str):
    """日志操作装饰器"""

    def decorator(func):
        def wrapper(*args, **kwargs):
            logger = get_logger(func.__module__)

            with LogContext(logger, f"{operation} - {func.__name__}"):
                return func(*args, **kwargs)

        return wrapper

    return decorator


# 便捷的日志记录函数
def debug(message: str, logger_name: str = __name__):
    """记录调试信息"""
    get_logger(logger_name).debug(message)


def info(message: str, logger_name: str = __name__):
    """记录信息"""
    get_logger(logger_name).info(message)


def warning(message: str, logger_name: str = __name__):
    """记录警告"""
    get_logger(logger_name).warning(message)


def error(message: str, logger_name: str = __name__, exc_info: bool = False):
    """记录错误"""
    get_logger(logger_name).error(message, exc_info=exc_info)


def critical(message: str, logger_name: str = __name__, exc_info: bool = False):
    """记录严重错误"""
    get_logger(logger_name).critical(message, exc_info=exc_info)


# 示例使用
if __name__ == "__main__":
    # 设置日志
    setup_logger(log_file=Path("test.log"), level="DEBUG", console_output=True)

    # 测试日志
    logger = get_logger(__name__)

    logger.debug("这是调试信息")
    logger.info("这是普通信息")
    logger.warning("这是警告信息")
    logger.error("这是错误信息")
    logger.critical("这是严重错误信息")

    # 测试敏感数据过滤
    logger.info("用户登录: username=test, password=secret123")

    # 测试上下文管理器
    with LogContext(logger, "测试操作"):
        import time

        time.sleep(1)
        logger.info("操作进行中...")

    # 测试装饰器
    @log_operation("测试函数")
    def test_function():
        logger.info("函数执行中...")
        return "success"

    result = test_function()
    logger.info(f"函数返回: {result}")
