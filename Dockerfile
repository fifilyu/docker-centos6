FROM centos:6

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

####################
# 设置YUM
####################
RUN grep '*.i386 *.i586 *.i686' /etc/yum.conf || echo "exclude=*.i386 *.i586 *.i686" >> /etc/yum.conf
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
COPY file/etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

COPY pkg/rpm/epel-release-6-8.noarch.rpm /tmp/
RUN ulimit -n 1024 && rpm -ivh /tmp/epel-release-6-8.noarch.rpm

COPY file/etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo
RUN ulimit -n 1024 && yum makecache

####################
# 更新系统软件包
####################
RUN ulimit -n 1024 && yum update -y

####################
# 中文环境支持
####################
RUN ulimit -n 1024 && yum install -y wqy-microhei-fonts wqy-zenhei-fonts wqy-unibit-fonts


####################
# 安装常用软件包
####################
RUN ulimit -n 1024 && yum install -y iproute rsync yum-utils tree pwgen vim-enhanced wget curl screen bzip2 tcpdump unzip tar xz bash-completion telnet chrony sudo strace openssh-server openssh-clients mlocate

RUN grep 'set fencs=utf-8,gbk' /etc/vimrc || echo 'set fencs=utf-8,gbk' >>/etc/vimrc

####################
# 设置文件句柄
####################
RUN grep '*               soft   nofile            65535' /etc/security/limits.conf || echo "*               soft   nofile            65535" >> /etc/security/limits.conf
RUN grep '*               hard   nofile            65535' /etc/security/limits.conf || echo "*               hard   nofile            65535" >> /etc/security/limits.conf

####################
# 关闭SELINUX
####################
RUN echo SELINUX=disabled>/etc/selinux/config
RUN echo SELINUXTYPE=targeted>>/etc/selinux/config


####################
# 配置SSH
####################
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
COPY file/etc/ssh/sshd_config /etc/ssh/sshd_config

####################
# 安装Python3.12
####################
RUN ulimit -n 1024 && yum install -y tcl tk xz zlib gcc

###########################
## 安装依赖：OpenSSL-1.1.1n
###########################
COPY file/usr/local/openssl-1.1.1n /usr/local/openssl-1.1.1n
RUN echo '/usr/local/openssl-1.1.1n/lib' > /etc/ld.so.conf.d/openssl-1.1.1n.conf
RUN ldconfig
RUN ldconfig -p | grep openssl-1.1.1n 

###########################
## 安装依赖：SQLite-3.33
###########################
COPY file/usr/local/sqlite-3.33 /usr/local/sqlite-3.33
RUN echo '/usr/local/sqlite-3.33/lib' > /etc/ld.so.conf.d/sqlite-3.33.conf
RUN ldconfig
RUN ldconfig -p | grep sqlite-3.33

###########################
## 安装Python312
###########################
COPY file/usr/local/python-3.12.2/ /usr/local/python-3.12.2/
WORKDIR /usr/local
RUN test -L python3 || ln -s python-3.12.2 python3

ARG py_bin_dir=/usr/local/python3/bin
RUN echo "export PATH=${py_bin_dir}:\${PATH}" > /etc/profile.d/python3.sh

WORKDIR ${py_bin_dir}
RUN test -L pip312 || ln -v -s pip3 pip312
RUN test -L python312 || ln -v -s python3 python312

RUN ./pip312 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN ./pip312 install --root-user-action=ignore -U pip

####################
# 安装常用编辑工具
####################
RUN ./pip312 install --root-user-action=ignore -U yq toml-cli

COPY file/usr/local/bin/jq /usr/local/bin/jq
RUN chmod 755 /usr/local/bin/jq

RUN ulimit -n 1024 && yum install -y xmlstarlet crudini

####################
# BASH设置
####################
RUN echo "alias ll='ls -l --color=auto --group-directories-first'" >> /root/.bashrc

####################
# 清理
####################
RUN rm -f /root/anaconda-ks.cfg /root/install.log  /root/install.log.syslog
RUN ulimit -n 1024 && yum clean all

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22
