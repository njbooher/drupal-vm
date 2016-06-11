#!/bin/bash

git clone https://github.com/drush-ops/drush.git /usr/share/drush
pushd /usr/share/drush && git checkout tags/5.9.0 && popd
ln -s /usr/share/drush/drush /usr/bin/drush
# need to run drush once as root so library gets downloaded
drush --version
