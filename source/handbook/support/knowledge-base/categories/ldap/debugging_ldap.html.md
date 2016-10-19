---
layout: markdown_page
title: Debugging LDAP
category: LDAP
---

### On this page
{:.no_toc}

- TOC
{:toc}

----

##### Notes:

This assumes an omnibus installation.

______________


See LDAP troubleshooting in docs - [View Docs](http://docs.gitlab.com/ee/administration/auth/ldap.html#troubleshooting)

**Testing the LDAP server**

1. Install `ldapsearch`

```
# Ubuntu
apt-get install ldap-utils
# CentOS
yum install openldap-clients
```

2. Check LDAP settings

Edit the following values to match the LDAP configuration in `gitlab.rb`

**Example LDAP configuration**

```
# cat /etc/gitlab/gitlab.rb | grep -A 24 ldap_servers
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
   main: # 'main' is the GitLab 'provider ID' of this LDAP server
     label: 'LDAP'
     host: '127.0.0.1'
     port: 389
     uid: 'uid'
     method: 'plain' # "tls" or "ssl" or "plain"
     bind_dn: 'cn=admin,dc=ldap-testing,dc=mrchris,dc=me'
     password: 'Password1'
     active_directory: true
     allow_username_or_email_login: false
     block_auto_created_users: false
     base: 'dc=ldap-testing,dc=mrchris,dc=me'
     user_filter: ''
     attributes:
       username: ['uid', 'userid', 'sAMAccountName']
       email:    ['mail', 'email', 'userPrincipalName']
       name:       'cn'
       first_name: 'givenName'
       last_name:  'sn'
     group_base: 'ou=groups,dc=ldap-testing,dc=mrchris,dc=me'
     admin_group: 'gitlab_admin'
EOS
```

**LDAP search switches**

+ **-D** = Bind DN 
   +  GitLab config value: `bind_dn: 'cn=admin,dc=ldap-testing,dc=mrchris,dc=me'`

+ **-b** = Search base
   +  GitLab config value: `base: 'dc=ldap-testing,dc=mrchris,dc=me'`

+ **-w** = Password
   +  GitLab config value: `password: 'Password1'`
  
+ **-w** = Port & **-h** = Host
   +  GitLab config value: `port: 389` 
   +  GitLab config value: `host: 127.0.0.1` 

+ **-s** = Search scope
   + GitLab config value: None
   + Default is **sub**
   + Using `sub "(objectclass=*)` will return "all" objects

**Get all LDAP objects for baseDN**

```
ldapsearch -D "cn=admin,dc=ldap-testing,dc=mrchris,dc=me" \
-w Password -p 389 -h 127.0.0.1 \
-b "dc=ldap-testing,dc=mrchris,dc=me" -s sub "(objectclass=*)"
```

#### LDAP Error messages (`production.log`)

##### Could not find member DNs for LDAP group

```
Could not find member DNs for LDAP group #<Net::LDAP::Entry:0x00000007220388 
```

This usually indicates an issue with the `uid` configuration value in `gitlab.rb` 

When running `ldapsearch` you can see what attribute is used for the LDAP username. In the below case the username attribute is `uid`. Ensure `uid: 'uid'` in the configuration. The default Microsoft Active Directory username value is `sAMAccountName`

```
dn: cn=user test,ou=people,dc=ldap-testing,dc=mrchris,dc=me
sn: test
givenName: user
uid: test
cn: user test
```

##### Cannot find LDAP group with CN 'GROUP_NAME'. Skipping

This indicates the admin_group name was not found `admin_group: 'gitlab_admin'`. Ensure the group exists in AD and is under the `group_base` 

##### LDAP search error: Invalid DN Syntax

This indicates a syntax error with one of the configured DNs. Check the following values, ensure they're the full DN.

+ `group_base`
+ `bind_dn`
+ `base`


**Testing LDAP** - valid for 8.10 >

1. Update the log_level

    ```
    vi /opt/gitlab/embedded/service/gitlab-rails/config/environments/production.rb
    ```

   + Find "config.log_level = :info"

   + Update `info` to `debug`

2. Launch the rails console

```
gitlab-rails c
```

   1. Perform a group sync

	```
	LdapGroupSyncWorker.new.perform
	```

   1. Perform a user sync

	```
	LdapSyncWorker.new.perform
	```
	
	
   1. Check the console for sync output


**Removing exclusive lease** - Testing (valid for 8.6 to 8.9)

This is used to force an instant sync of LDAP for testing purposes. 

1. Edit any LDAP settings required
1. Edit `vi /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/ldap/group_sync.rb`
1. Comment out the exclusive lease section *(lines may differ in releases)* - [View code](https://gitlab.com/gitlab-org/gitlab-ee/blob/5c8b211c7b8746ec6d5697e495ddb68f2ac08dd7/lib/gitlab/ldap/group_sync.rb#L70-73) 
1. Run a reconfigure `sudo gitlab-ctl reconfigure` **This will restart GitLab**
1. Launch GitLab rails console `gitlab-rails console`
1. Execute `Gitlab::LDAP::GroupSync.execute`
1. LDAP sync will now run
1. **Revert changes to the `group_sync.rb` file when finished**
 `/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/ldap/group_sync.rb`


**Additional testing**

1. Start the rails console

```
sudo gitlab-rails console
```
2. Create a new adapter instance

```
adapter = Gitlab::LDAP::Adapter.new('ldapmain')
```
   
3. Find a group by common name. Replace **UsersLDAPGroup** with the common name to search.

**GitLab 8.11 >**

```
group =  EE::Gitlab::LDAP::Group.find_by_cn('UsersLDAPGroup', adapter)
```


**GitLab < 8.10**

```
group =  Gitlab::LDAP::Group.find_by_cn('UsersLDAPGroup', adapter)
```
   
4. Check `member_dns`

```
group.member_dns
```