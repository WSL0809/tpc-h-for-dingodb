#!/bin/bash

# TPC-H查询测试脚本
set -e

echo "开始TPC-H查询测试..."

# 生成查询1
echo "生成TPC-H查询1..."
cd /tpch/dbgen
./qgen -d 1 > /tpch/query1.sql

echo "生成的查询1:"
cat /tpch/query1.sql

echo ""
echo "执行查询1 (简单聚合查询，压力较小):"
time mysql -h mysql -uroot -p123456 tpch < /tpch/query1.sql

echo ""
echo "执行一些简单的统计查询:"

echo "各表记录数统计:"
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

echo ""
echo "按地区统计客户数量:"
mysql -h mysql -uroot -p123456 tpch -e "
SELECT r.R_NAME as region, COUNT(c.C_CUSTKEY) as customer_count
FROM REGION r
JOIN NATION n ON r.R_REGIONKEY = n.N_REGIONKEY
JOIN CUSTOMER c ON n.N_NATIONKEY = c.C_NATIONKEY
GROUP BY r.R_NAME
ORDER BY customer_count DESC;
"

echo ""
echo "订单状态统计:"
mysql -h mysql -uroot -p123456 tpch -e "
SELECT O_ORDERSTATUS, COUNT(*) as order_count, 
       ROUND(AVG(O_TOTALPRICE), 2) as avg_price
FROM ORDERS 
GROUP BY O_ORDERSTATUS;
"

echo ""
echo "TPC-H测试完成!"