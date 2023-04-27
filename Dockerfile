###
# Dockerfile for Unidata Tomcat.
###
FROM tomcat:10-jdk17

MAINTAINER Unidata

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends  \
        gosu \
        zip \
        unzip \
        && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Eliminate default web applications
    rm -rf ${CATALINA_HOME}/webapps/* && \
    rm -rf ${CATALINA_HOME}/webapps.dist && \
    # Obscuring server info
    cd ${CATALINA_HOME}/lib && \
    mkdir -p org/apache/catalina/util/ && \
    unzip -j catalina.jar org/apache/catalina/util/ServerInfo.properties \
        -d org/apache/catalina/util/ && \
    sed -i 's/server.info=.*/server.info=Apache Tomcat/g' \
        org/apache/catalina/util/ServerInfo.properties && \
    zip -ur catalina.jar \
        org/apache/catalina/util/ServerInfo.properties && \
    rm -rf org && cd ${CATALINA_HOME} && \
    # Setting restrictive umask container-wide
    echo "session optional pam_umask.so" >> /etc/pam.d/common-session && \
    sed -i 's/UMASK.*022/UMASK           007/g' /etc/login.defs

# Security enhanced web.xml
COPY web.xml ${CATALINA_HOME}/conf/

# Security enhanced server.xml
COPY server.xml ${CATALINA_HOME}/conf/

# Tomcat start script
COPY start-tomcat.sh ${CATALINA_HOME}/bin
COPY entrypoint.sh /

# Start container
ENTRYPOINT ["/entrypoint.sh"]
CMD ["start-tomcat.sh"]
