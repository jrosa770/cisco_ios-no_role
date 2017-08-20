# Non Role Based Playbook
Template for non role based ios, on demmand configuration. Uses Ansible modules.
> Folder Structure:
```
cisco_ios-no_role/
├── backup
│   └── README.md
├── cisco-cli-push.yml
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
└── tasks
    ├── banner_motd.yml
    ├── configure-interface.yml
    ├── ios_command-freeform.yml
    ├── reload_ios.yml
    ├── runn-backup-save-to-start.yml
    └── set-dns.yml
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
> Playbook
The playbook can be used to affect a group in the hosts inventory file or a particular host within a group
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

If SSH Keys are used for authentication you will need to establish where to find the ssh key file under provider
```yml
  tasks:
  - name: define provider
    set_fact:
      provider:
        ssh_keyfile: /path_to_ssh_key_file
```

> Task Options:
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

Writing a very generic task for `ios_command:`
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

Saving the output to a file
```yml
- name: append to output
# append the command output to a local file
  copy:
    content: "{{ freeform.stdout[0] }}"
    dest: "play_results/{{ inventory_hostname }}.txt"
```

> Ecrypting the `secrets.yml` file
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
`chmod 600 vault_pass.py`

Running Playbook:
```sh
ansible-playbook cisco-cli-push.yml --vault-password-file vault_pass.py - i hosts
```

Editing Encrypted files in vault
```sh
$ansible-vault edit secrets.yml
Vault password: your_secret_password
```
Or
```sh
$ansible-vault edit secrets.yml --vault-password-file vault_pass.py - i hosts
```