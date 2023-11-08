# Minimal Disk Image
#
# Firewall configuration
firewall --enabled
# Use network installation
url --url="INSTALL_REPO"
# Root password
rootpw --iscrypted ROOT_PWD

# Network information
network  --bootproto=dhcp --onboot=on --activate
# System keyboard
keyboard --xlayouts=us --vckeymap=us
# System language
lang en_US.UTF-8
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info
# Shutdown after installation
shutdown
# System timezone
timezone Asia/Beijing
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="ext4" --size=40000
part swap --size=1000

%pre
#!/bin/bash
mkdir -p /mnt/sysimage/usr/lib64/
chmod 0755 /mnt/sysimage/usr/lib64/
cp /usr/lib64/libbep_env.so /mnt/sysimage/usr/lib64
%end

%post
touch /etc/sysconfig/network

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=dhcp
NAME=eth0
DEVICE=eth0
ONBOOT=yes
EOF

rm -rf /etc/systemd/system/multi-user.target.wants/kbox.service
rm -rf /etc/systemd/system/multi-user.target.wants/kdump.service
rm -rf /usr/lib/systemd/system/kbox.service
rm -rf /usr/lib/systemd/system/kdump.service
rm -rf /boot/initramfs*
rm -rf /usr/share/icons/hicolor/icon-theme.cache
rm -rf /usr/share/icons/Adwaita/icon-theme.cache

#fix shadows and shadows- time field
awk 'BEGIN{FS=OFS=":"} {$3=18099; print $0 > "/etc/shadow"}' /etc/shadow;
awk 'BEGIN{FS=OFS=":"} {$3=18099; print $0 > "/etc/shadow-"}' /etc/shadow-;


#fix /etc/pki/ca-trust/extracted/java/cacerts time field
rm /etc/pki/ca-trust/extracted/java/cacerts
/usr/bin/ca-legacy install
/usr/bin/update-ca-trust


%end

%packages --excludedocs
@core --nodefaults
%end
