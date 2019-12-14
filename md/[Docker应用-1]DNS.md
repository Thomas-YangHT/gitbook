## **DNS**
![image](http://upload-images.jianshu.io/upload_images/12123313-87c29ce2cdaa8c70?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
#### **DNS的重要性**
- 几乎所有应用都要使用DNS服务，她的重要性不言而喻，DNS的故障经常会导致网络中依赖她的应用的连锁反应，我就曾遇到过k8s集群的coreDNS不断重启，原因就是连接不到上层的DNS，因此建立一个稳定的内部DNS致关重要。
#### **两种实现**
* 传统的DNS应用是bind，稳定而高效
* 新生的DNS应用叫dnsmasq，kubernetes也是使用它，简单易配，包含dhcp服务，但从使用中发现，经常触发查询上限而拒绝服务，调高上限也解决不了问题
## **三种运行方法**
- 下面给出了两种DNS使用docker运行的三种方法：
---
### 1.  dnsmasq使用docker run启动
---
```
docker run   --name dnsmasq -d \
-p 53:53/udp   -p 8080:8080 \
-v /opt/dnsmasq.conf:/etc/dnsmasq.conf \
-e TZ＝'Asia/Shanghai' \
-e "HTTP_USER=admin"  -e "HTTP_PASS=admin" \
--restart always   jpillora/dnsmasq
```
#####注：dnsmasq.conf参考[这里](https://wiki.archlinux.org/index.php/Dnsmasq_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
---
### 2.  bind 使用compose
---
```
mkdir cmp_bind; cd cmp_bind; 
cat  >docker-compose.yml
<<EOF
bind:
image: sameersbn/bind
volumes:
- /opt/bind:/data
- /opt/bind/entrypoint.sh:/sbin/entrypoint.sh
ports:
- "53:53/udp"
environment:
- WEBMIN_ENABLED=false
restart: always
EOF
docker-compose up -d
```
##### 注： 代码中的opt/bind目录可以从[这里](https://github.com/Thomas-YangHT/docker-compose/tree/master/bind)下载，也可以先运行一个不带-v参数的容器，
---
### 3. bind使用docker run启动
---
```
docker run --name bind -d \
-p 53:53/udp \
-e WEBMIN_ENABLED=false \
-v /opt/bind:/data \
-v /opt/bind/entrypoint.sh:/sbin/entrypoint.sh \
sameersbn/bind:latest
```

### **注：** 
- [bind 参考
](https://hub.docker.com/r/sameersbn/bind/)
- 代码中的-v参数挂载的卷，都可以先运行一个不带-v参数的容器，从里面CP出来，这样做的好处是方便保存和修改。
- 如果配置主从DNS，注意增加-p 53:53/tcp，来同步数据。
- [DNS的配置参考](https://thomas-yanght.github.io/appsrv/dns.html)
![Linux命令用法速查公众号，如：输入ls，返回用法链接，内含500+命令用法](http://upload-images.jianshu.io/upload_images/12123313-cb461a3e8c2135b2?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)