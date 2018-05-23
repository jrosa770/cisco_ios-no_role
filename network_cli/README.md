# Ansible 2.5+ Connection via Network_CLI Plugin

It is already documented that the "provider" feature for some of the modules is being deprecated and it is recommended to move playbooks to connection: nework_cli. This brings a complication on how to migrate or how to adapt old playbooks from the "connection: local" plugin with the time-tested and proven "provider" module authentication feature. This may appear a bit difficult or confusing. But as this document will outline it may not be as difficult as it sounds and it will show the benefit of this change within Ansible.

Prior to Ansible 2.5, using networking modules required the connection type to be set to local. A playbook executed the python module locally, and then connected to a networking platform to perform tasks. This but different than how most non-networking Ansible modules functioned. In general, most Ansible modules are executed on compared to being executed locally on the Ansible control node. Although many networking platforms can execute Python code, the vast majority require the CLI or an API as the only means for interacting with the device.

In an effort to help streamline the passing of credentials, network modules support an additional parameter called a provider, first introduced in Ansible 2.3. A network automation playbook would run locally, use an Ansible inventory (just like a normal playbook) but then use the provider on a task-by-task basis to authenticate and connect to each networking platform. This differs from a Linux focused playbook that would initially to devices using credentials in the inventory itself or passed through the command line.

The provider method is functional for networking but is a different paradigm compared to connection methods on Linux hosts. With Ansible 2.5 the network_cli connection method also becomes a connection. This allows playbooks to look, feel and operate just like they do on Linux hosts. Let's show what this means for your playbooks:

Refer to the following example that compares playbooks using the built-in Cisco IOS module (ios_config):

## Ansible 2.4 and Older
```yml
---
- hosts: ios
  connection: local
  gather_facts: no

  vars:
    provider:
      username: admin
      password: ansible

  tasks:
    - name: Backup configuration
      ios_config:
        backup: yes
        provider: "{{ provider }}"
```

## Ansible 2.5+

```yml
---
- hosts: ios
  connection: network_cli
  remote_user: admin
  become: yes
  become_method: enable

  tasks:
    - name: Backup configuration
      ios_config:
        backup: yes
```
Most users myself included do not include clear text authentication credentials in playbooks and keep passing such credential to a bare minimum via command line. The best and most secure practice to pass authentication credential is by using ansible-vault and then taking advantage of a centralized authentication file, in other articles, some of my examples I've used the filename "secrets.yml"

```yml
#secrets.yml
---
creds:
 username: ansible
 password: '@ns1Bl3'
#Uncomment next line 
```

## Ansible 2.4 and Older

```yml
---
- hosts: ios
  gather_facts: no
  connection: local

  tasks:
  - name: obtain login credentials
    include_vars: secrets.yml

  - name: define provider
    set_fact:
      provider:
        host: "{{ inventory_hostname }}"
        username: "{{ creds['username'] }}"
        password: "{{ creds['password'] }}"#Uncomment next line if enable password is needed#auth_pass: "{{ creds['auth_pass'] }}"
        transport: cli

  - name: IOS Interface Configuration
    ios_config:
    provider: "{{ provider }}"
    lines:
      - description VLAN200_ACCESS
      - switchport access vlan 200
      - switchport mode access
    parents: interface GigabitEthernet1/0/1
```

## Now the same on for Ansible 2.5+ using the network_cli plugin

```yml
---
- hosts: ios
  gather_facts: yes
  connection: network_cli
  become: yes
  become_method: enable
  ignore_errors: yes

  tasks:
  - name: obtain login credentials
    include_vars: secrets.yml

  - name: Set Username and Password
    set_fact:
      remote_user: "{{ creds['username'] }}"
      ansible_ssh_pass: "{{ creds['password'] }}"

  - name: IOS Interface Configuration
    ios_config:
    lines:
      - description VLAN200_ACCESS
      - switchport access vlan 200
      - switchport mode access
    parents: interface GigabitEthernet1/0/1
```

If other user accounts are needed and already added to the "secrets.yml" file:
```yml
#secrets.yml
---
creds:
 username: ansible
 password: '@ns1Bl3'
#Uncomment next line for enable (leave single space):
# auth_pass: 3n@bl3

alt_creds:
 username: ansible_alt
 password: '@ns1Bl3_@Lt'
#Uncomment next line for enable (leave single space):
# auth_pass: 3n@bl3


#playbook.yml
---
- hosts: ios
  gather_facts: yes
  connection: network_cli
  become: yes
  become_method: enable
  ignore_errors: yes

  vars:
    authentication_provider: normal

  tasks:
  - name: obtain login credentials
    include_vars: secrets.yml

  - name: Set Primary Username and Password
    set_fact:
      remote_user: "{{ creds['username'] }}"
      ansible_ssh_pass: "{{ creds['password'] }}"
    when: authentication_provider == "normal"

  - name: Set Alternate Username and Password
    set_fact:
      remote_user: "{{ alt_creds['username'] }}"
      ansible_ssh_pass: "{{ alt_creds['password'] }}"
    when: authentication_provider == "alternate"
```
This should help to migrate your pre 2.5 Ansible playbooks and overcome the upcoming deprecation of the provider module authentication.