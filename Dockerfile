FROM centos:centos6
MAINTAINER Kyäni, Inc. <devops@kyanicorp.com>

EXPOSE 80

ADD bin/KMS_NAME /opt/KMS_NAME
RUN chmod +x /opt/KMS_NAME
WORKDIR /opt
CMD /opt/KMS_NAME
