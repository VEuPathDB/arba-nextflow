FROM ubuntu:focal

LABEL maintainer="rdemko2332@gmail.com"

RUN apt-get update \
  && apt-get install -y perl perl-doc python3 python-is-python3 \
  && apt-get clean \
  && apt-get purge \
  && apt-get autoclean \
  && apt-get autoremove \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD bin/rulesheet.tsv /bin/
ADD bin/identifyUninformative.py /bin/

WORKDIR /work
