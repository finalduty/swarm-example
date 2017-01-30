#!/bin/bash

set -eu

[ `which jq &>/dev/null; echo $?` -eq 0 ] || apt install -y jq

deploy_source="src"

deploy_dir_base="/deploy"
deploy_app_name="example_app"
deploy_colour="$(echo `curl -s 10.0.0.11/v1/kv/example-app/test/colour -H "Host: consul.local" | jq -r .[].Value  | base64 -d`)"
active_colour="$(echo `curl -s 10.0.0.11/v1/kv/example-app/active/colour -H "Host: consul.local" | jq -r .[].Value  | base64 -d`)"
deploy_dir_bottom="html"

deploy_path="$deploy_dir_base/$deploy_app_name/$deploy_colour/$deploy_dir_bottom"

if [ -d $deploy_path ]; then
    echo "Deploying $deploy_app_name to $deploy_colour"
    echo "Deploy Path: $deploy_path"
    
    rsync -triP --del $deploy_source/ $deploy_path

    find $deploy_path -type d -exec chmod -c 755 {} +
    find $deploy_path -type f -exec chmod -c 644 {} +
    chown -Rc nobody. $deploy_path 
    
else
    echo "Something went wrong"   
    exit 1
fi
