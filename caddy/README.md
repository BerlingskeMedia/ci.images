# caddy

HTTP/1-2-3 web server with automatic HTTPS, including [s3 driver](https://github.com/ss098/certmagic-s3) for cert storage


## Example:

`docker run --name caddy-test -d -p 80:80 <repo_url>/caddy:latest`

This will start a service responding with `200 OK` on port `80`
