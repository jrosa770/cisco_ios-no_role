# My All in One Device Specific YAML File for Ansible

When I started with Ansible my tendency was to use a lot of one-time use device .yml files for tasks. As I started centralizing my playbooks I began to explore on how to centralized and multiuse device specific variable files. What I came up with was a file that in a way mirror the device is intended to affect during Ansible plays. While at the end of the play have the playbook change status of the file itself, so it could be ready and re-used again with the same or other playbooks. In effect making this in practice a multiuse, dynamic template.

Now for this example, we have are going to make the following assumptions:

    1. The device is an 8 port 2900 IOS switch.
    2. The FQDN name for the devices is example-sw-01.example.com. With an alias example-sw-01
    3. The name of the file will match the alias: example-sw-01.yml
    4. The hostname in the ansible inventory example-sw-01 so it matches the {{inventory_hostname }}.yml call in the playbook

The file will look like this:

```yml
system:
  - device_name: example-sw-01
    location_domain_name: example.com
    location: "1 Street Example USA"
    type: switch
    hardware: 2900
    device_os: ios
    ios_update: no
    ios_admin:
      admin_if: 2
      ipv4: 10.2.2.2
      mask: 255.255.255.0
      gw: 10.2.2.254

 Templates
# == Access ==
#  - name: interface [Type][module]/[instance]/[port]
#    vlan: [vlan Number]
#    if_type: access
#    channel_group: [number] # IF PART of PORT CHANNEL
#    current: [modify] # Change | [keep] # leave untouched | [absent] # decommision or delete | [ignore] #Self Explanatory

# == Trunk ==
#  - name: interface [Type][module]/[instance]/[port]
#    vlan: [native vlan] or 1
#    trunk_allowed: '[vlan range]' or all
#    if_type: trunk
#    channel_group: [number] # IF PART of PORT CHANNEL
#    current: [modify] # Change | [keep] # leave untouched | [absent] # decommision or delete | [ignore] #Self Explanatory

interfaces:
  - name: 'interface GigabitEthernet1/0/1'
    vlan: 2
    trunk_allowed: all
    if_type: trunk
    current:keep

  - name: 'interface GigabitEthernet1/0/2'
    vlan: 10
    if_type: access
    voip: enabled
    voip_vlan: 100
    current: keep

  - name: 'interface GigabitEthernet1/0/3'
    vlan: 10
    if_type: access
    voip: enabled
    voip_vlan: 100
    current: keep

  - name: 'interface GigabitEthernet1/0/4'
    vlan: 10
    if_type: access
    voip: enabled
    voip_vlan: 100
    current: keep

  - name: 'interface GigabitEthernet1/0/5'
    vlan: 10
    if_type: access
    voip: enabled
    voip_vlan: 100
    current: keep

  - name: 'interface GigabitEthernet1/0/6'
    vlan: 10
    if_type: access
    voip: disabled
    voip_vlan: 100
    current: keep

  - name: 'interface GigabitEthernet1/0/7'
    vlan: 20
    if_type: access
    voip: enabled
    voip_vlan: 200
    current: modify

  - name: 'interface GigabitEthernet1/0/8'
    vlan: 20
    if_type: access
    voip: disabled
    voip_vlan: 200
    current: modify
```

As seen in the example above the main purpose is to recreate the device into a file. But what makes it the most useful is the "current" variable, as it is the variable that will tell the playbook if the interface will change, or kept as-is.

The possible values for the "current" variable are:

    * [modify] # Change
    * [keep] # Leave untouched
    * [absent] # or delete
    * [ignore] # Self Explanatory

Now let's see the playbook:

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
    include: secrets.yml

# This task will call the file example-sw-01.yml
  - name: obtain hardware vars for {{ inventory_hostname }}
    include_vars: my_device_files/{{ inventory_hostname }}.yml

# This task will clear the interface configuration if "current" 
# is set to modify
  - name: Clear IOS Interface Configuration for {{inventory_hostname}}
    ios_config:
      lines:
        - default {{item.name}}
      match: none
      save_when: changed
    with_items: "{{ interfaces }}"
    when: item.current == "modify"

# This task will configure a data vlan if "current" 
# is set to modify
  - name: IOS Switchport Access Interface Configuration for {{inventory_hostname}}
    ios_config:
      lines:
        - switchport access vlan {{item.vlan}}
        - switchport mode access
        - spanning-tree portfast
      parents: "{{item.name}}"
      match: none
      save_when: changed
    with_items: "{{ interfaces }}"
    when: (item.current == "modify") and
          (item.if_type == "access") and
          (item.voip == "disabled")
  
# This task will configure a data and voice vlan if "current" is set to modify
  - name: IOS Switchport Access with VoIP Interface Configuration for {{inventory_hostname}}
    ios_config:
      lines:
        - switchport access vlan {{item.vlan}}
        - switchport mode access
        - switchport voice vlan {{item.voip_vlan}}
        - spanning-tree bpduguard enable
        - spanning-tree guard loop
        - spanning-tree portfast
      parents: "{{item.name}}"
      match: none
      save_when: changed
    with_items: "{{ interfaces }}"
    when: (item.current == "modify") and
          (item.if_type == "access") and
          (item.voip == "enabled")


# This task will configure then interface as a trunk if "current" 
# is set to modify
  - name: IOS Switchport Data Only Access Interface Configuration for {{inventory_hostname}}
    ios_config:
      lines:
        - switchport trunk native vlan {{item.vlan}}
        - switchport trunk allowed vlan {{item.trunk_allowed}}
        - switchport mode trunk
      parents: "{{item.name}}"
      match: none
      save_when: changed
    with_items: "{{ interfaces }}"
    when: (item.current == "modify") and
          (item.if_type == "trunk")

# This task will set "current" from modify back to keep. 
# in order to return the section of the file to its original state
# thus mirroring the new state of the device
  - name: Change current value fom modify to keep in host variable file
    replace:
      path: my_device_files/{{ inventory_hostname }}.yml
      regexp: 'current: modify'
      replace: 'current: keep'
      after: 'interfaces:'
```
The command to call the playbook and file:
```
user@ansible:~$ ansible-playbook playbook.yml -l example-sw-01
```
With the example- -01.yml, the playbook will produce the following changes:

    * Clear the configurations of interface GigabitEthernet1/0/7 and interface GigabitEthernet1/0/8
    * Set interface GigabitEthernet1/0/7 to data 20 and voice 200
    * Set interface GigabitEthernet1/0/8 to data 20
    * Set all current: modify to current: keep in the "example- -01.yml" file