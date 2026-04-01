Name: python-Twisted
Summary: Event-driven networking framework written in Python
Version: %{_productversion}
Release: 1.vmw.%{_buildnumber}
License: LGPL
Group: Applications/Internet
URL: http://www.twistedmatrix.com/
Source: %{_srctgz}
BuildRoot: %{_tmppath}/twisted-%{version}-root
AutoReqProv: no
Requires: python
Provides: python-Twisted = %{version}-%{release}

%description
An event-driven networking framework written in Python and licensed
under the LGPL. Twisted supports TCP, UDP, SSL/TLS, multicast, Unix
sockets, a large number of protocols (including HTTP, NNTP, SSH, IRC,
FTP, and others), and much more.

%prep
%setup -q -n twisted-%{version}

%install
%{__rm} -rf %{buildroot}
%{_python} setup.py install --root="%{buildroot}" --prefix="%{_prefix}"
find %{buildroot} -name \*.so -exec %{__chmod} 0755 {} \;
if test -d %{buildroot}/%{_prefix}/lib; then
   %{__mv} %{buildroot}/%{_prefix}/lib %{buildroot}/%{_prefix}/lib64
fi

%clean
%{__rm} -rf %{buildroot}


%files
%defattr(-, root, root, 0755)
%{_pythonsitelib}/twisted
%{_pythonsitelib}/Twisted*
/usr/bin/*

%changelog
* Fri Jun 02 2017 uddinm@vmware.com
- Updated to version 17.1.0
* Thu Mar 31 2016 mjankowski@vmware.com
- Updated to version 16.0.0
* Wed Aug 27 2014 jkovalch@vmware.com
- Initial Build for SLES11, version 12.2.0
