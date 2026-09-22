- [Unidata Tomcat Docker](#h-C944C5F1)
  - [Introduction](#h-1411CF81)
    - [Security Hardening Measures](#h-6C9EE33A)
      - [Introduction](#h-F5641083)
      - [web.xml Enhancements](#h-76CE835C)
      - [server.xml Enhancements](#h-8027E0B0)
      - [Digested Passwords](#h-4CE92D2E)
      - [CVEs](#h-C1DF14EF)
  - [Versions](#h-6C0AB867)
  - [Prerequisites](#h-61809CB7)
  - [Installation](#h-FB3558BB)
  - [Usage](#h-B602CE28)
  - [Configuration](#h-AFA7F4DC)
    - [Configurable Tomcat UID and GID](#h-E4632DC9)
    - [HTTPS](#h-D725A36E)
      - [Self-signed Certificates](#h-C24884FC)
      - [Certificate from CA](#h-B5E124BB)
  - [Testing](#h-32889858)



<a id="h-C944C5F1"></a>

# Unidata Tomcat Docker

A security-hardened Tomcat container for [thredds-docker](https://github.com/Unidata/thredds-docker).


<a id="h-1411CF81"></a>

## Introduction

This repository contains files necessary to build and run a security hardened Tomcat Docker container, based off of a canonical [Tomcat base image](https://hub.docker.com/_/tomcat/). The Unidata Tomcat Docker images associated with this repository are [available on Docker Hub](https://hub.docker.com/r/unidata/tomcat-docker/). All default web applications have been expunged from this container so it will primarily serve as a base image for other containers.


<a id="h-6C9EE33A"></a>

### Security Hardening Measures


<a id="h-F5641083"></a>

#### Introduction

This image includes the security-related configuration changes listed below. Deployment and application security require additional configuration and validation.

-   Eliminated default Tomcat web applications
-   Run Tomcat with an unprivileged runtime UID/GID (via `entrypoint.sh`)
-   By default, only writable Tomcat runtime directories (`CATALINA_HOME/logs`, `CATALINA_HOME/temp`, and `CATALINA_HOME/work`) are owned by the configured runtime UID/GID. Ownership and permissions elsewhere in `CATALINA_HOME`, including `conf`, `bin`, `lib`, and `webapps`, are left unchanged.

In your runtime configuration, ensure `server.xml` and `web.xml` bind mounts are read-only. This prevents the Tomcat process from modifying configuration files supplied by the host and is a recommended security practice. For example, with Docker Compose:

```yaml
- ./files/server.xml:/usr/local/tomcat/conf/server.xml:ro
- ./files/web.xml:/usr/local/tomcat/conf/web.xml:ro
```


<a id="h-76CE835C"></a>

#### web.xml Enhancements

The following changes have been made to [web.xml](./web.xml) from the out-of-the-box version:

-   Added `SAMEORIGIN` anti-clickjacking option
-   HTTP header security filter (`httpHeaderSecurity`) uncommented/enabled


<a id="h-8027E0B0"></a>

#### server.xml Enhancements

The following changes have been made to [server.xml](./server.xml) from the out-of-the-box version:

-   Server version information is obscured to user via `server` attribute for all `Connector` elements
-   Shutdown port disabled
-   Tomcat-generated error responses omit stack traces, error details, and server information via `ErrorReportValve`. Application-defined error responses must separately avoid exposing sensitive details.
-   Digested passwords. See next section.

The active `Connector` has `relaxedPathChars` and `relaxedQueryChars` attributes. This change may not be optimal for security, but must be done [to accommodate DAP requests](https://github.com/Unidata/thredds-docker/issues/209) which THREDDS must perform.


<a id="h-4CE92D2E"></a>

#### Digested Passwords

This container configures a `UserDatabaseRealm` in `server.xml` with a `CredentialHandler` using the `sha-512` algorithm. Passwords defined in `tomcat-users.xml` must therefore use digested passwords in the `password` attributes of the `user` elements. Generating a digested password is simple. Here is an example for the `sha-512` digest algorithm:

```sh
docker run --rm tomcat:11-jdk17 \
    /usr/local/tomcat/bin/digest.sh -a sha-512 mysupersecretpassword
```

This command will yield something like:

```sh
mysupersecretpassword:94e334bc71163a69f2e984e73741f610e083a8e11764ee3e396f6935c3911f49$1$a5530e17501f83a60286f6363a8647a277c9cfdb
```

The hash after the `:` is what you will use for the `password` attribute in `tomcat-users.xml`.

More information about this topic is available in the [Tomcat documentation](https://tomcat.apache.org/tomcat-11.0-doc/realm-howto.html#Digested_Passwords).


<a id="h-C1DF14EF"></a>

#### CVEs

We strive to maintain the security of this project's DockerHub images by updating them with the latest upstream security improvements. If you have any security concerns, please email us at [security@unidata.ucar.edu](mailto:security@unidata.ucar.edu) to bring them to our attention.


<a id="h-6C0AB867"></a>

## Versions

See tags listed [on dockerhub](https://hub.docker.com/r/unidata/tomcat-docker/tags). Note, these versions are not necessarily static and will evolve due to upstream image changes. It's recommended to check regularly to ensure you have the latest image.


<a id="h-61809CB7"></a>

## Prerequisites

Before you begin using this Docker container project, make sure your system has Docker installed. Docker Compose is optional but recommended.


<a id="h-FB3558BB"></a>

## Installation

You can either pull the image from DockerHub with:

```sh
docker pull unidata/tomcat-docker:<version>
```

Or you can build it yourself with:

1.  ****Clone the repository****: `git clone https://github.com/Unidata/tomcat-docker.git`
2.  ****Navigate to the project directory****: `cd tomcat-docker`
3.  ****Build the Docker image****: `docker build -t tomcat-docker:<version>` .


<a id="h-B602CE28"></a>

## Usage

Note that this project is meant to serve as a base image for other containerized Docker Tomcat web applications. Refer to the image created by this project in your Dockerfile. For example:

```sh
FROM unidata/tomcat-docker:<version>
```

Sometimes it is useful to enter this container via bash and poke around, just to see what is there. For example,

```sh
docker run -it unidata/tomcat-docker:<version> bash
```


<a id="h-AFA7F4DC"></a>

## Configuration


<a id="h-E4632DC9"></a>

### Configurable Tomcat UID and GID

The problem with mounted Docker volumes and UID/GID mismatch headaches is best explained here: <https://denibertovic.com/posts/handling-permissions-with-docker-volumes/>.

This container allows you to control the Tomcat runtime UID/GID via `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` environment variables. If not set, the default UID/GID is `1000/1000`. For example,

```sh
docker run --name tomcat \
     -e TOMCAT_USER_ID=`id -u` \
     -e TOMCAT_GROUP_ID=`getent group $USER | cut -d':' -f3` \
     -v `pwd`/logs:/usr/local/tomcat/logs/ \
     -v  /path/to/your/webapp:/usr/local/tomcat/webapps \
     -d -p 8080:8080 unidata/tomcat-docker:<version>
```

where `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` have been configured with the desired runtime UID/GID. If using `docker compose`, see `compose.env` to configure the Tomcat runtime UID/GID inside the container.

Bind-mounted files must be readable by the configured runtime UID/GID. For example, a TLS private key with mode `0600` must be owned by `TOMCAT_USER_ID`.

This feature enables greater control of file permissions written outside the container via mounted volumes (e.g., files contained within the Tomcat logs directory such as `catalina.out`).

Derived images and applications that need additional runtime state can provide whitespace-separated directories relative to `CATALINA_HOME`:

```Dockerfile
ENV TOMCAT_ADDITIONAL_WRITABLE_DIRS="content/thredds"
```

At container startup, each existing directory is recursively assigned to the configured Tomcat runtime UID/GID. The base image itself continues to make only `logs`, `temp`, and `work` writable.

Note that containers that inherit this container and override `entrypoint.sh` must arrange the Tomcat runtime UID/GID themselves. The supplied `entrypoint.sh` creates an account when needed or reuses an existing account with the configured UID. On Docker Desktop for macOS, bind-mount ownership and permission behavior differs from native Linux, so matching container UID/GID values may not produce the same host filesystem behavior.


<a id="h-D725A36E"></a>

### HTTPS

This Tomcat container can support HTTPS for either self-signed certificates which can be useful for experimentation or certificates from a CA for a production server. For a complete treatment on this topic, see <https://tomcat.apache.org/tomcat-11.0-doc/ssl-howto.html>.


<a id="h-C24884FC"></a>

#### Self-signed Certificates

For local HTTPS testing, generate a 30-day self-signed RSA certificate. This certificate is not intended for production.

```sh
openssl req -new -newkey rsa:4096 -sha256 -days 30 -nodes -x509 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
    -keyout ./ssl.key -out ./ssl.crt
chmod 600 ./ssl.key
```

The private key must be owned by the Tomcat runtime UID (1000 by default) for the 600 permissions above.

Then augment the `server.xml` from this repository with this additional XML snippet for [Tomcat TLS capability](https://tomcat.apache.org/tomcat-11.0-doc/ssl-howto.html):

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150"
           enableLookups="false"
           disableUploadTimeout="true"
           acceptCount="100"
           SSLEnabled="true">
  <SSLHostConfig>
    <Certificate certificateFile="${catalina.base}/conf/ssl.crt"
                 certificateKeyFile="${catalina.base}/conf/ssl.key" />
  </SSLHostConfig>
</Connector>
```

Mount the configuration, certificate, and private key read-only. Publish HTTPS on loopback for this local test:

```sh
docker run -d -p 127.0.0.1:8443:8443 \
    -v "$PWD/server.xml:/usr/local/tomcat/conf/server.xml:ro" \
    -v "$PWD/ssl.crt:/usr/local/tomcat/conf/ssl.crt:ro" \
    -v "$PWD/ssl.key:/usr/local/tomcat/conf/ssl.key:ro" \
    tomcat-docker:<version>
```

Alternatively, after building the image, use this `docker-compose.yml` with `docker compose up -d`:

```yaml
services:
  unidata-tomcat:
    image: tomcat-docker:<version>
    ports:
      - "127.0.0.1:8443:8443"
    volumes:
      - ./ssl.crt:/usr/local/tomcat/conf/ssl.crt:ro
      - ./ssl.key:/usr/local/tomcat/conf/ssl.key:ro
      - ./server.xml:/usr/local/tomcat/conf/server.xml:ro
```

After Tomcat starts:

```sh
curl --cacert ./ssl.crt https://localhost:8443/
```


<a id="h-B5E124BB"></a>

#### Certificate from CA

Obtain a server certificate (`ssl.crt`), its private key (`ssl.key`), and any intermediate CA certificates (`intermediates.crt`), in PEM format. Do not include the root CA certificate.

Create a PKCS12 keystore:

```sh
openssl pkcs12 -export \
    -in ssl.crt \
    -inkey ssl.key \
    -certfile intermediates.crt \
    -name mydomain.com \
    -out keystore.p12
```

OpenSSL will prompt for the password protecting `keystore.p12`.

Add this connector inside the `Service` element in `server.xml`:

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           SSLEnabled="true">
  <SSLHostConfig protocols="TLSv1.2,TLSv1.3">
    <Certificate certificateKeystoreFile="${catalina.base}/conf/keystore.p12"
                 certificateKeystoreType="PKCS12"
                 certificateKeyAlias="mydomain.com"
                 certificateKeystorePassword="xxxx" />
  </SSLHostConfig>
</Connector>
```

Replace `xxxx` with the password entered when creating the keystore.

Mount `server.xml` and the keystore read-only, using your locally built `tomcat-docker:<version>` image:

```sh
docker run -d -p 127.0.0.1:8443:8443 \
    -v "$PWD/server.xml:/usr/local/tomcat/conf/server.xml:ro" \
    -v "$PWD/keystore.p12:/usr/local/tomcat/conf/keystore.p12:ro" \
    tomcat-docker:<version>
```

The PKCS12 keystore contains the private key, so restrict access to it while ensuring it is readable by the Tomcat runtime user.

Verify HTTPS after startup. A TLS connector initialization failure does not necessarily terminate Tomcat if another connector can still start.


<a id="h-32889858"></a>

## Testing

If you would like to do a small test to ensure the Unidata Tomcat Docker image is working:

```sh
mkdir -p /tmp/test/ROOT
echo 'It works' > /tmp/test/ROOT/index.html
docker run --name tomcat \
    -e TOMCAT_USER_ID=1000 \
    -e TOMCAT_GROUP_ID=1000 \
    -v /tmp/test:/usr/local/tomcat/webapps:ro \
    -d -p 127.0.0.1:8080:8080 \
    tomcat-docker:<version>
curl http://127.0.0.1:8080/
```

Expected result: `It works`.
