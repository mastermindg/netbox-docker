# API Examples

## Insert Device From JSON

A Token is required for non-read requests. The token is set via the Admin UI.

```curl -H "Authorization: Token $token" -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @example_device.json 'http://localhost/api/dcim/devices/'
```

## Search Device by Name
```curl 'http://localhost/api/dcim/devices/?name=sw-01-bos'
```

## Search Dvices by Rack
```curl 'http://localhost/api/dcim/devices/?rack_id=1'
```

## Get all Devices that are Networked (minus storage)
```curl 'http://localhost/api/dcim/devices/?is_network_device=true'
```

## Get all VMs
```curl 'http://localhost/api/virtualization/virtual-machines/'
```

## Get the first available IP
```curl 'http://localhost/api/ipam/prefixes/1/available-ips/?limit=1'
```

