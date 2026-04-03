# Layer 2 — cclaw 增强架构设计
# 版本：1.0.0 | 日期：2026-04-03
# 定位：协议层，描述基于 Claude Code 源码洞察的四项增强协议
# 前置阅读：docs/layer1-openclaw-native.md

---

## 增强层的来源

2026 年 3 月 31 日，Anthropic 意外泄露 Claude Code 51.2 万行生产源码。
泄露内容涵盖 17 个子系统，包括记忆管理、多 Agent 协调、工具权限、验证机制等核心模块。

cclaw 增强层的设计原则只有一条：**只借鉴已被工程验证的收敛解，不引入实验性设计。​**

泄露源码证明了以下模式在生产环境中有效：
- 三层分级记忆（指针层 + 话题层 + 归档层）
- 定时触发的记忆整理周期（autoDream）
- 置信度门控的对抗性验证（adversarial_verification）
- 强制前置的结构化计划（PLAN_MODE）
- XML 结构化的 Agent 间通信（Coordinator Mode）

以上五个模式，全部通过 OpenClaw 的 Skills + AGENTS.md 实现，不修改本体代码。

---

## 三层记忆架构

### 设计来源

Claude Code `memory_manager` 子系统。原始实现使用内部数据库，cclaw 将其适配为 OpenClaw 的 Markdown 文件存储。

### 三层结构

```
MEMORY.md          ← L1 指针层：索引入口，每次启动必读
topics/*.md        ← L2 话题层：按需加载，存放结构化记录
transcripts/*.md   ← L3 归档层：只追加，只 grep，不全量读取
```

### 为什么分三层

单文件记忆的根本问题是上下文窗口污染：随着会话积累，记忆文件越来越大，Agent 每次启动都要全量读取，最终导致有效上下文被历史记录挤占。

三层设计解决了这个问题：
- L1 永远保持小（≤50 行，每行 ≤150 字符），启动成本固定
- L2 按需加载，只读取当前任务相关的话题
- L3 从不主动读取，只在 Dream Cycle 中 grep 扫描

### L1 指针格式

```
[话题名] → topics/[文件名].md | [摘要，≤100字符] | 最后更新: YYYY-MM-DD
```

### L2 话题文件结构

```markdown
# [话题名]

## Summary
[一句话概述]

## Key Data
[关键数据点]

## Decisions
[决策记录，含时间戳]

## Corrections
[错误修正记录]

## Pending
[未解决问题，含 [CONFLICT] 标记]
```

### L3 归档规范

- 文件名：`transcripts/YYYY-MM-DD.md`
- 只追加，不修改
- Dream Cycle 扫描时使用 grep 提取关键词，不全量读取
- 关键词：`决定`、`confirmed`、`decision`、`错误`、`修正`、`correction`、`待定`、`pending`、`unresolved`

---

## Dream Protocol

### 设计来源

Claude Code `autoDream` 模块 + `memory_consolidation` 子系统。

### 核心逻辑

autoDream 解决的问题是：记忆系统在长期运行后会产生碎片——过时的决策、已解决的 pending、重复的数据点散落在各处。定期整理是维持记忆系统健康的必要操作。

### 触发机制（三重门）

```
条件 1：距上次整理 ≥ 24 小时
条件 2：自上次整理后累计会话 ≥ 5 次
条件 3：当前无活跃任务
```

三个条件必须同时满足才自动触发。手动触发（输入 `dream`）跳过所有条件检查。

三重门的设计意图：防止在活跃工作期间打断任务，同时确保记忆系统不会长期不整理。

### Dream Cycle 四步骤

```
Step 1  扫描 L3  →  grep 提取关键信息
Step 2  更新 L2  →  追加决策、修正、数据点
Step 3  刷新 L1  →  重写指针索引，按时间降序
Step 4  输出报告 →  整理统计，标注下次预计触发时间
```

完整实现见 `skills/dream/SKILL.md`。

---

## Verification Protocol

### 设计来源

Claude Code `adversarial_verification` 模块。

### 核心逻辑

对抗性验证的前提假设：单向推理容易产生确认偏误。强制构建反向论证，再合并双方权重，能够显著降低错误结论的输出概率。

### 触发条件

满足以下任一条件时强制触发：

- 主观置信度 < 0.85
- 涉及不可逆操作（删除、覆盖、部署、发布）
- 结论与已有记忆存在潜在矛盾

