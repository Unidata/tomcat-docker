###
# Dockerfile for Unidata Tomcat.
###
FROM tomcat:11-jdk17

LABEL org.opencontainers.image.authors="UCAR / NSF Unidata"

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends  \
        gosu \
        && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Eliminate default web applications
    rm -rf ${CATALINA_HOME}/webapps/* && \
    rm -rf ${CATALINA_HOME}/webapps.dist && \
    mkdir -p ${CATALINA_HOME}/conf/Catalina/localhost

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
