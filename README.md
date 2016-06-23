ansible-nagios
==============
Ansible Playbook for setting up the Nagios monitoring system and clients

**Ansible Bugs**
   - Currently I'm affected by these Ansible bugs which keep some of the
     template-generated configurations from working correctly on Ansible 2.1.0.0-1 (Fedora)
     * [Ansible bug #9260](https://github.com/ansible/ansible/issues/9260)
     * [Ansible bug #15525](https://github.com/ansible/ansible/issues/15525)

**What does it do?**
   - Automated deployment of Nagios on CentOS or RHEL
     * Generates service checks, and hosts from Ansible inventory
     * Wraps Nagios in SSL via Apache
     * Approach was inspired from the official [ansible examples](https://github.com/ansible/ansible-examples)

**Requirements**
   - RHEL7 or CentOS7+ server/client with no modifications
     - Fedora 23 or higher needs to have ```yum python2 python2-dnf libselinux-python``` packages.
       * You can run this against Fedora clients prior to running Ansible ELK:
       - ```ansible fedora-client-01 -u root -m shell -i hosts -a "dnf install yum python2 libsemanage-python python2-dnf -y"```

**Notes**
   - Sets the ```nagiosadmin``` password to ```changeme```, you'll want to change this.
   - Nagios ports default to 80/443 for HTTPD/Nagios, but these are configurable in ```install/group_vars/all.yml```
   - Implementation is very simple, with only the following server types generated right now:
     - out-of-band interfaces (Dell iDRAC, IPMI etc) (ping/ssh)
     - webservers (http check)
     - network switches (ping/ssh)

**Nagios Server Instructions**
   - Clone repo and setup your hosts file
```
git clone https://github.com/sadsfae/ansible-nagios
cd ansible-elk
sed -i 's/host-01/yournagioshost/' hosts
```
   - Run the playbook
```
ansible-playbook -i hosts install/elk.yml
```
   - Navigate to the server at http://yourhost
   - Default login is ```nagiosadmin / changeme```

**TODO**
   - Hope the Ansible bugs above get fixed
   - Write equivalent ```nagios-client``` playbooks for NRPE
