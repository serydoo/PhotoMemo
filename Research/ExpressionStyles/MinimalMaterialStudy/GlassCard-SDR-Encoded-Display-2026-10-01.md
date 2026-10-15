# GlassCard SDR 最终编码图显示缩放研究

Engineering Loop，P2，使用共享adapter和实际writer，不修改生产默认。前片已闭合受控sRGB编码/metadata回读，但原尺寸核心对比不能代替小屏采样。固定1920×1080、compatible1.4、bright-checker、panelH×0.025/c0.12/white0.96，H与相伴365天两组文本。源先通过ImageIO准备，adapter生成完整输出，再PNG/JPEG/HEIC保存回读；未编码栅格作独立对照。

矩阵：2文本×4格式(含native)×360/600显示宽×1x/3x×4位置=128行。CG高质量插值缩放完整输出与同坐标无字背景；未压缩透明字形mask使用同一缩放，90%核心对比、P10、缺失、alpha总量及逻辑字号一起记录。未命中核心记NA，不记通过。mask插值可能过冲，不当精确覆盖率；1x为诊断、3x非UIKit/Photos采样认证。alpha总量/density²为采样指标，不是物理墨迹面积。

职责：Layout仍拥有几何，研究compatible plan保持既有水平空间；adapter处理材质，writer处理编码。无复杂私照、Photos、设备或HDR输入，不能外推任意照片可读性/色彩质量/性能。通过macOS实际测试build、CSV完整性和NA一致性校验后保存证据并移除临时副本。

## 逐层控制结果

初轮128行：360宽3x所有格式8组均有核心，native/PNG最低5.148、JPEG/HEIC5.101；360宽1x各有5/8组缺核心，NA不视为通过。主/次逻辑字号为6.811/5.174；600宽为11.351/8.624，不随density增长。

JPEG直接ImageIO图绘制至600宽1x，最低4.096/P10 4.345，6/8组低于4.5；PNG/HEIC同设置约5.101。增加JPEG quality0.9/1.0后192行控制：600宽1x最低仍4.096，0.9有5/8组低于4.5，1.0为6/8；360宽1x quality0.9最低4.473且5/8缺核心。这不支持把高质量参数当作通用修复。质量并非实际App配置变更，源属性中仅加入ImageIO质量选项。

完整分辨率栅格控制扩展到224行：先把默认JPEG解码图绘制成1920×1080 sRGB CG bitmap，再做同样displayResize，600宽1x最低恢复5.101、0/8低于4.5；360宽1x恢复5.148但5/8仍无核心。两条JPEG路径在360/600宽3x最低分别5.101/4.962，相同。观察只定位到ImageIO图→CG绘制/缩放组合，不宣称已定位内部DCT/解码器原因，也不证明UIKit/Photos相同。

最终控制复用已生成的同一个JPEG文件，不再次编码raster分支，避免编码差异混入。后续定量对比需将各编码图先完整栅格化到明确sRGB，再以同一采样器缩放；direct ImageIO draw保留为独立诊断，不能混作纯材质对比。完整栅格化增加内存，不据此要求production无条件full decode。

透明mask参考来自未编码字形；每个格式的sampledInkMass相同是控制定义，不能证明有损编码保留笔画。核心对比才来自各格式ink/backing实际回读。mask high插值/归一alpha可过冲，未当精确物理覆盖率。目标高度按整数取整，输出不保证原比例数学上完全相等；mask/front/back使用同目标尺寸。

## 研究决定

保留c=0.12共享SDR候选，拒绝因1x直接JPEG路径的下降而加深材质或直接提高默认JPEG质量。3x受控编码采样支持继续研究；逻辑字体小和实际复杂照片阅读问题仍未闭合，不开启Release入口、不认定全局可读性或iPhone验收通过。下一片应整理研究规格/验证清单与可复用测量路径，之后以真实设备的实际展示和Photos回读取得产品判断；大图内存/取消/线程处理仍独立推进。

## 最终验证闭环

`/tmp/MemoMarkGlassEncodedDisplayFinal.xcresult` targeted probe实际执行1项通过、0失败/跳过，app/test build完成；224行含相同JPEG文件复用控制，首轮128行与最终对应记录全字段相等。分析器确认唯一键、NA/核心缺失一致、native/PNG各记录相等。中间128/192/224控制各实际1项通过；初轮probe编译因pointSize字段命名修正后通过，保留日志。

最终xcresult记录一条runtime QoS priority inversion警告，来源指向研究probe，未定位到具体CI/CG/writer调用；不把测试通过当作线程/性能门槛闭合。当前测试MainActor同步处理为研究，下一Engineering slice应明确非UI像素/编码阶段、取消/内存与UI绘制边界后再评估。

5个临时测试文件与保留研究源比对后移除，`git diff --check`通过。完整最终证据在 `$HOME/Documents/Codex/2026-10-01/GlassCardSDREncodedDisplayFinal/`；128/192/首次224的独立目录保留。本片没有新iOS编译/真机/Photos或HDR/Live Photo验收，生产默认/编码参数未变，未提交/推送。