### 执行流程

```
1. 输出初始结论（正向论证路径）
2. 切换视角，主动构建反向论证
3. 评估双方论据权重
4. 合并输出最终结论，标注置信度
```

### 输出格式

```
[初始结论]
反向验证：[反向论据]
综合评估：[最终结论] | 置信度: 0.00~1.00
```

### 置信度阈值说明

| 范围 | 含义 | 处理方式 |
|------|------|---------|
| 0.90~1.00 | 高置信 | 直接输出 |
| 0.85~0.89 | 中置信 | 输出但标注不确定性 |
| 0.70~0.84 | 低置信 | 强制触发验证流程 |
| <0.70 | 极低置信 | 触发验证 + 要求用户确认 |

---

## Plan Protocol

### 设计来源

Claude Code `PLAN_MODE` + `task_decomposer` 子系统。

### 核心逻辑

复杂任务在没有显式计划的情况下直接执行，会导致中途发现方向错误、已完成步骤需要回滚的情况。强制前置计划输出，让用户在执行前确认路径，是降低不可逆错误的最有效手段。

### 触发条件

满足以下任一条件时强制先输出计划：

- 涉及 3 个以上独立步骤
- 预计影响 2 个以上文件
- 包含不可逆操作
- 用户明确要求「先规划」

### 计划格式

```xml
<plan>
  <goal>[任务目标]</goal>
  <steps>
    <step id="1" type="[read|write|analyze|verify]">[步骤描述]</step>
    <step id="2" type="...">[步骤描述]</step>
  </steps>
  <risks>[潜在风险，如无则填 none]</risks>
  <reversible>[yes|no]</reversible>
</plan>
```

XML 格式来自 Claude Code Coordinator Mode 的通信规范——结构化消息比自由文本更易于解析和验证。

### 确认流程

```
Agent 输出 <plan>
    ↓
用户审查
    ↓
用户输入 confirm / ok  →  执行
用户修改步骤          →  重新输出 <plan>，再次等待确认
用户取消              →  终止任务
```

---

## Agent 间通信规范

### 设计来源

Claude Code `coordinator_mode` + `subagent_manager` 子系统。

### 适用场景

当 OpenClaw 项目中存在多个角色（主 Agent + 子 Agent，或多个专职 Agent）时，使用此规范进行通信。

### 任务下发格式

```xml
<task>
  <type>[analyze|write|verify|search]</type>
  <input>[输入内容或文件路径]</input>
  <output_format>[期望的输出格式]</output_format>
  <constraints>[约束条件]</constraints>
  <timeout>[秒数，默认 300]</timeout>
</task>
```

### 结果返回格式

```xml
<result>
  <status>[success|partial|failed]</status>
  <content>[输出内容]</content>
  <confidence>[0.00~1.00]</confidence>
  <notes>[备注，如无则省略]</notes>
</result>
```

### 子 Agent 权限约束

Claude Code 源码揭示的关键设计：子 Agent 的权限必须严格小于主 Agent。具体实现：

- 子 Agent 的 AGENTS.md 只包含其职责范围内的指令
- 子 Agent 不得直接写入主记忆（MEMORY.md / topics/）
- 子 Agent 的输出必须经主 Agent 验证后才能写入持久存储

---

## 增强层与原生层的关系

```
原生 OpenClaw
├── Gateway（不修改）
├── Skills 系统（cclaw 在此层添加 4 个 Skills）
├── SOUL.md（不修改）
├── AGENTS.md（cclaw 在此层追加协议指令）
└── Markdown 记忆存储（cclaw 在此层规范目录结构）

cclaw 增强层（全部通过文件实现，不修改本体）
├── skills/dream/SKILL.md     → Dream Protocol
├── skills/verify/SKILL.md    → Verification Protocol
├── skills/wiki/SKILL.md      → Wiki Protocol
├── skills/extract/SKILL.md   → Extract Protocol
├── templates/AGENTS.md       → 四项协议的行为约定
└── templates/MEMORY.md       → 三层记忆初始结构
```

增强层的所有内容都是文件，没有运行时依赖，没有需要编译的代码。原生 OpenClaw 可以直接运行全部增强内容。

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-04-03 | 初始版本，基于 Claude Code 51.2 万行源码泄露的架构洞察 |
