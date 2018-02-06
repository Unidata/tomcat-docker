###
# Dockerfile for Unidata Tomcat.
###
FROM tomcat:8.0-jre8

###
# Usual maintenance
###
RUN apt-get update && \
    apt-get install -y \
        zip \
        && \
    ###
    # Cleanup apt
    ###
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    ###
    # Eliminate default web applications
    ###
    rm -rf ${CATALINA_HOME}/webapps/* && \
    rm -rf ${CATALINA_HOME}/server/webapps/* && \
    ###
    # Obscuring server info
    ###
    mkdir -p ${CATALINA_HOME}/lib/org/apache/catalina/util/ && \
    unzip -j ${CATALINA_HOME}/lib/catalina.jar \
        org/apache/catalina/util/ServerInfo.properties \
        -d ${CATALINA_HOME}/lib/org/apache/catalina/util/ && \
    sed -i 's/server.info=.*/server.info=Apache Tomcat/g' \
        ${CATALINA_HOME}/lib/org/apache/catalina/util/ServerInfo.properties && \
    zip -ur ${CATALINA_HOME}/lib/catalina.jar \
        ${CATALINA_HOME}/lib/org/apache/catalina/util/ServerInfo.properties && \
    rm -rf ${CATALINA_HOME}/lib/org && \
    sed -i 's/<Connector/<Connector server="Apache" secure="true"/g' \
        ${CATALINA_HOME}/conf/server.xml && \
    ###
    # Ugly, embarrassing, fragile solution to adding the digest attribute until we
    # get XSLT or the equivalent figured out. True for other XML manipulations
    # herein.
    # https://github.com/Unidata/tomcat-docker/issues/27
    ##
    sed -i 's/resourceName/digest="SHA" resourceName/g' \
        ${CATALINA_HOME}/conf/server.xml && \
    ###
    # Setting restrictive umask container-wide
    ###
    echo "session optional pam_umask.so" >> /etc/pam.d/common-session && \
    sed -i 's/UMASK.*022/UMASK           007/g' /etc/login.defs

###
# gosu is a non-optimal way to deal with the mismatches between Unix user and
# group IDs inside versus outside the container resulting in permission
# headaches when writing to directory outside the container.
###

# Installation instructions copy/pasted from
# https://github.com/tianon/gosu/blob/master/INSTALL.md
# minus ca-certificates which we are inheriting from parent container
ENV GOSU_VERSION 1.10

RUN set -ex; \
    \
    fetchDeps=' \
        wget \
    '; \
    apt-get update; \
    apt-get install -y --no-install-recommends $fetchDeps; \
    rm -rf /var/lib/apt/lists/*; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu \
        "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc \
        "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    \
    # verify the signature
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
    chmod +x /usr/local/bin/gosu; \
    # verify that the binary works
    gosu nobody true; \
    \
    apt-get purge -y --auto-remove $fetchDeps

###
# Capture stack traces to non-existent file
###
COPY error-page.xml.snippet ${CATALINA_HOME}
RUN sed -i '$d' ${CATALINA_HOME}/conf/web.xml && \
    cat error-page.xml.snippet >> ${CATALINA_HOME}/conf/web.xml && \
    rm error-page.xml.snippet

###
# Tomcat start script
###
COPY start-tomcat.sh ${CATALINA_HOME}/bin
COPY entrypoint.sh /

###
# Start container
###
ENTRYPOINT ["/entrypoint.sh"]
CMD ["start-tomcat.sh"]
