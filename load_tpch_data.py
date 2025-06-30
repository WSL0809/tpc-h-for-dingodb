#!/usr/bin/env python3

import mysql.connector
import os
import sys

def connect_mysql():
    """连接到MySQL数据库"""
    try:
        conn = mysql.connector.connect(
            host='127.0.0.1',
            port=3306,
            user='root',
            password='123456',
            database='tpch_test'
        )
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL连接错误: {err}")
        sys.exit(1)

def load_region_table(conn):
    """加载REGION表数据"""
    cursor = conn.cursor()
    
    with open('dbgen/region.tbl', 'r') as f:
        for line in f:
            fields = line.strip().split('|')
            if len(fields) >= 3:
                r_regionkey = int(fields[0])
                r_name = fields[1]
                r_comment = fields[2]
                
                sql = "INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES (%s, %s, %s)"
                cursor.execute(sql, (r_regionkey, r_name, r_comment))
    
    conn.commit()
    cursor.close()
    print("REGION表数据加载完成")

def load_nation_table(conn):
    """加载NATION表数据"""
    cursor = conn.cursor()
    
    with open('dbgen/nation.tbl', 'r') as f:
        for line in f:
            fields = line.strip().split('|')
            if len(fields) >= 4:
                n_nationkey = int(fields[0])
                n_name = fields[1]
                n_regionkey = int(fields[2])
                n_comment = fields[3]
                
                sql = "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES (%s, %s, %s, %s)"
                cursor.execute(sql, (n_nationkey, n_name, n_regionkey, n_comment))
    
    conn.commit()
    cursor.close()
    print("NATION表数据加载完成")

def load_supplier_table(conn, limit=100):
    """加载SUPPLIER表数据（限制记录数）"""
    cursor = conn.cursor()
    count = 0
    
    with open('dbgen/supplier.tbl', 'r') as f:
        for line in f:
            if count >= limit:
                break
            fields = line.strip().split('|')
            if len(fields) >= 7:
                s_suppkey = int(fields[0])
                s_name = fields[1]
                s_address = fields[2]
                s_nationkey = int(fields[3])
                s_phone = fields[4]
                s_acctbal = float(fields[5])
                s_comment = fields[6]
                
                sql = "INSERT INTO SUPPLIER (S_SUPPKEY, S_NAME, S_ADDRESS, S_NATIONKEY, S_PHONE, S_ACCTBAL, S_COMMENT) VALUES (%s, %s, %s, %s, %s, %s, %s)"
                cursor.execute(sql, (s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment))
                count += 1
    
    conn.commit()
    cursor.close()
    print(f"SUPPLIER表数据加载完成 ({count} 条记录)")

def check_data_counts(conn):
    """检查各表的数据量"""
    cursor = conn.cursor()
    
    tables = ['REGION', 'NATION', 'SUPPLIER', 'CUSTOMER', 'PART', 'PARTSUPP', 'ORDERS', 'LINEITEM']
    
    print("\n=== 数据统计 ===")
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"{table}: {count:,} 条记录")
    
    cursor.close()

def main():
    """主函数"""
    print("开始加载TPC-H数据到MySQL...")
    
    # 切换到正确的目录
    os.chdir('/Users/wangshilong/Downloads/TPC-H V3.0.1')
    
    # 连接数据库
    conn = connect_mysql()
    
    try:
        # 清空现有数据
        cursor = conn.cursor()
        print("清空现有数据...")
        cursor.execute("DELETE FROM LINEITEM")
        cursor.execute("DELETE FROM ORDERS") 
        cursor.execute("DELETE FROM PARTSUPP")
        cursor.execute("DELETE FROM CUSTOMER")
        cursor.execute("DELETE FROM PART")
        cursor.execute("DELETE FROM SUPPLIER")
        cursor.execute("DELETE FROM NATION")
        cursor.execute("DELETE FROM REGION")
        conn.commit()
        cursor.close()
        
        # 加载小表数据
        load_region_table(conn)
        load_nation_table(conn)
        load_supplier_table(conn, limit=100)  # 只加载100个供应商
        
        # 检查数据
        check_data_counts(conn)
        
        print("\n数据加载完成！现在可以运行查询测试了。")
        
    except Exception as e:
        print(f"加载数据时出错: {e}")
        
    finally:
        conn.close()

if __name__ == "__main__":
    main()