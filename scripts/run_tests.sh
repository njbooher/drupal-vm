#!/bin/bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

cd ${TRIPAL_VM_DIR}

rm -f logs/*

ln -sf ${TRIPAL_VM_DIR}/config/centos7.local.config.yml ${TRIPAL_VM_DIR}/local.config.yml

vagrant plugin install vagrant-hostsupdater vagrant-vbguest vagrant-auto_network
time vagrant up
