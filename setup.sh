POLICY_SERVER=cfengine-policy.supported.systems
CFENGINE_CHECKOUT_DIR=/root/cfengine
CFENGINE_REPO_URL=https://github.com/rsp2k/freebsd-cfengine
CFENGINE_WORK_DIR=/var/cfengine
CFSERVERD_BIND_IP=0.0.0.0
CFENGINE_NETWORK=10.1.16.0/20
CFENGINE_REPLACE_TOKENS="POLICY_SERVER CFENGINE_WORK_DIR CFSERVERD_BIND_IP CFENGINE_NETWORK"
E
SMTP_SERVER=0.0.0.0
MAIL_FROM=cfengine@example.com
MAIL_TO=ryan@supported.systems

echo "Installing CFEngine Core 3.11.0-build1"

pkg install cfengine

echo "Create key"
cf-key

CFKEY=/var/cfengine/ppkeys/localhost.pub

ln -s /usr/local/bin/cf-* /var/cfengine/bin/


echo "checkout repo"
svnlite checkout ${CFENGINE_REPO_URL} ${CFENGINE_HOME}

cd ${CFENGINE_WORK_DIR}

CFENGINE_SVN_INPUTS=${CFENGINE_CHECKOUT_DIR}/trunk/cfengine/inputs
for file in ${CFENGINE_SVN_INPUTS}
do
	sed -i '' 's/{{POLICY_SERVER}}/${POLICY_SERVER}/' ${file}
	sed -i '' 's/{{CFENGINE_WORK_DIR}}/${CFENGINE_WORK_DIR}/' ${file}
	sed -i '' 's/{{CFSERVERD_BIND_IP}}/${CFSERVERD_BIND_IP}/' ${file}
	sed -i '' 's/{{CFENGINE_NETWORK}}/${CFENGINE_NETWORK}/' ${file}
	sed -i '' 's/{{SMTP_SERVER}}/${SMTP_SERVER}/' ${file}
	sed -i '' 's/{{MAIL_FROM}}/${MAIL_FROM}/' ${file}
	sed -i '' 's/{{MAIL_TO}}/${MAIL_TO}/' ${file}
done

ln -s ${CFENGINE_CHECKOUT_DIR}/trunk/cfengine/inputs ${CFENGINE_WORK_DIR}/
ln -s ${CFENGINE_CHECKOUT_DIR}/trunk/cfengine/masterfiles ${CFENGINE_WORK_DIR}/
ln -s ${CFENGINE_CHECKOUT_DIR}/trunk/cfengine/masterfiles ${CFENGINE_WORK_DIR}/
mkdir /var/cfengine/masterfiles
