if [[ $UID != 0 ]]; then
	echo "root privileges required. Insert password..."
	sudo "$0" "$@"
fi

cd /etc/yum.repos.d
wget https://copr.fedorainfracloud.org/coprs/macieks/openresolv/repo/epel-7/macieks-openresolv-epel-7.repo
rpm --import https://copr-be.cloud.fedoraproject.org/results/macieks/openresolv/pubkey.gpg
yum update -y
yum install openresolv -y

cd /etc/openvpn
wget https://raw.githubusercontent.com/masterkorp/openvpn-update-resolv-conf/master/update-resolv-conf.sh
mv update-resolv-conf.sh update-resolv-conf
chmod +x /etc/openvpn/update-resolv-conf

if [[ "$1" = "-update-conf" && ! -z "$2" ]]; then
  cd "$2"
  for f in `ls | grep ovpn`; do
    echo "script-security 2" >> $f;
    echo "up /etc/openvpn/update-resolv-conf" >> $f;
    echo "down /etc/openvpn/update-resolv-conf" >> $f;
	done
fi
sudo systemctl enable --now systemd-resolved
