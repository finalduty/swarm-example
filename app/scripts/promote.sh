#!/bin/bash

set -eu

apt install -y sshpass &>/dev/null

EXITCODE=0

deploy_app_name="example_app"
deploy_base_dir="/deploy"
deploy_base_url="example.local"
deploy_colour="$(echo `curl -s 10.0.0.11/v1/kv/example-app/test/colour -H "Host: consul.local" | jq -r .[].Value  | base64 -d`)"
active_colour="$(echo `curl -s 10.0.0.11/v1/kv/example-app/active/colour -H "Host: consul.local" | jq -r .[].Value  | base64 -d`)"

## Test that website works in staging
[ `curl -sLI -o /dev/null -w "%{http_code}\n" 10.0.0.11 -H "Host: $deploy_colour.$deploy_base_url"` -eq 200 ] || EXITCODE=1
[ `curl -sL 10.0.0.11 -H "Host: $deploy_colour.$deploy_base_url" | egrep -c "Hello"` -ne 0 ] || EXITCODE=1

## Exit here if we failed any tests, 
if [ $EXITCODE -gt 0 ]; then
    echo "Post-Deploy Tests Failed"
    exit $EXITCODE
else
    echo "Post-Deploy Tests Passed"
fi

## Swap backends for production and testing key/values in Consul
[ `curl -s -X PUT -d "$active_colour" 10.0.0.11/v1/kv/example-app/test/colour -H "Host: consul.local"` ] || EXITCODE=2
[ `curl -s -X PUT -d "$deploy_colour" 10.0.0.11/v1/kv/example-app/active/colour -H "Host: consul.local"` ] || EXITCODE=2

## Call an adult if we fail here D:
if [ $EXITCODE -gt 0 ]; then
    echo "KV Promotion failed, oh crap D:"
    exit $EXITCODE
else
    echo "KV Promotion successful"
fi

## If by this point we've passed the post-deploy tests and the promotion, we can update the binding for nginx
## If it went bad, nothing has been updated here, but we'd probably be safe anyways

### NEVER EVER EVER EVER USE THIS IN PRODUCTION HOLY SHIT IT'S BAD ###
sshpass -p Passw0rd ssh -oStrictHostKeyChecking=no root@10.0.0.11 /etc/nginx/conf.d/example.switch
sshpass -o Passw0rd ssh -oStrictHostKeyChecking=no root@10.0.0.21 docker service scale example_app-$active_colour=2 example_app-$deploy_colour=5