#!/bin/sh

set -e

function ssh_keys_to_user(){
  SSH_USER="$1"
  MYHOME="$2"
  SSH_KEY="$3"
  echo "=> Adding SSH key to ${MYHOME}"
  mkdir -p ${MYHOME}/.ssh
  chmod go-rwx ${MYHOME}/.ssh
  echo "${SSH_KEY}" > ${MYHOME}/.ssh/authorized_keys
  echo "${SSH_KEY}"
  chmod go-rw ${MYHOME}/.ssh/authorized_keys
  echo "=> Done!"
  chown -R $SSH_USER:$SSH_USER /${MYHOME}/.ssh
}


if [ -z "$ROOT_PASSWORD" ]; then 
  echo "You must modify the root password"
  exit 1
fi

echo root:$ROOT_PASSWORD | chpasswd

if [ -z "$SSH_USER" ] && [ -z "$SSH_PASSWORD" ]; then 
  echo "Define a new user and password for access"
  exit 1
fi

#Creo el nuevo usuario
adduser "$SSH_USER" -D -s /bin/ash
echo $SSH_USER:$SSH_PASSWORD | chpasswd
chown root:$SSH_USER /home/$SSH_USER
chmod 750 /home/$SSH_USER

mkdir -p /home/$SSH_USER/public
chown $SSH_USER: /home/$SSH_USER/public
chmod 750 /home/$SSH_USER/public

echo "Subsystem       sftp    internal-sftp

Match User $SSH_USER
    ChrootDirectory %h
    AllowTCPForwarding no
    X11Forwarding no
    ForceCommand internal-sftp ">> /etc/ssh/sshd_config
#Match User $SSH_USER

if [ -z "${SSH_ROOT_KEY}" ]; then
	echo "=> Please pass your public key for ROOT in the SSH_ROOT_KEY environment variable"
	exit 1
fi

if [ ! -z "$SSH_USER_KEY" ]; then
  ssh_keys_to_user $SSH_USER "/home/$SSH_USER" "$SSH_USER_KEY"   #===> Acceso para el usuario creado
fi

ssh_keys_to_user "root" "/root" "$SSH_ROOT_KEY"   #===> Acceso como root


echo "========================================================================"
echo "You can now connect to this container via SSH using:"
echo ""
echo "    ssh -p <port> <user>@<host>"
echo ""
echo "Choose root (full access) or  (limited user account) as <$SSH_USER>."
echo "========================================================================"

exec /usr/sbin/sshd -D
