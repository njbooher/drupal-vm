#!/bin/bash

LOAD_RO=false
LOAD_GO=false

while :
do
    case "$1" in
        -r | --ro)
        LOAD_RO=true
        shift
        ;;
        -g | --go)
        LOAD_GO=true
        shift
        ;;
        *)
        break
        ;;
    esac
done

BRANCH=$1
if [ "$BRANCH" == "7.x-2.x" ]; then
    SITENAME="tripal2x";
elif [ "$BRANCH" == "7.x-2.0" ]; then
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
pushd ${SITENAME} && git checkout tags/7.43 && popd

pushd ${SITENAME}
mkdir sites/default/files
drush si minimal -y --db-url=pgsql://${DBUSER}:${DBPASS}@${DBHOST}/${SITENAME} --site-name=${SITENAME} --account-name=${DRUPALUSER} install_configure_form.update_status_module='array(FALSE,FALSE)'
sudo chown ${APACHEUSER} sites/default/files/

# set up drupal admin stuff
drush vset admin_theme seven
drush dl -y admin_menu environment_indicator
drush en -y admin_menu_toolbar environment_indicator

# install tripal
if [ "$BRANCH" == "7.x-2.x" ]; then
    git clone https://github.com/tripal/tripal.git sites/all/modules/tripal
    pushd sites/all/modules/tripal && git checkout ${BRANCH} && popd
else
    git clone https://github.com/tripal/tripal.git sites/all/modules/tripal
    pushd sites/all/modules/tripal && git checkout tags/${BRANCH} && popd
fi;
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

if [ "$BRANCH" == "7.x-2.x" ]; then
    # in 2.x installing tripal_cv queues a few jobs, including the Chado Feature Properties load
    drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}
else
    # in 2.0 Chado Feature Properties need loaded manually
    drush ev "\$cfp_obo_id = db_query('SELECT obo_id FROM {tripal_cv_obo} WHERE name = \'Chado Feature Properties\'')->fetchObject()->obo_id; tripal_submit_obo_job(array('obo_id' => \$cfp_obo_id));"
    drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}
fi;

if [ "$LOAD_RO" == true ]; then
    wget --no-check-certificate -O ro.obo https://www.drupal.org/files/issues/ro.txt
    drush ev "\$r_obo_id = db_query('SELECT obo_id FROM {tripal_cv_obo} WHERE name = \'Relationship Ontology\'')->fetchObject()->obo_id; db_update('tripal_cv_obo')->fields(array('name' => 'Relationship Ontology', 'path' => 'ro.obo' )) ->condition('obo_id', \$r_obo_id)->execute(); tripal_submit_obo_job(array('obo_id' => \$r_obo_id));"
    drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}
fi

if [ "$LOAD_GO" == true ]; then
    drush ev "\$g_obo_id = db_query('SELECT obo_id FROM {tripal_cv_obo} WHERE name = \'Gene Ontology\'')->fetchObject()->obo_id; db_update('tripal_cv_obo')->fields(array('name' => 'Gene Ontology', 'path' => 'http://www.geneontology.org/ontology/gene_ontology.obo' )) ->condition('obo_id', \$g_obo_id)->execute(); tripal_submit_obo_job(array('obo_id' => \$g_obo_id));"
    drush trp-run-jobs --username=${DRUPALUSER} --root=${WEBROOT}${SITENAME}
fi

popd
popd
