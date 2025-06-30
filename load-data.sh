#!/bin/bash

# TPC-H数据生成和加载脚本
set -e

echo "开始TPC-H数据生成和加载过程..."

# 检查MySQL连接
echo "等待MySQL启动..."
while ! mysql -h mysql -uroot -p123456 -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done
echo "MySQL已启动"

# 进入dbgen目录
cd /tpch/dbgen

# 生成scale factor 1的数据 (约1GB)
echo "生成TPC-H数据 (Scale Factor 1)..."
./dbgen -s 1 -f

# 检查生成的文件
echo "生成的数据文件:"
ls -lh *.tbl

# 创建数据目录并移动文件
mkdir -p /tpch/data
mv *.tbl /tpch/data/

# 加载数据到MySQL
echo "开始加载数据到MySQL..."

# 小表先加载
echo "加载REGION表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/region.tbl' 
INTO TABLE REGION 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(R_REGIONKEY, R_NAME, R_COMMENT, @dummy);"

echo "加载NATION表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/nation.tbl' 
INTO TABLE NATION 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT, @dummy);"

echo "加载SUPPLIER表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/supplier.tbl' 
INTO TABLE SUPPLIER 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(S_SUPPKEY, S_NAME, S_ADDRESS, S_NATIONKEY, S_PHONE, S_ACCTBAL, S_COMMENT, @dummy);"

echo "加载PART表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/part.tbl' 
INTO TABLE PART 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(P_PARTKEY, P_NAME, P_MFGR, P_BRAND, P_TYPE, P_SIZE, P_CONTAINER, P_RETAILPRICE, P_COMMENT, @dummy);"

echo "加载PARTSUPP表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/partsupp.tbl' 
INTO TABLE PARTSUPP 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(PS_PARTKEY, PS_SUPPKEY, PS_AVAILQTY, PS_SUPPLYCOST, PS_COMMENT, @dummy);"

echo "加载CUSTOMER表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/customer.tbl' 
INTO TABLE CUSTOMER 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(C_CUSTKEY, C_NAME, C_ADDRESS, C_NATIONKEY, C_PHONE, C_ACCTBAL, C_MKTSEGMENT, C_COMMENT, @dummy);"

echo "加载ORDERS表..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/orders.tbl' 
INTO TABLE ORDERS 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE, O_ORDERDATE, O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT, @dummy);"

echo "加载LINEITEM表 (最大的表)..."
mysql -h mysql -uroot -p123456 tpch -e "
LOAD DATA LOCAL INFILE '/tpch/data/lineitem.tbl' 
INTO TABLE LINEITEM 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n'
(L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY, L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS, L_SHIPDATE, L_COMMITDATE, L_RECEIPTDATE, L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT, @dummy);"

# 检查数据加载情况
echo "数据加载完成! 检查表记录数:"
mysql -h mysql -uroot -p123456 tpch -e "
SELECT 'REGION' as table_name, COUNT(*) as row_count FROM REGION UNION ALL
SELECT 'NATION', COUNT(*) FROM NATION UNION ALL
SELECT 'SUPPLIER', COUNT(*) FROM SUPPLIER UNION ALL
SELECT 'PART', COUNT(*) FROM PART UNION ALL
SELECT 'PARTSUPP', COUNT(*) FROM PARTSUPP UNION ALL
SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS UNION ALL
SELECT 'LINEITEM', COUNT(*) FROM LINEITEM;
"

echo "TPC-H数据加载完成!"
echo "你现在可以运行TPC-H查询了。"