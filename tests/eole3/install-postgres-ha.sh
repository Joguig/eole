#!/bin/bash
# shellcheck disable=SC2034,SC2148

ROLE="$1"
ID_REPLICA="$2"

if ! command -v jq 
then
	export DEBIAN_FRONTEND=noninteractive
	apt-get install -y jq
fi
PG_VERSION=14
DIR_CONF="/etc/postgresql/$PG_VERSION"
PARTAGE_OWNER="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER"
case $1 in
    "master")
        apt update
        apt install postgresql postgresql-contrib
        
        psql "CREATE ROLE repl_user WITH REPLICATION LOGIN PASSWORD 'EXAMPLE_PASSWORD';"
        
        IP_MASTER=$(ciGetIP)
        echo "IP_MASTER=$IP_MASTER"
        echo "$IP_MASTER" >"$PARTAGE_OWNER/master.ip"

        cat "$DIR_CONF/main/postgresql.conf"
        if grep 'listen_addresses' "$DIR_CONF/main/postgresql.conf"
        then
            echo "listen_addresses ok"
        else
        
            cat >>"$DIR_CONF/main/postgresql.conf" <<EOF
listen_addresses = '$IP_MASTER'
EOF
        fi

        #wal_level = logical
        #wal_log_hints = on
        
        cat "$DIR_CONF/main/pg_hba.conf"
        
        cat >>"$DIR_CONF/main/pg_hba.conf" <<EOF
        host    replication     repl_user       10.106.0.2/32           md5
EOF

        systemctl restart postgresql
        # ha ready to add replica
        ;;

    "replica")
        apt update
        apt install postgresql postgresql-contrib

        IP_REPLICA=$(ciGetIP)
        echo "IP_REPLICA=$IP_REPLICA"
        echo "$IP_REPLICA" >"$PARTAGE_OWNER/replica-${ID_REPLICA}.ip"

        IP_MASTER=$(cat "$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/master.ip")
        
        echo "nettoyage"
        rm -rv "/var/lib/postgresql/$PG_VERSION/main/"

        pg_basebackup -h "$IP_MASTER" -U repl_user -X stream -C -S "replica_${ID_REPLICA}" -v -R -W -D "/var/lib/postgresql/$PG_VERSION/main/"
        
        # restaure acl
        chown postgres -R "/var/lib/postgresql/$PG_VERSION/main/"
        
        systemctl start postgresql
        ;;
        
    "prepare-test")
        psql -v ON_ERROR_STOP=1 --username "postgres" <<EOF
CREATE DATABASE test_db;
\c test_db;
CREATE TABLE products (
   product_id SERIAL PRIMARY KEY,
   product_name VARCHAR (50)
);
INSERT INTO products(product_name) VALUES ('LEATHER JACKET');
INSERT INTO products(product_name) VALUES ('WINTER HOODIE');
INSERT INTO products(product_name) VALUES ('BROWN WALLET');
EOF
        ;;
        
    "replica-test")
        psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "test_db"  <<EOF
SELECT 
   product_id,
   product_name
FROM products;
EOF

        psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "test_db"  <<EOF
INSERT INTO products(product_name) VALUES ('RED TSHIRT');
EOF
        # erreur ==> read only
        ;;
    *)
        echo "option $1 inconnu"
        ;;
esac
