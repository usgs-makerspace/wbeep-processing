FROM rocker/geospatial:3.6.0 

RUN sudo apt-get install -y curl &&\
  sudo apt-get install -y gnupg &&\
  curl -sL https://deb.nodesource.com/setup_12.x | bash - &&\
  sudo apt-get install -y nodejs &&\
  sudo apt-get update &&\
  npm install -g mapshaper

#bring in DOI root cert.  Remove this statement for non-USGS persons
RUN /usr/bin/wget -O /usr/lib/ssl/certs/DOIRootCA.crt http://sslhelp.doi.net/docs/DOIRootCA2.cer && \
  ln -sf /usr/lib/ssl/certs/DOIRootCA.crt /usr/lib/ssl/certs/`openssl x509 -hash -noout -in /usr/lib/ssl/certs/DOIRootCA.crt`.0 && \
  echo "\\n\\nca-certificate = /usr/lib/ssl/certs/DOIRootCA.crt" >> /etc/wgetrc; 

WORKDIR /home/rstudio/

RUN install2.r --error \
	lwgeom \	
 	geojsonio

RUN mkdir -p wbeep-processing &&\
    chown rstudio wbeep-processing
WORKDIR wbeep-processing



	
