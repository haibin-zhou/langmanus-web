# LangManus Web UI - 集成测试指南

## 快速开始

本指南将帮助您快速测试 LangManus Web UI 前端与后端API的集成。

## 前置条件

- ✅ Node.js 20+ (已安装)
- ✅ Python 3.8+ (已安装)
- ✅ pnpm (已安装)

## 步骤1: 启动前端服务

前端服务已经在运行中：

```bash
# 前端服务状态
✅ 运行在: http://localhost:3000
✅ 进程ID: 查看运行中的进程
✅ 环境变量: NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

## 步骤2: 启动后端API服务

### 方法1: 使用启动脚本 (推荐)

```bash
./start_backend.sh
```

### 方法2: 手动启动

```bash
# 安装Python依赖
pip3 install -r requirements.txt

# 启动后端服务
python3 backend_example.py
```

## 步骤3: 验证服务状态

### 检查后端API

```bash
# 健康检查
curl http://localhost:8000/

# 预期响应
{
  "message": "LangManus Backend API is running",
  "timestamp": "2025-06-02T...",
  "endpoints": {
    "chat_stream": "/api/chat/stream",
    "docs": "/docs"
  }
}
```

### 检查前端服务

```bash
# 访问前端
curl -I http://localhost:3000

# 预期响应
HTTP/1.1 200 OK
```

## 步骤4: 测试API集成

### 使用curl测试流式API

```bash
curl -X POST http://localhost:8000/api/chat/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "messages": [
      {
        "id": "test_001",
        "role": "user",
        "type": "text",
        "content": "你好，请介绍一下自己"
      }
    ],
    "deep_thinking_mode": false,
    "search_before_planning": false,
    "debug": true
  }' \
  --no-buffer
```

### 预期的SSE响应

```
event: start_of_workflow
data: {"workflow_id": "uuid-string", "input": [...]}

event: start_of_agent
data: {"agent_name": "coordinator", "agent_id": "uuid-string"}

event: start_of_llm
data: {"agent_name": "coordinator"}

event: message
data: {"message_id": "uuid-string", "delta": {"content": "感"}}

event: message
data: {"message_id": "uuid-string", "delta": {"content": "谢"}}

...

event: end_of_llm
data: {"agent_name": "coordinator"}

event: end_of_agent
data: {"agent_id": "uuid-string"}

event: end_of_workflow
data: {"workflow_id": "uuid-string", "messages": [...]}
```

## 步骤5: 前端界面测试

1. **打开浏览器访问**: http://localhost:3000

2. **测试基本对话**:
   - 在输入框中输入: "你好"
   - 点击发送按钮
   - 观察流式响应效果

3. **测试深度思考模式**:
   - 启用"深度思考"开关
   - 输入复杂问题: "请分析人工智能的发展趋势"
   - 观察推理过程和最终回答

4. **测试搜索增强模式**:
   - 启用"搜索前规划"开关
   - 输入需要搜索的问题
   - 观察工具调用过程

## 步骤6: 调试和监控

### 前端调试

1. 打开浏览器开发者工具 (F12)
2. 查看 Network 面板中的 SSE 连接
3. 查看 Console 面板中的日志信息

### 后端调试

1. 查看后端控制台输出
2. 访问 API 文档: http://localhost:8000/docs
3. 使用 FastAPI 自动生成的交互式文档测试

## 常见问题排查

### 1. CORS 错误

**问题**: 前端无法连接后端，出现跨域错误

**解决方案**:
```bash
# 检查后端CORS配置
# 确保后端允许 http://localhost:3000 访问
```

### 2. 连接超时

**问题**: SSE连接建立失败或中断

**解决方案**:
```bash
# 检查后端服务状态
curl http://localhost:8000/api/health

# 检查网络连接
ping localhost
```

### 3. 环境变量问题

**问题**: 前端无法找到后端API

**解决方案**:
```bash
# 检查环境变量
cat .env

# 确保包含
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

### 4. 端口冲突

**问题**: 端口被占用

**解决方案**:
```bash
# 检查端口使用情况
netstat -tlnp | grep :8000
netstat -tlnp | grep :3000

# 杀死占用进程
kill -9 <PID>
```

## 性能测试

### 并发测试

```bash
# 使用 ab 工具测试并发性能
ab -n 100 -c 10 -T 'application/json' -p test_payload.json http://localhost:8000/api/chat/stream
```

### 内存监控

```bash
# 监控后端内存使用
top -p $(pgrep -f backend_example.py)

# 监控前端内存使用
top -p $(pgrep -f next)
```

## 高级测试场景

### 1. 长时间对话测试

测试多轮对话的稳定性和内存管理。

### 2. 大文本处理测试

发送包含大量文本的消息，测试流式处理能力。

### 3. 异常情况测试

- 网络中断恢复
- 服务重启恢复
- 无效请求处理

## 集成检查清单

- [ ] 前端服务正常启动 (http://localhost:3000)
- [ ] 后端服务正常启动 (http://localhost:8000)
- [ ] 环境变量配置正确
- [ ] CORS配置正确
- [ ] SSE连接建立成功
- [ ] 流式消息正常接收
- [ ] 错误处理正常工作
- [ ] 深度思考模式正常
- [ ] 搜索增强模式正常
- [ ] 前端UI响应正常
- [ ] 后端日志输出正常

## 部署建议

### 开发环境

- 前端: http://localhost:3000
- 后端: http://localhost:8000

### 生产环境

- 使用反向代理 (Nginx)
- 配置HTTPS
- 设置适当的CORS策略
- 添加速率限制
- 配置日志收集

## 支持和反馈

如果遇到问题，请检查：

1. 服务状态和日志
2. 网络连接
3. 配置文件
4. 依赖版本

需要帮助时，请提供：
- 错误信息
- 服务日志
- 环境信息
- 复现步骤

---

**测试完成后，您就可以开始开发自己的后端服务了！** 🎉 