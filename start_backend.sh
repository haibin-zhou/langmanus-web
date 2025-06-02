#!/bin/bash

echo "🚀 LangManus Backend API 启动脚本"
echo "=================================="

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装，请先安装Python3"
    exit 1
fi

echo "✅ Python版本: $(python3 --version)"

# 安装依赖
echo "📦 安装Python依赖..."
pip3 install -r requirements.txt

# 启动后端服务
echo "🚀 启动后端API服务..."
echo "📖 API文档将在: http://localhost:8000/docs"
echo "🔗 前端连接地址: http://localhost:8000/api/chat/stream"
echo "💡 请确保前端环境变量: NEXT_PUBLIC_API_URL=http://localhost:8000/api"
echo ""
echo "按 Ctrl+C 停止服务"
echo "=================================="

python3 backend_example.py 