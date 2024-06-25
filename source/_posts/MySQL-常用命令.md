---
title: MySQL-常用命令
date: 2024-06-25 14:12:17
tags: MySQL
categories: MySQL
---

# 查看库空间大小
```sql
select
TABLE_SCHEMA,
concat(truncate(sum(data_length)/1024/1024,2),' MB') as data_size,
concat(truncate(sum(index_length)/1024/1024,2),'MB') as index_size,
concat(truncate(sum(data_length+index_length)/1024/1024/1024,2),'GB') as 单库总大小
from information_schema.tables
group by TABLE_SCHEMA
ORDER BY data_size desc;
```