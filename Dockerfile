###
# Dockerfile for Unidata Tomcat.
###

FROM tomcat:jre8

###
# Usual maintenance
###

RUN apt-get update && apt-get install -y openjdk-8-jdk

###
# Tomcat User
###

RUN groupadd -r tomcat && \
	useradd -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin \
  -c "Tomcat user" tomcat
`
###
# Eliminate default web applications
###

RUN rm -rf ${CATALINA_HOME}/webapps/* && \
    rm -rf ${CATALINA_HOME}/server/webapps/* 

###
# Change CATALINA_HOME ownership to tomcat user and tomcat group
# Restrict permission on conf and log directories
###

RUN chown -R tomcat:tomcat ${CATALINA_HOME} && \
    chmod 400 ${CATALINA_HOME}/conf/* && \
    chmod 300 ${CATALINA_HOME}/logs/.

WORKDIR ${CATALINA_HOME}/lib

###
# Obscuring server info
###

RUN jar xf catalina.jar org/apache/catalina/util/ServerInfo.properties
RUN sed -i 's/server.info=.*/server.info=Apache Tomcat/g' org/apache/catalina/util/ServerInfo.properties
RUN jar uf catalina.jar org/apache/catalina/util/ServerInfo.properties
RUN rm -rf org

WORKDIR ${CATALINA_HOME}

RUN sed -i 's/<Connector/<Connector server="Apache"/g' \
    ${CATALINA_HOME}/conf/server.xml

###
# Capture stack traces to non-existant file
###

COPY error-page.xml.snippet ${CATALINA_HOME}

RUN sed -i '$d' ${CATALINA_HOME}/conf/web.xml && \
    cat error-page.xml.snippet >> ${CATALINA_HOME}/conf/web.xml && \
    rm error-page.xml.snippet

###
# Setting restrictive umask container wide
###

RUN echo "session optional pam_umask.so" >> /etc/pam.d/common-session
RUN sed -i 's/UMASK.*022/UMASK           007/g' /etc/login.defs

USER tomcat

CMD ["catalina.sh", "run"]
