---
title: EMQX-备份还原
date: 2024-06-11 14:12:17
tags: EMQX
categories: EMQX
---

[官方文档](https://docs.emqx.com/zh/emqx/latest/operations/backup-restore.html)

# 备份

```bash
emqx_ctl data export
```

# 还原
**注意** \<filename\> 必须是绝对路径

```bash
emqx_ctl data import <filename>
```