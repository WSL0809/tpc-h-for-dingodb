#!/bin/bash

# 快速TPC-H测试脚本 - 使用本地MySQL
set -e

echo "快速TPC-H测试开始..."

# 进入dbgen目录并修复编译问题
cd dbgen

# 修复makefile
if [ ! -f makefile ]; then
    cp makefile.suite makefile
    sed -i.bak 's/CC      = /CC      = gcc/' makefile
    sed -i.bak 's/DATABASE= /DATABASE= MYSQL/' makefile
    sed -i.bak 's/MACHINE = /MACHINE = LINUX/' makefile
    sed -i.bak 's/WORKLOAD = /WORKLOAD = TPCH/' makefile
fi

# 修复malloc.h问题
sed -i.bak 's/#include <malloc.h>/#include <stdlib.h>/' bm_utils.c

echo "开始编译dbgen和qgen..."
make clean
make

if [ -f dbgen ] && [ -f qgen ]; then
    echo "编译成功!"
    ls -la dbgen qgen
else
    echo "编译失败"
    exit 1
fi

# 生成小规模数据
echo "生成TPC-H数据 (Scale Factor 0.1 - 约100MB)..."
./dbgen -s 0.1 -f 

echo "生成的数据文件:"
ls -lh *.tbl

# 检查本地MySQL连接
echo "检查MySQL连接..."
if mysql -h127.0.0.1 -P3306 -uroot -p123456 -e "SELECT 1" 2>/dev/null; then
    echo "连接到本地MySQL成功"
    
    # 创建数据库
    mysql -h127.0.0.1 -P3306 -uroot -p123456 -e "DROP DATABASE IF EXISTS tpch_test; CREATE DATABASE tpch_test;"
    
    # 创建表结构
    mysql -h127.0.0.1 -P3306 -uroot -p123456 tpch_test < ../sql-scripts/01-create-tables.sql
    
    echo "数据库和表创建成功"
    
    # 加载数据（简化版本）
    echo "加载REGION表..."
    mysql -h127.0.0.1 -P3306 -uroot -p123456 --local-infile=1 tpch_test -e "
    LOAD DATA LOCAL INFILE 'region.tbl' 
    INTO TABLE REGION 
    FIELDS TERMINATED BY '|' 
    LINES TERMINATED BY '\n'
    (R_REGIONKEY, R_NAME, R_COMMENT, @dummy);"
    
    echo "TPC-H快速测试完成!"
    
    # 显示统计
    mysql -h127.0.0.1 -P3306 -uroot -p123456 tpch_test -e "
    SELECT 'REGION' as table_name, COUNT(*) as row_count FROM REGION;
    "
    
else
    echo "无法连接到MySQL，请确保:"
    echo "1. MySQL在127.0.0.1:3306运行"
    echo "2. root用户密码是123456"
    echo "3. 启用了local-infile"
fi

echo "测试脚本执行完成"