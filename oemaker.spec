Name:           oemaker
Summary:        a duilding tool for making DVD ISO
License:        Mulan PSL v2
Group:          System/Management
Version:        1.1.2
Release:        4
BuildRoot:      %{_tmppath}/%{name}
Source:         https://gitee.com/openeuler/oemaker/repository/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       createrepo dnf-plugins-core genisoimage isomd5sum grep bash libselinux-utils libxml2
Requires:       lorax >= 19.6.78-1

Patch0001: 0001-change-source-iso-method.patch
Patch0002: 0002-bug-fix-I3B7CH.patch
Patch0003: 0003-delete-firefox-from-xml-file-of-x86_64.patch

%description
a building tool for making DVD ISO

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

cd %{name}
install -m 700 oemaker.sh %{buildroot}/opt/oemaker/oemaker.sh
install -m 700 make_debug.sh %{buildroot}/opt/oemaker/make_debug.sh
install -m 700 img_repo.sh %{buildroot}/opt/oemaker/img_repo.sh
install -m 700 init.sh %{buildroot}/opt/oemaker/init.sh
install -m 700 iso.sh %{buildroot}/opt/oemaker/iso.sh
install -m 700 rpm.sh %{buildroot}/opt/oemaker/rpm.sh
install -m 400 config/rpmlist.xml %{buildroot}/opt/oemaker/config/rpmlist.xml
install -m 400 config/x86_64/* %{buildroot}/opt/oemaker/config/x86_64/
install -m 400 config/aarch64/* %{buildroot}/opt/oemaker/config/aarch64/
install -m 700 docs/* %{buildroot}/opt/oemaker/docs/
cp -a 80-openeuler %{buildroot}/opt/oemaker/
cd -

%pre

%post
ln -s /opt/oemaker/oemaker.sh /bin/oemaker

%preun

%postun
rm -r /bin/oemaker
rm -rf /opt/oemaker


%files
%defattr(-,root,root)
%dir /opt
%dir /opt/oemaker
/opt/oemaker/*

%clean
rm -rf $RPM_BUILD_ROOT/*
rm -rf %{buildroot}
rm -rf $RPM_BUILD_DIR/%{name}

%changelog
* Mon Mar 15 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-4
- ID:NA
- SUG:NA
- DESC: delete firefox from x86_64

* Sat Mar 13 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-3
- ID:NA
- SUG:NA
- DESC: fix bug I3B7CH

* Thu Mar 11 2021 miao_kaibo <miaokaibo@outlook.com> - 1.1.2-2
- ID:NA
- SUG:NA
- DESC: update oemaker to 1.1.2 from 1.0.0

* Sat Jul 25 2020 zhuchunyi <zhuchunyi@huawei.com> - 1.0.0-1
- ID:NA
- SUG:NA
- DESC:package init
