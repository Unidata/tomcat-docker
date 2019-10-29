###
# Dockerfile for Unidata Tomcat.
###
FROM tomcat:8.5-jdk8-openjdk

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
    cd ${CATALINA_HOME}/lib && \
    mkdir -p org/apache/catalina/util/ && \
    unzip -j catalina.jar org/apache/catalina/util/ServerInfo.properties \
        -d org/apache/catalina/util/ && \
    sed -i 's/server.info=.*/server.info=Apache Tomcat/g' \
        org/apache/catalina/util/ServerInfo.properties && \
    zip -ur catalina.jar \
        org/apache/catalina/util/ServerInfo.properties && \
    rm -rf org && cd ${CATALINA_HOME} && \
    sed -i 's/<Connector/<Connector server="Apache" secure="true"/g' \
        ${CATALINA_HOME}/conf/server.xml && \
    ###
    # Ugly, embarrassing, fragile solution to adding the CredentialHandler
    # element until we get XSLT or the equivalent figured out. True for other
    # XML manipulations herein.
    # https://github.com/Unidata/tomcat-docker/issues/27
    # https://stackoverflow.com/questions/32178822/tomcat-understanding-credentialhandler
    ##

    sed -i 's/resourceName="UserDatabase"\/>/resourceName="UserDatabase"><CredentialHandler className="org.apache.catalina.realm.MessageDigestCredentialHandler" algorithm="SHA" \/><\/Realm>/g' \
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
ENV GOSU_VERSION 1.11

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
    export KEY=B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            keyserver.pgp.com \
                            pgp.mit.edu) ; do \
        gpg --batch --keyserver "$server" --recv-keys $KEY && break || : ; \
    done; \
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
