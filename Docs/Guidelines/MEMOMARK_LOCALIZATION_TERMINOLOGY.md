# MemoMark Localization Terminology

Status: Phase 4A working terminology baseline

This table is the shared vocabulary for the main App UI, Settings,
Configuration Center, diagnostics, and future Share/Widget/macOS surfaces. It
does not change the semantic names used by the Memory Engine or the persisted
coding model. User-facing copy should use these terms consistently unless a
sentence requires a natural grammatical form.

| Concept | 简体中文 | English | 日本語 | 한국어 |
| --- | --- | --- | --- | --- |
| Memory | 记忆 | Memory | 思い出 | 추억 |
| Memory Subject | 记忆对象 | Memory Subject | メモリー対象 | 추억 대상 |
| Time Anchor | 时间锚点 | Time Anchor | タイムアンカー | 시간 앵커 |
| Configuration | 配置 | Configuration | 設定 | 구성 |
| Preset | 预设 | Preset | プリセット | 프리셋 |
| Expression | 表达 | Expression | 表現 | 표현 |
| Output | 输出 | Output | 出力 | 출력 |
| Output Language | 输出语言 | Output Language | 出力言語 | 출력 언어 |
| Interface Language | 应用界面语言 | Interface Language | アプリの表示言語 | 앱 인터페이스 언어 |
| Memory Card | 记忆卡片 | Memory Card | メモリーカード | 메모리 카드 |
| Share | 分享 | Share | 共有 | 공유 |
| Processing | 处理 | Processing | 処理 | 처리 |
| Album | 相册 | Album | アルバム | 앨범 |
| Photo | 照片 | Photo | 写真 | 사진 |
| Live Photo | Live Photo | Live Photo | Live Photo | Live Photo |
| Renderer | Renderer | Renderer | Renderer | Renderer |
| Apple Photos | Apple Photos | Apple Photos | Apple Photos | Apple Photos |

## Usage rules

- `Preset` is the user-facing term. Do not introduce `Template` in new UI
  copy, even though the internal model may continue to use `Template`.
- `Memory Subject` describes the person or relationship around which a memory
  is expressed. It is not a generic contact or photo owner.
- `Time Anchor` describes the important date or life event. It is not a
  generic timestamp.
- `Expression` describes how the memory is worded or presented. It is not a
  translation of the user's own text.
- `Output Language` controls generated memory/date expressions in a Preset.
  `Interface Language` controls the App UI. The two must not be substituted.
- Japanese and Korean copy may change word order for natural grammar, but the
  concept mapping must remain stable across screens.
