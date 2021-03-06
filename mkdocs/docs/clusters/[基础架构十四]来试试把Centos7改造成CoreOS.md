## 基础架构十四：来试试把Centos7改造成CoreOS

##### 前言：


* 本文的目的是将CentOS7配置自动化，改造为容易使用的容器OS，向CoreOS看齐
* CoreOS是非常有名的容器OS，现就叫ContainerOS，内置的Docker 18.06, Kernel 4.14, socat/ebtables/etcdctl/ipvsadm等，使用user_data配置文件自动配置和更新，是容器时代的OS首选，安装各种Docker应用、K8s，非常方便，但似乎国内一般公司使用的人并不多，安装可参考[《基础架构八 CoreOS》](https://mp.weixin.qq.com/s?__biz=Mzg4MjAyMDgzMQ==&mid=100000109&idx=1&sn=83f2fb086760c29a0e22f65ab92cc3d3&chksm=4f5c59dd782bd0cb68760fe0c435153f9139692c604ff63ef179d56c86ef0225a0d5add2bafe&mpshare=1&scene=1&srcid=122309w18x1jAinyDX16VxHx#rd)；

* CentOS可能是使用最广泛的LINUX版本了，目前最新7.6版本，但安装配置需要很多项目调整，各种文章仁智各见；

* KVM+QEMU：LINUX上被广泛使用的内核级虚拟机，使用一系列virsh来管理虚拟机，有基于WEB和图形化的virtualization manager，稳定、方便，使用广泛；

##### 目标：在基于KVM的虚拟机上，将最小化安装好的CentOS7改造为类似CoreOS的容器OS，自动配置主机名、网卡参数、SSH的认证KEY等，使虚拟机配置自动化，方便自动化安装各种容器应用和K8S集群



##### 准备：最小化安装好一个CentOS7的KVM虚拟机

* 过程比较简单，就略过了，需要2CPU，4G内存，2网卡，40G硬盘分500M给boot，10G给/，剩下的挂在/var/lib/docker下：

```shell
/dev/vda1     xfs  500M  /boot
/dev/vda2     xfs   10G     /
/dev/vda3     xfs    30G    /var/lib/docker
```

* 贴一下virt-install命令：


```shell
virt-install -n kvmbase2 --vcpus 2 -r 4096 \
--disk /mnt/kvm/centos-7.qcow2.kvm,format=qcow2,size=40 \
--network bridge=br0 \
--network network=default \
--os-type=linux --os-variant=rhel7.2 \
--cdrom /mnt/software/CentOS-7-x86_64-Minimal-1511.iso \
--vnc --vncport=5910 --vnclisten=0.0.0.0
```



##### 改造步骤

* 第一步：将琐碎的调整命令和步骤收集为一个[SHELL脚本](https://raw.githubusercontent.com/Thomas-YangHT/shell/master/10-env_CentosDocker.sh)，跑一下就配置好了CentOS7的虚拟机，4.18版的内核，18.09版的Docker
* 第二步：写一个[python脚本](https://raw.githubusercontent.com/Thomas-YangHT/shell/master/centosConfig.py)，解析YAML格式的user_data配置文件，简单放在rc.local里，每次系统启动时自动更新系统配置
* 第三步：测试。看看自动配置脚本能否正常运转，要做的就是配置好的user_data拷贝进虚拟机的位置/var/log/coreos-install/user_data，运行一下/etc/rc.local或者reboot
* 第四步：将虚拟机的CLONE和配置自动化。由两个脚本完成，按照[配置文件](https://raw.githubusercontent.com/Thomas-YangHT/k8s-ha-autoinstall/master/CONFIG) 来[自动生成user_data的脚本](https://raw.githubusercontent.com/Thomas-YangHT/k8s-ha-autoinstall/master/clone_kvm/user_data_centos.sh)和[clone脚本](https://raw.githubusercontent.com/Thomas-YangHT/k8s-ha-autoinstall/master/clone_kvm/clone_machine.sh)，COPY自动生成的[user_data](https://raw.githubusercontent.com/Thomas-YangHT/k8s-ha-autoinstall/master/clone_kvm/user_data.master1)文件进新clone的虚拟机，重启即完成配置
* 第五步：安装K8S。[用我的3分钟装好K8S自动安装脚本](https://github.com/Thomas-YangHT/k8s-ha-autoinstall/blob/master/README.md)，跑的结果是并不比CoreOS的虚拟机慢
* 后续测试：用kolla安装OPENSTACK





-----

##### 第一步的系统配置SHELL说明

```shell
#kvm虚拟机安装：CentOS-7-x86_64-Minimal-1511.iso

#1.分区 /var/lib/docker 30G xfs用ftype=1重新格式化以适应docker overlay需要
umount /dev/vda3;sleep 2
mkfs -t xfs -f -n ftype=1 /dev/vda3 && \
mount /dev/vda3 /var/lib/docker && \
VDA="/dev/vda3 /var/lib/docker         xfs     defaults        0 0" && \
cp -f /etc/fstab /etc/fstab.bak && \
grep -v "/var/lib/docker" /etc/fstab.bak|grep -v "swap" >/etc/fstab && \
echo $VDA >>/etc/fstab
swapoff -a

#2.network两块网卡，一个接br0虚交换上配静态IP，一个接default默认虚交换上配DHCP
HOSTNAME=base
DNS1=192.168.31.140
IP=192.168.31.11
GW=
hostnamectl set-hostname $HOSTNAME
sed -i 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth*
echo """
nameserver $DNS1
nameserver 223.5.5.5
nameserver 114.114.114.114
""">/etc/resolv.conf
cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
UUID=
HWADDR=`ip a show dev eth0|grep -Po "ether \K\w+:\w+:\w+:\w+:\w+:\w+"`
DNS1=$DNS1
DNS2=223.5.5.5
IPADDR=$IP
PREFIX=24
GATEWAY=$GW
PROXY_METHOD=none
BROWSER_ONLY=no
EOF
#eth1
cat >/etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
TYPE=Ethernet
BOOTPROTO=DHCP
NAME=eth1
DEVICE=eth1
ONBOOT=yes
EOF
systemctl restart network

#3.yum我使用内部repo,请根据实际情况修改，或改为外部yum源
#===External repo===
#yum install epel-release -y
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#===External repo===
#------if have internal yum repo, set_local_repo.sh, Example:
cd /etc/yum.repos.d/;mv * .. -f
curl -o /etc/yum.repos.d/Centos7-Base-yunwei.repo    192.168.31.253/config/CentOS-Base-yunwei.repo && \
curl -o /etc/yum.repos.d/epel-yunwei.repo   192.168.31.253/config/epel-yunwei.repo && \
curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7  192.168.31.253/config/RPM-GPG-KEY-EPEL-7
#curl -o /etc/yum.repos.d/rdo-release-yunwei.repo  192.168.31.253/config/rdo-release-yunwei.repo
#curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud  192.168.31.253/config/RPM-GPG-KEY-CentOS-SIG-Cloud
#------internal yum repo-----#
yum repolist
yum remove -y PyYAML python-requests python-ipaddress python-urllib3
yum install -y wget net-tools sysstat vim curl git chrony ntpdate \
      python-pip socat ebtables iptables-service ipvsadm
#python-devel libffi-devel gcc openssl-devel \
yum update -y

#4.pip配置
mkdir ~/.pip;cd ~/.pip
cat >pip.conf <<EOF
[global]
timeout = 60
index-url = http://pypi.douban.com/simple
trusted-host = pypi.douban.com
EOF
pip install -U pip
pip install PyYAML requests ipaddress urllib3==1.22 ansible fabric

#6.SSHD不使用DNS反查
grep UseDNS=no  /etc/ssh/sshd_config
[ $? != 0 ] && sed  -i  '/UseDNS/i UseDNS=no' /etc/ssh/sshd_config

#7.serial port console
grep serial /etc/default/grub
[ $? != 0 ] && sed -i.ori -e 's/"console"/"console serial"/g' \
-e '/GRUB_TERMINAL/a\GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"' \
-e '/GRUB_TERMINAL/a\GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0,115200"' \
/etc/default/grub && \
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg

#8.ethX网卡名
grep net.ifnames=0 /boot/grub2/grub.cfg
[ $? != 0 ] &&  sed -i.ori 's/rhgb/net.ifnames=0 biosdevnam=0 rhgb/g' /boot/grub2/grub.cfg

#9.BASH提示符
echo 'export PS1="\[\e[32;40m\]\u@\h\[\e[35;40m\]\t\[\e[0m\]\w#"' >>/root/.bashrc

#10.语言字符集
echo 'LANG="zh_CN.UTF-8"' >/etc/locale.conf
echo 'LC_ALL="en_US.UTF-8"' >>/etc/locale.conf

#11.时区
rm /etc/localtime -f
ln -s  /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#12.时间同步，请根据自身实际修改IP
#ntpdate $NTP_SERVER; clock -w
CHRONY_SRV=192.168.122.1
grep $CHRONY_SRV /etc/chrony.conf
[ $? != 0 ] && sed -i.ori -e 's/server/#server/g' -e "/server 3./a\server $CHRONY_SRV iburst" /etc/chrony.conf && \
systemctl restart chronyd
chronyc sourcestats -v

#13.selinux
sed -i.ori 's/enforcing/disabled/' /etc/selinux/config

#14.FORWARD & bridge
echo "
vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
" > /etc/sysctl.conf
sed -i.ori '$a\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

#15.SSH ID，内部下载地址请修改
SSH_AUTHKEY_URL=http://192.168.31.253/config/auth-key
mkdir /root/.ssh
cd /root/.ssh
mkdir ~/.ssh;cd ~/.ssh;
wget -O auth-key  $SSH_AUTHKEY_URL && \
cat auth-key >authorized_keys && \
echo "">>authorized_keys

#16.安装Docker 18.09，装了最新版docker，k8s只测试到18.06，实测是不影响安装k8s
#DURL=https://download.docker.com/linux/centos/7/x86_64/stable/Packages/
#内部的下载，请根据实际情况修改或用上面的外部链接
DURL=http://192.168.31.253/software/
S1=${DURL}containerd.io-1.2.0-3.el7.x86_64.rpm
S2=${DURL}docker-ce-18.09.0-3.el7.x86_64.rpm
S3=${DURL}docker-ce-cli-18.09.0-3.el7.x86_64.rpm
yum install -y $S1 $S2 $S3

#17.设置docker
mkdir /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf << 'EOF'
[Service]
MountFlags=shared
EOF
#这句似乎没有用，新版的docker已经是accept的了
sed -i "13i ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT" /usr/lib/systemd/system/docker.service

#18.访问私有的Docker仓库
DOCK_REGISTRY="192.168.31.140:5000"
mkdir /etc/docker
tee /etc/docker/daemon.json <<EOF
{
"registry-mirrors": [ "https://registry.docker-cn.com"],
"insecure-registries": [ "$DOCK_REGISTRY","192.168.100.222:5000"]
}
EOF
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
docker info

#19.kernel upgrade
KURL=http://192.168.31.253/software/
KERNEL=${KURL}kernel-ml-4.18.12-1.el7.elrepo.x86_64.rpm
KERNEL_DEVEL=${KURL}kernel-ml-devel-4.18.12-1.el7.elrepo.x86_64.rpm
yum install -y $KERNEL $KERNEL_DEVEL
#rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm && \
#yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml -y
grub2-set-default 0

#20.ip_vs
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
/sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
if [ $? -eq 0 ]; then
/sbin/modprobe \${kernel_module}
fi
done
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs

#END.数了数，大小20+项修改
```

-----



##### user_data示例（由user_data_centos.sh自动生成，请根据实际修改IP）

```yaml
#cloud-config  

hostname: master1

centos:    
  units:  
    - name: ifcfg-eth0  
      content: |  
        TYPE=Ethernet
        BOOTPROTO=static
        DEFROUTE=yes
        IPV4_FAILURE_FATAL=no
        IPV6INIT=yes
        IPV6_AUTOCONF=yes
        IPV6_DEFROUTE=yes
        IPV6_FAILURE_FATAL=no
        NAME=eth0
        DEVICE=eth0
        ONBOOT=yes
        UUID=
        HWADDR=
        DNS1=192.168.253.110
        DNS2=114.114.114.114
        IPADDR=192.168.253.31
        PREFIX=24
        GATEWAY=192.168.253.125
        PROXY_METHOD=none
        BROWSER_ONLY=no

update:
  reboot-strategy: off

users:    
  - name: root  
    ssh-authorized-keys:   
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCTVrS0pCy91x47yaOFBzBYl7eBcaCRssEVifShwdFmklkHUSCHJu9MDp6lhju3mO/5toRb5lCdEU2q5HnUN27Ohqt6Mf1ICrOMd0Add9G+pmJ/9Rtb0BnGZ5SK6QaJbGU3jxoPDpik+8zfVXDCK/YWjsulheLMXJI9wR+f9/y7SEZMfH3LkDVnKhurv/gNhcea7zJrAaoH5TQLBJeNxnPxPAinWt3jMLPoPU6boHwGdhyv3tO60rFJFloJ3fVYUSzypYpHUkB+7gFs3MGv6qz9V5eK+yotSph4pUOD5XjQ172MeXZc0qm3okqZj00YvkEd5nfhS7NBo5pMRh0WnvDx root@bsd
    # ssh rsa 这里插入ssh的public key，用于安装后远程ssh连接时候使用。

  - groups:  
      - sudo  
      - docker
      - wheel
      - rkt


```



-----

##### 自动配置python脚本（在rc.local里开机时运行一次）

```python
import yaml   
import commands

#放置两份user_data，当path指向的user_data有变化时，会执行配置更新操作
path='/var/lib/coreos-install/user_data'
pathrun='/var/lib/centos-config/user_data'
cmd='HWADDR=`ip a show dev eth0|grep -Po "ether \K\w+:\w+:\w+:\w+:\w+:\w+"`;sed -i "s/HWADDR=.*/HWADDR=$HWADDR/g" '+path
(status,datavalue) = commands.getstatusoutput(cmd)
print "cmd:"+str(status)+":"+str(datavalue)
(status,diffvalue) = commands.getstatusoutput('diff '+path+' '+pathrun)
if status != 0 :
    (status,datevalue) = commands.getstatusoutput('cp -f '+path+' '+pathrun)
    f=open(path)  
    CONFDIC=yaml.load(f) 
    user=CONFDIC['users'][0]['name']
    sshkey=CONFDIC['users'][0]['ssh-authorized-keys'][0]
    hostname=CONFDIC['hostname']
    ifname=CONFDIC['centos']['units'][0]['name']
    ifcfg=CONFDIC['centos']['units'][0]['content']
    ifcfgpath='/etc/sysconfig/network-scripts/'
    sshkeypath='/root/.ssh/'
    print diffvalue
    (status,datevalue) = commands.getstatusoutput('echo """'+ifcfg+'""">'+ifcfgpath+ifname)
    (status,datevalue) = commands.getstatusoutput('echo """'+sshkey+'""">'+sshkeypath+'authorized_keys')
    (status,datevalue) = commands.getstatusoutput('hostnamectl set-hostname '+hostname)
    (status,datevalue) = commands.getstatusoutput('logger Update config'+str(diffvalue[0]))
    (status,datevalue) = commands.getstatusoutput('reboot')
else :
    print 'Config is uptodate'    



```



##### 可以直接在[这里](https://pan.baidu.com/s/1iDm6KwZ4c4xcCAkpYe0KlQ)下载配置好的CentOS虚拟机镜相



##### 参考：

* [陈沙克KOLLA安装OPENSTACK](http://www.chenshake.com/kolla-installation/#i-3)
* [lentil1016K8S自动化安装](https://www.kubernetes.org.cn/4948.html)
* [青蛙小白使用 kubeadm 安装新版本 Kubernetes 1.13](https://mp.weixin.qq.com/s/vK6mOElXk_gYfW6lSsTZgA)





![Linux命令搜索工具](https://mmbiz.qpic.cn/mmbiz_jpg/zAqPR4x6QEGIM9EAt4plibBMqSUBlerpd0kP6TLujKxLk1x67EvQwFMBMajEhtesH9aLFDneE7KZI6KPMWPTTaQ/640?wx_fmt=jpeg)

