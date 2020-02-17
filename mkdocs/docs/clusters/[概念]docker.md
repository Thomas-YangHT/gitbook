# docker概念
---
## **docker是什么？**
  * 为了解决应用环境配置的难题，将一个个应用打包成镜相(image)，存放这个镜相的地方称为docker仓库(registry),运行起来的实例称为容器（container）
![image](http://upload-images.jianshu.io/upload_images/12123313-0401451b1906521e?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  * 相当于把应用放到chroot环境里运行
![image](http://upload-images.jianshu.io/upload_images/12123313-c9dd268fc778067a?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  * 如同把货物（应用）打包到集装箱（容器）里一样
![image](http://upload-images.jianshu.io/upload_images/12123313-4ad5a490e98a62af?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  * 站在 Docker 的角度，软件就是容器的组合：业务逻辑容器、数据库容器、储存容器、队列容器......Docker 使得软件可以拆分成若干个标准化容器，然后像搭积木一样组合起来。
![image](http://upload-images.jianshu.io/upload_images/12123313-d2ca1089180f124f?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## **如何使用？**
  * 通过一组docker命令来实现打包、运行、起动、停止、删除、上传、下载等一系列相关操作。 
![image](http://upload-images.jianshu.io/upload_images/12123313-66eed42d4393cb1b?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  * 基本命令
    * docker info 显示基本信息
    * docker run  启动一个容器实例
    * docker ps   查询容器
    * docker images 查询镜相
    * docker cp   在容器与宿主机间复制文件
    * docker start/stop/logs/restart 启动/停止/查日志/重启容器
    * docker exec 在运行的容器中执行命令
    * docker rm   用于删除容器
    * [命令参考](https://docs.docker.com/engine/reference/run/#general-form)
##  **有何特性？**
  * one build, run anywhere.
  * 跨平台、跨运行库  
![image](http://upload-images.jianshu.io/upload_images/12123313-73f5495c9768bff7?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## **docker registry？** 
  * 即docke私有仓库，用于存储docker image，可以通过push、pull、tag等简单命令来使用这些镜相。
 ![image](http://upload-images.jianshu.io/upload_images/12123313-c28dec06d77af71c?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
##   **dockerfile？**
  * 用于定义docker image镜相
 ![image](http://upload-images.jianshu.io/upload_images/12123313-1f920a3101e1c688?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
##  **docker-compose？**
  * 使用一个[docker-compose.yml](https://docs.docker.com/compose/compose-file/#service-configuration-reference)来定义容器，比[docker run](https://docs.docker.com/engine/reference/run/#general-form)命令使用更方便。
##  **入门教程**
  * https://mp.weixin.qq.com/s/xMhgFUEJWhcZdEkMsQPx8Q
  * http://www.ruanyifeng.com/blog/2018/02/docker-tutorial.html
---

## **安装升级**
---
* 自带版本： yum install docker
* 最新版本： curl -sSL https://get.docker.com/ | sh
* 使用官方yum源升级：
```
[root@docker ~]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[root@docker ~]# yum install docker-ce
```
* 也可下载后安装，官方下载：
  * https://download.docker.com/linux/centos/7/x86_64/stable/Packages/
  * https://yum.dockerproject.org/repo/main/centos/7/

## **配置镜像源为国内官方源以及内部仓库**
---
[root@docker ~]# vim /etc/docker/daemon.json
```
{
"registry-mirrors": [ "https://registry.docker-cn.com"],
"insecure-registries": [ "192.168.254.211:5000"]
}
#注：将IP替换成自建docker仓库的IP
```
## [**dockerfile示例**](https://docs.docker.com/engine/reference/builder/)
---
* 用于定义docker image镜相
```
ubuntu jenkins example
FROM jenkins
USER root
RUN echo '' > /etc/apt/sources.list.d/jessie-backports.list && \
wget http://mirrors.163.com/.help/sources.list.jessie -O /etc/apt/sources.list && \
apt-get update && apt-get install -y git
```
## [**docker-compose安装**](https://docs.docker.com/compose/gettingstarted/#step-1-setup)
---
* [查询版本](https://github.com/docker/compose/releases/)
* 升级docker-compose至指定版本
```
#注：替换1.19.0为想要安装的版本
curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
* 查看版本信息
```
docker-compose --version
```
* [基本命令](https://docs.docker.com/compose/gettingstarted/#step-1-setup)
```
docker-compose up -d  #后台启动
docker-compose ps     #查看启动的容器
docker-compose start/stop/rm/restart/logs #容器的启动、停止、删除、重启、查日志
```
* [docker-compose.ym示例l](https://docs.docker.com/compose/compose-file/#service-configuration-reference)
```
version: "3.3"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    configs:
      - source: my_config
        target: /redis_config
        uid: '103'
        gid: '103'
        mode: 0440
configs:
  my_config:
    file: ./my_config.txt
  my_other_config:
    external: true
```
## **监控、管理工具**
---
[weave scope](https://www.cnblogs.com/CloudMan6/p/9118943.html)

![image](http://upload-images.jianshu.io/upload_images/12123313-c4cf985cde37f521?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Linux命令用法速查公众号，如：输入ls，返回用法链接，内含500+命令用法](http://upload-images.jianshu.io/upload_images/12123313-cb461a3e8c2135b2?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)