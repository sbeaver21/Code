Name: python-zope.interface
Summary: Zope 3 Interfaces for Python
Version: %{_productversion}
Release: 1.vmw.%{_buildnumber}
License: ZPL
Group: Development/Libraries
URL: http://pypi.python.org/pypi/zope.interface
Source: %{_srctgz}
BuildRoot: %{_tmppath}/zope_interface-%{version}-root

%description
This package is intended to be independently reusable in any Python
project. It is maintained by the Zope Toolkit project.

This package provides an implementation of object interfaces for Python.
Interfaces are a mechanism for labeling objects as conforming to a given
API or contract. So, this package can be considered as implementation of
the Design By Contract methodology support in Python.

%prep
%setup -n zope_interface-%{version}

%install
%{__rm} -rf %{buildroot}
%{_python} setup.py install --skip-build --root="%{buildroot}" --prefix="%{_prefix}"
find %{buildroot} -name \*.so -exec %{__chmod} 0755 {} \;
if test -d %{buildroot}/%{_prefix}/lib; then
   %{__mv} %{buildroot}/%{_prefix}/lib %{buildroot}/%{_prefix}/lib64
fi

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%{_pythonsitelib}/zope*

%changelog
* Wed May 24 2017 uddinm@vmware.com
- Updated to 4.4.1
* Thu Mar 31 2016 mjankowski@vmware.com
- Updated to 4.1.3
* Tue Aug 26 2014 jkovalch@vmware.com
- Initial build for SLES11, version 3.8.0
