#!/bin/bash

set -e

PROFILE_DIR="$HOME/docker/wireguard-profiles"
ENV_FILE="$HOME/docker/vpn-stack/.env"
COMPOSE_DIR="$HOME/docker/vpn-stack"

echo
echo "══════════════════════════════════════"
echo "        Surfshark VPN Switcher"
echo "══════════════════════════════════════"
echo

if [ ! -d "$PROFILE_DIR" ]; then
    echo "Profile directory missing:"
    echo "$PROFILE_DIR"
    exit 1
fi

declare -a profiles

echo "Available VPN Locations"
echo

count=1

for file in "$PROFILE_DIR"/*.conf; do

    [ -e "$file" ] || continue

    profiles[$count]="$file"

    endpoint=$(grep "^Endpoint" "$file" | awk '{print $3}')
    location=$(echo "$endpoint" | sed 's/\.prod\.surfshark\.com.*//')

    case "$location" in

        ca-tor)
            name="🇨🇦 Canada - Toronto"
            ;;

        cz-prg)
            name="🇨🇿 Czech Republic - Prague"
            ;;

        us-den)
            name="🇺🇸 United States - Denver"
            ;;

        us-nyc)
            name="🇺🇸 United States - New York"
            ;;

        *)
            name="🌎 $location"
            ;;

    esac

    echo "$count) $name"

    ((count++))

done


echo

if [ "$count" -eq 1 ]; then
    echo "No WireGuard profiles found."
    exit 1
fi


read -rp "Choose a location: " choice


selected="${profiles[$choice]}"


if [ -z "$selected" ]; then
    echo "Invalid selection"
    exit 1
fi


echo
echo "Loading:"
echo "$selected"
echo


# Read WireGuard values

private=$(grep "^PrivateKey" "$selected" | awk '{print $3}')
address=$(grep "^Address" "$selected" | awk '{print $3}')
public=$(grep "^PublicKey" "$selected" | awk '{print $3}')

endpoint_full=$(grep "^Endpoint" "$selected" | awk '{print $3}')

endpoint_host=$(echo "$endpoint_full" | cut -d: -f1)
endpoint_port=$(echo "$endpoint_full" | cut -d: -f2)


# Resolve hostname because Gluetun requires an IP

if [[ "$endpoint_host" =~ [a-zA-Z] ]]; then

    echo "Resolving VPN endpoint..."

    endpoint_host=$(dig +short "$endpoint_host" | tail -n1)

fi


if [[ -z "$endpoint_host" ]]; then

    echo
    echo "ERROR: Could not resolve VPN endpoint"
    exit 1

fi


echo
echo "VPN endpoint:"
echo "$endpoint_host:$endpoint_port"
echo


echo "Updating .env..."


# Backup current configuration

cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d-%H%M%S)"


# Escape special sed characters

escape_sed()
{
    echo "$1" | sed 's/[\/&]/\\&/g'
}


private=$(escape_sed "$private")
address=$(escape_sed "$address")
public=$(escape_sed "$public")
endpoint_host=$(escape_sed "$endpoint_host")
endpoint_port=$(escape_sed "$endpoint_port")


# Update .env

sed -i "s|^WIREGUARD_PRIVATE_KEY=.*|WIREGUARD_PRIVATE_KEY=$private|" "$ENV_FILE"

sed -i "s|^WIREGUARD_ADDRESSES=.*|WIREGUARD_ADDRESSES=$address|" "$ENV_FILE"

sed -i "s|^WIREGUARD_PUBLIC_KEY=.*|WIREGUARD_PUBLIC_KEY=$public|" "$ENV_FILE"

sed -i "s|^WIREGUARD_ENDPOINT_IP=.*|WIREGUARD_ENDPOINT_IP=$endpoint_host|" "$ENV_FILE"

sed -i "s|^WIREGUARD_ENDPOINT_PORT=.*|WIREGUARD_ENDPOINT_PORT=$endpoint_port|" "$ENV_FILE"


echo
echo "Restarting Gluetun..."
echo


cd "$COMPOSE_DIR"


docker compose down

docker compose up -d


echo
echo "Waiting for Gluetun health..."

for i in {1..12}; do

    status=$(docker inspect --format='{{.State.Health.Status}}' gluetun 2>/dev/null || true)

    echo "Gluetun status: $status"

    if [ "$status" = "healthy" ]; then
        break
    fi

    sleep 5

done


echo
docker ps --filter name=gluetun --filter name=qbittorrent


echo
echo "VPN switch complete"
echo
