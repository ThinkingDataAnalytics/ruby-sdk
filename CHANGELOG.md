**1.2.0** (2020/08/28)
- 新增track_update接口，支持可更新事件
- 新增track_overwrite接口，支持可重写事件

**v1.1.0** (2020/02/11)
- 数据类型支持array类型
- 新增 user_append 接口，支持用户的数组类型的属性追加
- BatchConsumer 性能优化：支持选择是否压缩；移除 Base64 编码
- DebugConsumer 优化: 在服务端对数据进行更完备准确地校验

**v1.0.0** (2019-11-20)
- 支持三种模式的上报: DebugConsumer, BatchConsumer, LoggerConsumer.
- 支持事件上报和用户属性上报.
- 支持公共事件属性.
