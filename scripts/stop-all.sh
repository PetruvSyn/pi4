#!/bin/bash

cd ~/docker || exit

for dir in */; do
    if [ -f "$dir/compose.yml" ] || [ -f "$dir/compose.yaml" ]; then
        echo "Stopping $dir"
        (cd "$dir" && docker compose stop)
    fi
done

echo "All Docker stacks stopped."
