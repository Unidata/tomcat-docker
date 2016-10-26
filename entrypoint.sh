#!/bin/bash
set -e

if [ "$1" = 'catalina.sh' ]; then

    ###
    # Change CATALINA_HOME ownership to tomcat user and tomcat group
    # Restrict permissions on conf
    ###

    chown -R tomcat:tomcat ${CATALINA_HOME} && chmod 400 ${CATALINA_HOME}/conf/*
    sync
    exec gosu tomcat "$@"
fi

exec "$@"
