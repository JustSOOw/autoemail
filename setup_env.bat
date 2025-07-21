@echo off
chcp 65001 >nul
title 域名邮箱管理器 - 环境设置

echo.
echo ========================================
echo 🔧 域名邮箱管理器 - 虚拟环境设置
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
echo 🔧 设置虚拟环境...

REM 运行Python设置脚本
python scripts\setup_env.py

if errorlevel 1 (
    echo.
    echo ❌ 虚拟环境设置失败
    pause
    exit /b 1
)

echo.
echo ✅ 虚拟环境设置完成
echo.
echo 📋 下一步操作:
echo    1. 激活虚拟环境: venv\Scripts\activate
echo    2. 运行项目: python run.py
echo    或者直接运行: run.bat
echo.

pause
