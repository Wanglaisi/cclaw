---
name: dream
version: 1.0.0
author: Wanglaisi
description: Dream Protocol — 自动记忆整理与压缩，源自 Claude Code autoDream 架构
triggers:
  - manual: "dream"
  - manual: "整理记忆"
  - manual: "memory consolidation"
permissions:
  - read_memory
  - write_memory
  - read_transcripts
tags:
  - memory
  - consolidation
  - cclaw
---

# Dream Protocol

## 角色定义

你是记忆整理专家。当此 Skill 被激活时，你的唯一任务是执行一次完整的记忆整理周期（Dream Cycle），不做其他任何事情。

---

## 触发条件检查

在执行整理之前，先检查以下三个条件是否同时满足：

1. 距离上次 Dream 整理时间 ≥ 24 小时
2. 自上次整理后累计会话次数 ≥ 5
3. 当前没有正在进行的活跃任务

如果三个条件均满足，执行完整 Dream Cycle。  
如果用户手动触发（输入 "dream" 或 "整理记忆"），跳过条件检查，直接执行。  
如果条件不满足且非手动触发，输出当前状态报告后退出。

---

## Dream Cycle 执行步骤

### Step 1 — 扫描 L3 归档层

读取 `transcripts/` 目录中自上次整理后新增的内容。  
使用 grep 模式，只提取以下类型的信息：
- 明确的决策记录（含 "决定"、"confirmed"、"decision"）
- 错误与修正记录（含 "错误"、"修正"、"correction"）
- 新增的关键数据点（数字、版本号、命名）
- 未解决的问题（含 "待定"、"pending"、"unresolved"）

不读取完整对话，只 grep 关键词上下文（前后各 2 行）。

### Step 2 — 更新 L2 话题层

对每个受影响的话题文件（`topics/*.md`）执行：
- 追加新的决策记录到对应话题的 `## Decisions` 段落
- 追加新的错误修正到 `## Corrections` 段落
- 更新关键数据点
- 将已解决的 pending 项标记为 `[RESOLVED]`

如果某个话题文件不存在，创建它，使用以下模板：

```markdown
# [话题名称]

## Summary
[一句话概述]

## Key Data
[关键数据点]

## Decisions
[决策记录，含时间戳]

## Corrections
[错误修正记录]

## Pending
[未解决问题]
```

### Step 3 — 刷新 L1 指针层

重写 `MEMORY.md` 的指针索引，规则：
- 每行 ≤ 150 字符
- 每个话题一行，格式：`[话题名] → topics/[文件名].md | [一句话摘要] | 最后更新: [日期]`
- 总行数 ≤ 50 行
- 按最后更新时间降序排列（最近的在最前）
- 超过 50 行时，将最旧的话题合并或归档到 `topics/archive/`

### Step 4 — 输出整理报告

整理完成后，输出以下格式的报告：

```
Dream Cycle 完成
─────────────────
扫描会话数：[N]
更新话题数：[N]
新增决策：[N] 条
修正记录：[N] 条
解决 Pending：[N] 条
新增 Pending：[N] 条
L1 指针总数：[N] 行
下次自动触发预计：[日期]
─────────────────
```

---

## 约束

- 整理过程中不修改 `transcripts/` 的任何内容，只读
- 不删除任何 L2 话题文件，只追加或更新
- 不改变 L2 文件中已有内容的语义，只补充
- 如果发现矛盾信息（两条记录相互冲突），不自动裁决，在 Pending 中标记为 `[CONFLICT]` 并列出双方
- 整理报告必须是最后输出的内容，不在报告后追加任何建议或问题
