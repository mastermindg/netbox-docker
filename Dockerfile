FROM python:3.6-alpine

RUN apk add --no-cache \
      bash \
      build-base \
      ca-certificates \
      cyrus-sasl-dev \
      graphviz \
      jpeg-dev \
      libffi-dev \
      libxml2-dev \
      libxslt-dev \
      openldap-dev \
      openssl-dev \
      postgresql-dev \
      postgresql-client \
      python-dev \
      openldap-dev \
      wget

RUN pip install gunicorn

WORKDIR /opt

ARG BRANCH=master
ARG URL=https://github.com/digitalocean/netbox/archive/$BRANCH.tar.gz
RUN wget -q -O - "${URL}" | tar xz \
  && mv netbox* netbox

WORKDIR /opt/netbox
# Temp fix for Django 3.7 deps
RUN pip install djangorestframework==3.6.4
RUN pip install -r requirements.txt
RUN pip install napalm
RUN pip install json-logging-py
RUN pip install django-auth-ldap

RUN ln -s configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY include/gunicorn_logging.conf /opt/netbox/
COPY include/gunicorn_config.py /opt/netbox/
COPY include/wait_for_postgres.sh /opt/netbox/
COPY include/ldap_config.py /opt/netbox/netbox/netbox/

WORKDIR /opt/netbox/netbox

COPY include/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]

VOLUME ["/etc/netbox-nginx/"]

CMD ["gunicorn", "--log-config", "/opt/netbox/gunicorn_logging.conf", "-c /opt/netbox/gunicorn_config.py", "netbox.wsgi"]
