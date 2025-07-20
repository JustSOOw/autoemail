@echo off
chcp 65001 >nul
title 域名邮箱管理器

echo.
echo ========================================
echo 🚀 域名邮箱管理器
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
echo 🔍 检查虚拟环境...

REM 检查是否存在虚拟环境
if exist "venv\Scripts\activate.bat" (
    echo ✅ 发现虚拟环境，正在激活...
    call venv\Scripts\activate.bat
    echo ✅ 虚拟环境已激活
) else (
    echo ⚠️  未发现虚拟环境
    echo 🔧 正在设置虚拟环境...
    python scripts\setup_env.py
    if errorlevel 1 (
        echo ❌ 虚拟环境设置失败
        pause
        exit /b 1
    )
    echo ✅ 虚拟环境设置完成，请重新运行此脚本
    pause
    exit /b 0
)

echo.
echo 🚀 启动应用程序...
python run.py %*

pause
