###
# Dockerfile for Unidata Tomcat.
###
FROM tomcat:8.0-jre8

###
# Usual maintenance
###

RUN apt-get update && apt-get install -y zip

###
# Tomcat User
###

RUN groupadd -r tomcat && \
	useradd -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin \
  -c "Tomcat user" tomcat

###
# Tomcat start script
###

COPY start-tomcat.sh ${CATALINA_HOME}/bin

RUN chmod +x ${CATALINA_HOME}/bin/start-tomcat.sh

###
# Eliminate default web applications
###

RUN rm -rf ${CATALINA_HOME}/webapps/* && \
    rm -rf ${CATALINA_HOME}/server/webapps/* 

WORKDIR ${CATALINA_HOME}/lib

###
# Obscuring server info
###

RUN mkdir -p org/apache/catalina/util/ && \
    unzip -j catalina.jar org/apache/catalina/util/ServerInfo.properties \
    -d org/apache/catalina/util/
RUN sed -i 's/server.info=.*/server.info=Apache Tomcat/g' \
    org/apache/catalina/util/ServerInfo.properties
RUN zip -ur catalina.jar org/apache/catalina/util/ServerInfo.properties
RUN rm -rf org

WORKDIR ${CATALINA_HOME}

RUN sed -i 's/<Connector/<Connector server="Apache" secure="true"/g' \
    ${CATALINA_HOME}/conf/server.xml

###
# Ugly, embarrassing, fragile solution to adding the digest attribute until we
# get XSLT or the equivalent figured out. True for other XML manipulations
# herein.
# https://github.com/Unidata/tomcat-docker/issues/27
##

RUN sed -i 's/resourceName/digest="SHA" resourceName/g' \
    ${CATALINA_HOME}/conf/server.xml

###
# Capture stack traces to non-existent file
###

COPY error-page.xml.snippet ${CATALINA_HOME}

RUN sed -i '$d' ${CATALINA_HOME}/conf/web.xml && \
    cat error-page.xml.snippet >> ${CATALINA_HOME}/conf/web.xml && \
    rm error-page.xml.snippet

###
# Setting restrictive umask container-wide
###

RUN echo "session optional pam_umask.so" >> /etc/pam.d/common-session
RUN sed -i 's/UMASK.*022/UMASK           007/g' /etc/login.defs

###
# gosu is a non-optimal way to deal with the mismatches between Unix user and
# group IDs inside versus outside the container resulting in permission
# headaches when writing to directory outside the container.
###

# Installation instructions copy/pasted from https://github.com/tianon/gosu
# minus ca-certificates which we are inheriting from parent container

ENV GOSU_VERSION 1.10

ENV GOSU_URL https://github.com/tianon/gosu/releases/download/$GOSU_VERSION

RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu $GOSU_URL/gosu-$dpkgArch \
    && wget -O /usr/local/bin/gosu.asc $GOSU_URL/gosu-$dpkgArch.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove wget

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

###
# Start container
###

CMD ["start-tomcat.sh"]
