#!/bin/bash
set -e

if [ "$1" = 'catalina.sh' ]; then
    chown -R tomcat:tomcat ${CATALINA_HOME} && \
        chmod 400 ${CATALINA_HOME}/conf/* && \
        chmod 300 ${CATALINA_HOME}/logs/.
    sync
    exec gosu tomcat "$@"
fi

exec "$@"
