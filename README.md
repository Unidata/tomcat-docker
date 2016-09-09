# Unidata Tomcat Docker

[![Travis Status](https://travis-ci.org/Unidata/tomcat-docker.svg?branch=master)](https://travis-ci.org/Unidata/tomcat-docker)

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

## Pulling the Container

To pull the Unidata Tomcat container from the Docker Hub registry:

      docker pull unidata/tomcat:latest

It is best to be on a fast network when pulling containers as they can be quite large.

## Building the Container

Alternatively, rather than pulling the container you can clone this repository and build the Unidata Tomcat Docker container:

    docker build  -t unidata/tomcat:latest .

It is best to be on a fast network when building containers as there can be many intermediate layers to download.
