#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get install debtree
debtree eole-server >"$VM_DIR/debtree-eole-server.dot"