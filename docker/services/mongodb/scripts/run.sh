#!/bin/sh

. /scripts/vars.sh

echo "================================================"
echo "MONGODB PORT:       $DOCKER_DB_PORT"
echo "MONGODB ENGINE:     $DB_STORAGE_ENGINE"
echo "MONGODB JOURNALING: $DB_JOURNALING"
echo "MONGODB MOUNTPOINT: $DOCKER_DB_MOUNTPOINT"
echo "MONGODB LOG PATH:   $DB_LOGPATH"
echo "================================================"

/usr/bin/mongod --dbpath "$DOCKER_DB_MOUNTPOINT" --port "$DOCKER_DB_PORT" --logpath "$DB_LOGPATH" --storageEngine "$DB_STORAGE_ENGINE" --"$DB_JOURNALING"