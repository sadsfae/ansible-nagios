ansible-nagios
==============
Playbook for setting up the Nagios monitoring server and clients (CentOS/RHEL/Fedora/FreeBSD)

![Nagios](/image/ansible-nagios.png?raw=true)

[![CI](https://travis-ci.org/sadsfae/ansible-nagios.svg?branch=master)](https://travis-ci.org/sadsfae/ansible-nagios)

## What does it do?
   - Automated deployment of Nagios Server on CentOS7 or RHEL7
   - Automated deployment of Nagios client on CentOS6/7/8, RHEL6,7,8, Fedora and FreeBSD
     * Generates service checks and monitored hosts from Ansible inventory
     * Generates comprehensive checks for the Nagios server itself
     * Generates comprehensive checks for all hosts/services via NRPE
     * Generates most of the other configs based on jinja2 templates
     * Wraps Nagios in SSL via Apache
     * Sets up proper firewall rules (firewalld or iptables-services)
     * This is also available via [Ansible Galaxy](https://galaxy.ansible.com/sadsfae/ansible-nagios/)

## How do I use it?
   - Add your nagios server under `[nagios]` in `hosts` inventory
   - Add respective services/hosts under their inventory group, **hosts can only belong under one group.**
   - Take a look at `install/group_vars/all.yml` to change anything like email address, nagios user, guest user etc.
   - Run the playbook.  Read below for more details if needed.

## Requirements
   - RHEL7 or CentOS7 for Nagios server only.
   - RHEL6/7/8, CentOS6/7/8, Fedora or FreeBSD for the NRPE Nagios client
   - If you require SuperMicro server monitoring via IPMI (optional) then do the following
     - Install```perl-IPC-Run``` and ```perl-IO-Tty``` RPMs for RHEL7.
       - I've placed them [here](https://funcamp.net/w/rpm/el7/) if you can't find them, CentOS7 has them however.
     - Modify ```install/group_vars/all.yml``` to include ```supermicro_enable_checks: true```

## Notes
   - Sets the ```nagiosadmin``` password to ```changeme```, you'll want to change this.
   - Creates a read-only user, set ```nagios_create_guest_user: false``` to disable this in ```install/group_vars/all.yml```
   - You can turn off creation/management of firewall rules via ```install/group_vars/all.yml```
   - Adding new hosts to inventory file will just regenerate the Nagios configs

## Supported Service Checks
   - Implementation is very simple, with the following resource/service checks generated:
     - Generic out-of-band interfaces *(ping, ssh, http)*
     - Generic Linux servers *(ping, ssh, load, users, procs, uptime, disk space, swap, zombie procs)*
     - Generic Linux servers with MDADM RAID (same as above)
     - [ELK servers](https://github.com/sadsfae/ansible-elk) *(same as servers plus elasticsearch and Kibana)*
     - Elasticsearch *(same as servers plus TCP/9200 for elasticsearch)*
     - Webservers *(same as servers plus 80/TCP for webserver)*
     - DNS Servers *(same as servers plus UDP/53 for DNS)*
     - DNS Servers with MDADM RAID (same as above)
     - Jenkins CI *(same as servers plus TCP/8080 for Jenkins and optional nginx reverse proxy with auth)*
     - FreeNAS Appliances *(ping, ssh, volume status, alerts, disk health)*
     - Network switches *(ping, ssh)*
     - IoT and ping-only devices *(ping)*
     - Dell iDRAC server checks via @dangmocrang [check_idrac](https://github.com/dangmocrang/check_idrac)
       - You can select which checks you want in ```install/group_vars/all.yml```
         - CPU, DISK, VDISK, PS, POWER, TEMP, MEM, FAN
     - SuperMicro server checks via the IPMI interface.
       - CPU, DISK, PS, TEMP, MEM: or anything supported via ```freeipmi``` sensors.
       - *Note: This is **not** the best way to monitor things, SNMP checks are WIP once we purchase licenses for them for our systems
   - ```contacts.cfg``` notification settings are in ```install/group_vars/all.yml``` and templated for easy modification.

## Nagios Server Instructions
   - Clone repo and setup your Ansible inventory (hosts) file
```
git clone https://github.com/sadsfae/ansible-nagios
cd ansible-nagios
sed -i 's/host-01/yournagioshost/' hosts
```
   - Add any hosts for checks in the ```hosts``` inventory
   - The same host can only belong to **one** host inventory category
   - Note that you need to add ```ansible_host``` entries __only__ for IP addresses for idrac, switches, out-of-band interfaces and anything that typically doesn't support Python and Ansible fact discovery.
   - Anything __not__ an ```idrac```, ```switch``` or ```oobserver``` should use the FQDN (or an /etc/hosts entry) for the inventory hostname or you may see this error:
     - ```AnsibleUndefinedVariable: 'dict object' has no attribute 'ansible_default_ipv4'}```

```
[webservers]
webserver01

[switches]
switch01 ansible_host=192.168.0.100
switch02 ansible_host=192.168.0.102

[oobservers]
webserver01-ilo ansible_host=192.168.0.105

[servers]
server01

[servers_with_mdadm_raid]

[jenkins]
jenkins01

[dns]

[dns_with_mdadm_raid]

[idrac]
database01-idrac ansible_host=192.168.0.106

[supermicro-6048r]
web01-supermicro-ipmi ansible_host=192.168.0.108

[supermicro-6018r]

[supermicro-1028r]

```
   - Run the playbook
```
ansible-playbook -i hosts install/nagios.yml
```
   - Navigate to the server at https://yourhost/nagios
   - Default login is ```nagiosadmin / changeme``` unless you changed it in ```install/group_vars/all.yml```

## Known Issues

* If you're using a non-root Ansible user you will want to edit ```install/group_vars/all.yml``` setting, e.g. AWS EC2:

```
ansible_system_user: ec2-user
```

* SELinux doesn't always play well with Nagios, or the policies may be out of date as shipped with CentOS/RHEL.
```
avc: denied { create } for pid=8800 comm="nagios" name="nagios.qh
```
   - If you see this (or nagios doesn't start) you'll need to create an SELinux policy module.
```
# cat /var/log/audit/audit.log | audit2allow -M mynagios
# semodule -i mynagios.pp
```
Now restart Nagios and Apache and you should be good to go.
```
systemctl restart nagios
systemctl restart httpd
```
If all else fails set SELinux to permissive until it's running then run the above command again.
```
setenforce 1
```

* If you have errors on RHEL7 you may need a few [Perl packages](https://funcamp.net/w/rpm/el7/) if you opted to include SuperMicro monitoring via:

```
supermicro_enable_checks: true
```

## Mass-generating Ansible Inventory
If you're using something like [QUADS](https://quads.dev/about-quads) to manage your infrastructure automation scheduling you can do the following to generate all of your out-of-band or iDRAC interfaces.

```
quads-cli --ls-hosts | sed -e 's/^/mgmt-/g' > /tmp/all_ipmi_2019-10-23
for ipmi in $(cat all_ipmi_2019-10-23); do printf $ipmi ; echo " ansible_host=$(host $ipmi | awk '{print $NF}')"; done > /tmp/add_oobserver
```

Now you can paste `/tmp/add_oobserver` under the `[oobservers]` or `[idrac]` Ansible inventory group respectively.


## Demonstration
   - You can view a video of the Ansible deployment here:

[![Ansible Nagios](http://img.youtube.com/vi/6vfhflwC_Wg/0.jpg)](http://www.youtube.com/watch?v=6vfhflwC_Wg "Deploying Nagios with Ansible")

## iDRAC Server Health Details
   - The iDRAC health checks are all optional, you can pick which ones you want to monitor.

![CHECK](/image/idrac-check.jpg?raw=true)

   - The iDRAC health check will provide exhaustive health information and alert upon it.

![iDRAC](/image/nagios-idrac.png?raw=true)

## Files

```
.
├── hosts
├── install
│   ├── group_vars
│   │   └── all.yml
│   ├── nagios.yml
│   └── roles
│       ├── firewall
│       │   └── tasks
│       │       └── main.yml
│       ├── firewall_client
│       │   └── tasks
│       │       └── main.yml
│       ├── instructions
│       │   └── tasks
│       │       └── main.yml
│       ├── nagios
│       │   ├── files
│       │   │   ├── check_ipmi_sensor
│       │   │   ├── idrac_2.2rc4
│       │   │   ├── idrac-smiv2.mib
│       │   │   ├── nagios.cfg
│       │   │   └── nagios.conf
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── cgi.cfg.j2
│       │       ├── check_freenas.py.j2
│       │       ├── commands.cfg.j2
│       │       ├── contacts.cfg.j2
│       │       ├── devices.cfg.j2
│       │       ├── dns.cfg.j2
│       │       ├── dns_with_mdadm_raid.cfg.j2
│       │       ├── elasticsearch.cfg.j2
│       │       ├── elkservers.cfg.j2
│       │       ├── freenas.cfg.j2
│       │       ├── idrac.cfg.j2
│       │       ├── ipmi.cfg.j2
│       │       ├── jenkins.cfg.j2
│       │       ├── localhost.cfg.j2
│       │       ├── oobservers.cfg.j2
│       │       ├── servers.cfg.j2
│       │       ├── servers_with_mdadm_raid.cfg.j2
│       │       ├── services.cfg.j2
│       │       ├── supermicro_1028r.cfg.j2
│       │       ├── supermicro_6018r.cfg.j2
│       │       ├── supermicro_6048r.cfg.j2
│       │       ├── switches.cfg.j2
│       │       └── webservers.cfg.j2
│       └── nagios_client
│           ├── files
│           │   ├── bsd_check_uptime.sh
│           │   └── check_raid
│           ├── handlers
│           │   └── main.yml
│           ├── tasks
│           │   └── main.yml
│           └── templates
│               └── nrpe.cfg.j2
├── meta
│   └── main.yml
└── tests
    └── test-requirements.txt

21 directories, 43 files

```
