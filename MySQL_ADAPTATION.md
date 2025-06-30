# TPC-H MySQL适配文档

## 概述

本文档记录了将TPC-H数据生成器(DBGEN)和查询生成器(QGEN)适配MySQL数据库的完整过程。原始的TPC-H工具包主要支持Oracle、DB2、Informix等数据库，本次适配使其能够直接生成MySQL兼容的INSERT语句和查询。

## 适配目标

- 修改DBGEN生成MySQL兼容的INSERT语句
- 修改QGEN生成MySQL兼容的查询语法
- 保持与原有TPC-H标准的兼容性
- 支持不同规模的测试数据生成

## 修改清单

### 1. Makefile配置修改

**文件**: `dbgen/makefile`

```makefile
# 原配置
DATABASE= ORACLE

# 修改为
DATABASE= MYSQL
```

**说明**: 设置编译时的数据库类型宏定义，影响条件编译。

### 2. 数据库宏定义添加

**文件**: `dbgen/tpcd.h`

在现有数据库定义后添加MySQL支持：

```c
#ifdef MYSQL
#define GEN_QUERY_PLAN ""
#define START_TRAN ""
#define END_TRAN ""
#define SET_OUTPUT ""
#define SET_ROWCOUNT "limit %d;\n"
#define SET_DBASE "use %s;\n"
#endif
```

**说明**: 
- `SET_ROWCOUNT`: MySQL使用`LIMIT`而非Oracle的`ROWNUM`
- `SET_DBASE`: MySQL使用`USE database`语法
- 其他宏设为空字符串，因为MySQL不需要特殊的事务或输出控制

### 3. 输出格式宏修改

**文件**: `dbgen/dss.h`

修改记录输出格式宏：

```c
#ifdef MYSQL
#define  PR_STRT(fp)   /* any line prep for a record goes here */
#define  PR_END(fp)    fprintf(fp, ");\n")   /* finish the record here */
#else
#define  PR_STRT(fp)   /* any line prep for a record goes here */
#define  PR_END(fp)    fprintf(fp, "\n")   /* finish the record here */
#endif
```

**说明**: MySQL模式下记录以`);\n`结尾，普通模式仍使用`\n`。

### 4. 数据打印函数修改

**文件**: `dbgen/print.c`

#### 4.1 字符串格式化修改

```c
case DT_STR:
#ifdef MYSQL
    if (format == DT_VSTR) {
        /* MVS特殊处理 */
        fprintf(target, "%c%c%-*s", 
            (len >> 8) & 0xFF, len & 0xFF, len, (char *)data);
    } else {
#ifdef MYSQL
        fprintf(target, "'%s'", (char *)data);
#else
        fprintf(target, "%s", (char *)data);
#endif
    }
#else
#ifdef MYSQL
    fprintf(target, "'%s'", (char *)data);
#else
    fprintf(target, "%s", (char *)data);
#endif
#endif /* MVS */
    break;
```

**说明**: 在MySQL模式下，所有字符串都用单引号包围。

#### 4.2 字段分隔符修改

```c
#ifdef EOL_HANDLING
if (sep)
#endif /* EOL_HANDLING */
#ifdef MYSQL
if (sep) fprintf(target, ", ");
#else
fprintf(target, "%c", SEPARATOR);
#endif
```

**说明**: MySQL模式使用`, `作为字段分隔符，原模式使用`|`分隔符。

### 5. 表输出函数修改

**文件**: `dbgen/print.c`

为每个表的输出函数添加INSERT语句前缀：

#### 5.1 REGION表

```c
int pr_region(code_t *c, int mode)
{
static FILE *fp = NULL;
        
   if (fp == NULL)
        fp = print_prep(REGION, mode);

#ifdef MYSQL
   fprintf(fp, "INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES (");
#endif
   PR_STRT(fp);
   PR_HUGE(fp, &c->code);
   PR_STR(fp, c->text, REGION_LEN);
   PR_VSTR_LAST(fp, c->comment, c->clen);
   PR_END(fp);

   return(0);
}
```

