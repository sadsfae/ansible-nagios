ansible-nagios
==============
Ansible Playbook for setting up the Nagios monitoring system on CentOS/RHEL.

![Nagios](/image/ansible-nagios.png?raw=true)

**What does it do?**
   - Automated deployment of Nagios on CentOS or RHEL
     * Generates service checks, and monitored hosts from Ansible inventory
     * Wraps Nagios in SSL via Apache
     * Templating inspired from the official [ansible examples](https://github.com/ansible/ansible-examples)

**Requirements**
   - RHEL7 or CentOS7+ for Nagios server.

**Notes**
   - Sets the ```nagiosadmin``` password to ```changeme```, you'll want to change this.
   - Implementation is very simple, with only the following server types generated right now:
     - out-of-band interfaces (Dell iDRAC, IPMI etc) (ping/ssh)
     - generic servers (ping, ssh, users, load, swap)
     - webservers (http check, ping, ssh, users, load, swap)
     - network switches (ping/ssh)
   - I do not setup the ```contacts.cfg``` file for notifications

**Nagios Server Instructions**
   - Clone repo and setup your hosts file
```
git clone https://github.com/sadsfae/ansible-nagios
cd ansible-nagios
sed -i 's/host-01/yournagioshost/' hosts
```
   - Add any hosts for checks in the ```hosts``` inventory
   - Note that you need to add ```ansible_host``` aliases for switches, out-of-band interfaces and anything that typically doesn't support Python and Ansible fact discovery.
```
[webservers]
webserver01

[switches]
switch01 ansible_host=192.168.0.100
switch02 ansible_host=192.168.0.102

[oobservers]
webserver01-idrac ansible_host=192.168.0.105

[servers]
server01
```
   - Run the playbook
```
ansible-playbook -i hosts install/elk.yml
```
   - Navigate to the server at https://yourhost/nagios
   - Default login is ```nagiosadmin / changeme``` unless you changed it in ```install/group_vars/all.yml```

**TODO**
   - Write equivalent ```nagios-client``` playbooks for NRPE
   - Expand checks
   - Add support for new server types
   - Allow for Nagios/HTTP ports to be configurable

**Files**

```
├── hosts
└── install
    ├── group_vars
    │   └── all.yml
    ├── nagios.yml
    └── roles
        ├── nagios
        │   ├── files
        │   │   ├── localhost.cfg
        │   │   ├── nagios.cfg
        │   │   ├── nagios.conf
        │   │   └── services.cfg
        │   ├── tasks
        │   │   └── main.yml
        │   └── templates
        │       ├── oobservers.cfg.j2
        │       ├── servers.cfg.j2
        │       ├── switches.cfg.j2
        │       └── webservers.cfg.j2
        └── nagios-client

8 directories, 12 files
```
