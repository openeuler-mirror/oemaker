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
part / --fstype="ext4" --size=15000
part swap --size=1000
%pre
#!/bin/bash
mkdir -p /mnt/sysimage/usr/lib64/
chmod 0755 /mnt/sysimage/usr/lib64/
cp /usr/lib64/libbep_env.so /mnt/sysimage/usr/lib64
%end
%post
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
useradd -m devstation
usermod -aG wheel devstation
echo "devstation ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "devstation" | passwd --stdin devstation
passwd -d devstation
passwd -d root

if ! grep -q "\[daemon\]" /etc/gdm/custom.conf; then
    echo "[daemon]" >> /etc/gdm/custom.conf
fi

sed -i "/\[daemon\]/a AutomaticLoginEnable=true" /etc/gdm/custom.conf
sed -i "/\[daemon\]/a AutomaticLogin=devstation" /etc/gdm/custom.conf

echo "devstation ALL=(ALL) NOPASSWD: /usr/bin/nautilus" >> /etc/sudoers
touch /etc/polkit-1/rules.d/50-nautilus.rules
cat << EOR > /etc/polkit-1/rules.d/50-nautilus.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("action_id") == "org.gnome.nautilus.file-manager" &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOR

cp /usr/share/applications/calamares.desktop /etc/xdg/autostart/

systemctl enable gdm
systemctl set-default graphical.target

systemctl enable calamares

su - devstation -c gsettings set org.gnome.desktop.input-sources sources "[(xkb, us), (ibus, libpinyin)]"

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

#fix shadows and shadows- time field
awk 'BEGIN{FS=OFS=":"} {$3=18099; print $0 > "/etc/shadow"}' /etc/shadow;
awk 'BEGIN{FS=OFS=":"} {$3=18099; print $0 > "/etc/shadow-"}' /etc/shadow-;

#fix /etc/pki/ca-trust/extracted/java/cacerts time field
rm /etc/pki/ca-trust/extracted/java/cacerts
/usr/bin/ca-legacy install
/usr/bin/update-ca-trust


%end

%packages --excludedocs
%end
