# 일단 파이썬을 기본으로 깔고 그 위에 pyspark 올리고 app.py 실행시키는 쪽으로다가.. ?? -> noooooo!!!. spark에 s3를 올리려면 하둡api가 필요하다! ubuntu같은 운영체제 위에 올리는 게 맞다.
FROM ubuntu:20.04

# Timezone 설정
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
WORKDIR /usr/
# 베이스 이미지에 필요한 소프트웨어를 설치 및 구성
RUN apt-get update && \
    apt-get install -y curl unzip python3 python3-setuptools wget python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    #easy_install3 pip py4j && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHONHASHSEED 0
ENV PYTHONHASHSEED UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# 설치 : 1) JAVA 11 , 2) HADOOP 3.3.4 , 3) SPARK 3.4.1
# JAVA
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get clean && \
    # 계속 apt-get clean 해주는 이유 :  패키지 관리자가 사용한 캐시 파일과 임시 파일을 정리하여 이미지 크기 축소에 도움됨
    rm -rf /var/lib/apt/lists/*
# JAVA_HOME 환경 변수 설정
ENV JAVA_HOME (dirname $(dirname $(readlink -f $(which java))))
ENV PATH $PATH:$JAVA_HOME/bin

# HADOOP
ENV HADOOP_VERSION 3.3.4
# 이건 그냥 변수에 값을 저장하는 걸로 생각하면 됨! 근데 이제 패키지의 환경 관련된 변수이므로 '환경변수'
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN wget "https://dlcdn.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz"
RUN tar -xvzf hadoop-3.3.4.tar.gz
RUN rm -rf $HADOOP_HOME/share/doc
    # 아마 필요없는 파일이라 지우는 듯...?
RUN chown -R root:root $HADOOP_HOME
    # 폴더의 소유자를 root로 변경

# SPARK
ENV SPARK_PACKAGE spark-3.4.1-bin-hadoop3
ENV SPARK_HOME /usr/spark-3.4.1-bin-hadoop3
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN wget "https://dlcdn.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz"
    #| gunzip \
RUN tar -xvzf spark-3.4.1-bin-hadoop3.tgz
#RUN mv spark-3.4.1-bin-hadoop3 /usr/spark-3.4.1-bin-hadoop3
    # 걍 이름 바꾸는거
RUN chown -R root:root $SPARK_HOME

# YARN_CONF_DIR 환경 변수 설정
ENV YARN_CONF_DIR $HADOOP_HOME/etc/hadoop
# HADOOP_CONF_DIR 환경 변수 설정
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop

# install Hadoop-AWS.jar
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
# install AWS-java.jar
RUN wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
# move jar files
RUN mv hadoop-aws-3.3.4.jar $SPARK_HOME/jars
RUN mv aws-java-sdk-bundle-1.12.262.jar $SPARK_HOME/jars

# Copy your PySpark application code to the container
COPY ./drop-dup-jjw.py usr/drop-dup-jjw.py

# Run your PySpark application
CMD ["/usr/spark-3.4.1-bin-hadoop3/bin/spark-submit", "/usr/drop-dup-jjw.py"]