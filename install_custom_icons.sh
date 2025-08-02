#!/bin/bash

# 自定义图标功能安装脚本
echo "🔧 安装自定义图标功能依赖..."

# 检查虚拟环境
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "✅ 检测到虚拟环境: $VIRTUAL_ENV"
else
    echo "⚠️  未检测到虚拟环境，建议在虚拟环境中安装"
fi

# 安装Pillow
echo "📦 安装 Pillow 图片处理库..."
pip install Pillow==10.4.0

if [ $? -eq 0 ]; then
    echo "✅ Pillow 安装成功"
else
    echo "❌ Pillow 安装失败"
    exit 1
fi

# 验证安装
echo "🧪 验证安装..."
python -c "from PIL import Image; print('✅ PIL/Pillow 导入成功')"

if [ $? -eq 0 ]; then
    echo "🎉 自定义图标功能依赖安装完成！"
    echo ""
    echo "现在可以运行项目了："
    echo "  python run.py"
else
    echo "❌ 验证失败"
    exit 1
fi