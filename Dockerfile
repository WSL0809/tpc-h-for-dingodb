FROM ubuntu:20.04

# 设置非交互模式避免安装时的提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    make \
    mysql-client \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /tpch

# 复制TPC-H文件
COPY . .

# 设置dbgen目录权限
RUN chmod -R 755 dbgen/

# 进入dbgen目录并构建
WORKDIR /tpch/dbgen

# 创建makefile
RUN cp makefile.suite makefile

# 修改makefile配置
RUN sed -i 's/CC      = /CC      = gcc/' makefile && \
    sed -i 's/DATABASE= /DATABASE= MYSQL/' makefile && \
    sed -i 's/MACHINE = /MACHINE = LINUX/' makefile && \
    sed -i 's/WORKLOAD = /WORKLOAD = TPCH/' makefile

# 修复malloc.h问题
RUN sed -i 's/#include <malloc.h>/#include <stdlib.h>/' bm_utils.c

# 编译
RUN make clean && make

# 设置环境变量
ENV DSS_PATH=/tpch/dbgen
ENV DSS_CONFIG=/tpch/dbgen
ENV DSS_QUERY=/tpch/dbgen

# 创建一个启动脚本
RUN echo '#!/bin/bash\n\
echo "TPC-H Docker环境已准备就绪"\n\
echo "dbgen和qgen已编译完成"\n\
echo "使用以下命令生成数据:"\n\
echo "  ./dbgen -s 1    # 生成scale factor 1的数据"\n\
echo "  ./qgen -d 1     # 生成查询1"\n\
echo ""\n\
ls -la dbgen qgen\n\
exec "$@"' > /tpch/start.sh && chmod +x /tpch/start.sh

ENTRYPOINT ["/tpch/start.sh"]
CMD ["/bin/bash"]