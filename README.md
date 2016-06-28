ansible-nagios
==============
Ansible Playbook for setting up the Nagios monitoring system and clients on CentOS/RHEL.

![Nagios](/image/ansible-nagios.png?raw=true)

**What does it do?**
   - Automated deployment of Nagios on CentOS or RHEL
     * Generates service checks, and monitored hosts from Ansible inventory
     * Generates comprehensive checks for the Nagios server
     * Generates comprehensive checks for all hosts/services via NRPE
     * Wraps Nagios in SSL via Apache
     * Sets up proper firewall rules (firewalld or iptables-services)

**Requirements**
   - RHEL7 or CentOS7+ for Nagios server.

**Notes**
   - Sets the ```nagiosadmin``` password to ```changeme```, you'll want to change this.
   - Implementation is very simple, with only the following server types generated right now:
     - out-of-band interfaces *(ping, ssh, http)*
     - generic servers *(ping, ssh, load, users, procs, uptime, disk space)*
     - webservers *(http, ping, ssh, load, users, procs, uptime, disk space)*
     - network switches *(ping, ssh)*
   - ```contacts.cfg``` notification settings are in ```install/group_vars/all.yml``` and templated for easy modification.
   - Adding new hosts to inventory file will just regenerate the Nagios configs

**Nagios Server Instructions**
   - Clone repo and setup your Ansible inventory (hosts) file
```
git clone https://github.com/sadsfae/ansible-nagios
cd ansible-nagios
sed -i 's/host-01/yournagioshost/' hosts
```
   - Add any hosts for checks in the ```hosts``` inventory
   - Note that you need to add ```ansible_host``` entries for IP addresses for switches, out-of-band interfaces and anything that typically doesn't support Python and Ansible fact discovery.
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
        │       ├── commands.cfg.j2
        │       ├── contacts.cfg.j2
        │       ├── oobservers.cfg.j2
        │       ├── servers.cfg.j2
        │       ├── switches.cfg.j2
        │       └── webservers.cfg.j2
        └── nagios-client
            ├── tasks
            │   └── main.yml
            └── templates
                └── nrpe.cfg.j2

10 directories, 16 files
```
