#!/bin/bash
set -e

# preferable to fire up Tomcat via start-tomcat.sh which will start Tomcat with
# security manager, but inheriting containers can also start Tomcat via
# catalina.sh

USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}

if [ "$1" = 'start-tomcat.sh' ] || [ "$1" = 'catalina.sh' ]; then
    ###
    # Tomcat user
    ###
    if ! id tomcat; then
      groupadd -r tomcat -g ${GROUP_ID}
      useradd -g tomcat -d ${CATALINA_HOME} \
          -u ${USER_ID} \
          -s /sbin/nologin \
          -c "Tomcat user" tomcat
    fi

    ###
    # Change CATALINA_HOME ownership to tomcat user and tomcat group
    # Restrict permissions on conf
    ###

    chown -R tomcat:tomcat ${CATALINA_HOME} && chmod 400 ${CATALINA_HOME}/conf/*
    sync
    exec gosu tomcat "$@"
fi

exec "$@"
