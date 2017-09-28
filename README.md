# netbox-docker

Run [NetBox](https://github.com/digitalocean/netbox) in Docker

This image includes Napalm and some API documentation/scripts for implementing and automating an infrastructure.

All of the volumes are stored locally for testing and to easily port the database at some future time.

## Quickstart

To get NetBox up and running:

```
$ git clone -b master https://github.com/mastermindg/netbox-docker.git
$ cd netbox-docker
$ docker-compose up -d
```

Default credentials:

* Username: **admin**
* Password: **admin**

## Configuration

You can configure the app using environment variables. These are defined in `netbox.env`.