#### 5.2 NATION表

```c
int pr_nation(code_t *c, int mode)
{
static FILE *fp = NULL;
        
   if (fp == NULL)
        fp = print_prep(NATION, mode);

#ifdef MYSQL
   fprintf(fp, "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES (");
#endif
   PR_STRT(fp);
   PR_HUGE(fp, &c->code);
   PR_STR(fp, c->text, NATION_LEN);
   PR_INT(fp, c->join);
   PR_VSTR_LAST(fp, c->comment, c->clen);
   PR_END(fp);

   return(0);
}
```

#### 5.3 CUSTOMER表

```c
int pr_cust(customer_t *c, int mode)
{
static FILE *fp = NULL;
        
   if (fp == NULL)
        fp = print_prep(CUST, 0);

#ifdef MYSQL
   fprintf(fp, "INSERT INTO CUSTOMER (C_CUSTKEY, C_NAME, C_ADDRESS, C_NATIONKEY, C_PHONE, C_ACCTBAL, C_MKTSEGMENT, C_COMMENT) VALUES (");
#endif
   PR_STRT(fp);
   // 原有字段输出代码...
   PR_END(fp);

   return(0);
}
```

#### 5.4 SUPPLIER表

```c
int pr_supp(supplier_t *supp, int mode)
{
static FILE *fp = NULL;
        
   if (fp == NULL)
        fp = print_prep(SUPP, mode);

#ifdef MYSQL
   fprintf(fp, "INSERT INTO SUPPLIER (S_SUPPKEY, S_NAME, S_ADDRESS, S_NATIONKEY, S_PHONE, S_ACCTBAL, S_COMMENT) VALUES (");
#endif
   PR_STRT(fp);
   // 原有字段输出代码...
   PR_END(fp);

   return(0);
}
```

#### 5.5 PART表

```c
int pr_part(part_t *part, int mode)
{
static FILE *p_fp = NULL;

    if (p_fp == NULL)
        p_fp = print_prep(PART, 0);

#ifdef MYSQL
   fprintf(p_fp, "INSERT INTO PART (P_PARTKEY, P_NAME, P_MFGR, P_BRAND, P_TYPE, P_SIZE, P_CONTAINER, P_RETAILPRICE, P_COMMENT) VALUES (");
#endif
   PR_STRT(p_fp);
   // 原有字段输出代码...
   PR_END(p_fp);

   return(0);
}
```

#### 5.6 PARTSUPP表

```c
int pr_psupp(part_t *part, int mode)
{
   // 在循环中为每个供应商记录添加INSERT前缀
   for (i = 0; i < SUPP_PER_PART; i++) {
#ifdef MYSQL
      fprintf(ps_fp, "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_AVAILQTY, PS_SUPPLYCOST, PS_COMMENT) VALUES (");
#endif
      PR_STRT(ps_fp);
      // 原有字段输出代码...
      PR_END(ps_fp);
   }

   return(0);
}
```

#### 5.7 ORDERS表

```c
int pr_order(order_t *o, int mode)
{
    // 文件准备代码...
#ifdef MYSQL
    fprintf(fp_o, "INSERT INTO ORDERS (O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE, O_ORDERDATE, O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT) VALUES (");
#endif
    PR_STRT(fp_o);
    // 原有字段输出代码...
    PR_END(fp_o);

    return(0);
}
```

#### 5.8 LINEITEM表

```c
int pr_line(order_t *o, int mode)
{
    // 文件准备代码...
    for (i = 0; i < o->lines; i++) {
#ifdef MYSQL
        fprintf(fp_l, "INSERT INTO LINEITEM (L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY, L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS, L_SHIPDATE, L_COMMITDATE, L_RECEIPTDATE, L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT) VALUES (");
#endif
        PR_STRT(fp_l);
        // 原有字段输出代码...
        PR_END(fp_l);
    }

   return(0);
}
```

