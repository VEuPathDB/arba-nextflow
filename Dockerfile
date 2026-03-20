FROM ubuntu:focal

LABEL maintainer="rdemko2332@gmail.com"

RUN apt-get update \
  && apt-get install -y perl perl-doc \
  && apt-get clean \
  && apt-get purge \
  && apt-get autoclean \
  && apt-get autoremove \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD bin/rulesheet.tsv /bin/

WORKDIR /work
