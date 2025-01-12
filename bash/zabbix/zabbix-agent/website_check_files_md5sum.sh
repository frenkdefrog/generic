#!/usr/bin/env bash

# Fájl, amibe az eredményeket mentjük
OUTPUT_DIR="/opt/zabbix/scripts/hashes"

# Könyvtárak, ahol a mappákat keresni fogjuk
TARGET_DIR="/var/www"
CLIENTS_DIR="/var/www/clients"

# Fájl, ahol az előző mappák számát tároljuk
PREVIOUS_COUNT_FILE="/tmp/previous_folder_count.txt"

# a ZABBIX usereparameter fájl
ZABBIX_USERPARAM_FILE="/etc/zabbix/zabbix_agentd.d/custom_webfolder_checksums.conf"

# Hash számolása egy-egy adott mappához
generate_hash() {
    local link_name=$1
    local folder=$2
    if [ -d "$folder" ]; then
        local folder_hash=$(find "$folder" -type f -name "*.php" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{print $1}')
        echo "$link_name $folder $folder_hash" > "$OUTPUT_DIR/$link_name.txt" && chown zabbix:zabbix "$OUTPUT_DIR/$link_name.txt" && chmod 600 "$OUTPUT_DIR/$link_name.txt"
    fi
}

# Cleanup function amit exit előtt kell végrehajtani
cleanup() {
    echo "Cleaning up temporary files and resources..."
    # Add any cleanup commands here
    echo "Cleanup done."
}

# Trap beállítás a SIGINT és SIGTERM signálok elkapására
trap cleanup SIGINT SIGTERM

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR" && chown zabbix:zabbix "$OUTPUT_DIR"
fi

# Mappák összegyűjtése a CLIENTS_DIR-ből, kihagyva a backup mappákat
declare -A web_folders
for folder in "$CLIENTS_DIR"/*/*; do
    if [ -d "$folder" ] && [[ ! "$folder" =~ _bak_ ]]; then
        real_path=$(realpath "$folder")
        web_folders["$real_path"]=1
    fi
done

# Szimbolikus linkek és azok nevei figyelembevétele a TARGET_DIR-ben
declare -A link_names
for link in "$TARGET_DIR"/*; do
    if [ -L "$link" ]; then
        real_path=$(realpath "$link")
        link_name=$(basename "$link")
        link_name=$(echo "$link_name" | sed 's/\./_/g')
        web_folders["$real_path"]=$link_name
    fi
done

# Aktuális weboldalak számának lekérdezése
current_count=${#web_folders[@]}

# Az előző weboldalak számának értéke, ha létezik a temp file
if [ -f "$PREVIOUS_COUNT_FILE" ]; then
    previous_count=$(cat "$PREVIOUS_COUNT_FILE")
else
    previous_count=0
fi

for folder in "${!web_folders[@]}"; do
    link_name="${web_folders[$folder]}"
    generate_hash "$link_name" "$folder/web" &
done

# Várunk, hogy a háttérben futó folyamatok lezáruljanak
wait

# Összehasonlítjuk az aktuális és az előző weboldalak számát
if [ "$current_count" -ne "$previous_count" ]; then
    echo "" > "$ZABBIX_USERPARAM_FILE"

    for folder in "${!web_folders[@]}"; do
        echo "UserParameter=${web_folders[$folder]}.checksum,grep -o '[a-f0-9]\{32\}' $OUTPUT_DIR/${web_folders[$folder]}.txt" >> "$ZABBIX_USERPARAM_FILE"
    done

    echo "$current_count" > "$PREVIOUS_COUNT_FILE"
    systemctl restart zabbix-agent
fi
