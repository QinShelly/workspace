# 面试题库 - 含电话面试 #

## 电话面试说明 ##
电话面试目的应为过滤掉明显不符合要求的面试者，而不是以直接找到符合要求的面试者为目的。电话面试每过滤掉一个面试者，都可以省下大量后续时间。
故电话面试应以一些基本要求（比如英语，沟通），及基本知识点（数据库，编程）为主。

以下标出的一些**基本题**可用于电话面试，如答不出说明某方面基础极差，可以直接fail之。能答出基本题者可以考虑做onsite面试。   

## 其他说明 ##
问题不需要全问，可以按面试进程适当选择问题。
面试者应该答出大部分题目，而不是全部。  
应注意面试者是否强烈倾向于用一种技术解决所有问题，比如都用数据库，或者都用Java。这通常不是好迹象。
面试时应着重考察面试者性格时候积极，沟通是否顺畅，和现有公司文化是否match。

题库顺序安排以BI Engineer的要求为主  
Database > Data Warehouse > Coding > Cube > Algorithms

## 英语 ##
**能用英语做自我介绍，能听懂简单问题**  
如英语要求高，可将某技术题目要求面试者用英语回答

## 沟通 ##
- **可让面试者描述自己做的的项目，功能，职责, 应当要求沟通顺畅, 思路清晰**  
- 面试者介绍利用其业余时间做的项目，程序
 
## 技术 ##
1. Database
- **left join，right join，inner join区别**
- **数据的横转纵，纵转横**  
- 找到表中的重复数据，做去重处理  
- A表Join B表, a.id = b.id 放在On与Where区别
- 使用Partitioned Table的好处
- Hash Join， Merge Join，Nested Loop的区别
- 性能调优的经验

> 如面试者有SQL Server背景
- **Clustered Index 与 Non-Clustered index区别**
- 共享锁及排他锁的区别，试举例
- 锁升级的概念
- SQL Server中的Isolation Level，及解决的问题

> 题目
- 假设多条记录包括开始时间和结束时间， 结束时间和下一条开始时间之间应连续，试找出数据中不连续记录（Gap）
- 取账户表在某时刻余额，假设账户表仅支持存入，取出操作
- 一数据量极大表，无Partition，无Index，须按特定条件删除约1/2 数据，如何操作。
- 一parent/child形式表，试找出某记录的root

2. Data Warehouse
- **雪花模型和星形模型哪个较好**
- **ETL如何取增量数据**
- 缓慢变化维 Slowing Changing Dimension（Type 2）如何实现，设计及ETL具体做法

3. Coding
- **写一小程序，将一字符串倒序排列**
- 堆、栈数据结构的理解，并描述如何简单实现
- 特定名称的进程无法正常退出，累计大量僵尸进程，如何批量杀进程。 
- 从网页中提取所有电话号码，电话号码都有比较固定的形式，如xxxx-xxxx, (xxx)xxxx-xxxx

4. 如面试者有SSAS背景
- Cube Process 的不同Option的区别
- Last NonEmpty聚合方式的含义
- DistinctCount Measure设计时的注意事项
- 优化Process Cube性能的方法，如只process增量，使用stage cube避免影响客户使用等。
- 优化查询性能的方法，如Aggregation， Partition等

> MDX
- 试解释元组(tuple)概念
- 写MDX取当前某度量与一年前同度量之差 (LY Chg), 可假设一年为365天。
- Freeze语句的作用，多数人应该回答不出，若回答出是好现象。
- 优化MDX性能的方法，使用trace，profiler，如能提出MDX Studio最佳。

5. Algorithms
- 简要描述一些常用排序算法，如快速，堆，插入等。
- 深度优先，广度优先搜索的区别