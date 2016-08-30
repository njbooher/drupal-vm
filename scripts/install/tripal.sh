#!/bin/bash

BRANCH=$1
if [ "$BRANCH" == "7.x-2.0" ]; then
    SITENAME="tripal2";
else
    echo "Branch must be 7.x-2.0 or 7.x-2.x";
    exit 1;
fi;

pushd ${WEBROOT}

# wipe old site
sudo -u postgres psql -c "DROP DATABASE ${SITENAME}"
sudo rm -rf ${SITENAME}

# install drupal
sudo -u postgres psql -c "CREATE DATABASE ${SITENAME} OWNER ${DBUSER}"
sudo mkdir ${SITENAME}
sudo chown ${USER} ${SITENAME}
git clone https://github.com/drupal/drupal.git ${SITENAME}
pushd ${SITENAME} && git checkout tags/7.44 && popd

pushd ${SITENAME}
mkdir sites/default/files
drush si minimal -y --db-url=pgsql://${DBUSER}:${DBPASS}@${DBHOST}/${SITENAME} --site-name=${SITENAME} --account-name=${DRUPALUSER} install_configure_form.update_status_module='array(FALSE,FALSE)'
sudo chown ${APACHEUSER} sites/default/files/

# set up drupal admin stuff
drush vset admin_theme seven
drush dl -y admin_menu environment_indicator
drush en -y admin_menu_toolbar environment_indicator

# install tripal

git clone https://github.com/tripal/tripal.git sites/all/modules/tripal
pushd sites/all/modules/tripal && git checkout tags/${BRANCH} && popd

drush dl -y ctools views
drush en -y views_ui
wget --no-check-certificate https://drupal.org/files/drupal.pgsql-bytea.27.patch
patch -p1 < drupal.pgsql-bytea.27.patch
pushd sites/all/modules/views
patch -p1 < ../tripal/tripal_views/views-sql-compliant-three-tier-naming-1971160-22.patch
popd
drush en -y tripal_core
drush cc all
drush ev "tripal_add_job('Install Chado v1.2', 'tripal_core', 'tripal_core_install_chado', array('Install Chado v1.2'), 1);"
drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}
drush en -y tripal_views
drush en -y tripal_db
drush en -y tripal_cv
drush en -y tripal_organism
drush en -y tripal_analysis
drush en -y tripal_feature

git clone https://github.com/tripal/tripal_blast.git sites/all/modules/tripal_blast
drush en -y tripal_blast

drush ev "\$cfp_obo_id = db_query('SELECT obo_id FROM {tripal_cv_obo} WHERE name = \'Chado Feature Properties\'')->fetchObject()->obo_id; tripal_submit_obo_job(array('obo_id' => \$cfp_obo_id));"
drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}


popd
popd
