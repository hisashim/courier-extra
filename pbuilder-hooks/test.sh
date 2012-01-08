#!/bin/sh
if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
  then
  PACKAGE=$1
  VERSION=$2
  DEBREV=$3
  DEB=${PACKAGE}_${VERSION}-${DEBREV}
  else
  exit 1
fi

echo "### Editing apt lines..."
cp -v /etc/apt/sources.list /etc/apt/sources.list.bak
echo 'deb http://cdn.debian.net/debian unstable main contrib non-free' >> /etc/apt/sources.list
echo "### /etc/apt/sources.list"
diff -u /etc/apt/sources.list.bak /etc/apt/sources.list
apt-get update
apt-get update
echo "### Installing the package and requirements..."
dpkg -i /var/cache/pbuilder/result/${DEB}_all.deb
apt-get install -f --yes
echo "### dpkg -l | grep '^ii'"
dpkg -l | grep '^ii'

echo "### Setting up CMAPs and font maps..."
if [ -f /etc/texmf/texmf.d/50dvipdfmx.cnf ]
then
  cp -v /etc/texmf/texmf.d/50dvipdfmx.cnf /etc/texmf/texmf.d/50dvipdfmx.cnf.bak
  echo 'CMAPINPUTS = .;/usr/share/fonts/cmap//' >> /etc/texmf/texmf.d/50dvipdfmx.cnf
  echo "### /etc/texmf/texmf.d/50dvipdfmx.cnf"
  diff -u /etc/texmf/texmf.d/50dvipdfmx.cnf.bak /etc/texmf/texmf.d/50dvipdfmx.cnf
elif [ -f /etc/texmf/texmf.d/80DVIPDFMx.cnf ]
then
  echo "### /etc/texmf/texmf.d/80DVIPDFMx.cnf"
  cat /etc/texmf/texmf.d/80DVIPDFMx.cnf
else
  echo "### Neither 50dvipdfmx.cnf or 80DVIPDFMx.cnf found."
  ls -la /etc/texmf/texmf.d/
fi
update-texmf

echo "### Copying source package..."
cp -v /var/cache/pbuilder/result/${DEB}.dsc ./
cp -v /var/cache/pbuilder/result/${PACKAGE}_${VERSION}.orig.tar.gz ./
cp -v /var/cache/pbuilder/result/${DEB}_*.changes ./
echo "### Extracting source package..."
tar xfz ${PACKAGE}_${VERSION}.orig.tar.gz
echo "### Processing test documents..."
cd courier-extra-${VERSION}
apt-get install t1utils
make test
make mostlyclean
make test MAP=
make mostlyclean
make test MAP=courier-extra-pcr
make mostlyclean
make test MAP=courier-extra-ucr
make mostlyclean
make test MAP=courier-extra-fcr
make mostlyclean
echo "### Copying test result to /var/cache/pbuilder/result..."
tar cfz ${DEB}-test.tar.gz pcr*.pdf courier-extra-test.pdf
cp -v ${DEB}-test.tar.gz /var/cache/pbuilder/result
cd -
echo "### Testing uninstallation..."
dpkg --remove ${PACKAGE}
dpkg --install /var/cache/pbuilder/result/${DEB}_all.deb
dpkg --purge ${PACKAGE}
