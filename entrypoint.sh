#!/bin/bash
set -e

# preferable to fire up Tomcat via start-tomcat.sh which will start Tomcat with
# security manager, but inheriting containers can also start Tomcat via
# catalina.sh

if [ "$1" = 'start-tomcat.sh' ] || [ "$1" = 'catalina.sh' ]; then

    USER_ID=${TOMCAT_USER_ID:-1000}
    GROUP_ID=${TOMCAT_GROUP_ID:-1000}

    ###
    # Tomcat user
    ###
    groupadd -r tomcat -g ${GROUP_ID} && \
    useradd -u ${USER_ID} -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin \
        -c "Tomcat user" tomcat

    ###
    # Change CATALINA_HOME ownership to tomcat user and tomcat group
    # Restrict permissions on conf
    ###

    chown -R tomcat:tomcat ${CATALINA_HOME} && chmod 400 ${CATALINA_HOME}/conf/*
    sync

    ###
    # Deactivate CORS filter in web.xml if DISABLE_CORS=1
    # Useful if CORS is handled outside of Tomcat (e.g. in a proxying webserver like nginx)
    ###
    if [ "$DISABLE_CORS" == "1" ]; then
      echo "Deactivating Tomcat CORS filter"
      sed -i 's/<!-- CORS_START.*/<!-- CORS DEACTIVATED BY DISABLE_CORS -->\n<!--/; s/^.*<!-- CORS_END -->/-->/' \
        ${CATALINA_HOME}/conf/web.xml
    fi

    exec gosu tomcat "$@"
fi

exec "$@"
