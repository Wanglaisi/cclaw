# Layer 1 — 原生 OpenClaw 架构解读
# 版本：1.0.0 | 日期：2026-04-03
# 定位：稳定层，描述 OpenClaw 本体能力边界，不含增强内容

---

## 什么是 OpenClaw

OpenClaw 是一个以「长期运行 Agent」为核心设计目标的 AI 平台。与普通对话助手的根本区别在于：它假设 Agent 会持续存在，跨会话积累状态，而不是每次对话从零开始。

原生 OpenClaw 的三个核心概念：

**Gateway**：Agent 的入口控制器，负责路由用户请求到对应的 Skill 或直接处理。所有外部输入都经过 Gateway 过滤，Gateway 也是权限边界的执行点。

**Skills**：Agent 的能力单元。每个 Skill 是一个独立的 Markdown 文件（`SKILL.md`），包含 YAML frontmatter（元数据）和自然语言指令（行为描述）。Skills 不需要编写代码，本质上是结构化的行为约定。

**SOUL.md**：Agent 的人格与价值观定义文件。存放 Agent 的身份描述、行为边界、优先级规则。SOUL.md 的内容在所有会话中持续有效，优先级高于单次会话指令。

---

## Skills 系统详解

### SKILL.md 文件格式

```yaml
---
name: skill-name          # Skill 唯一标识符
version: 1.0.0            # 语义化版本号
author: username          # 作者
description: ...          # 一句话描述
triggers:                 # 触发条件列表
  - manual: "关键词"      # 用户手动触发
  - auto: condition       # 自动触发条件（可选）
permissions:              # 所需权限声明
  - read_memory
  - write_memory
tags:                     # 分类标签
  - tag1
---

# Skill 名称

[自然语言行为指令]
```

### Skills 与 Plugins 的安全边界

OpenClaw 原生区分两类扩展：

**Skills（Markdown 指令）​**：运行在 Agent 的语言理解层，不直接执行系统调用。相对安全，适合社区分享。ClawHub 上的 13,000+ 社区 Skills 均属此类。

**Plugins（原生代码）​**：直接运行在 OpenClaw 进程中，无沙箱隔离。拥有完整系统权限，安全风险显著高于 Skills。安装第三方 Plugin 前必须审计源码。

### ClawHub

OpenClaw 官方 Skill 市场，托管社区贡献的 Skills。安装方式：在 OpenClaw 设置中输入 Skill 的 ClawHub ID 或 GitHub 路径。

---

## 记忆存储机制

原生 OpenClaw 的记忆存储为普通 Markdown 文件，存放在项目目录中。没有内置的向量数据库或图数据库——所有「记忆」本质上是文本文件的读写。

这个设计的含义：
- 记忆内容完全透明，人类可直接读取和编辑
- 没有自动的记忆压缩或整理机制（这是 cclaw 增强层要解决的问题）
- 记忆的质量完全取决于 Agent 的写入策略

---

## AGENTS.md

项目根目录的 `AGENTS.md` 是 Agent 的行为指令文件。每次会话开始时自动加载，优先级仅次于 SOUL.md。

`AGENTS.md` 的典型内容：
- 任务处理流程约定
- 文件读写规范
- 输出格式要求
- 禁止行为列表

与 SOUL.md 的区别：SOUL.md 定义「Agent 是谁」，AGENTS.md 定义「Agent 怎么做事」。

---

## 兼容性与安全基线

**最低版本要求**：OpenClaw v2026.1.29+

v2026.1.29 之前的版本存在 CVE-2026-25253 漏洞：WebSocket token 在特定条件下会泄露到日志文件，攻击者可借此劫持 Agent 会话。v2026.1.29 已修复此漏洞。

**版本确认方式**：

```bash
openclaw --version
```

---

## 原生能力边界总结

原生 OpenClaw 提供了：
- Skills 系统（行为约定层）
- SOUL.md + AGENTS.md（身份与行为定义）
- Markdown 文件记忆存储
- Gateway 权限路由
- ClawHub Skill 市场

原生 OpenClaw **不提供**：
- 自动记忆整理与压缩
- 对抗性验证机制
- 结构化任务计划协议
- 多 Agent 协调通信规范
- 按需加载的分层记忆索引

以上缺失能力由 cclaw 增强层（Layer 2）补充。
