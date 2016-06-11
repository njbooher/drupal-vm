#!/bin/bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

run_test() {
    vagrant plugin install vagrant-hostsupdater vagrant-vbguest
    time vagrant up
    vagrant destroy -f
    rm -rf provisioning/roles ${VAGRANT_DOTFILE_PATH} ${VAGRANT_HOME} ${TRIPAL_VM_WORKDIRPATH}/VirtualBox
}

cd ${TRIPAL_VM_DIR}

rm -f logs/*

ln -sf ${TRIPAL_VM_DIR}/config/ubuntu1204.local.config.yml ${TRIPAL_VM_DIR}/local.config.yml
run_test

ln -sf ${TRIPAL_VM_DIR}/config/ubuntu1404.local.config.yml ${TRIPAL_VM_DIR}/local.config.yml
run_test

ln -sf ${TRIPAL_VM_DIR}/config/centos6.local.config.yml ${TRIPAL_VM_DIR}/local.config.yml
run_test

ln -sf ${TRIPAL_VM_DIR}/config/centos7.local.config.yml ${TRIPAL_VM_DIR}/local.config.yml
run_test

rm ${TRIPAL_VM_DIR}/local.config.yml
