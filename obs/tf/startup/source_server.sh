#!/bin/bash


if [[ $# -lt 4 ]];then
    echo "please specify frontend host, source host, backend host and data disk, usage: ./source_server.sh 172.16.1.81 172.16.1.89 172.16.1.95 172.16.1.84 /dev/vdb"
    exit 1
fi
frontend_host=$1
source_host=$2
backend_host=$3
home_backend_host=$4
data_disk=$5

echo "Starting obs source service with backend server ${backend_host}.."
#enable and start sshd service
echo "Enabling sshd service if not enabled"
systemctl enable sshd.service

echo "Disabling all service before start"
# disable all obs service first
systemctl disable obssrcserver.service
systemctl disable obsrepserver.service
systemctl disable obsservice.service
systemctl disable obsdodup.service
systemctl disable obssignd.service
systemctl disable obsservicedispatch.service
systemctl disable obsdeltastore.service
systemctl disable obsscheduler.service
systemctl disable obsdispatcher.service
systemctl disable obspublisher.service
systemctl disable obssigner.service
systemctl disable obswarden.service
systemctl disable obsworker.service
systemctl disable apache2
systemctl disable mysql
systemctl disable memcached
systemctl disable obs-api-support.target

systemctl stop obssrcserver.service
systemctl stop obsrepserver.service
systemctl stop obsservice.service
systemctl stop obsdodup.service
systemctl stop obssignd.service
systemctl stop obsservicedispatch.service
systemctl stop obsdeltastore.service
systemctl stop obsscheduler.service
systemctl stop obsdispatcher.service
systemctl stop obspublisher.service
systemctl stop obssigner.service
systemctl stop obswarden.service
systemctl stop obsworker.service
systemctl stop apache2
systemctl stop mysql
systemctl stop memcached
systemctl stop obs-api-support.target


# prepare the disk
if [[ ! -e ${data_disk} ]];then
    echo "No data disk found ${data_disk}"
    exit 1
fi
if [[ ! -e  /dev/OBS/server ]];then
    pvcreate ${data_disk}
    vgcreate "OBS" ${data_disk}
    lvcreate  -l 100%FREE  "OBS" -n "server"
    mkfs.ext3 /dev/OBS/server
    echo "/dev/mapper/OBS-server /srv  ext3 defaults 0 0" >> /etc/fstab
    mkdir -p /tmp/srv
    cp -a /srv/* /tmp/srv
    mount -a
    cp -a /tmp/srv/* /srv/
    rm -rf /tmp/srv
fi

# update configuration file
echo "Updating configuration file for obs source service"

curl https://openeuler.obs.cn-south-1.myhuaweicloud.com:443/infrastructure/BSConfig.pm -o /usr/lib/obs/server/BSConfig.pm

sed -i "s/\$HOSTNAME/backend.openeuler.org/g" /etc/slp.reg.d/obs.repo_server.reg
sed -i "s/\$HOSTNAME/source.openeuler.org/g" /etc/slp.reg.d/obs.source_server.reg

echo "Updating the cluster hosts info"
# update hosts info:
#    1. <frontend_host> build.openeuler.org
#    2. <source_host> source.openeuler.org
#    3. <backend_host> backend.openeuler.org
hostnamectl set-hostname source.openeuerl.org
if ! grep -q "build.openeuler.org" /etc/hosts; then
    echo "${frontend_host} build.openeuler.org" >> /etc/hosts
else
    sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} build.openeuler.org/${frontend_host} build.openeuler.org/g" /etc/hosts
fi
if ! grep -q "source.openeuler.org" /etc/hosts; then
    echo "${source_host} source.openeuler.org" >> /etc/hosts
else
    sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} source.openeuler.org/${source_host} source.openeuler.org/g" /etc/hosts
fi
if ! grep -q "backend.openeuler.org" /etc/hosts; then
    echo "${backend_host} backend.openeuler.org" >> /etc/hosts
else
    sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} backend.openeuler.org/${backend_host} backend.openeuler.org/g" /etc/hosts
fi
if ! grep -q "home-backend.openeuler.org" /etc/hosts; then
    echo "${home_backend_host} home-backend.openeuler.org" >> /etc/hosts
else
    sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} home-backend.openeuler.org/${home_backend_host} home-backend.openeuler.org/g" /etc/hosts
fi

echo "updating the osc configuration files"
#update osc config file
if [[ ! -d /root/.config/osc ]];then
    mkdir -p  /root/.config/osc
fi

if [[ -e /root/.config/osc/oscrc ]];then
    rm /root/.config/osc/oscrc
fi
curl -o /root/.config/osc/oscrc https://openeuler.obs.cn-south-1.myhuaweicloud.com:443/infrastructure/oscrc

# update cache folder for scm service
echo CACHEDIRECTORY="/srv/cache/obs/tar_scm" > /etc/obs/services/tar_scm

# copy service files into
cp ./service/* /usr/lib/obs/service/
cp ./build-pkg-rpm /usr/lib/build/build-pkg-rpm
mkdir -p /usr/lib/obs/source_md5
chmod 777 /usr/lib/obs/source_md5
mkdir -p /srv/cache/obs/tar_scm/{incoming,repo,repourl}
mkdir -p /srv/cache/obs/tar_scm/repo/euleros-version

echo "Restarting source service"
# restart the frontend service
systemctl enable obsstoragesetup.service
systemctl enable obssrcserver.service
systemctl enable obsdeltastore.service
systemctl enable obsservicedispatch.service
systemctl enable obsservice.service

systemctl start obsstoragesetup.service
systemctl start obssrcserver.service
systemctl start obsdeltastore.service
systemctl start obsservicedispatch.service
systemctl start obsservice.service
echo "OBS source server successfully started"
SOURCE_REPO_ID=`cat /srv/obs/projects/_repoid`
echo "Important, Please use this ID: ${SOURCE_REPO_ID} to replace the file content of '/srv/obs/projects/_repoid' and '/srv/obs/build/_repoid' in the backend server"
