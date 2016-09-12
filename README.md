# Unidata Tomcat Docker

This repository contains files necessary to build and run a security hardened Tomcat Docker container, based off of the canonical [Tomcat base image](https://hub.docker.com/_/tomcat/). The Unidata Tomcat Docker images associated with this repository are [available on Docker Hub](https://hub.docker.com/r/unidata/tomcat-docker/).

## Security Hardening Measures

This Tomcat container was security hardened according to [OWASP recommendations](https://www.owasp.org/index.php/Securing_tomcat). Specifically,

- Eliminated default Tomcat web applications
- Run Tomcat with unprivileged user `tomcat`
- All files in `CATALINA_HOME` are owned by user `tomcat`
- Files in `CATALINA_HOME/conf` are read only (`400`) by user `tomcat`
- Files in `CATALINA_HOME/logs` are write only (`300`) by user `tomcat`
- Server version information is obscured to user
- Stack traces are not returned to user
- Container-wide `umask` of `007`

## Versions

- `unidata/tomcat-docker:8` based off of [canonical Tomcat 8 container](https://hub.docker.com/_/tomcat/) (`tomcat:jre8`).
