# ansible-nagios

Playbook for setting up the Nagios monitoring server and clients

![Nagios](/image/ansible-nagios.png?raw=true)

[![GA](https://github.com/sadsfae/ansible-nagios/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/sadsfae/ansible-nagios/actions)

## Table of Contents

- [What does it do?](#what-does-it-do)
- [How do I use it?](#how-do-i-use-it)
- [Requirements](#requirements)
  - [Collection Dependencies](#collection-dependencies)
- [Notes](#notes)
- [Supported Service Checks](#supported-service-checks)
- [Nagios Server Instructions](#nagios-server-instructions)
- [Known Issues](#known-issues)
- [Mass-generating Ansible Inventory](#mass-generating-ansible-inventory)
- [Demonstration](#demonstration)
- [iDRAC Server Health Details](#idrac-server-health-details)
- [Files](#files)

## What does it do?

- Automated deployment of Nagios Server on CentOS7, Rocky 8/9 or RHEL 7/8/9/10, Debian/Ubuntu
- Automated deployment of Nagios client on CentOS6/7/8, RHEL6/7/8/9/10 or Rocky, Fedora, Ubuntu/Debian and FreeBSD
  - Generates service checks and monitored hosts from Ansible inventory
  - Generates comprehensive checks for the Nagios server itself
  - Generates comprehensive checks for all hosts/services via NRPE
  - Generates most of the other configs based on jinja2 templates
  - Wraps Nagios in SSL via Apache
  - Sets up proper firewall rules (firewalld or iptables-services)
  - Support sending alerts via email and outgoing webhooks.
  - This is also available via [Ansible Galaxy](https://galaxy.ansible.com/sadsfae/ansible-nagios/)

## How do I use it?

- Add your nagios server under `[nagios]` in `hosts` inventory
- Add respective services/hosts under their inventory group, **hosts can only belong under one group.**
- Take a look at `install/group_vars/all.yml` to change anything like email address, nagios user, guest user etc.
- Run the playbook. Read below for more details if needed.

## Requirements

- Rocky, RHEL, Debian, Ubuntu Linux for Nagios server only 
- Rocky, RHEL, Debian, Ubuntu, Fedora Linux and FreeBSD for NRPE Nagios client. 

### Collection Dependencies

This role requires the following Ansible collections:
- `community.general` (for UFW firewall management)
- `ansible.posix` (for firewalld and SELinux boolean management)

**Installing via System Packages (Recommended):**

RHEL/Rocky/Fedora:
```bash
sudo dnf install ansible-collection-community-general ansible-collection-ansible-posix
```

Debian/Ubuntu:
```bash
sudo apt install ansible-collection-community-general ansible-collection-ansible-posix
```

**Alternative: Installing via Ansible Galaxy:**
```bash
ansible-galaxy collection install -r requirements.yml
```

## Notes

- Sets the `nagiosadmin` password to `changeme`, you'll want to change this.
- Creates a read-only user, set `nagios_create_guest_user: false` to disable
  this in `install/group_vars/all.yml`
- You can turn off creation/management of firewall rules via `install/group_vars/all.yml`
- Adding new hosts to inventory file will just regenerate the Nagios configs

## Supported Service Checks

- Implementation is very simple, with the following resource/service checks generated:
  - Generic out-of-band interfaces *(ping, ssh, http)*
  - Generic Linux servers *(ping, ssh, load, users, procs, uptime, disk space,
    swap, zombie procs)*
  - Generic Linux servers with MDADM RAID (same as above)
  - File Monitor hosts *(same as servers plus file age monitoring with configurable thresholds)*
  - [ELK servers](https://github.com/sadsfae/ansible-nagios) *(same as servers
    plus elasticsearch and Kibana)*
  - Elasticsearch *(same as servers plus TCP/9200 for elasticsearch)*
  - Webservers *(same as servers plus 80/TCP for webserver)*
  - Webservers with SSL certificate checking *(same as webservers plus checks
    SSL certificate validity/expiration)*
  - DNS Servers *(same as servers plus UDP/53 for DNS)*
  - DNS Servers with MDADM RAID (same as above)
  - DNS Service Only (DNS and ICMP check)
  - Jenkins CI *(same as servers plus TCP/8080 for Jenkins and optional nginx
    reverse proxy with auth)*
  - FreeNAS Appliances *(ping, ssh, volume status, alerts, disk health)*
  - Network switches *(ping, ssh)*
  - IoT and ping-only devices *(ping)*
  - Dell iDRAC server checks via @dangmocrang [check_idrac](https://github.com/dangmocrang/check_idrac)
    - You can select which checks you want in `install/group_vars/all.yml`
      - CPU, DISK, VDISK, PS, POWER, TEMP, MEM, FAN
  - [QUADS](https://quads.dev/about-quads) Servers *(same as server plus
    alerting on active assignments that are not validated after a time
    threshold)*
- `contacts.cfg` notification settings are in `install/group_vars/all.yml` and
  templated for easy modification.

## Nagios Server Instructions

- Clone repo and setup your Ansible inventory (hosts) file

```bash
git clone https://github.com/sadsfae/ansible-nagios
cd ansible-nagios
sed -i 's/host-01/yournagioshost/' hosts
```

- Add any hosts for checks in the `hosts` inventory
- The same host can only belong to **one** host inventory category
- Note that you need to add `ansible_host` entries **only** for IP addresses
  for idrac, switches, out-of-band interfaces and anything that typically
  doesn't support Python and Ansible fact discovery.
- Anything **not** an `idrac`, `switch` or `oobserver` should use the FQDN (or
  an /etc/hosts entry) for the inventory hostname or you may see this error:
  - `AnsibleUndefinedVariable: 'dict object' has no attribute 'ansible_default_ipv4'}`

```ini
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

[quads_servers]
```

- Run the playbook

```bash
ansible-playbook -i hosts install/nagios.yml
```

- Navigate to the server at `https://yourhost/nagios`
- Default login is `nagiosadmin / changeme` unless you changed it in
  `install/group_vars/all.yml`

## Known Issues

- If you're using a non-root Ansible user you will want to edit
  `install/group_vars/all.yml` setting, e.g. AWS EC2:

```yaml
ansible_system_user: ec2-user
```

- SELinux doesn't always play well with Nagios, or the policies may be out of
  date as shipped with CentOS/RHEL.

```text
avc: denied { create } for pid=8800 comm="nagios" name="nagios.qh
```

- If you see this (or nagios doesn't start) you'll need to create an SELinux
  policy module.

```bash
# cat /var/log/audit/audit.log | audit2allow -M mynagios
# semodule -i mynagios.pp
```

Now restart Nagios and Apache and you should be good to go.

```bash
systemctl restart nagios
systemctl restart httpd
```

If all else fails set SELinux to permissive until it's running then run the
above command again.

```bash
setenforce 1
```

## Mass-generating Ansible Inventory

If you're using something like [QUADS](https://quads.dev/about-quads) to manage
your infrastructure automation scheduling you can do the following to generate all
of your out-of-band or iDRAC interfaces.

```bash
quads-cli --ls-hosts | sed -e 's/^/mgmt-/g' > /tmp/all_ipmi_2019-10-23
for ipmi in $(cat all_ipmi_2019-10-23); do printf $ipmi ; echo " ansible_host=$(host $ipmi | awk '{print $NF}')"; done > /tmp/add_oobserver
```

Now you can paste `/tmp/add_oobserver` under the `[oobservers]` or `[idrac]`
Ansible inventory group respectively.

## Demonstration

- You can view a video of the Ansible deployment here:

[![Ansible Nagios](http://img.youtube.com/vi/6vfhflwC_Wg/0.jpg)](http://www.youtube.com/watch?v=6vfhflwC_Wg "Deploying Nagios with Ansible")

## iDRAC Server Health Details

- The iDRAC health checks are all optional, you can pick which ones you want to
  monitor.

![CHECK](/image/idrac-check.jpg?raw=true)

- The iDRAC health check will provide exhaustive health information and alert
  upon it.

![iDRAC](/image/nagios-idrac.png?raw=true)

## Files

```text
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
│       │       ├── jenkins.cfg.j2
│       │       ├── localhost.cfg.j2
│       │       ├── oobservers.cfg.j2
│       │       ├── servers.cfg.j2
│       │       ├── servers_with_mdadm_raid.cfg.j2
│       │       ├── services.cfg.j2
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

21 directories, 38 files
```
