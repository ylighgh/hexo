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

# 查看数据库字符集
```sql
show create database `hera-cdht`;
```
```sql
mysql>  show create database `hera-cdht`;
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
| Database  | Create Database                                                                                                                     |
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
| hera-cdht | CREATE DATABASE `hera-cdht` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */ |
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.09 sec)
```

# 创建数据库
```sql
-- 仅创建数据库
CREATE DATABASE `dev-cdht-themis`;

-- 创建数据库并且指定字符集
CREATE DATABASE `dev-cdht-themis` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
```

# 查看用户
```sql
use mysql;
select host,user from user;

-- 查看指定用户权限
select * from user where user='xxx';
```

# 创建用户
```sql
CREATE USER 'finley'@'localhost' IDENTIFIED BY 'password';
```