#!/bin/bash

smbcontrol smbd debug "all:0 \
                tdb:0 \
                printdrivers:0 \
                lanman:0 \
                smb:0 \
                rpc_parse:0 \
                rpc_srv:0 \
                rpc_cli:0 \
                passdb:0 \
                sam:0 \
                auth:0 \
                winbind:0 \
                vfs:0 \
                idmap:0 \
                quota:0 \
                acls:0 \
                locking:0 \
                msdfs:0 \
                dmapi:0 \
                registry:0 \
                scavenger:0 \
                dns:0 \
                ldb:0 \
                tevent:0 \
                auth_audit:0 \
                auth_json_audit:0 \
                kerberos:0 \
                drs_repl:0 \
                smb2:0 \
                smb2_credits:0 \
                dsdb_audit:3 \
                dsdb_json_audit:3 \
                dsdb_password_audit:3 \
                dsdb_password_json_audit:3 \
                dsdb_transaction_audit:3 \
                dsdb_transaction_json_audit:3 \
                dsdb_group_audit:3 \
                dsdb_group_json_audit:3"
smbcontrol smbd debuglevel
