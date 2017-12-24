FIREWALL_CERTIFICATE_PATH=/cygdrive/g/PortalDevelopers/Firewall.pem
ANSIBLE=/opt/ansible
PATH=/bin:$PATH:$ANSIBLE/bin
PYTHONPATH=$ANSIBLE/lib:
ANSIBLE_LIBRARY=$ANSIBLE/library
C_INCLUDE_PATH=/usr/include:/usr/include/python2.7:$C_INCLUDE_PATH
C_PLUS_INCLUDE_PATH=/usr/include:/usr/include/python2.7:$C_PLUS_INCLUDE_PATH
LIBRARY_PATH=/usr/lib:$LIBRARY_PATH
LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
mkdir -p ~
echo 'ANSIBLE=/opt/ansible' > ~/.bashrc
echo 'PATH=/bin:$PATH:$ANSIBLE/bin' >> ~/.bashrc
echo 'PYTHONPATH=$ANSIBLE/lib:' >> ~/.bashrc
echo 'ANSIBLE_LIBRARY=$ANSIBLE/library' >> ~/.bashrc
echo 'C_INCLUDE_PATH=/usr/include:/usr/include/python2.7:$C_INCLUDE_PATH' >> ~/.bashrc
echo 'C_PLUS_INCLUDE_PATH=/usr/include:/usr/include/python2.7:$C_PLUS_INCLUDE_PATH' >> ~/.bashrc
echo 'LIBRARY_PATH=/usr/lib:$LIBRARY_PATH' >> ~/.bashrc
echo 'LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
if [ -f $FIREWALL_CERTIFICATE_PATH ]; then
  cp $FIREWALL_CERTIFICATE_PATH /etc/pki/ca-trust/source/anchors/firewall.pem
fi
update-ca-trust
mkdir -p ~/.pip
echo "[global]" > ~/.pip/pip.conf
echo "cert = /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem" >> ~/.pip/pip.conf
echo "[build_ext]" > ~/.pydistutils.cfg
echo "include_dirs=/usr/include" >> ~/.pydistutils.cfg
echo "library_dirs=/usr/lib" >> ~/.pydistutils.cfg
echo "rpath=/usr/lib" >> ~/.pydistutils.cfg
cd /lib/python2.7/site-packages/
python easy_install.py pip
cd /tmp
pip install kerberos requests_kerberos pynacl ansible
