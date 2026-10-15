# GlassCard 研究源码与复现边界

本目录保存 GlassCard 材质、尺寸、容器及元数据实验的 Swift 探针和 Python 分析/测试源码。源码随完整项目同步，但不并入 MemoMark App target，不引入生产依赖，也不改变生产 Layout、Renderer 或媒体行为。

各研究记录说明当时的编译/测试环境、临时 Swift Testing 注入方式与附件名称；不要把所有独立 probe 同时加入正式测试 target（可能存在实验类型重名及历史 API 假设）。探针历史运行通过不代表所有 probe 在最新生产 API 上重新 typecheck 或获得媒体生产认证。

Python 分析脚本通常接收合成 fixture 或 XCTest 导出附件目录。缺少原始产物时，不能宣称完成同一实验；私人照片与原始设备附件不随 GitHub 发布。无需 fixture 的 HEIC 引用单元测试可在本目录运行：

```sh
python3 -m unittest -v test_glasscard_heic_references
```

其余 test_glasscard_container_inspector.py / test_glasscard_fixture_repair.py 需首个位置参数传入对应 fixture 根目录，按同名研究记录生成，不能用自动发现跳过输入要求。Python 源码可以先使用 py_compile 检查语法，Swift probe 可逐文件 parse；这些检查均不替代实验所需的生成/回读或真实 PhotoKit 验收。
