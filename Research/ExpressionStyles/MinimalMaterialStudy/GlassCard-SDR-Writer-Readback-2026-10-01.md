# GlassCard 实际 writer 色彩与metadata回读

Engineering Loop，P2研究验证。证据：显式sRGB compositor和裸PNG回读通过，但生产writer从sourceProperties拷贝清理，仅覆盖尺寸/方向/描述等指定字段。需验证source profile/EXIF ColorSpace与输出sRGB的关系，而非直接更换生产行为。

范围：受控bright-checker、compatible1.4、c=0.12、white0.96，640×360，同源的ink/backing经显式sRGB合成后调用实际MetadataPreservingImageWriter输出PNG/JPEG/HEIC。传入合成属性含旧尺寸/方向6、Display P3 profile name、EXIF uncalibrated65535、固定拍摄日期、合成GPS与曝光。无私人照片、网络、Photos或原始文件写入。

验证：ImageIO回读实际像素空间/标签/尺寸/方向/EXIF/GPS/描述，PNG字节对照、有损编码误差及同坐标核心文字对比。Metadata关键项先记录各格式表现，发现冲突后才根据实际证据制定P1修正。缺失方向按ImageIO默认up解释但报告缺失；不得把缺失字段说成已保留。JPEG/HEIC不强求逐字节一致。输出端类型支持先确认。使用macOS原生测试build，不代替iPhone/Photos/HDR/Live Photo。

## 首轮实际编码结果

3格式×4slot=12行，ink/backing分别经同一writer编码后回读，在原始字形mask90%核心位置比较。不是对压缩后mask重新选择像素，也不把压缩误差强行归零。

| 格式 | 原始最低 | 回读最低 | 回读最低P10 | 最大RGBA字节差 | 平均RGBA字节差 |
|---|---:|---:|---:|---:|---:|
| PNG | 5.242463 | 5.242463 | 5.630943 | 0 | 0 |
| JPEG | 5.242463 | 5.008320 | 5.581445 | 10 | 0.043223 |
| HEIC | 5.242463 | 5.054620 | 5.581445 | 8 | 0.033314 |

字节差由解码图与原始输出经同一sRGB RGBA读取后比较，平均包括alpha；是该受控棋盘/小画布的误差，不是任意彩色照片质量预算。640×360有自己的字形采样，不能直接等同1080/1920结果。

三个格式的decodedColorSpace均kCGColorSpaceSRGB，profileName均sRGB IEC61966-2.1，方向1、输出640×360。EXIF原始时间2001:02:03 04:05:06、曝光0.01、光圈2.8，合成GPS22.5/113.9以及描述/UserComment在三格式均回读到。PNG/JPEG的EXIF ColorSpace=1；HEIC=65535。不能只按这一个数值判定HEIC像素丢失或错误染色；需与解码空间/ICC综合区分。

首次probe实际执行1项通过：`/tmp/MemoMarkGlassWriter.xcresult`。后续增加profile/time/GPS断言及仅改变EXIF色彩来源值的彩色控制。未修改生产writer。

## 继承色彩标签控制与处理决定

仅改变来源EXIF ColorSpace=1/65535，其余保持同一显式sRGB彩色栅格，三格式共6行：PNG/JPEG始终输出1，HEIC保留输入值。全部decodedColorSpace=sRGB、profileName=sRGB IEC61966-2.1。这确认HEIC标签继承差异；本轮没有证据证明ICC解码错色，不据此修改全局writer。新源响应材质最终接入规范须明确输出颜色标签由实际输出空间派生，不能把源属性拷贝当作新输出色彩契约；此规范尚未接入生产。

受控源properties里的Display P3名字在三格式均没有把输出改标为P3；该控制只是名字与EXIF数值，不含真实P3文件的完整ICC/XMP/auxiliary资源，不能认证真实广色域或HDR文件的处理。metadata回读仅核查所列字段；拍摄时区/subsec、厂商私有字段、Live Photo pairing清理、48MP内存、文件时间和完整metadata不在本轮证据内。

## 验证闭环

增强profile/time/GPS断言后，`/tmp/MemoMarkGlassWriterControls.xcresult`实际执行2项通过，0失败/跳过，app/test build完成；初轮1项通过记录保留。分析器验证12行及唯一slot键，另6行色彩标签控制本地保存；临时3个测试文件与研究源比对后移除，`git diff --check`通过。输出附件在 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRWriterReadback/`；writer-sdr.jpeg为导出的JPEG附件名。原测试临时输出目录清理，无私人输入或上传。

本片生产源码/默认未改、未提交或推送，无新iPhone/Photos/HDR/Live Photo认证。下一步收敛共享研究material adapter与显式输出颜色metadata策略，再将真实输出尺寸/缩放检查复用于编码回读图；不能因小受控样本通过直接开放Release authoring。
