#!/bin/bash

if [[ -n ${SALT_ENV} ]]; then
    environment=${SALT_ENV}
else
    environment="devmode"
fi

export PATH="$PATH:/root/bin"

mkdir -p /etc/salt/master.d

echo 'autosign_file: /etc/salt/autosign.conf' > /etc/salt/master.d/autosign.conf

cat > /etc/salt/autosign.conf << AUTOSIGN_CONF
salt
minion-*
AUTOSIGN_CONF

/bin/cat > /etc/salt/master.d/pillar_engine.conf << ENGINE_CONF
master_tops:
  saltclass:
    path: /srv/saltclass

ext_pillar:
  - saltclass:
    - path: /srv/saltclass
ENGINE_CONF

if [[ $environment == devmode ]]; then
/bin/cat > /etc/salt/master.d/fileserver.conf << FILESERVER
fileserver_backend:
  - roots
  - gitfs

gitfs_provider: gitpython

gitfs_ref_types:
  - tag
  - branch

file_roots:
  devmode:
    - /srv/formulas/nocbot-formula-firewalld
    - /srv/formulas/nocbot-formula-firewalld
    - /srv/formulas/nocbot-formula-salt

gitfs_base: salt

FILESERVER

else

/bin/cat > /etc/salt/master.d/fileserver.conf << FILESERVER
fileserver_backend:
  - roots
  - gitfs

gitfs_provider: gitpython

gitfs_ref_types:
  - tag
  - branch

gitfs_base: salt

gitfs_remotes:
  - https://github.com/nocbot-project/nocbot-formula-salt.git:
    - root: salt
    - mountpoint: salt://salt
    - saltenv:
        - $environment
$(
        if [[ $environment == production ]]; then
          echo "          - ref: master"
        else
          echo "          - ref: $environment"
        fi
)
FILESERVER
fi

dnf install -y git python3-GitPython salt-master

systemctl enable salt-master
systemctl restart salt-master
