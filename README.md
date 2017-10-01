# netbox-docker

Run [NetBox](https://github.com/digitalocean/netbox) in Docker

This image runs 2.2beta at this time. It also includes NAPALM. The repo includes some API documentation/scripts for implementing and automating an infrastructure.

All of the data is stored locally for testing and to easily port the database at some future time.

NAPALM credentials are stored in include/napalm.env. It's excluded from the repo so add credentials to it if you want to use NAPALM.

## Quickstart

To get NetBox up and running:

```
$ git clone -b master https://github.com/mastermindg/netbox-docker.git
$ cd netbox-docker
$ touch include/napalm.env
$ docker-compose build
$ docker-compose up -d
```

Default credentials:

* Username: **admin**
* Password: **admin**

## Configuration

You can configure the app using environment variables. These are defined in `netbox.env`.

## API

I created a Ruby class to interact with the Netbox API. If you want to use it get RVM and Bundler and do:

```bundle install
```
