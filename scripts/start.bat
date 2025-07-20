@echo off
chcp 65001 >nul
title 域名邮箱管理器

echo.
echo ========================================
echo 🚀 域名邮箱管理器启动器
echo ========================================
echo.

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 未找到Python，请先安装Python 3.9或更高版本
    echo.
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python已安装
python --version

echo.
echo 🔍 检查依赖包...

REM 检查PyQt6
python -c "import PyQt6" >nul 2>&1
if errorlevel 1 (
    echo ❌ PyQt6未安装，正在安装依赖包...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ 依赖包安装失败
        pause
        exit /b 1
    )
) else (
    echo ✅ 依赖包已安装
)

echo.
echo 🚀 启动应用程序...
echo.

REM 切换到项目根目录
cd /d "%~dp0\.."

REM 启动应用程序
python scripts\start.py

if errorlevel 1 (
    echo.
    echo ❌ 应用程序启动失败
    pause
    exit /b 1
)

echo.
echo ✅ 应用程序已退出
pause
