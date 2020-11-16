FROM artifactory.wma.chs.usgs.gov/docker-official-mirror/ubuntu:18.04
#based on https://hub.docker.com/r/klokantech/tippecanoe
#with newer ubuntu

ARG BUILD_DATE

LABEL maintainer="wwatkins@usgs.gov"
LABEL version=0.1.0
LABEL org.label-schema.build-date=$BUILD_DATE

# Update repos and install dependencies
RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get -y install git build-essential libsqlite3-dev zlib1g-dev wget \
  && apt-get -y autoremove

#bring in DOI root cert.  Remove this statement for non-USGS persons
RUN /usr/bin/wget -O /usr/lib/ssl/certs/DOIRootCA.crt https://owi-common-resources.s3-us-west-2.amazonaws.com/resources/InstallFiles/SSL/DOIRootCA.cer && \
  ln -sf /usr/lib/ssl/certs/DOIRootCA.crt /usr/lib/ssl/certs/`openssl x509 -hash -noout -in /usr/lib/ssl/certs/DOIRootCA.crt`.0 && \
  echo "\\n\\nca-certificate = /usr/lib/ssl/certs/DOIRootCA.crt" >> /etc/wgetrc; 

# Create a directory and copy in all files
RUN mkdir -p /tmp/tippecanoe-src

WORKDIR /tmp/tippecanoe-src

# Build tippecanoe
RUN git clone https://github.com/mapbox/tippecanoe.git /tmp/tippecanoe-src

RUN make && make install \
  && rm -rf /tmp/tippecanoe-src \
  && apt-get -y remove --purge build-essential && apt-get -y autoremove

WORKDIR /home/wbeep-processing
