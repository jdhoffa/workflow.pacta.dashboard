FROM --platform=arm64 ghcr.io/rmi-pacta/workflow.transition.monitor:main

RUN apt-get update && apt-get install -y \
  sudo \
  gdebi-core \
  pandoc \
  pandoc-citeproc \
  libcurl4-gnutls-dev \
  libcairo2-dev \
  libxt-dev \
  xtail \
  wget

# install packages for dependency resolution and installation
RUN Rscript -e "install.packages('pak')"
RUN Rscript -e "pak::pkg_install('renv')"

# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
  gdebi -n ss-latest.deb && \
  rm -f version.txt ss-latest.deb && \
  . /etc/environment && \
  R -e "pak::pkg_install(c('shiny', 'rmarkdown'))" && \
  cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
  chown shiny:shiny /var/lib/shiny-server

EXPOSE 3838

COPY bin/shiny-server.sh /usr/bin/shiny-server.sh
COPY ./app/* /srv/shiny-server/

# install workflow dependencies
RUN Rscript -e "\
  workflow_pkgs <- renv::dependencies('/srv/shiny-server')[['Package']]; \
  pak::pkg_install(workflow_pkgs); \
  "  

COPY bin/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# run app
CMD ["/usr/bin/entrypoint.sh"]
