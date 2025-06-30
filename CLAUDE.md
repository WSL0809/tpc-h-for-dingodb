# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the TPC-H benchmark toolkit version 3.0.1 - a database benchmark for decision support systems. The toolkit consists of:

- **DBGEN**: Database population generator that creates test data
- **QGEN**: Query generator that creates parameterized SQL queries from templates
- **Reference data**: Pre-generated reference datasets for validation
- **SQL queries**: 22 standard TPC-H benchmark queries

## Core Architecture

### Main Components

1. **dbgen/** - Core data generation toolkit
   - `dbgen` executable: Generates database tables as flat files or direct DB load
   - `qgen` executable: Generates executable queries from templates
   - `build.c`: Table generation logic (mk_XXXX routines for each table)
   - `print.c`: Output formatting (pr_XXXX routines for each table)
   - `driver.c`: Main control and command line parsing for DBGEN
   - `qgen.c`: Main control for query generation
   - `varsub.c`: Parameter substitution for query templates

2. **ref_data/** - Reference datasets for validation at different scale factors (1, 100)

3. **dev-tools/** - Development utilities

### Data Schema
The benchmark implements a sales/order processing schema with 8 tables:
- CUSTOMER, SUPPLIER, PART, PARTSUPP, ORDERS, LINEITEM, NATION, REGION

## Build Instructions

### Building the Executables

1. Copy the makefile template:
   ```bash
   cd dbgen
   cp makefile.suite makefile
   ```

2. Edit the makefile to set:
   - `CC` = your C compiler (gcc, clang, etc.)
   - `DATABASE` = target database (ORACLE, INFORMIX, DB2, SQLSERVER, etc.)
   - `MACHINE` = platform (LINUX, WIN32, etc.)
   - `WORKLOAD` = TPCH

3. Build:
   ```bash
   make clean
   make
   ```

This creates `dbgen` and `qgen` executables.

## Common Commands

### Data Generation

Generate scale factor 1 dataset (default ~1GB):
```bash
cd dbgen
./dbgen -s 1
```

Generate specific table only (L=lineitem, O=orders, etc.):
```bash
./dbgen -s 1 -T L -f
```

Generate large datasets in parallel chunks:
```bash
./dbgen -s 100 -S 1 -C 100 -T L -v  # First chunk
./dbgen -s 100 -S 2 -C 100 -T L -v  # Second chunk
# Continue incrementing -S for each chunk
```

Generate update files for throughput testing:
```bash
./dbgen -s 1 -U 4  # 4 update streams
```

### Query Generation

Generate query with default parameters:
```bash
cd dbgen
./qgen -d 1  # Query 1 with defaults
```

Generate query parameter sets:
```bash
./qgen -s 1 -r 101000000 -l subparam_1
```

Generate all 22 queries:
```bash
for i in {1..22}; do ./qgen -d $i > query_$i.sql; done
```

### Validation

Compare generated data against reference:
```bash
cd dbgen/reference
# Run reference commands like:
bash cmd_base_sf1
bash cmd_qgen_sf1
```

Run answer validation:
```bash
cd dbgen/check_answers
./pairs.sh dir1 dir2  # Compare two result sets
```

## File Organization

- `dbgen/queries/` - SQL query templates (1.sql through 22.sql)
- `dbgen/answers/` - Expected query outputs for validation
- `dbgen/variants/` - Alternative query formulations
- `dbgen/tests/` - Test scripts for data validation
- `dbgen/reference/` - Reference command files for validation
- `ref_data/` - Pre-generated reference datasets

## Environment Variables

- `DSS_PATH` - Directory for flat file output (default: current dir)
- `DSS_CONFIG` - Directory for config files (default: current dir)  
- `DSS_DIST` - Distribution definition file (default: dists.dss)
- `DSS_QUERY` - Directory for query templates (default: current dir)

## Scale Factors

Valid TPC-H scale factors: 1, 10, 100, 300, 1000, 3000, 10000, 30000, 100000
- Scale factor 1 ≈ 1GB of data
- Scale factor 100 ≈ 100GB of data

## Query Parameter Generation

Query parameters are generated using specific random seeds. The QGEN tool uses these to create reproducible parameter sets for benchmark runs. Each query has multiple parameters that get substituted into templates.

## Data Validation

Use the reference data and command files to validate your generated data matches the official TPC-H reference outputs. This is critical for benchmark compliance.