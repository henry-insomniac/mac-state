# mac-state 文档

本目录用于沉淀 `mac-state` 的产品分析、技术方案和实施计划。

当前文档：

- `product-analysis-and-technical-plan.md`
  - 对标 `iStatistica Pro` 的功能拆解
  - 产品目标、范围边界、兼容策略
  - 面向 `macOS 11+`、`Intel + Apple Silicon` 的技术方案
- `implementation-roadmap.md`
  - 功能优先级矩阵
  - 模块划分与目录建议
  - 里程碑计划、测试策略和风险清单
- `xcode-project-structure-and-bootstrap.md`
  - Xcode 工程组织方式
  - target 划分与依赖关系
  - 首批模块骨架与初始化落地顺序

适用前提：

- 主线目标平台为 `macOS 11.0+`
- 构建产物为 `Universal 2`（`arm64 + x86_64`）
- 以菜单栏常驻原生 App 为核心形态
