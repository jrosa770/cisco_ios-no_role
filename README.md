# Non Role Cisco IOS Module Based Ansible Playbook

Template for non role based ios, on demmand configuration. Uses Ansible modules for Cisco IOS.

## Folder Structure

```tree
cisco_ios-no_role/
├── backup
│   └── README.md
├── cisco-cli-l2-multi-vlan.yml
├── cisco-cli-l2-multi-vlan_dynamic.yml
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
│   ├── ios_command-multi-vlan-exist-check.yml
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
│   ├── vlan_id.j2
│   ├── vlan-delete.j2
│   ├── vlan-deploy.j2
│   └── vlan-multi.j2
└── vars
    ├── README.md
    ├── vlan.yml
    ├── vlan_id.yml # Created by Playbook Task
    ├── vlans.yml
    └── vlans-multi.yml

# Updated Tree: 9/6/2017
```

> Usage:

```sh
ansible-playbook cisco-cli-push.yml -i hosts
```

> With debug:

```sh
ansible-playbook -vvv cisco-cli-push.yml -i hosts
```

## Options in Playbook and Tasks

### Playbook Options

The playbook can be directed to affect a group in the hosts inventory file or a particular host within a group

Group = ios:

```yml
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

```yml
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

> If SSH Keys are used for authentication you will need to establish where to find the ssh key file under provider

```yml
  tasks:
  - name: define provider
    set_fact:
      provider:
        ssh_keyfile: /path_to_ssh_key_file
```

#### Task Options:

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

#### Workaround for the `ios_command` no template limitation

The IOS module for `ios_config` and `ios_template` have built in provisions for IOS configurations produced via templates. On the other hand `ios_command` module does not contain any provisions for templates only single or multiple commands under the `commands:` instruction. This is due to that `ios_command` is not really intended to be used for configuration changes so in reality is not needed.

Example:

```yml
- name: An ios_command routine
  ios_command:
    commands: show vlan
```

Or:

```yml
- name: An ios_command routine
  ios_command:
    commands:
      - show vlan id 11
      - show vlan id 12
      - show vlan
```

The workaround is a separate task using the `template:` module in Ansible.

Example from: `cisco-cli-l2-multi-vlan_dynamic.yml`

```yml
  - name: create vlan_id.yml file for show vlan id task
    template: 
       src=templates/vlan_id.j2 
       dest=vars/vlan_id.yml
    with_items: "{{ vlans }}"
```

Template `templates/vlan_id.j2`:

```py
show:
{% for key,value in vlans|dictsort %} - sh vlan id {{ value.id }} 
{% endfor %}
```

* Notice that the template includes the space needed for proper syntax

Vars file (`vars\vlans-multi.yml`):

```yml
---
proc: deploy
vlans_add:
 ANSIBLE_TEST_VLAN10: { id: 10, }
 ANSIBLE_TEST_VLAN11: { id: 11, }
vlans: "{{ vlans_add }}"
```

Created file:

```yml
show:
 - sh vlan id 10
 - sh vlan id 11 
```

Task (From: `tasks/ios_command-multi-vlan-exist-check.yml`):

```yml
---
- name: obtain vars
  include_vars: vars/vlan_id.yml

- name: check for vlan "{{ vlans }}"
  ios_command:
    commands: "{{ show }}"
    provider: "{{ provider }}"
  ignore_errors: yes
  register: sh_vlan_output
```

Playbook Debug:

```sh
TASK [create vlan_id.yml file for show vlan id task] ******************************************************************************************************************************************
ok: [ios-swt-1] => (item= ANSIBLE_TEST_VLAN10) => {
    "changed": false,
    "diff": {
        "after": {
            "path": "vars/vlan_id.yml"
        },
        "before": {
            "path": "vars/vlan_id.yml"
        }
    },
    "gid": 197121,
    "group": "None",
    "invocation": {
        "module_args": {
            "attributes": null,
            "backup": null,
            "content": null,
            "delimiter": null,
            "dest": "vars/vlan_id.yml",
            "diff_peek": null,
            "directory_mode": null,
            "follow": true,
            "force": false,
            "group": null,
            "mode": null,
            "original_basename": "vlan_id.j2",
            "owner": null,
            "path": "vars/vlan_id.yml",
            "recurse": false,
            "regexp": null,
            "remote_src": null,
            "selevel": null,
            "serole": null,
            "setype": null,
            "seuser": null,
            "src": null,
            "state": null,
            "unsafe_writes": null,
            "validate": null
        }
    },
    "item": " ANSIBLE_TEST_VLAN10",
    "mode": "0644",
    "owner": "ansible_usr",
    "path": "vars/vlan_id.yml",
    "size": 47,
    "state": "file",
    "uid": 197609
}
ok: [ios-swt-1] => (item=ANSIBLE_TEST_VLAN11) => {
    "changed": false,
    "diff": {
        "after": {
            "path": "vars/vlan_id.yml"
        },
        "before": {
            "path": "vars/vlan_id.yml"
        }
    },
    "gid": 197121,
    "group": "None",
    "invocation": {
        "module_args": {
            "attributes": null,
            "backup": null,
            "content": null,
            "delimiter": null,
            "dest": "vars/vlan_id.yml",
            "diff_peek": null,
            "directory_mode": null,
            "follow": true,
            "force": false,
            "group": null,
            "mode": null,
            "original_basename": "vlan_id.j2",
            "owner": null,
            "path": "vars/vlan_id.yml",
            "recurse": false,
            "regexp": null,
            "remote_src": null,
            "selevel": null,
            "serole": null,
            "setype": null,
            "seuser": null,
            "src": null,
            "state": null,
            "unsafe_writes": null,
            "validate": null
        }
    },
    "item": "ANSIBLE_TEST_VLAN11",
    "mode": "0644",
    "owner": "ansible_usr",
    "path": "vars/vlan_id.yml",
    "size": 47,
    "state": "file",
    "uid": 197609
}
TASK [obtain vars] ****************************************************************************************************************************************************************************
task path: ios-cli-ansible/tasks/ios_command-multi-vlan-exist-check.yml:2
looking for "vars/vlan_id.yml" at "ios-cli-ansible/vars/vlan_id.yml"
ok: [ios-swt-1] => {
    "ansible_facts": {
        "show": [
            "show vlan id 11",
            "show vlan id 12"
        ]
    },
    "changed": false
}
```