**说明**: 每个表输出函数都添加了对应的INSERT语句前缀，包含正确的表名和字段名。

### 6. 编译问题修复

#### 6.1 malloc.h包含问题

**文件**: `dbgen/bm_utils.c`, `dbgen/varsub.c`

```c
#ifndef _POSIX_SOURCE
#ifdef __APPLE__
#include <stdlib.h>
#else
#include <malloc.h>
#endif
#endif /* POSIX_SOURCE */
```

**说明**: macOS系统使用`stdlib.h`而非`malloc.h`。

#### 6.2 重复case问题

**问题**: `DT_STR`和`DT_VSTR`在某些平台上是相同的值，导致switch语句中case重复。

**解决**: 将两个case合并为一个，使用if语句区分处理逻辑。

## 输出格式对比

### 原格式 (管道分隔)
```
0|AFRICA|lar deposits. blithely final packages cajole.|
1|AMERICA|hs use ironic, even requests. s|
```

### MySQL格式 (INSERT语句)
```sql
INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES (0, 'AFRICA', 'lar deposits. blithely final packages cajole.');
INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES (1, 'AMERICA', 'hs use ironic, even requests. s');
```

## 使用方法

### 1. 编译

```bash
cd dbgen
cp makefile.suite makefile
# 确保 DATABASE=MYSQL
make clean && make
```

### 2. 生成数据

```bash
# 生成所有表 (scale factor 1)
./dbgen -s 1

# 生成特定表
./dbgen -T r -f  # REGION表
./dbgen -T n -f  # NATION表
./dbgen -T L -s 0.01 -f  # LINEITEM表(小规模)
```

### 3. 导入MySQL

```bash
# 创建数据库和表
mysql -u root -p database_name < ../sql-scripts/01-create-tables.sql

# 导入数据
mysql -u root -p database_name < region.tbl
mysql -u root -p database_name < nation.tbl
mysql -u root -p database_name < lineitem.tbl
```

### 4. 生成查询

```bash
export DSS_QUERY=./queries
./qgen -d 1  # 生成查询1
```

## 测试结果

### 数据量统计
- REGION: 5条记录
- NATION: 25条记录  
- LINEITEM (scale 0.01): 60,175条记录

### 性能测试
使用scale factor 0.01进行轻量级测试，适合开发和调试环境。生产环境可使用scale factor 1或更大值。

## 注意事项

1. **字符串转义**: 当前实现未处理字符串中的单引号转义，如果数据包含单引号需要额外处理。

2. **日期格式**: TPC-H使用标准日期格式，MySQL应能正确处理。

3. **数据类型**: 确保MySQL表结构中的数据类型与生成的数据兼容。

4. **字符集**: 建议使用UTF-8字符集以避免字符编码问题。

5. **大数据量**: 对于大scale factor，建议分批导入或使用LOAD DATA INFILE。

## 扩展支持

当前适配主要针对基础的数据生成，如需支持其他表或复杂查询，可按相同模式在对应的`pr_xxx`函数中添加INSERT语句前缀。

支持的表包括：
- REGION ✅ (5条记录)
- NATION ✅ (25条记录)
- SUPPLIER ✅ (100条记录 @ scale 0.01)
- CUSTOMER ✅ (1,500条记录 @ scale 0.01)
- PART ✅ (2,000条记录 @ scale 0.01)
- PARTSUPP ✅ (8,000条记录 @ scale 0.01)
- ORDERS ✅ (15,000条记录 @ scale 0.01)
- LINEITEM ✅ (60,175条记录 @ scale 0.01)

## 总结

通过以上修改，TPC-H工具包已成功适配MySQL数据库，能够生成标准的INSERT语句和兼容的查询语法。这为在MySQL环境下进行TPC-H基准测试提供了完整的工具链支持。