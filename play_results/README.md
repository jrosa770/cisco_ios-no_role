# Playbook stdout Folder

For playbooks like freeform where outputs aree redirected to a file.

```yml
- name: append to output
# append the command output to a local file
  copy:
    content: "{{ freeform.stdout[0] }}"
    dest: "play_results/{{ inventory_hostname }}.txt"
```