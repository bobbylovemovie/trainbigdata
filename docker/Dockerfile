FROM ubuntu:22.04

LABEL org.opencontainers.image.title="trainbigdata:2026" \
      org.opencontainers.image.description="Single-node Big Data sandbox (Hadoop, HBase, Hive, Spark, MariaDB, JupyterLab) replacing the Cloudera QuickStart VM"

ARG HADOOP_VERSION=3.3.6
ARG HIVE_VERSION=3.1.3
ARG HBASE_VERSION=2.5.15
ARG SPARK_VERSION=3.5.9
ARG FLUME_VERSION=1.11.0
ARG MARIADB_JDBC_VERSION=3.4.1

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_MAPRED_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive \
    HBASE_HOME=/opt/hbase \
    SPARK_HOME=/opt/spark \
    FLUME_HOME=/opt/flume \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    HIVE_CONF_DIR=/opt/hive/conf \
    HBASE_CONF_DIR=/opt/hbase/conf \
    SPARK_CONF_DIR=/opt/spark/conf

# --- OS packages -----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-8-jdk-headless \
        python3 python3-pip python3-venv \
        mariadb-server mariadb-client \
        curl wget ca-certificates gnupg netcat-openbsd less vim procps unzip \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

# JAVA_HOME differs by arch (java-8-openjdk-amd64 / java-8-openjdk-arm64);
# resolve it once at build time instead of relying on shell expansion at runtime.
RUN ln -sfn "$(dirname "$(dirname "$(readlink -f "$(which javac)")")")" /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH=${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${HIVE_HOME}/bin:${HBASE_HOME}/bin:${SPARK_HOME}/bin:${FLUME_HOME}/bin:${PATH}

# --- Hadoop ------------------------------------------------------------------
RUN wget -q "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" -O /tmp/hadoop.tgz \
    && tar -xzf /tmp/hadoop.tgz -C /opt \
    && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm /tmp/hadoop.tgz

# --- Hive ---------------------------------------------------------------------
RUN wget -q "https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz" -O /tmp/hive.tgz \
    && tar -xzf /tmp/hive.tgz -C /opt \
    && mv /opt/apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} \
    && rm /tmp/hive.tgz \
    && rm -f ${HIVE_HOME}/lib/guava-*.jar \
    && cp ${HADOOP_HOME}/share/hadoop/common/lib/guava-*.jar ${HIVE_HOME}/lib/

# --- HBase ----------------------------------------------------------------
RUN wget -q "https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz" -O /tmp/hbase.tgz \
    && tar -xzf /tmp/hbase.tgz -C /opt \
    && mv /opt/hbase-${HBASE_VERSION} ${HBASE_HOME} \
    && rm /tmp/hbase.tgz

# --- Spark ------------------------------------------------------------------
RUN wget -q "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" -O /tmp/spark.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt \
    && mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
    && rm /tmp/spark.tgz

# --- Flume (legacy ingestion concept, kept optional) -------------------------
RUN wget -q "https://downloads.apache.org/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz" -O /tmp/flume.tgz \
    && tar -xzf /tmp/flume.tgz -C /opt \
    && mv /opt/apache-flume-${FLUME_VERSION}-bin ${FLUME_HOME} \
    && rm /tmp/flume.tgz

# --- MariaDB JDBC driver, shared by Hive metastore and the Spark JDBC lab ---
RUN wget -q "https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/${MARIADB_JDBC_VERSION}/mariadb-java-client-${MARIADB_JDBC_VERSION}.jar" \
        -O ${HIVE_HOME}/lib/mariadb-java-client-${MARIADB_JDBC_VERSION}.jar \
    && cp ${HIVE_HOME}/lib/mariadb-java-client-${MARIADB_JDBC_VERSION}.jar /opt/mariadb-java-client.jar

# --- JupyterLab --------------------------------------------------------------
# Versions pinned: an unconstrained `pip install jupyterlab` makes pip's
# resolver backtrack through hundreds of old jupyterlab/jupyterlab-server
# releases on this Python (very slow). Pinning avoids that entirely.
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir jupyterlab==4.2.5 jupyterlab-server==2.27.3

# --- student user + directories ---------------------------------------------
RUN useradd -m -s /bin/bash student \
    && echo "student:student" | chpasswd \
    && mkdir -p /opt/hadoop/data/nn /opt/hadoop/data/dn /opt/hadoop/data/tmp /opt/hadoop/data/pid /opt/hadoop/data/logs /opt/hadoop/data/zookeeper /var/log/lab /home/student/notebooks \
    && chown -R student:student ${HADOOP_HOME} ${HIVE_HOME} ${HBASE_HOME} ${SPARK_HOME} ${FLUME_HOME} /var/log/lab /home/student

COPY docker/config/hadoop/ ${HADOOP_CONF_DIR}/
COPY docker/config/hive/hive-site.xml ${HIVE_CONF_DIR}/hive-site.xml
COPY docker/config/hbase/hbase-site.xml ${HBASE_CONF_DIR}/hbase-site.xml
COPY docker/config/flume/flume.conf ${FLUME_HOME}/conf/flume.conf
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/labctl /usr/local/bin/labctl
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/bootstrap-hdfs.sh /usr/local/bin/bootstrap-hdfs.sh
COPY scripts/smoke-test.sh /usr/local/bin/smoke-test.sh
COPY datasets/ /opt/lab-datasets/
# Canonical lab files, OUTSIDE the /home/student volume so they stay in sync
# with the image on every rebuild. entrypoint.sh seeds ~/labs from here into
# the (persistent) student home on first boot only; smoke-test.sh always
# reads from here directly so it tests the image, not a stale seeded copy.
COPY labs/ /opt/labs/

# Precompile the modern WordCount example (see labs/03-mapreduce/README.md
# for why the original org.myorg.WordCount jar was not reused).
RUN mkdir -p /tmp/wc-classes \
    && javac -classpath "$(hadoop classpath)" -d /tmp/wc-classes /opt/labs/03-mapreduce/WordCount.java \
    && jar -cf /opt/labs/03-mapreduce/wordcount.jar -C /tmp/wc-classes . \
    && rm -rf /tmp/wc-classes

RUN chmod +x /usr/local/bin/labctl /usr/local/bin/entrypoint.sh /usr/local/bin/bootstrap-hdfs.sh /usr/local/bin/smoke-test.sh \
    && chown -R student:student /opt/labs /opt/lab-datasets

EXPOSE 8888 9870 8088 16010 10000

VOLUME ["/opt/hadoop/data", "/var/lib/mysql", "/home/student"]

WORKDIR /home/student
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
