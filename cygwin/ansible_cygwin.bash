#!/usr/bin/bash
#
DateTimeStamp=$(date '+%m-%d-%y_%H:%M:%S')
# INSTALL
install_ansible="pip install ansible"
install_ansible_play="pip install ansible-toolset ansible-toolkit ansible-lint"
#
# UPGRADE
upgrade_ansible_play="pip install --ignore-installed --upgrade ansible"
upgrade_ansible="pip install --ignore-installed --upgrade ansible-toolset ansible-toolkit ansible-lint ansible-vault"
#
# PROCESS
echo "This Script will install or upgrade you Cygwin Ansible installation"
#
echo -n "Install Ansible(i) or Upgrade Current Installation (u): "
read iu
#
if [ "$iu" == "i" ]; then
    echo "Installing Ansible..."
    $install_ansible
    echo "Adding the ansible.cfg file into /etc/ansible folder"
touch /etc/ansible/ansible.cfg
echo "[defaults]" >> /etc/ansible/ansible.cfg
echo "library        = /usr/lib/python2.7/site-packages/ansible/modules" >> /etc/ansible/ansible.cfg
echo "inventory      = /etc/ansible/hosts" >> /etc/ansible/ansible.cfg
echo "remote_tmp     = $HOME/.ansible/tmp" >> /etc/ansible/ansible.cfg
echo "forks          = 5" >> /etc/ansible/ansible.cfg
echo "private_key_file = $HOME/.ssh/known_hosts" >> /etc/ansible/ansible.cfg
echo "host_key_checking = False" >> /etc/ansible/ansible.cfg
echo "host_key_auto_add = True" >> /etc/ansible/ansible.cfg
echo "ssh_args = -o ControlMaster=auto -o ControlPersist=60s" >> /etc/ansible/ansible.cfg
echo "become=True" >> /etc/ansible/ansible.cfg
echo "become_method=su" >> /etc/ansible/ansible.cfg
echo "# become_user=root" >> /etc/ansible/ansible.cfg
echo "become_ask_pass=False" >> /etc/ansible/ansible.cfg
echo "pipelining = True" >> /etc/ansible/ansible.cfg
    #
    read -p "Continuing in 5 Seconds...." -t 5
    echo "Continuing ...."
    echo "Installing Ansible Playbook dependencies..."
    $install_ansible_play
    echo "Installation Completed on "$DateTimeStamp
elif [ "$iu" == "u" ]; then
    echo "Upgrading Ansible..."
    $upgrade_ansible
    #
    read -p "Continuing in 5 Seconds...." -t 5
    echo "Continuing ...."
    echo "Upgrading Ansible Playbook dependencies..."
    $upgrade_ansible_play
    echo -n "Upgrade Completed on "$DateTimeStamp
fi
# eof
