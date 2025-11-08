# FROM huangt820/dolphinscheduler:3.3.1-standalone-py-datax
FROM apache/dolphinscheduler-standalone-server:3.3.1

# 安装 python3
RUN apt-get update && sudo apt-get install -y python3 && rm -rf /var/lib/apt/lists/*

# 安装aliyunpan同步工具
RUN mkdir -p /opt/aliyunpan
COPY ./yunpan/aliyunpan /opt/aliyunpan

# 安装dataX
RUN mkdir -p /opt/datax/script
COPY ./datax /opt/datax

WORKDIR /opt/dolphinscheduler

# 安装mvn工具用于插件下载
RUN mkdir -p ./.mvn/wrapper
COPY ./3.3.1/mvn/wrapper ./.mvn/wrapper/

# 安装插件
COPY ./libs/mysql-connector-j-9.4.0.jar ./standalone-server/libs/
COPY ./3.3.1/plugins ./plugins

# 禁用90%负载保护机制
COPY ./3.3.1/conf/application.yaml ./standalone-server/conf/

# 环境变量
ENV PYTHON_LAUNCHER=/usr/bin/python3
ENV DATAX_LAUNCHER=/opt/datax/bin/datax.py
RUN echo 'export JAVA_HOME=/opt/java/openjdk' >> /etc/bash.bashrc
RUN echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/bash.bashrc
RUN echo 'export PYTHON_LAUNCHER=/usr/bin/python3' >> /etc/bash.bashrc
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN echo 'export DATAX_LAUNCHER=/opt/datax/bin/datax.py' >> /etc/bash.bashrc
