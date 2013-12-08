#!/bin/bash
#disable anonymous bind
cat >>/etc/openldap/slapd.d/cn=config.ldif <<EOB
olcDisallows: bind_anon
EOB

#require authentication
cat >>/etc/openldap/slapd.d/cn=config/olcDatabase={-1}frontend.ldif <<EOB
olcRequires: authc
EOB

#Set the root password. See http://www.openldap.org/faq/data/cache/347.html
cat >>/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif <<EOB
olcRootPW: {SSHA}REDACTED
EOB

BDBNUM=`/bin/ls /etc/openldap/slapd.d/cn=config/olcDatabase*bdb.ldif|cut -c 46`

cat >>/etc/openldap/slapd.d/cn=config/olcDatabase={$BDBNUM}bdb.ldif <<EOB
olcRootPW: {SSHA}REDACTED
EOB
sed -i'' -e 's/olcSuffix.*/olcSuffix: o=REDACTED/' /etc/openldap/slapd.d/cn=config/olcDatabase={$BDBNUM}bdb.ldif
sed -i'' -e 's/olcRootDN.*/olcRootDN: cn=Manager,o=REDACTED/' /etc/openldap/slapd.d/cn=config/olcDatabase={$BDBNUM}bdb.ldif

sed -i'' -e 's/olcMonitoring: FALSE/olcMonitoring: TRUE/' /etc/openldap/slapd.d/cn=config/olcDatabase*monitor.ldif

/bin/chown -R ldap:ldap /etc/openldap
/usr/sbin/slapadd -l /var/cfengine/recipes/openldap/init.ldif
/bin/cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
/bin/chown -R ldap /var/lib/ldap
/sbin/service slapd start
/sbin/service slapd restart

