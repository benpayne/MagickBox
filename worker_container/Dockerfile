##############################################
#
# Docker file to build a bucket for MagickBox
# 
##############################################
FROM ubuntu

RUN apt-get update 
RUN apt-get install -y python3 python3-pip python3-pydicom gearman gearman-tools iputils-ping dnsutils
RUN mkdir -p /root/storage/
RUN mkdir -p /root/storage/memory

COPY info.json /root/storage/
COPY work.sh /root/
COPY extractor.py /root/
COPY run_gearman.sh /root/

RUN chmod 775 /root/work.sh /root/extractor.py /root/run_gearman.sh

COPY db-plugin.code /root/storage/

ENV AETITLE="TESTBUCKET"

CMD ["/root/run_gearman.sh"]