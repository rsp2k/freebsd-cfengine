POLICY_SERVER=cfengine-policy.supported.systems
CFENGINE_WORK_DIR=/var/cfengine
CF_SERVER_BIND_IP=0.0.0.0
CFENGINE_NETWORK=10.1.16.0/20

SMTP_SERVER=0.0.0.0
MAIL_FROM=cfengine@example.com
MAIL_TO=ryan@supported.systems

echo "Installing CFEngine Core 3.11.0-build1"

pkg install cfengine

cf-key
CF_KEY=/var/cfengine/ppkeys/localhost.pub

vi /var/cfengine/inputs/cfagent.conf

ln -s /usr/local/bin/cf-* /var/cfengine/bin/

mkdir /var/cfengine/masterfiles

cat <<EOF
#####################################
#                                   #
# cf-serverd.cf - CFEngine Server   #
#                                   #
#####################################

body server control {
    skipverify          => { "${CFENGINE_NETWORK}" ;
    allowconnects       => { "${CFENGINE_NETWORK}" };
    allowallconnects    => { "${CFENGINE_NETWORK}" };
    maxconnections      => "100";
    logallconnections   => "true";
    bindtointerface     => "${CF_SERVER_BIND_IP}";
    cfruncommand        => "$(sys.workdir)/bin/cf-agent";
    allowusers          => { "root" };
}

# Make sure that the server is running on the policy servers
bundle agent server {

vars:

    "rc_d" string => "/usr/local/etc/rc.d";

processes:
    
    policy_servers::

        "cf-serverd"
            
            comment       => "Make sure cf-serverd runs on the policy servers",
            restart_class => "start_cfserverd";

commands:

    start_cfserverd::
    
        "$(rc_d)/cf-serverd start";
}

bundle server access_rules {

access:

    # Allow clients access to the input files
    "$(g.inputfiles)"

        admit => { "${CFENGINE_NETWORK}" };

    # Allow clients access to the masterfiles
    "$(g.masterfiles)"

        admit => { "${CFENGINE_NETWORK}" };
}

EOF > ${CFENGINE_WORK_DIR}/inputs/cf-serverd.cf

cat <<EOF
#####################################
#                                   #
# cf-execd.cf - CFEngine Executor   #
#                                   #        
#####################################

body executor control {
    splaytime           => "1";
    mailto              => "${MAIL_TO}";
    mailfrom            => "${MAIL_FROM}";
    smtpserver          => "${SMTP_SERVER}";
    mailmaxlines        => "100";
    schedule            => { "Min05" };
    executorfacility    => "LOG_DAEMON";
}

# Make sure the executor is running
bundle agent executor {

vars:

    "rc_d" string => "/usr/local/etc/rc.d";

processes:

    "cf-execd"
    
        comment       => "Make sure that cf-execd runs on all hosts",
        restart_class => "start_cfexecd";

commands:

    start_cfexecd::

        "$(rc_d)/cf-execd start";
}

EOF > ${CFENGINE_WORK_DIR}/inputs/cf-execd.cf

cat <<EOF
#####################################
#                                   #
# cf-report.cf - CFEngine Reports #
#                                   #
#####################################

body reporter control {
    reports         => { "performance", "last_seen", "monitor_history" };
    build_directory => "$(sys.workdir)/reports";
    report_output   => "text";
}
EOF > ${CFENGINE_WORK_DIR}/inputs/cf-report.cf

cat <<EOF
#################################################
#                                               #
# classes.cf - CFEngine user-defined classes  #
#                                               #
#################################################

bundle common myclasses {

vars:

    "sysctl_jailed" string => execresult("/sbin/sysctl -n security.jail.jailed", "noshell");

classes:

    "freebsd_jail" expression => strcmp("$(sysctl_jailed)", "1");
    "freebsd_host" expression => strcmp("$(sysctl_jailed)", "0");

    "policy_servers" or => {
        classify("$(g.policyhost)")
    };
}
EOF > ${CFENGINE_WORK_DIR}/inputs/cf-report.cf

cat <<EOF
#####################################################
#                                                   #
# cleanup.cf - CFEngine promises for tidying up   #
#                                                   #
#####################################################

# A bundle for cleaning up old and not needed files and directories
bundle agent cleanup {
    
files:

    # Cleanup old reports
    "$(sys.workdir)/outputs"
    
        comment         => "Clean up reports older than 3 days",
        delete          => tidy,
        file_select     => days_old("3"),
        depth_search    => recurse("inf");
}
EOF > ${CFENGINE_WORK_DIR}/inputs/cleanup.cf

cat <<EOF
#####################################################
#                                                   #
# promises.cf - Main CFEngine configuration file    #
#                                                   #
#####################################################

body common control {

    any::

        bundlesequence => { @(g.bundlesequence) };

    any:: 

        inputs => {
            "update.cf",
            "library.cf",
            "classes.cf",
            "cf-execd.cf",
            "cf-serverd.cf",
            "cleanup.cf"
        };

    output_prefix => "cf3>";
}

# global vars
bundle common g {

vars:

    "workdir"           string => "${CFENGINE_WORK_DIR}";
    "masterfiles"       string => "$(workdir)/masterfiles";
    "inputfiles"        string => "$(workdir)/inputs";
    "policyhost"        string => "${POLICY_SERVER}";
    "bundlesequence"    slist  => { "update", "executor", "server", "cleanup" };
}

body runagent control {
    hosts => { "127.0.0.1", "${CFENGINE_NETWORK}" };
}

EOF > ${CFENGINE_WORK_DIR}/inputs/promises.cf

cat <<EOF
#####################################################
#                                                   #
# update.cf - Promises for updating policy files    #
#                                                   #
#####################################################

bundle agent update {

vars:

    "u_workdir"     string => "${CFENGINE_WORK_DIR}";
    "u_policyhost"  string => "${POLICY_SERVER}";

classes:

    "u_policy_servers" or => { classify("$(u_policyhost)") };

files:

    "$(u_workdir)/."

        comment         => "Set proper permissions of the work directory",
        create          => "true", 
        perms           => u_workdir_perms("0600");

    "$(u_workdir)/bin/." 

        comment         => "Copy CFEngine binaries to $(u_workdir)/bin",
        create          => "true",
        perms           => u_workdir_perms("0700"),
        depth_search    => u_recurse("inf"),
        file_select     => u_cf3_bin_files,
        copy_from       => u_copy_cf3_bin_files("/usr/local/sbin");
 
    "$(u_workdir)/masterfiles/."
    
        comment         => "Set proper permissions of the $(u_workdir)/masterfiles directory",
        create          => "true",
        perms           => u_workdir_perms("0600"),
        depth_search    => u_recurse("inf");

    u_policy_servers::

        "$(u_workdir)/inputs/."

            comment             => "Set proper permissions of input files on policy server",
            create              => "true",
            perms               => u_workdir_perms("0600"),
            depth_search        => u_recurse("inf");

    !u_policy_servers::

        "$(u_workdir)/inputs/." 

            comment         => "Update input files from policy server",
            create          => "true",
            perms           => u_workdir_perms("0600"),
            depth_search    => u_recurse("inf"),
            copy_from       => u_policy_copy("$(u_policyhost)");
}

#
# u_cf3_bin_files
# 

body file_select u_cf3_bin_files {
    leaf_name   => { "cf-.*" };
    file_result => "leaf_name";
}

#
# u_workdir_perms
# 

body perms u_workdir_perms(mode) {
    mode    => "$(mode)";
    owners  => { "root" };
    groups  => { "wheel" };
}

# 
# u_policy_copy
#

body copy_from u_policy_copy(server) {
    source      => "$(u_workdir)/inputs";
    servers     => { "$(u_policyhost)" };
    compare     => "digest";
    purge       => "true";
    copy_backup => "false";
}

#
# u_copy_cf3_bin_files
#

body copy_from u_copy_cf3_bin_files(path) {
    source  => "$(path)";
    compare => "digest";
}

# 
# u_recurse
#

body depth_search u_recurse(d) {
    depth   => "$(d)";
    xdev    => "true";
}
EOF > ${CFENGINE_WORK_DIR}/inputs/update.cf


cat <<EOF
#########################################
#                                       #    
# failsafe.cf - Failsafe configuration  #
#                                       #
#########################################

body common control {

    any::

        bundlesequence => { "update" };

        inputs => { "update.cf" };
}

bundle common failsafe_globals {

vars:
    
    "f_policyhost" string => "cfengine.example.org";

classes:

    "f_policy_servers" or => { classify("$(f_policyhost)") };
}
EOF > ${CFENGINE_WORK_DIR}/inputs/failsafe.cf



