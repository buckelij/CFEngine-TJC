# CFENGINE-TJC #

These CFEngine scripts are sanitized versions of those used to configure
TJC CentOS 6 servers. The scripts have been modified from the originals,
so they aren't guaranteed to run as-is. They are designed to manage all
aspects of the system with the exception of the following:

 * /etc/cfkey secret

 * CFEngine installation

 * Network configuration

 * Local disk configuration

 * Interactive logon passwords

 * Application code deployment, which is typically handled by development
   or operations via Jenkins or custom scripts.

Rather than running a central CFEngine server to distribute configuration
updates to clients, new configuration is pushed to sets of servers via
the *zzzdeploy.sh* script.  Once the configuration is in place on the
servers, cssh is used to run commands on each server to to merge the
common and system-specific configuration (via *deploy.sh*) and then
apply the configuration.

The included cfengine_stdlib is from CFEngine 3.2. If a later version
of CFEngine is used, update the cfengine_stdlib to that version.

These scripts have been tested only on CentOS 6 x86_64.

Servers listed on the servers_all or backend_all slists in promises.cf
should be specified one-per-line.

grep for 'REDACTED' in these files to find areas where you may need to
fill in site-local values.

# Common #


*cleanup.cf*

  Cleans up old CFEngine run logs

*glpi.cf*

  Installs and runs the GLPI fusion-inventory agent. The address for
  the GLPI server is hard-coded.

*mcafee.cf*

  Installs McAfee AntiVirus :(

*mcafee_excludes.cf*

  Default directories excluded from scanning (mostly java archives
  that timeout when scanned).  To add additional excludes, copy
  mcafee_excludes.cf to the system-specific folder (e.g. foo) and add
  the additional folders. The deploy.sh script will overwrite the common
  mcafee_exludes with the  the system-specific mcafee_excludes.

*packages.cf*

  Packages we want installed on all systems (but aren't included in the
  base image).

*promises.cf*

  A system-specific promises.cf will almost always be used instead of the
  common promises.cf, but this default will execute the common scripts.

*services.cf*

  Enable NTP. Disable IPTables. Set SELinux permissive.  NOTE: If
  your system is not protected by another firewall, do not disable
  IPTables. You  should set SELinux to enforcing if possible (technically
  and politically), but these CFEngine scripts have not be tested with
  SELinux enforcing.

*vmware_tools.cf*

  Installs VMWare 5.1 guest tools. Also, removes old versions of VMWare
  tools.  BUG: VMWare tools repo does not gpg-check packages.

*yum_repos.cf*

  Configure yum to use local CentOS mirror, including the CR repo.

*zabbix.cf*

  Installs and configures zabbix agent. Additional CFEngine
  scripts can place zabbix UserParameter configuration under
  /etc/zabbix/zabbix_agentd/ and subsequent CFEngine runs will detect the
  new file and restart the zabbix agent. If a new version of zabbix-agent
  is detected in a yum repository, it will automatically be installed.

# System-Specific #


The 'foo' group of servers is used as an example here. This set includes
configuration scripts to install Apache Tomcat, Apache HTTPD, MySQL,
Memcached, OpenLDAP, NFS server, and to mount SMB file shares. The file
'promises.cf' contains the 'common control' section that is the beginning
of configuration execution.

In cases where a configuration bundle is likely to be used on
multiple sets of system, an effort is made to move variation outside
of configuration script itself. For example, the *tomcat.cf* bundle
expects that the variable 'tomcat_password' and 'tomcat_java_opts' will
be specified in 'common def' bundle in promises.cf. In other cases,
for example the 'sorry server' configuration in *apache_sorry.cf*,
values are defined directly in the configuration file.

In order to prevent passwords from being stored in plaintext on
the source control server, passwords and other sensitive data is
stored encrypted with the password specified in /etc/cfkey on each
system. For example, if the password in /etc/cfkey is 'cfkeyS3cret',
and the mysql root password you want to store is 'mysqlPassw0rd',
you would set the *promises.cf/common def* mysql_password value to
'U2FsdGVkX1+aIXFa20nAccL/9peb1oh+Ughi5C2OhPs='. This value is derived
with the following command:

  echo mysqlPassw0rd | openssl enc -des3 -e -a -pass pass:cfkeyS3cret

And is decrypted by CFEngine on the fly with the command:

  "password" string => execresult( "/bin/echo $(def.mysql_password) | \
        /usr/bin/openssl enc -des3 -d -a -pass file:/etc/cfkey",
        "useshell");

*apachephp.cf*

  Installs and configures a basic Apache httpd server with PHP. PHP is
  configured with a post_max_size of 16M and a upload_max_filesize of 10M.

*apache_sorry.cf*

  Installs and configures Apache httpd to act as a backup 'sorry server'
  to serve down pages if the load balancer detects that web servers
  are unavailable.

*authzn.cf*

  Configures local users and service accounts. Pretty messy.

*mcafee_excludes.cf*

  See the 'Common' notes above.

*memcached.cf*

  Installs and configures a small memcached instance.

*mysql.cf*

  Installs and configures MySQL server. Also installs additional Zabbix
  monitoring and schedules a nightly mysqldump.

*nfs_logs.cf*

  NFS read-only exports the /usr/local/tomcat/logs directory.

*openldap.cf*

  Installs and configures an OpenLDAP server and schedules backups.

*promises.cf*

  Defines the servers, the roles of the servers, variables that are
  used by the various bundles, and the execution order of each bundle
  for each role.

*smb_mounts.cf*

  Mounts SMB shares and configures monitoring. Note that credentials
  for each share must be manually put into the relevant file in
  /etc/autocreds/.  /etc/autocreds is an ecryptfs volume.

*tomcat.cf*

  Installs and configures Apache Tomcat from tar. can upgrade to new
  versions and migrate data.  NOTES: * Probably better to build an RPM
  and separate data to /var.
         * Noisy on initial install.
