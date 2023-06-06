# Parameterized Nginx

This version of Nginx takes parameters to generate simple, minimal configuration of Nginx that will act as proxy

# Input variables

| name          | default               | description                 | 
|---------------|-----------------------|-----------------------------|
| FORWARD_HOST  | http://127.0.0.1:8080 | Proxy target                |
| RESOLVER_ADDR | 172.16.0.2            | Address of local DNS        |
| PORT          | 8080                  | Port Nginx should listen on |


