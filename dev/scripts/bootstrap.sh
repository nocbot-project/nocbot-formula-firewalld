#!/bin/bash

# salt-master has needs
# salt-minion has needs

if [[ -n ${SALT_ENV} ]]; then
    environment=${SALT_ENV}
else
    environment="devmode"
fi

dnf install -y epel-release
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

dnf install -y https://repo.saltstack.com/py3/redhat/salt-py3-repo-latest.el8.noarch.rpm
rpm --import /etc/pki/rpm-gpg/saltstack-signing-key

dnf clean all

export PATH="$PATH:/root/bin"

# We need to remove all traces of salt-minion to setup testing
# needrestart throws ugly warnings in the terminal so remove it for testing
if command -v salt-minion >/dev/null 2>&1; then
    dnf -q remove -y salt-minion
fi

rm -rf /etc/salt
rm -rf /var/log/salt
rm -rf /var/cache/salt

# Start Salt Master configuration
if [[ $(hostname -s) == 'salt' ]]; then
    chmod 700 /root/bin/salt-master.sh
    /root/bin/salt-master.sh
fi

mkdir -p /etc/salt/minion.d

echo "saltenv: $environment" > /etc/salt/minion.d/saltenv.conf
echo "master: salt.$(hostname -d)" > /etc/salt/minion.d/master.conf
echo "id: $(hostname -s)" > /etc/salt/minion.d/id.conf

/bin/cat > /etc/salt/minion.d/schedule.conf << SCHEDULE
schedule:
  highstate:
    function: state.highstate
    minutes: 15
SCHEDULE

# cronjob to run salt-minion approximately every 10 to 15 minutes
# Keep here in case schedule.conf gets messed up for some reason
/bin/cat > /etc/cron.d/minion-highstate << 'HIGHSTATE'
# SHELL=/bin/bash
# PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# MAILTO=root
# HOME=/
# # Call a highstate randomly, between 10 and 15 minutes.
# */10 * * * * root sleep $(((${RANDOM} \%4) +1)); /usr/bin/salt-call state.highstate > /dev/null 2>&1
HIGHSTATE

echo "startup_states: highstate" > /etc/salt/minion.d/startup_states.conf

dnf upgrade -y
dnf install -y salt-minion python3-tornado

/bin/cat > /usr/local/bin/hs << HS
#!/bin/bash

salt-call state.highstate
HS

chmod 770 /usr/local/bin/hs
sleep 5
systemctl restart salt-minion
