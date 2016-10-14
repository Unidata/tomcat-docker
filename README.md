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

## Versions

- `unidata/tomcat-docker:8` based off of [canonical Tomcat 8 container](https://hub.docker.com/_/tomcat/) (`tomcat:jre8`).

## HTTP Over SSL

This Tomcat container can support HTTP over SSL. For example, generate a self-signed certificate with `openssl` (or better yet, obtain a real certificate from a certificate authority):

```bash
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
    "/C=US/ST=Colorado/L=Boulder/O=Unidata/CN=tomcat.example.com" -keyout \
    ./ssl.key -out ./ssl.crt
```

Then augment the `server.xml` from this repository with this additional XML snippet for [Tomcat SSL capability](https://tomcat.apache.org/tomcat-8.0-doc/ssl-howto.html):

```xml
<Connector port="8443"
       maxThreads="150"
       enableLookups="false"
       disableUploadTimeout="true"
       acceptCount="100"
       scheme="https"
       secure="true"
       SSLEnabled="true"
       SSLCertificateFile="${catalina.base}/conf/ssl.crt"
       SSLCertificateKeyFile="${catalina.base}/conf/ssl.key" />
```

Mount over the existing `server.xml` and add the SSL certificate and private key with:

```bash
docker run -it -d  -p 80:8080 -p 443:8443 \
    -v /path/to/server.xml:/usr/local/tomcat/conf/server.xml \
    -v /path/to/ssl.crt:/usr/local/tomcat/conf/ssl.crt \
    -v /path/to/ssl.key:/usr/local/tomcat/conf/ssl.key \
    unidata/tomcat-docker:8
```

or if using `docker-compose` the `docker-compose.yml` will look like:

```yaml
unidata-tomcat:
  image: unidata/tomcat-docker:8
  ports:
    - "80:8080"
    - "443:8443"
  volumes:
    - /path/to/ssl.crt:/usr/local/tomcat/conf/ssl.crt
    - /path/to/ssl.key:/usr/local/tomcat/conf/ssl.key
    - /path/to/server.xml:/usr/local/tomcat/conf/server.xml
```
