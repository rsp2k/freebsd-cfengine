# freebsd-cfengine

The work directory of CFEngine (/var/cfengine) contains several directories. The **bold** diretories are contained in this repository.

* /var/cfengine/bin - CFEngine binaries
* **/var/cfengine/inputs** - Main configuration files of CFEngine
* /var/cfengine/lastseen - Contains records of last-seen agents
* **/var/cfengine/masterfiles** - Master files on the server, that agents will request from the server
* /var/cfengine/modules - Contains additional variables and classes definition based on user-defined code
* /var/cfengine/outputs - Contains reports of previous runs of cf-agent(8)
* /var/cfengine/ppkeys - Stores the authentication keys
* /var/cfengine/reports - The output directory used by cf-report(8)
* /var/cfengine/state - Directory containing the various states of promises

Steps to checkout
```
echo "Checking out repository"
svnlite checkout https://github.com/rsp2k/freebsd-cfengine/trunk/cfengine /root/cfengine

echo "linking repo dirs to work directory"
ln -s ${CFENGINE_CHECKOUT_DIR}/inputs /var/cfengine/
ln -s ${CFENGINE_CHECKOUT_DIR}/masterfiles /var/cfengine/
```
