FROM artifactory.wma.chs.usgs.gov/docker-official-mirror/rocker/geospatial:3.6.0 

ARG BUILD_DATE

LABEL maintainer="wwatkins@usgs.gov"
LABEL version=0.2.0
LABEL org.label-schema.build-date=$BUILD_DATE


RUN sudo apt-get install -y curl gnupg gdal-bin \
  && apt-get clean \
  && apt-get autoremove

#bring in DOI root cert.  Remove this statement for non-USGS persons
RUN /usr/bin/wget -O /usr/lib/ssl/certs/DOIRootCA.crt https://owi-common-resources.s3-us-west-2.amazonaws.com/resources/InstallFiles/SSL/DOIRootCA.cer && \
  ln -sf /usr/lib/ssl/certs/DOIRootCA.crt /usr/lib/ssl/certs/`openssl x509 -hash -noout -in /usr/lib/ssl/certs/DOIRootCA.crt`.0 && \
  echo "\\n\\nca-certificate = /usr/lib/ssl/certs/DOIRootCA.crt" >> /etc/wgetrc; 

WORKDIR /home/rstudio/

#default GDAL is kinda old, we need >= 2.3 for ID field in geojson
#uninstall the included GDAL first
RUN sudo apt-get remove --assume-yes libgdal-dev \
  && wget http://download.osgeo.org/gdal/2.4.2/gdal-2.4.2.tar.gz \
  && tar -xzvf gdal-2.4.2.tar.gz \
  && cd gdal-2.4.2 \
  && ./configure --prefix=/usr \
  && make && make install \
  && cd ../ \
  && rm gdal-2.4.2.tar.gz && rm -rf gdal-2.4.2

RUN install2.r --error \
	sf \
	lwgeom \
	ncmeta \
	assertthat \
  ggplot2

RUN mkdir -p wbeep-processing &&\
    chown rstudio wbeep-processing
WORKDIR wbeep-processing



	
