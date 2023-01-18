# ECS-void

This image runs void HTTP service on the configured TCP port and URI.

## Configuration

Configuration is made through environment variables:

| ENV name                  | Required | Default value | Possible values | Description                                               |
| :------------------------ | :------- | :------------ | :-------------- | :-------------------------------------------------------- |
| `ECS_PORT`, `PLUGIN_PORT` | **no**   | `8080`        | `1-65535`       | TCP port for the service to listen on                     |
| `ECS_URI`, `PLUGIN_URI`   | **no**   | `healthcheck` | _String_        | HTTP URI that the service will provide the healthcheck on |

## Example:

`docker run -e ECS_PORT=8081 -e ECS_URI=test -p 8081:8081 <repo_url>/ecs_void:latest` 

This will start a service responding with `200 OK` on port `80` with uri `/test`

Expected result:

```
curl -v http://localhost:8081/test
*   Trying 127.0.0.1:8081...
* Connected to localhost (127.0.0.1) port 8081 (#0)
> GET /test HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/7.85.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Wed, 18 Jan 2023 14:48:16 GMT
< Content-Length: 27
< Content-Type: text/plain; charset=utf-8
< 
* Connection #0 to host localhost left intact
Container is up and running
```