## Hadoop概念与架构

##### Hadoop：

- 是一个由Apache基金会所开发的分布式系统基础架构，为大数据处理提供了数据存储基础架构、编程模型，核心由HDFS和YARN(MapReduce2.0)组成，最新release版本3.1.1。
- 来源于GOOGLE的三篇论文
  - 1、《分布式文件系统》
  - 2、《分布式计算模型》
  - 3、《BigTable》
- 从传统的Hadoop三驾马车HDFS，MapReduce和HBase社区发展为60多个相关组件组成的庞大生态，其中包含在各大发行版中的组件就有25个以上，包括数据存储、执行引擎、编程和数据访问框架等。
- 官网：
  - <https://hadoop.apache.org/>
  - <https://github.com/apache/hadoop>
- 参考：<https://blog.csdn.net/heweimingming/article/details/82177142>

##### Hadoop的核心

- hdfs

  - HDFS，是Hadoop Distributed File System的简称，是Hadoop抽象文件系统的一种实现。Hadoop抽象文件系统可以与本地系统、Amazon S3等集成，甚至可以通过Web协议（webhsfs）来操作。HDFS的文件分布在集群机器上，同时提供副本进行容错及可靠性保证。例如客户端写入读取文件的直接操作都是分布在集群各个机器上的，没有单点性能压力。

  - 由NameNode和DataNode组成。namenode用于组织数据，datanode用于存储数据。

  - HDFS已经成为了大数据磁盘存储的事实标准，用于海量日志类大文件的在线存储

  - 参考：

    - <https://blog.csdn.net/sjmz30071360/article/details/79877846>
    - <https://www.cnblogs.com/laov/p/3434917.html>

  - 

    ![img](https://img.mubu.com/document_image/600df7e5-d8e6-4a32-85a0-af83edc7575b-132377.jpg)

- yarn

  - Apache Hadoop YARN （Yet Another Resource Negotiator，另一种资源协调者）是一种新的 Hadoop 资源管理器，它是一个通用资源管理系统，可为上层应用提供统一的资源管理和调度。由ResourceManager和NodeManager组成，即资源管理和结点管理。

  - 

    ![img](https://img.mubu.com/document_image/e6b39151-3c5d-4a54-8b90-69a8dd1f9425-132377.jpg)

  - 参考：<https://baike.baidu.com/item/yarn/16075826?fr=aladdin>

- ZooKeeper集群

  - 是 Hadoop集群管理的一个必不可少的模块,它主要用来解决分布式应用中经常遇到的数据管理问题，如集群管理、统一命名服务、分布式配置管理、分布式消息队列、分布式锁、分布式协调等。作用就好比ETCD之于K8S集群，Redis之于后端集群
  - 参考：
    - <https://baijiahao.baidu.com/s?id=1576064162464626&wfr=spider&for=pc>
    - <https://www.jianshu.com/p/fdcd6cd6a871>

- HBase

  - 是基于Hadoop的列数据库，为用户提供基于表的数据访问服务。
  - ![1548128563314](C:\Users\qinghua\AppData\Roaming\Typora\typora-user-images\1548128563314.png)

- Hive

  - 是在Hadoop上的一个查询服务，用户通过用户网关层的Hive客户端提交类SQL的查询请求，并通过客户端的UI查看返回的查询结果，该接口可提供数据部门准即时的数据查询统计服务。
  - ![img](https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=2251152696,2120524585&fm=26&gp=0.jpg)

- spark

  - **Apache Spark™**是用于大规模数据处理的统一分析引擎。
  - spark是一个实现快速通用的集群计算平台。它是由加州大学伯克利分校AMP实验室 开发的通用内存并行计算框架，用来构建大型的、低延迟的数据分析应用程序。它扩展了广泛使用的MapReduce计算模型。高效的支撑更多计算模式，包括交互式查询和流处理。spark的一个主要特点是能够在内存中进行计算，及时依赖磁盘进行复杂的运算，Spark依然比MapReduce更加高效。
  - 介绍：
    - <https://www.cnblogs.com/qingyunzong/p/8886338.html>
    - <https://www.cnblogs.com/miqi1992/p/5621268.html>
  - download: <http://spark.apache.org/downloads.html>
  - ![1548128005424](C:\Users\qinghua\AppData\Roaming\Typora\typora-user-images\1548128005424.png)

- 参考：

  - 一文看懂hadoop: <https://www.cnblogs.com/shijiaoyun/p/5778025.html>