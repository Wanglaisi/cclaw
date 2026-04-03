# cclaw

> Claude Code 源码架构洞察 × OpenClaw 增强方案  
> Dream Protocol · Verification Protocol · 三层记忆架构 · Skills 封装

---

## 这是什么

2026 年 3 月 31 日，Anthropic 意外泄露了 Claude Code 51.2 万行生产源码。  
这个仓库做一件事：**把泄露源码中已被工程验证的架构模式，转化为 OpenClaw 可直接安装的 Skills 和配置模板。​**

不需要修改 OpenClaw 本体，不需要插件，90% 的增强通过 Markdown 文件实现。

---

## 仓库结构

```
cclaw/
├── docs/
│   ├── layer1-openclaw-native.md      # 原生 OpenClaw 架构解读（稳定层）
│   └── layer2-enhanced-architecture.md # 增强架构设计（协议层）
├── skills/
│   ├── dream/SKILL.md                 # Dream Protocol — 自动记忆整理
│   ├── wiki/SKILL.md                  # Wiki Protocol — 结构化知识沉淀
│   ├── verify/SKILL.md                # Verification Protocol — 对抗性验证
│   └── extract/SKILL.md              # Extract Protocol — 上下文主动感知
├── templates/
│   ├── AGENTS.md                      # 完整行为指令模板
│   └── MEMORY.md                      # 三层指针记忆模板
└── scripts/
    └── init.sh                        # 一键初始化目录结构
```

---

## 核心设计

### 三层记忆架构

源自 Claude Code 的 `memory_manager` 子系统，经过 OpenClaw 适配：

| 层级 | 文件 | 作用 | 大小限制 |
|------|------|------|----------|
| L1 指针层 | `MEMORY.md` | 话题索引，每行 ≤150 字符 | ≤50 行 |
| L2 话题层 | `topics/*.md` | 按需加载的详细记录 | 无硬限制 |
| L3 归档层 | `transcripts/` | 只 grep，不全量读取 | 只追加 |

### Dream Protocol

对应 Claude Code 的 `autoDream` 触发机制。触发条件：
- 距上次整理 ≥24 小时，**且**
- 累计会话 ≥5 次，**且**
- 当前无活跃会话

触发后自动执行：压缩 L3 → 更新 L2 → 刷新 L1 指针。

### Verification Protocol

对应 Claude Code 的 `adversarial_verification` 模块。  
任何置信度 <0.85 的结论，强制触发反向论证再合并。

### Plan Protocol

对应 Claude Code 的 `PLAN_MODE`。  
复杂任务强制先输出结构化计划（XML 格式），用户确认后再执行。

---

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/Wanglaisi/cclaw.git
cd cclaw

# 一键初始化目录结构（在你的 OpenClaw 项目目录中运行）
bash scripts/init.sh /path/to/your/openclaw/project

# 安装第一个 Skill：Dream Protocol
cp skills/dream/SKILL.md /path/to/your/openclaw/project/skills/
```

然后将 `templates/AGENTS.md` 的内容合并到你项目的 `AGENTS.md` 中。

---

## Skills 清单

| Skill | 对应 Claude Code 模块 | 功能 |
|-------|----------------------|------|
| `dream` | `autoDream` + `memory_manager` | 自动记忆整理与压缩 |
| `wiki` | `knowledge_graph` | 结构化知识沉淀 |
| `verify` | `adversarial_verification` | 对抗性验证，防止过拟合 |
| `extract` | `context_extractor` | 主动感知，按需加载上下文 |

---

## 兼容性

- OpenClaw v2026.1.29+（CVE-2026-25253 修复版本）
- 不依赖 QMD / Cognee 插件
- 不修改 OpenClaw 本体代码

---

## 参考来源

- [tvytlx/ai-agent-deep-dive](https://github.com/tvytlx/ai-agent-deep-dive) — Claude Code 中文深度分析
- [ComeOnOliver/claude-code-analysis](https://github.com/ComeOnOliver/claude-code-analysis) — 17 个子系统逆向工程文档

---

## License

MIT © Wanglaisi
