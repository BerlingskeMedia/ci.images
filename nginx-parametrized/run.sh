_forward_host=${FORWARD_HOST:-"http://127.0.0.1:8080"}
_port=${PORT:-"8080"}
_resolver_addr=${RESOLVER_ADDR:-"172.16.0.2"}

env
echo host: $_forward_host
echo port: $_port
echo resolver: $_resolver_addr

generate_conf () {
   cat > /etc/nginx/conf.d/default.conf <<-EOF
resolver $_resolver_addr;

server {

  listen $_port;
  location / {
      proxy_pass $_forward_host;
  }
  location /release-version-nginx.txt {
    root /usr/share/nginx/html;
  }
}
EOF
}



while true
do
  generate_conf
  nginx -s reload
  sleep 3600
done