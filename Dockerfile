FROM amd64/ubuntu:20.04
# build using:
# docker build --no-cache -t magickbox -f ./build/Dockerfile .
#
# Run with:
#   docker run --rm -it -p 3000:80 -p 2813:2813 -p 11113:11113 -v /var/run/docker.sock:/var/run/docker.sock magickbox
#   open localhost:3000


ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/mb-startup.sh"

RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    apache2 \
    apt-utils \
    build-essential \
    bzip2 \
    ca-certificates \
    cron \
    curl \
    emacs-nox \
    php7.4 \
    php7.4-cli \
    php7.4-curl \
    php7.4-mbstring \
    libapache2-mod-php7.4 \
    jq \
    sudo \
    cron \
    file \
    less \
    procps \
    git \
    gearman-job-server \
    gearman \
    gearman-tools \
    monit \
    dcmtk \
    python \
    python3 \
    python3-pip \
    docker.io \
    telnet \
    net-tools

RUN apt-get clean

RUN pip install pydicom 

COPY code/web /var/www/html/code/web
COPY code/php /var/www/html/code/php
COPY index.php /var/www/html/index.php
COPY code /data/code
COPY streams /data/streams

COPY code/assets/monit/processing.conf /etc/monit/conf.d/processing.conf
COPY code/assets/monit/monitrc /etc/monit/monitrc
RUN chmod 600 /etc/monit/monitrc

COPY code/assets/apache2/apache2.conf /etc/apache2/apache2.conf
COPY code/assets/apache2/001-processing.conf /etc/apache2/sites-available/

RUN rm /var/www/html/index.html

RUN umask 002 && mkdir -p /data/.pids/ \
    && mkdir -p /data/logs/ \
    && mkdir -p /data/scratch/archive/ \
    && mkdir -p /data/scratch/raw/ \
    && touch /var/log/cron.log \
    && cron /var/www/html/code/assets/crontab.txt \
    && ln -s /etc/apache2/sites-available/001-processing.conf /etc/apache2/sites-enabled/001-processing.conf \
    && useradd -m -s /bin/bash -U processing \
    && usermod -a -G docker processing \
    && chgrp processing /data/logs \ 
    && chgrp processing /data/.pids \ 
    && chgrp -R processing /data/scratch  \ 
    && chown -R www-data:www-data /var/www/html/ \
    && chown -R www-data:www-data /data/code 

COPY code/bin/routing_master.json /data/code/bin/routing.json
RUN chmod 777 /data/logs

COPY code/assets/docker/mb-startup.sh /mb-startup.sh

RUN echo "processing ALL=(ALL) NOPASSWD: /usr/bin/docker" >> /etc/sudoers

RUN chmod +x /mb-startup.sh

EXPOSE 80
EXPOSE 2813
EXPOSE 11113
EXPOSE 4730

RUN /data/code/bin/install_buckets mytestbucket TESTBUCKET

ENTRYPOINT ["/mb-startup.sh", "start"]
