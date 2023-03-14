%ifarch aarch64
%global efi_aa64 1
%endif

%ifarch x86_64
%global efi_x64 1
%endif

%ifarch loongarch64
%global efi_loongarch64 1
%endif
Name:           oemaker
Summary:        a duilding tool for DVD ISO making and ISO cutting
License:        Mulan PSL v2
Group:          System/Management
Version:        2.0.3
Release:        18
BuildRoot:      %{_tmppath}/%{name}

Source:         https://gitee.com/openeuler/oemaker/repository/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Source1:        normal_aarch64.xml
Source2:        normal_x86_64.xml
Source3:        rpmlist.xml
Source4:        edge_normal_aarch64.xml
Source5:        edge_normal_x86_64.xml
Source6:	rpmlist_loongarch64.xml

Requires:       createrepo dnf-plugins-core genisoimage isomd5sum grep bash libselinux-utils libxml2
Requires:       lorax >= 19.6.78-1

Patch0001:	0001-rename-source-iso.patch
Patch0002:	0002-bugfix-I3QY98.patch
Patch0003:	0003-change-for-edge-computing.patch
Patch0004:	0004-bugfix-I3OGUT.patch
Patch0005:	0005-add-fpi_tail-param-for-grub.patch
Patch0006:	0006-support-usb-flash-drive-mode.patch
Patch0007:	0007-restore-env-after-selinux-status-changes.patch
Patch0008:	0008-add-parse_everything_deb_exclude.patch
Patch0009:	0009-automated-kickstart-function.patch
Patch0010:	0010-multipath-service-enable.patch
%ifarch loongarch64
Patch0100:	0001-add-loongarch-support-for-oemaker.patch
Patch0101:	0002-add-config-for-loongarch.patch
Patch0102:	0003-add-loongarch64-support-for-runtime-install.patch
Patch0103:	0004-add-loongarch64-support-for-normal.xml.patch
Patch0104:	0005-add-BOOTLOONGARCH.EFI-for-loongarch64.patch
%endif

%description
a building tool for DVD ISO making and ISO cutting

%package -n isocut
Summary: a building tool for ISO cutting
Requires: yum dnf-utils createrepo file util-linux genisoimage isomd5sum grep bash libselinux-utils libxml2
BuildRequires: bash

%description -n isocut
a building tool for ISO cutting

%prep
%setup -c
rm -rf %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/aarch64/normal.xml
cp %{SOURCE1} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/aarch64/normal.xml
rm -rf  %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/x86_64/normal.xml
cp %{SOURCE2} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/x86_64/normal.xml
rm -rf %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/rpmlist.xml
cp %{SOURCE3} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/rpmlist.xml
rm -rf %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/aarch64/edge_normal.xml
cp %{SOURCE4} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/aarch64/edge_normal.xml
rm -rf  %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/x86_64/edge_normal.xml
cp %{SOURCE5} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/x86_64/edge_normal.xml
cd %{_builddir}/%{name}-%{version}/%{name}
%ifarch loongarch64
rm -rf %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/rpmlist.xml
cp %{SOURCE6} %{_builddir}/%{name}-%{version}/%{name}/isomaker/config/rpmlist.xml
%endif
%autopatch -p1

%install
mkdir -p %{buildroot}/opt/
mkdir -p %{buildroot}/opt/oemaker
mkdir -p %{buildroot}/opt/oemaker/config
mkdir -p %{buildroot}/opt/oemaker/config/x86_64
mkdir -p %{buildroot}/opt/oemaker/config/aarch64
%ifarch loongarch64
mkdir -p %{buildroot}/opt/oemaker/config/loongarch64
%endif
mkdir -p %{buildroot}/opt/oemaker/docs
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/%{_sysconfdir}/isocut
chmod 750 %{buildroot}/%{_sysconfdir}/isocut

