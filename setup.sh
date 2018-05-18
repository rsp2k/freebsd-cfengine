#!/bin/sh

POLICY_SERVER=${POLICY_SERVER:-cfengine-policy.supported.systems}
CFENGINE_CHECKOUT_DIR=${CFENGINE_CHECKOUT_DIR:-/root/cfengine}
CFENGINE_REPO_URL=${CFENGINE_REPO_URL:-https://github.com/rsp2k/freebsd-cfengine/trunk/cfengine}
CFENGINE_WORK_DIR=${CFENGINE_WORK_DIR:-/var/cfengine}
CFSERVERD_BIND_IP=${CFSERVERD_BIND_IP:-0.0.0.0}
CFENGINE_NETWORK=${CFENGINE_NETWORK:-10.1.16.0/20}
SMTP_SERVER=${SMTP_SERVER:-0.0.0.0}
MAIL_FROM=${MAIL_FROM:-cfengine@example.com}
MAIL_TO=${MAIL_TO:-admin@example.com}
CFKEY=${CFENGINE_KEY:-/var/cfengine/ppkeys/localhost.pub}

echo "Installing CFEngine Core 3.11.0-build1"
pkg install cfengine
#cf-key --output-file=${CFENGINE_KEY}

sysrc cf_execd_enable="YES"
sysrc cf_serverd_enable="YES"

echo "linking pkg binaries to work dir"
rm ${CFENGINE_WORK_DIR}/bin/cf-*
ln -s /usr/local/bin/cf-* ${CFENGINE_WORK_DIR}/bin/

# match paths used by rc scripts installed by pkg
rm /usr/local/sbin/cf-execd
ln -s /usr/local/bin/cf-execd /usr/local/sbin
rm /usr/local/sbin/cf-monitord
ln -s /usr/local/bin/cf-monitord /usr/local/sbin
rm /usr/local/sbin/cf-serverd
ln -s /usr/local/bin/cf-serverd /usr/local/sbin

echo "checkout repo"
rm -rf ${CFENGINE_CHECKOUT_DIR}
svnlite checkout ${CFENGINE_REPO_URL} ${CFENGINE_CHECKOUT_DIR}

echo "linking repo dirs to work directory"
rm -rf ${CFENGINE_WORK_DIR}/inputs
ln -s ${CFENGINE_CHECKOUT_DIR}/inputs ${CFENGINE_WORK_DIR}/
rm -rf ${CFENGINE_WORK_DIR}/masterfiles
ln -s ${CFENGINE_CHECKOUT_DIR}/masterfiles ${CFENGINE_WORK_DIR}/
rm -rf ${CFENGINE_WORK_DIR}/ppkeys
ln -s ${CFENGINE_CHECKOUT_DIR}/ppkeys ${CFENGINE_WORK_DIR}/
chmod 700 ${CFENGINE_WORK_DIR}/ppkeys
rm ${CFENGINE_WORK_DIR}/README.md
ln -s ${CFENGINE_CHECKOUT_DIR}/README.md ${CFENGINE_WORK_DIR}/README.md

echo "Setting up config files"
CFENGINE_SVN_INPUTS=${CFENGINE_CHECKOUT_DIR}/inputs/*
for file in ${CFENGINE_SVN_INPUTS}
do
        sed -i '' s#POLICY_SERVER#$POLICY_SERVER# ${file}
        sed -i '' s#CFENGINE_WORK_DIR#$CFENGINE_WORK_DIR# ${file}
        sed -i '' s#CFSERVERD_BIND_IP#$CFSERVERD_BIND_IP# ${file}
        sed -i '' s#CFENGINE_NETWORK#$CFENGINE_NETWORK# ${file}
        sed -i '' s#SMTP_SERVER#$SMTP_SERVER# ${file}
        sed -i '' s#MAIL_FROM#$MAIL_FROM# ${file}
        sed -i '' s#MAIL_TO#$MAIL_TO# ${file}
done

#cd ${CFENGINE_WORK_DIR}

