## task 命令的笔记

```shell
task 1-2 done  # 把 ID 为 1 和 2 的任务标记为 [completed]
   
Completed task 1 '完成Kafka 入库开发'.
Completed task 2 '调试大数据程序,解决报错、 部署、 配置文件、 入库过程中出现打问题'.


task completed # 显示已经完成的任务

ID UUID     Created    Completed  Age Description                                                     
 - 1c9dde5e 2020-09-16 2020-09-21 4d  完成Kafka 入库开发
 - d95a033e 2020-09-16 2020-09-21 4d  调试大数据程序,解决报错、 部署、 配置文件、 入库过程中出现打问题


task 4 edit    # 编辑 ID 为 4 的任务


task 3-4 modify project:'Charging Pile' # 修改任务, 设置项目名

Modifying task 3 '解决配置参数导致的任务没有序列化问题'.
Modifying task 4 '和后端联调测试, 程序优化'.
Modified 2 tasks.


task 3 modify '修改任务描述信息' # 修改任务的描述信息
task 3 modify +pile           # 给任务添加标签
task 3 modify +charge         # 可以添加多个标签
task 3 modify -pile           # 移除任务的标签

task 1-4 long # 显示前4个任务的任务详情
task long     # 显示所有任务的任务详情


task diagnostics    # 平台、构建和环境详情

task burndown.daily   # 按天的任务燃尽图
task burndown.weekly  # 按周的任务燃尽图
task burndown.monthly # 按月的任务燃尽图

task export  # 导出任务为 JSON 格式

task 1 start          # 将指定任务标记为已启动
task +LATEST start    # 使用虚拟标签过滤任务并将其标记为已启动 

task 1 modify scheduled:2020-09-24 # 设置ID编号为1的任务在 2020-09-24 开始
```