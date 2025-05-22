#!/bin/bash

if [[ $(whoami) != 'root' ]]; then
  echo "Please run this script as root (or with sudo)."
  exit 1
fi

echo "Deleting all user non-root ..."

# Ambil daftar user dengan UID >= 1000, kecuali nobody dan root
users=$(awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "root" {print $1}' /etc/passwd)

for user in $users; do
    echo "Deleting user: $user"
    userdel -r "$user"
    if [[ $? -eq 0 ]]; then
        echo "Success to delete $user"
    else
        echo "Failed to delete $user"
    fi
done

echo "Finish. Only root user left."

read -p "New Password For Root [or press Enter to generate a random password]: " newpass
if [[ -z "${newpass}" ]]; then
  newpass=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
  echo "No password entered. A random password has been generated."
fi

rm -rf /etc/ssh/*
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
UsePAM yes
UseDNS no
TCPKeepAlive yes
X11Forwarding yes
PermitRootLogin yes
PrintMotd no
AcceptEnv LANG LC_*
ChallengeResponseAuthentication no
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
ssh-keygen -A
systemctl restart ssh  &> /dev/null
systemctl restart sshd &> /dev/null
echo "root:${newpass}" | chpasswd
clear
echo "Root password successfully updated."
echo "==================================="
echo "  New Root Password: ${newpass}"
echo "===================================" w
