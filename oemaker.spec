%ifarch aarch64
%global efi_aa64 1
%endif

%ifarch x86_64
%global efi_x64 1
%endif

Name:           oemaker
Summary:        a duilding tool for DVD ISO making and ISO cutting
License:        Mulan PSL v2
Group:          System/Management
Version:        2.0.0
Release:        3
BuildRoot:      %{_tmppath}/%{name}
Source:         https://gitee.com/openeuler/oemaker/repository/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Requires:       createrepo dnf-plugins-core genisoimage isomd5sum grep bash libselinux-utils libxml2
Requires:       lorax >= 19.6.78-1

Patch0001:      0001-replace-rsyslog-gnutls-by-rsyslog.patch
Patch0002:	0002-remove-atlas.patch

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
cd %{_builddir}/%{name}-%{version}/%{name}
%autopatch -p1

%install
mkdir -p %{buildroot}/opt/
mkdir -p %{buildroot}/opt/oemaker
mkdir -p %{buildroot}/opt/oemaker/config
mkdir -p %{buildroot}/opt/oemaker/config/x86_64
mkdir -p %{buildroot}/opt/oemaker/config/aarch64
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
install -m 400 %{name}/isomaker/config/rpmlist.xml %{buildroot}/opt/oemaker/config/rpmlist.xml
install -m 400 %{name}/isomaker/config/x86_64/* %{buildroot}/opt/oemaker/config/x86_64/
install -m 400 %{name}/isomaker/config/aarch64/* %{buildroot}/opt/oemaker/config/aarch64/
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
