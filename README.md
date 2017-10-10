# netbox-docker

Runs [NetBox](https://github.com/digitalocean/netbox) in Docker

This image runs 2.2beta at this time. It also includes NAPALM. The repo includes an API client for implementing and automating an infrastructure.

The database is stored locally for testing and to easily port it at some future time.

## Quickstart

To get NetBox up and running:

```
$ git clone -b master https://github.com/mastermindg/netbox-docker.git
$ cd netbox-docker
$ cp include/napalm.env.sample include/napalm.env
$ cp include/ldap.env.sample include/ldap.env
$ docker-compose build
$ docker volume prune -f # Clean cache if it's there
$ docker-compose up -d
```

Default credentials:

* Username: **admin**
* Password: **admin**

## Configuration

You can configure the app using environment variables. These are defined in include/netbox.env.

## API Client

The API client runs in it's own container alongside Netbox. It's configured to connect to the Netbox container. To get a list of available actions:

```
$ docker-compose run client
```

To get a list of devices in JSON:

```
$ docker-compose run client get dcim/devices --getspeak
```

## LDAP Integration

NetBox uses Django's built-in LDAP integration to allow LDAP users to authenticate. The configuration is defined in include/ldap_config.py. Environmental variables are used to keep secrets out of the config. These are defined in include/ldap.env. The configuration needs to be mapped to your LDAP server. For more information on setting up LDAP integration see [Netbox Docs](https://netbox.readthedocs.io/en/latest/installation/ldap/)


## NAPALM Integration

NAPALM credentials are stored in include/napalm.env. It's excluded from the repo so add credentials to it if you want to use NAPALM. A sample file is included as well. Just fill in the correct username and password to authenticate with your servers.