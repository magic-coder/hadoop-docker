# Creates pseudo distributed hadoop 3.0.0
#
# docker build -t sequenceiq/hadoop .

FROM sequenceiq/pam:centos-6.5
MAINTAINER SequenceIQ

USER root
ENV http_proxy http://10.239.4.80:913
ENV https_proxy http://10.239.4.80:913
# install dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl which tar sudo openssh-server openssh-clients rsync
# update libselinux. see https://github.com/sequenceiq/hadoop-docker/issues/14
RUN yum update -y libselinux

# java
#RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN rpm -i jdk-8u111-linux-x64.rpm
RUN rm jdk-8u111-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# download native support
RUN mkdir -p /tmp/native
ADD hadoop-native-64-3.0-alpha2.tgz /tmp/native

# hadoop
ADD hadoop-3.0.0-alpha2-SNAPSHOT.tar.gz /usr/local/
RUN cd /usr/local && ln -s ./hadoop-3.0.0-alpha2-SNAPSHOT hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV PATH=${HADOOP_COMMON_HOME}/bin:${HADOOP_COMMON_HOME}/sbin:${HADOOP_COMMON_HOME}/libexec:${PATH}

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# site.xml
ADD core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# fixing the libhadoop.so like a boss
RUN rm -rf /usr/local/hadoop/lib/native
RUN mv /tmp/native /usr/local/hadoop/lib

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config
# test for YARN-4266
RUN groupadd -g 1002 hadoop
RUN adduser -m -u 1003 -g hadoop --home /home/testuser1 testuser1
RUN adduser -m -u 1001 yarn
#USER testuser1
#WORKDIR /home/testuser1
#
#install python
#ADD get-pip.py /get-pip.py
#RUN chmod +x get-pip.py && python get-pip.py
#RUN yum install -y python-pip python-devel
#RUN yum groupinstall -y "Development Tools"
#RUN pip install pika
#add python app
#RUN gpasswd -a yarn wheel
#ADD run.py /run.py
