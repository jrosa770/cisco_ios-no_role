# Non Role Based Playbook
Template for non role based ios, on demmand configuration. Uses Ansible modules.
#### Folder Structure:
```
cisco_ios-no_role/
├── backup
│   └── README.md
├── cisco-cli-l2-multi-vlan.yml
├── cisco-cli-multi-vlan-delete.yml
├── cisco-cli-multi-vlan-deploy.yml
├── cisco-cli-push.yml
├── cisco-cli-vlan-delete.yml
├── cisco-cli-vlan-deploy.yml
├── config_partial
│   └── raw_banner.cfg
├── cygwin
│   ├── ansible_cygwin.bash
│   └── README.md
├── hosts
├── play_results
│   └── README.md
├── README.md
├── secrets.yml
├── tasks
│   ├── ios_banner-motd.yml
│   ├── ios_command-reload_ios.yml
│   ├── ios_command-runn-backup-save-to-start.yml
│   ├── ios_command-vlan-exist-check.yml
│   ├── ios_config-interface.yml
│   ├── ios_config-l2-multi-vlan.yml
│   ├── ios_config-multi-vlan-delete.yml
│   ├── ios_config-multi-vlan-deploy.yml
│   ├── ios_config-set-dns.yml
│   ├── ios_config-vlan-delete.yml
│   ├── ios_config-vlan-deploy.yml
│   ├── ios_config-vlan-exist-check.yml
│   └── ios_freeform.yml
├── templates
│   ├── README.md
│   ├── vlan-delete.j2
│   ├── vlan-deploy.j2
│   └── vlan-multi.j2
└── vars
    ├── README.md
    ├── vlan.yml
    ├── vlans.yml
    └── vlans-multi.yml
```

> Usage:
```
ansible-playbook cisco-cli-push.yml -i hosts
```

> With debug:
```
ansible-playbook -vvv cisco-cli-push.yml -i hosts
```

## Options in Playbook and Tasks

##### Playbook Options

The playbook can be directed to affect a group in the hosts inventory file or a particular host within a group
Group = ios 
```
# File: hosts
[ios]
ios-swt-1
ios-rtr-1
```
```yml
---
- hosts: ios
  gather_facts: no
  connection: local
```

The playbook will run the task on `ios-swt-1` and `ios-rtr-1`

For a particular host within the inventory file, in this case `ios-swt-1`:
```yml
---
- hosts: ios-swt-1
  gather_facts: no
  connection: local
```

> More on hosts inventory file structure

```
[ios-rtr]
ios-rtr-1

[ios-swt]
ios-swt-1

[ios:children]
ios-rtr
ios-swt

[ios:vars]
ansible_python_interpreter=/usr/bin/python
ansible_connection = local
# If SSH/ For Telnet - Port=23
port=22
```

```yml
---
- hosts: ios
  gather_facts: no
  connection: local
```

The playbook will run the task on groups `[ios-swt]` and `[ios-rtr]`


If SSH Keys are used for authentication you will need to establish where to find the ssh key file under provider
```yml
  tasks:
  - name: define provider
    set_fact:
      provider:
        ssh_keyfile: /path_to_ssh_key_file
```

##### Task Options:
```yml
- name: An IOS Configuration Task
  ios_config:
    provider: "{{ provider }}"
    # "authorize: [yes | no ]" Instructs the module to enter privileged mode on the remote device before sending any commands. 
    # Mainly If enable password (auth_pass:) is used in secret.yml
    authorize: yes
    lines:
      - [configuration line]
    # "backup: [yes | no] " Makes a backup of the running configuration to the playbook's folder (backup/)
    backup: yes
    # "save: [yes | no]" Saves running Configuration
    save: yes 
```

> Writing a very generic task for `ios_command:`

```yml
---
- name: Freeform Task
  ios_command:
    provider: "{{ provider }}"
    commands:
# Change the command after "-" to any IOS command you would like to run.
      - show version
  register: freeform

# Provides an output if -vvv is not used when running ansible-playbook
- debug: var=freeform.stdout_lines
```

> Saving the output to a file

```yml
- name: append to output
# append the command output to a local file
  copy:
    content: "{{ freeform.stdout[0] }}"
    dest: "play_results/{{ inventory_hostname }}.txt"
```

#### Ecrypting the `secrets.yml` file

```yml
$ansible-vault encrypt secrets.yml
New Vault password: your_secret_password
Confirm New Vault password: your_secret_password
```

> Running the Playbook with encrypted `secrets.yml`

Password Prompted:

```sh
ansible-playbook cisco-cli-push.yml --ask-vault-pass -i hosts
```

No password prompt:

Create a file containing the vault password (vault_pass.py or anything else) and lock down permissions

`$chmod 600 vault_pass.py`

Running Playbook with vault password file:

```sh
ansible-playbook cisco-cli-push.yml --vault-password-file vault_pass.py - i hosts
```

> Editing Encrypted files in vault

```sh
$ansible-vault edit secrets.yml
Vault password: your_secret_password
```
Or
```sh
$ansible-vault edit secrets.yml --vault-password-file vault_pass.py - i hosts
```
