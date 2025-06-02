# LangManus Web UI - 后端API接入文档

## 概述

本文档描述了如何为 LangManus Web UI 前端应用开发和集成后端API服务。前端应用基于 Next.js 15 构建，使用 Server-Sent Events (SSE) 协议进行实时流式通信。

## 目录

- [环境配置](#环境配置)
- [API端点规范](#api端点规范)
- [请求格式](#请求格式)
- [响应格式](#响应格式)
- [事件类型详解](#事件类型详解)
- [错误处理](#错误处理)
- [集成示例](#集成示例)
- [测试指南](#测试指南)

## 环境配置

### 前端环境变量

在前端项目根目录的 `.env` 文件中配置：

```bash
# 后端API服务地址
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

### 后端服务要求

- **协议**: HTTP/HTTPS
- **端口**: 建议使用 8000 (可自定义)
- **CORS**: 需要支持跨域请求
- **Content-Type**: 支持 `application/json`
- **流式响应**: 支持 Server-Sent Events

## API端点规范

### 主要端点

| 端点 | 方法 | 描述 | 协议 |
|------|------|------|------|
| `/chat/stream` | POST | 流式聊天对话 | SSE |

### 基础URL结构

```
{NEXT_PUBLIC_API_URL}/chat/stream
```

示例：`http://localhost:8000/api/chat/stream`

## 请求格式

### HTTP 请求头

```http
POST /api/chat/stream HTTP/1.1
Host: localhost:8000
Content-Type: application/json
Cache-Control: no-cache
Accept: text/event-stream
```

### 请求体结构

```typescript
interface ChatRequest {
  messages: Message[];           // 消息历史
  deep_thinking_mode: boolean;   // 深度思考模式
  search_before_planning: boolean; // 搜索前规划
  debug: boolean;               // 调试模式
}

interface Message {
  id: string;                   // 消息唯一标识
  role: "user" | "assistant";   // 消息角色
  type: "text" | "workflow";    // 消息类型
  content: string | object;     // 消息内容
}
```

### 请求示例

```json
{
  "messages": [
    {
      "id": "msg_001",
      "role": "user",
      "type": "text",
      "content": "请帮我分析一下人工智能的发展趋势"
    }
  ],
  "deep_thinking_mode": true,
  "search_before_planning": false,
  "debug": false
}
```

## 响应格式

### Server-Sent Events 格式

响应必须遵循 SSE 标准格式：

```
event: {event_type}
data: {json_data}

```

**注意**: 每个事件必须以两个换行符 `\n\n` 结束。

### 基础事件结构

```typescript
interface ChatEvent {
  type: string;    // 事件类型
  data: object;    // 事件数据
}
```

## 事件类型详解

### 1. 工作流事件

#### 开始工作流
```
event: start_of_workflow
data: {
  "workflow_id": "uuid-string",
  "input": [
    {
      "role": "user",
      "content": "用户输入内容"
    }
  ]
}
```

#### 结束工作流
```
event: end_of_workflow
data: {
  "workflow_id": "uuid-string",
  "messages": [
    {
      "role": "assistant",
      "content": "最终回复内容"
    }
  ]
}
```

### 2. Agent 事件

#### 开始 Agent
```
event: start_of_agent
data: {
  "agent_id": "uuid-string",
  "agent_name": "coordinator|researcher|analyst"
}
```

#### 结束 Agent
```
event: end_of_agent
data: {
  "agent_id": "uuid-string"
}
```

### 3. LLM 推理事件

#### 开始 LLM 推理
```
event: start_of_llm
data: {
  "agent_name": "coordinator"
}
```

#### 结束 LLM 推理
```
event: end_of_llm
data: {
  "agent_name": "coordinator"
}
```

### 4. 消息流事件

#### 流式消息
```
event: message
data: {
  "message_id": "uuid-string",
  "delta": {
    "content": "增量文本内容",
    "reasoning_content": "推理过程内容(可选)"
  }
}
```

### 5. 工具调用事件

#### 工具调用
```
event: tool_call
data: {
  "tool_call_id": "uuid-string",
  "tool_name": "tavily_search|crawl_tool|python_executor",
  "tool_input": {
    "query": "搜索关键词",
    "url": "https://example.com"
  }
}
```

#### 工具调用结果
```
event: tool_call_result
data: {
  "tool_call_id": "uuid-string",
  "tool_result": "工具执行结果的JSON字符串"
}
```

### 6. 报告事件

#### 开始报告
```
event: start_of_report
data: {
  "report_id": "uuid-string"
}
```

#### 结束报告
```
event: end_of_report
data: {
  "report_id": "uuid-string"
}
```

### 7. 心跳事件

```
: ping - 2025-06-02T08:22:00.000Z
```

## 完整事件流示例

### 简单对话流程

```
event: start_of_agent
data: {"agent_name": "coordinator", "agent_id": "agent_001"}

event: start_of_llm
data: {"agent_name": "coordinator"}

event: message
data: {"message_id": "msg_001", "delta": {"content": "你好"}}

event: message
data: {"message_id": "msg_001", "delta": {"content": "！我是"}}

event: message
data: {"message_id": "msg_001", "delta": {"content": "LangManus"}}

event: end_of_llm
data: {"agent_name": "coordinator"}

event: end_of_agent
data: {"agent_id": "agent_001"}

```

### 复杂工作流程

```
event: start_of_workflow
data: {"workflow_id": "wf_001", "input": [{"role": "user", "content": "分析AI趋势"}]}

event: start_of_agent
data: {"agent_name": "researcher", "agent_id": "agent_002"}

event: tool_call
data: {"tool_call_id": "tc_001", "tool_name": "tavily_search", "tool_input": {"query": "AI发展趋势2024"}}

event: tool_call_result
data: {"tool_call_id": "tc_001", "tool_result": "[{\"title\": \"AI趋势报告\", \"content\": \"...\"}]"}

event: start_of_llm
data: {"agent_name": "researcher"}

event: message
data: {"message_id": "msg_002", "delta": {"content": "根据搜索结果..."}}

event: end_of_llm
data: {"agent_name": "researcher"}

event: end_of_agent
data: {"agent_id": "agent_002"}

event: end_of_workflow
data: {"workflow_id": "wf_001", "messages": [{"role": "assistant", "content": "完整分析结果"}]}

```

## 错误处理

### HTTP 状态码

- `200 OK`: 成功建立SSE连接
- `400 Bad Request`: 请求格式错误
- `401 Unauthorized`: 认证失败
- `429 Too Many Requests`: 请求频率限制
- `500 Internal Server Error`: 服务器内部错误

### 错误响应格式

```
event: error
data: {
  "error": {
    "code": "INVALID_REQUEST",
    "message": "请求格式不正确",
    "details": "messages字段不能为空"
  }
}
```

### 连接中断处理

前端会自动处理连接中断，后端需要：

1. 支持请求取消 (AbortController)
2. 优雅关闭连接
3. 清理资源

## 集成示例

### Python FastAPI 示例

```python
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import json
import asyncio
import uuid

app = FastAPI()

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/chat/stream")
async def chat_stream(request: Request):
    data = await request.json()
    
    async def generate_events():
        # 开始工作流
        workflow_id = str(uuid.uuid4())
        yield f"event: start_of_workflow\n"
        yield f"data: {json.dumps({'workflow_id': workflow_id, 'input': data['messages']})}\n\n"
        
        # 开始Agent
        agent_id = str(uuid.uuid4())
        yield f"event: start_of_agent\n"
        yield f"data: {json.dumps({'agent_name': 'coordinator', 'agent_id': agent_id})}\n\n"
        
        # 开始LLM推理
        yield f"event: start_of_llm\n"
        yield f"data: {json.dumps({'agent_name': 'coordinator'})}\n\n"
        
        # 流式消息
        message_id = str(uuid.uuid4())
        response_text = "这是一个示例回复，展示了如何集成后端API。"
        
        for char in response_text:
            yield f"event: message\n"
            yield f"data: {json.dumps({'message_id': message_id, 'delta': {'content': char}})}\n\n"
            await asyncio.sleep(0.05)  # 模拟流式输出
        
        # 结束LLM推理
        yield f"event: end_of_llm\n"
        yield f"data: {json.dumps({'agent_name': 'coordinator'})}\n\n"
        
        # 结束Agent
        yield f"event: end_of_agent\n"
        yield f"data: {json.dumps({'agent_id': agent_id})}\n\n"
        
        # 结束工作流
        yield f"event: end_of_workflow\n"
        yield f"data: {json.dumps({'workflow_id': workflow_id, 'messages': [{'role': 'assistant', 'content': response_text}]})}\n\n"
    
    return StreamingResponse(
        generate_events(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Node.js Express 示例

```javascript
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();

app.use(cors({
  origin: 'http://localhost:3000',
  credentials: true
}));

app.use(express.json());

app.post('/api/chat/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Access-Control-Allow-Origin': 'http://localhost:3000',
    'Access-Control-Allow-Credentials': 'true'
  });

  const { messages, deep_thinking_mode, search_before_planning } = req.body;
  
  // 开始工作流
  const workflowId = uuidv4();
  res.write(`event: start_of_workflow\n`);
  res.write(`data: ${JSON.stringify({
    workflow_id: workflowId,
    input: messages
  })}\n\n`);

  // 模拟流式响应
  const responseText = "这是Node.js后端的示例回复。";
  const messageId = uuidv4();
  
  let index = 0;
  const interval = setInterval(() => {
    if (index < responseText.length) {
      res.write(`event: message\n`);
      res.write(`data: ${JSON.stringify({
        message_id: messageId,
        delta: { content: responseText[index] }
      })}\n\n`);
      index++;
    } else {
      // 结束工作流
      res.write(`event: end_of_workflow\n`);
      res.write(`data: ${JSON.stringify({
        workflow_id: workflowId,
        messages: [{ role: 'assistant', content: responseText }]
      })}\n\n`);
      
      clearInterval(interval);
      res.end();
    }
  }, 50);

  // 处理客户端断开连接
  req.on('close', () => {
    clearInterval(interval);
    res.end();
  });
});

app.listen(8000, () => {
  console.log('后端服务运行在 http://localhost:8000');
});
```

## 测试指南

### 1. 使用 curl 测试

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
        "content": "Hello"
      }
    ],
    "deep_thinking_mode": false,
    "search_before_planning": false,
    "debug": true
  }' \
  --no-buffer
```

### 2. 前端集成测试

1. 确保后端服务运行在 `http://localhost:8000`
2. 启动前端服务: `pnpm dev`
3. 访问 `http://localhost:3000`
4. 在聊天界面输入消息测试

### 3. 使用模拟数据测试

如果后端服务未就绪，可以使用前端内置的模拟数据：

访问: `http://localhost:3000?mock`

## 高级功能

### 1. 深度思考模式

当 `deep_thinking_mode: true` 时，后端应该：

- 提供更详细的推理过程
- 使用 `reasoning_content` 字段返回思考过程
- 增加处理时间和复杂度

### 2. 搜索增强模式

当 `search_before_planning: true` 时，后端应该：

- 在生成回复前进行网络搜索
- 发送 `tool_call` 和 `tool_call_result` 事件
- 基于搜索结果生成更准确的回复

### 3. 调试模式

当 `debug: true` 时，后端可以：

- 返回更详细的日志信息
- 包含性能指标
- 提供调试相关的元数据

## 性能建议

1. **连接管理**: 合理管理SSE连接，避免内存泄漏
2. **流式输出**: 及时发送数据块，提升用户体验
3. **错误恢复**: 实现重连机制和错误恢复
4. **资源清理**: 在连接断开时清理相关资源
5. **并发控制**: 限制同时处理的请求数量

## 安全考虑

1. **输入验证**: 验证所有输入参数
2. **速率限制**: 实现请求频率限制
3. **认证授权**: 根据需要添加身份验证
4. **CORS配置**: 正确配置跨域访问策略
5. **内容过滤**: 对用户输入和AI输出进行内容审核

## 故障排除

### 常见问题

1. **CORS错误**: 检查后端CORS配置
2. **连接超时**: 调整超时设置和心跳机制
3. **数据格式错误**: 验证JSON格式和事件结构
4. **编码问题**: 确保使用UTF-8编码

### 调试工具

1. 浏览器开发者工具的Network面板
2. 后端日志输出
3. 前端控制台错误信息
4. SSE连接状态监控

---

## 联系支持

如有技术问题或需要进一步支持，请参考：

- 项目GitHub仓库
- 技术文档
- 社区论坛

**版本**: v1.0.0  
**更新日期**: 2025-06-02 