install -m 700 %{name}/isomaker/oemaker.sh %{buildroot}/opt/oemaker/oemaker.sh
install -m 700 %{name}/isomaker/oemaker.sh %{buildroot}/%{_bindir}/oemaker
install -m 700 %{name}/isomaker/make_debug.sh %{buildroot}/opt/oemaker/make_debug.sh
install -m 700 %{name}/isomaker/img_repo.sh %{buildroot}/opt/oemaker/img_repo.sh
install -m 700 %{name}/isomaker/init.sh %{buildroot}/opt/oemaker/init.sh
install -m 700 %{name}/isomaker/iso.sh %{buildroot}/opt/oemaker/iso.sh
install -m 700 %{name}/isomaker/rpm.sh %{buildroot}/opt/oemaker/rpm.sh
install -m 700 %{name}/isomaker/env_record.sh %{buildroot}/opt/oemaker/env_record.sh
install -m 700 %{name}/isomaker/env_restore.sh %{buildroot}/opt/oemaker/env_restore.sh
install -m 400 %{name}/isomaker/config/rpmlist.xml %{buildroot}/opt/oemaker/config/rpmlist.xml
install -m 400 %{name}/isomaker/config/x86_64/* %{buildroot}/opt/oemaker/config/x86_64/
install -m 400 %{name}/isomaker/config/aarch64/* %{buildroot}/opt/oemaker/config/aarch64/
%ifarch loongarch64
install -m 400 %{name}/isomaker/config/loongarch64/* %{buildroot}/opt/oemaker/config/loongarch64/
%endif
install -m 700 %{name}/isomaker/docs/* %{buildroot}/opt/oemaker/docs/
cp -a %{name}/isomaker/80-openeuler %{buildroot}/opt/oemaker/


install -m 550 %{name}/isocut/isocut.py %{buildroot}/%{_bindir}/isocut
install -m 600 %{name}/isocut/config/repodata.template %{buildroot}/%{_sysconfdir}/isocut/

%if 0%{?efi_aa64}
    install -m 600 %{name}/isocut/config/aarch64/rpmlist %{buildroot}/%{_sysconfdir}/isocut/
    install -m 600 %{name}/isocut/config/aarch64/anaconda-ks.cfg %{buildroot}/%{_sysconfdir}/isocut/
%endif

%if 0%{?efi_x64}
    install -m 600 %{name}/isocut/config/x86_64/rpmlist %{buildroot}/%{_sysconfdir}/isocut/
    install -m 600 %{name}/isocut/config/x86_64/anaconda-ks.cfg %{buildroot}/%{_sysconfdir}/isocut/
%endif

%if 0%{?efi_loongarch64}
    install -m 600 %{name}/isocut/config/loongarch64/rpmlist %{buildroot}/%{_sysconfdir}/isocut/
    install -m 600 %{name}/isocut/config/loongarch64/anaconda-ks.cfg %{buildroot}/%{_sysconfdir}/isocut/
%endif
%pre

%post

%preun

%postun

%postun -n isocut
if [ "$1" = "0" ]; then
  rm -rf %{_sysconfdir}/isocut/*
fi

%files
%defattr(-,root,root)
%dir /opt
%dir /opt/oemaker
/opt/oemaker/*
%{_bindir}/oemaker

%files -n isocut
%defattr(-,root,root)
%config(noreplace) %attr(0600,root,root) %{_sysconfdir}/isocut/repodata.template
%config(noreplace) %attr(0600,root,root) %{_sysconfdir}/isocut/rpmlist
%config(noreplace) %attr(0600,root,root) %{_sysconfdir}/isocut/anaconda-ks.cfg
%{_bindir}/isocut
%dir %{_sysconfdir}/isocut
%{_sysconfdir}/isocut/*


%clean
rm -rf $RPM_BUILD_ROOT/*
rm -rf %{buildroot}
rm -rf $RPM_BUILD_DIR/%{name}

%changelog
* Tue Mar 14 2023 Wenlong Zhang <zhangwenlong@loongson.cn> - 2.0.3-18
- ID:NA
- SUG:NA
- DESC: Adjust the list of packages for loongarch

* Mon Feb 13 2023 sunhai <sunhai@huawei.com> - 2.0.3-17
- ID:NA
- SUG:NA
- DESC: enable multipath service

* Thu Dec 15 2022 wangkai <wangkai385@h-partners.com> - 2.0.3-16
- ID:NA
- SUG:NA
- DESC: Remove package openEuler-performance

* Mon Mar 28 2022 Wenlong Zhang <zhangwenlong@loongson.cn> - 2.0.3-15
- ID:NA
- SUG:NA
- DESC: add loongarch support for oemaker
        add config for loongarch
        delete pkg when build runtime and iso for loongarch

* Wed Apr 20 2022 xiangyuning <xiangyuning@huawei.com> - 2.0.3-14
- ID:NA
- SUG:NA
- DESC: restore the automated kickstart function

* Thu Mar 31 2022 zhouwenpei <zhouwenpei1@h-partners.com> - 2.0.3-13
- ID:NA
- SUG:NA
- DESC: add linux-firmware subpackage

* Mon Mar 28 2022 Senlin <xiasenlin1@huawei.com> - 2.0.3-12
- ID:NA
- SUG:NA
- DESC: add exclude list for everything

* Mon Mar 7 2022 xiangyuning <xiangyuning@huawei.com> - 2.0.3-11
- ID:NA
- SUG:NA
- DESC: modify restore env mode

* Fri Mar 4 2022 xiangyuning <xiangyuning@huawei.com> - 2.0.3-10
- ID:NA
- SUG:NA
- DESC: lorax cmd add printed log

* Fri Mar 4 2022 xiangyuning <xiangyuning@huawei.com> - 2.0.3-9
- ID:NA
- SUG:NA
- DESC: fix build oemaker failed issue

* Wed Mar 2 2022 xiangyuning <xiangyuning@huawei.com> - 2.0.3-8
- ID:NA
- SUG:NA
- DESC: restore env after selinux status changes 

* Wed Feb 23 2022 zhuyuncheng <zhuyuncheng@huawei.com> - 2.0.3-7
- ID:NA
- SUG:NA
- DESC: add Server install mode and packages for edge computing iso

* Wed Feb 23 2022 hanhui <hanhui15@h-partners.com> - 2.0.3-6
- DESC: delete gamin and openjpeg
        add rsyslog-gnutls and edk2-ovmf packages
        rename hisi_rde to hisi_trng_v2,libkae to uadk_engine

* Tue Feb 22 2022 jiangheng <jiangheng12@huawei.com> - 2.0.3-5
- ID:NA
- SUG:NA
- DESC: delete nscd package

* Mon Feb 14 2022 wangchong <952173335@qq.com> - 2.0.3-4
- ID:NA
- SUG:NA
- DESC: upgrade to 2.0.3 and support usb flash drive mode and delete some packages

* Fri Jan 21 2022 zhang_xubo <2578876417@qq.com> - 2.0.0-13
- ID:NA
- SUG:NA
- DESC: add opengauss server pakcage

* Thu Jan 20 2022 yaokai13 <yaokai13@huawei.com> - 2.0.0-12
- ID:NA
- SUG:NA
- DESC: delete decay package

* Thu Oct 14 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-11
- ID:NA
- SUG:NA
- DESC: bugfix I3OGUT

* Tue Sep 28 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-10
- ID:NA
- SUG:NA
- DESC: change for edge computing iso

* Tue Aug 26 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-9
- ID:NA
- SUG:NA
- DESC: change exclude list

* Tue Aug 17 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-8
- ID:NA
- SUG:NA
- DESC: delete decay package

* Thu Jul 15 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-7
- ID:NA
- SUG:NA
- DESC: replace gvfs-fuse by gvfs-fuse3

* Wed May 12 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-6
- ID:NA
- SUG:NA
- DESC: bugfix I3QY98

* Wed Apr 7 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-5
- ID:NA
- SUG:NA
- DESC: change for issue I3DJJW

* Fri Apr 2 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-4
- ID:NA
- SUG:NA
- DESC: rename source iso

* Thu Mar 25 2021 xinghe <xinghe1@huawei.com> - 2.0.0-3
- ID:NA
- SUG:NA
- DESC: remove atlas

* Sun Mar 21 2021 miao_kaibo <miaokaibo@outlook.com> - 2.0.0-2
- ID:NA
- SUG:NA
- DESC: replace rsyslog-gnutls by rsyslog

* Fri Mar 19 2021 zhuchunyi <zhuchunyi@huawei.com> - 2.0.0-1
- ID:NA
- SUG:NA
- DESC: upgrade version

* Sat Mar 17 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-7
- ID:NA
- SUG:NA
- DESC: delete or replace rpms which are not exist

* Sat Mar 13 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-6
- ID:NA
- SUG:NA
- DESC: add exclude rpm to rpmlist 

* Sat Mar 13 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-5
- ID:NA
- SUG:NA
- DESC: fix bug I3B7CH 

* Thu MAR 10 2021 Chen Qun <kuhn.chenqun@huawei.com> - 1.1.2-4
- ID:NA
- SUG:NA
- DESC: add qemu-block-iscsi in virtualization-hypervisor group

* Mon MAR 08 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-3
- ID:NA
- SUG:NA
- DESC: change method of creating source iso

* Thu MAR 01 2021 Chen Qun <kuhn.chenqun@huawei.com> - 1.1.2-2
- ID:NA
- SUG:NA
- DESC: add stratovirt in virtualization-hypervisor group

* Thu Feb 25 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-1
- ID:NA
- SUG:NA
- DESC:upgrade version

* Mon Feb 08 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.1-1
- ID:NA
- SUG:NA
- DESC:upgrade version

* Thu Oct 15 2020 zhuchunyi <zhuchunyi@huawei.com> - 1.0.1-1
- ID:NA
- SUG:NA
- DESC:upgrade version

* Tue Sep 29 2020 zhuchunyi <zhuchunyi@huawei.com> - 1.0.0-2
- ID:NA
- SUG:NA
- DESC:change Source format to URL

* Sat Jul 25 2020 zhuchunyi <zhuchunyi@huawei.com> - 1.0.0-1
- ID:NA
- SUG:NA
- DESC:package init
