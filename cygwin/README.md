# Cygwin Installation
In the case that a Linux and/ or Unix is not available Ansible can be run from Cygwin.

Cygwin is available at https://cygwin.com/install.html

The bash file ansible_cygwin will install Ansible in Cygwin64 and the components needed for the playbooks to run.

It will also a basic `ansible.cfg`. 

Requires Python 2.7 and PIP

You can install Python and pip, when setting up Cygwin for the first time, after install using the setup.exe or via apt-cyg (https://github.com/transcode-open/apt-cyg).
