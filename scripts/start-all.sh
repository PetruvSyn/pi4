#!/bin/bash

cd ~/docker || exit

# Start VPN stack first
if [ -d "vpn-stack" ]; then
    echo "Spinning up VPN stack"
    (cd "vpn-stack" && docker compose up -d)
fi

# Start remaining stacks
for dir in */; do
    if [ "$dir" != "vpn-stack/" ] && \
       ([ -f "$dir/compose.yml" ] || [ -f "$dir/compose.yaml" ]); then
        echo "Spinning up $dir"
        (cd "$dir" && docker compose up -d)
    fi
done

echo "All Docker stacks done been spun, yo."
