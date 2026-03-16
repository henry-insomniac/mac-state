# mac-state 产品分析与技术方案

更新日期：`2026-03-16`

## 1. 项目目标

`mac-state` 的目标不是做一个功能堆砌型的系统信息工具，而是做一个：

- 原生 `macOS` 菜单栏应用
- 常驻但低资源占用
- 小巧、秒开、交互顺滑
- 对开发者和普通用户都足够直观的状态监测工具

目标体验应更接近：

- 菜单栏一眼可读
- 点击后信息密度高但不拥挤
- 采样稳定、历史趋势可信
- 告警有用但不打扰

## 2. 对标产品拆解：iStatistica Pro

根据公开信息，`iStatistica Pro` 的核心能力可拆为以下几类：

### 2.1 核心系统监控

- CPU 总体占用
- 每核心 CPU 使用率
- 内存使用情况
- 磁盘容量和可用空间
- 网络上传/下载速率
- 电池信息
- 当前运行应用列表与资源占用

### 2.2 菜单栏与桌面展示

- 菜单栏实时指标
- 下拉面板/详情页
- Widget / 小组件

### 2.3 历史与输出

- 历史趋势图
- 资源使用统计
- 数据导出

### 2.4 自动化与通知

- 阈值告警
- 本地通知
- 部分自动化动作

### 2.5 深层硬件能力

- 传感器温度
- 风扇转速
- 部分磁盘 I/O 和更底层硬件指标

这部分在 `iStatistica Pro` 中是通过独立 Sensors 插件提供的。对我们来说，这说明产品架构不应该把所有能力都硬塞进主 App。

## 3. 我们的产品定位

`mac-state` 应该先做一款“非常好用的轻量原生监测工具”，而不是第一版就追求功能表面对齐。

第一阶段真正决定产品价值的能力是：

- 菜单栏信息表达
- 高质量弹出面板
- 核心指标稳定采集
- 历史趋势
- 通知规则
- 极低常驻占用

如果这些做不好，即使加上更多传感器数据，也很难替代成熟工具。

## 4. 平台与兼容约束

### 4.1 目标平台

- 主线目标平台：`macOS 11.0+`
- CPU 架构：`Intel x86_64` + `Apple Silicon arm64`
- 构建形式：`Universal 2`

### 4.2 为什么最低版本建议是 macOS 11

如果要同时支持 `Intel` 和 `Apple Silicon`，主线最低版本应该定在 `macOS 11.0`：

- `Apple Silicon` Mac 的统一兼容基线从 `macOS 11` 开始
- 这能避免在 `10.15` 及更早系统上为旧 API 和旧行为额外维护一套主线逻辑

结论：

- `macOS 11+` 作为主线
- 如未来确有业务必要，再单独维护 `10.15` 的 legacy 支线

### 4.3 兼容设计原则

- 不依赖只在 `macOS 13+` 才成熟可用的新主壳 API
- 壳层采用 `AppKit`
- 内容视图可以使用 `SwiftUI`
- 所有深层硬件能力必须允许“按系统版本、按芯片、按机型降级”

## 5. 功能范围建议

### 5.1 P0：MVP 必做

- 菜单栏常驻入口
- CPU 总体与每核心监控
- 内存已用、缓存、压力等级
- 磁盘空间概览
- 网络实时上下行速率
- 电池状态与健康信息基础展示
- 当前运行应用列表
- 历史短期趋势图
- 阈值告警
- 登录启动
- 设置页

### 5.2 P1：高价值增强

- 每应用 CPU / 内存趋势
- 更完整的网络接口信息
- 磁盘挂载与外接卷状态
- 数据导出（如 CSV）
- Widget
- 更完整的告警规则和冷却时间控制

### 5.3 P2：深层硬件能力

- 温度传感器
- 风扇转速
- 磁盘 I/O 速率
- 更细粒度 GPU 数据

### 5.4 P3：可选扩展

- 只读本地 API
- Web 仪表盘
- Shell / Shortcuts 集成
- 蓝牙设备电量等外围状态

## 6. 技术选型

### 6.1 总体建议

- 语言：`Swift 6`
- UI：`SwiftUI + AppKit` 混合
- 图表：优先自绘轻量图表，避免过重依赖
- 存储：`SQLite`
- 并发：`Swift Concurrency` + `actor`

### 6.2 为什么不用纯 SwiftUI 做外壳

如果要兼容旧版 `macOS` 并保证菜单栏交互质量，主壳应优先使用：

- `NSStatusItem`
- `NSPopover` 或 `NSPanel`
- `NSHostingController`

原因：

- 兼容性更稳
- 对菜单栏行为控制更细
- 对焦点、窗口尺寸、悬浮和快捷键支持更容易做扎实

## 7. 推荐架构

建议采用分层架构：

### 7.1 App Shell

负责：

- 状态栏图标与文本
- 弹出面板
- 设置窗口
- 生命周期管理
- 启动项管理

建议技术：

- `NSApplication`
- `NSStatusItem`
- `NSPopover`
- `NSWindowController`

### 7.2 Metrics Core

负责：

- 指标采样
- 数据标准化
- 时间序列缓存
- 历史落盘
- 告警计算

建议能力：

- 不直接依赖 UI
- 所有采样模块都暴露统一协议
- 支持按需启停

### 7.3 Feature Modules

建议拆为：

- `CPU`
- `Memory`
- `Disk`
- `Network`
- `Battery`
- `Processes`
- `Sensors`
- `Alerts`
- `Widgets`

### 7.4 Persistence

负责：

- 最近一段时间的高频历史
- 降采样后的长期历史
- 用户配置
- 面板布局配置
- 告警规则配置

### 7.5 Optional Helpers

后续可选：

- `LoginHelper`
- `SensorBridge`

其中：

- `LoginHelper` 解决旧版系统登录启动兼容
- `SensorBridge` 负责深层硬件访问，允许单独演进

## 8. 指标采集方案

### 8.1 CPU

目标：

- 总 CPU 占用
- 用户态 / 系统态占比
- 每核心占用
- 平均负载趋势

建议来源：

- `host_statistics`
- `processor_info`

设计要求：

- 通过两次采样差值计算使用率
- 打开主面板时提高刷新率
- 面板关闭时降频

### 8.2 Memory

目标：

- 已用内存
- 空闲内存
- 缓存/压缩
- 内存压力

建议来源：

- `host_statistics64`
- `vm_statistics64`
- `ProcessInfo.physicalMemory`

### 8.3 Disk

目标：

- 各卷总容量、可用容量
- 外接卷状态
- 磁盘使用率可视化

建议来源：

- `FileManager`
- `URLResourceValues`
- `DiskArbitration`

### 8.4 Network

目标：

- 总上传/下载速率
- 各接口速率
- IP 信息
- 接口上下线状态

建议来源：

- `getifaddrs`
- 接口字节计数差分
- `NWPathMonitor` 作为连通性补充

### 8.5 Battery

目标：

- 当前电量
- 充电状态
- 剩余时间估算
- 电池健康基础信息

建议来源：

- `IOPowerSources`

### 8.6 Processes

目标：

- 运行中应用
- 每应用 CPU / 内存
- 排序与筛选

建议来源：

- `NSWorkspace`
- `libproc`
- `proc_pid_rusage`

### 8.7 Sensors

这一层不要在 V1 承诺完全一致能力。

原因：

- 旧版系统与新版系统行为不完全一致
- `Intel` 与 `Apple Silicon` 获取路径可能不同
- 某些指标缺乏稳定统一的公开 API

建议抽象成：

- `SensorProvider`
- `IntelSensorProvider`
- `AppleSiliconSensorProvider`
- `NoopSensorProvider`

对 UI 来说，传感器模块只消费统一模型，不感知底层差异。

## 9. 交互与体验方案

### 9.1 菜单栏策略

菜单栏不是越多越好，应控制为：

- 默认显示 1 到 2 个关键指标
- 允许用户在 CPU / 内存 / 网络 / 电池中切换
- 文本宽度稳定，减少跳动

建议默认：

- 仅图标
- 图标 + 单一主指标
- 紧凑双指标模式

### 9.2 弹出面板

建议面板结构：

- 顶部：系统总览摘要
- 中部：核心模块卡片
- 底部：最近告警 / 快捷入口

设计原则：

- 支持键盘导航
- 默认信息密度高但不压迫
- 图表采用 30 分钟 / 6 小时 / 24 小时切换

### 9.3 低功耗策略

- 菜单栏关闭详情时低频采样
- 打开面板后提升刷新率
- 图表仅重绘变化区域
- 历史数据异步批量落盘

## 10. 启动与后台策略

建议做兼容层：

- `macOS 11-12`：通过 `SMLoginItemSetEnabled` + helper
- `macOS 13+`：通过 `SMAppService`

不要把登录启动逻辑写死在单一新 API 上，否则会直接抬高最低系统要求。

## 11. 数据存储方案

建议将数据分为三类：

### 11.1 配置数据

- 用户偏好
- 菜单栏展示项
- 告警规则
- 窗口状态

适合：

- `UserDefaults`
- 小型配置文件

### 11.2 高频历史数据

- 秒级或数秒级采样结果

适合：

- 内存环形缓冲
- 定时批量写入 `SQLite`

### 11.3 长期历史

- 经过降采样后的分钟级、小时级聚合

适合：

- `SQLite`
- 按模块分表

## 12. 构建与发布策略

### 12.1 建议主线发布方式

建议优先考虑：

- 官网分发 + notarization
- 或主 App 上架，深层能力通过独立 helper 提供

不建议第一阶段就把自己限制在“纯 App Store 且完整传感器能力必须全部可用”的目标上。

### 12.2 架构要求

所有目标都应支持：

- `arm64`
- `x86_64`

包括：

- 主 App
- Login Helper
- 后续 Sensor Helper

## 13. 风险与决策点

### 13.1 最大技术风险

- 传感器能力跨机型稳定性
- 旧版系统行为差异
- Intel 老机器上的常驻性能表现
- 历史采样频率与功耗之间的平衡

### 13.2 必须尽早确认的决策

- 是否把 `macOS 10.15` 明确排除在主线之外
- 是否接受“深层传感器能力后置”
- 是否以官网分发为主
- 是否第一版就做 Widget

## 14. 当前建议结论

推荐当前项目采用以下路线：

- 主线面向 `macOS 11.0+`
- 输出 `Universal 2`
- `AppKit` 做菜单栏壳层
- `SwiftUI` 做内容界面
- 核心能力先覆盖 CPU / 内存 / 磁盘 / 网络 / 电池 / 进程 / 历史 / 告警
- 深层传感器通过独立模块和降级策略后置实现

这条路线最符合以下目标：

- 原生体验
- 兼容旧版系统
- 兼容 Intel 与 M 芯片
- 低资源占用
- 未来仍能向完整监控产品扩展

## 15. 参考资料

- iStatistica Pro App Store
  - <https://apps.apple.com/us/app/istatistica-pro/id1447778660>
- iStatistica Pro 官方站
  - <https://www.imagetasks.com/istatistica/pro/>
- Apple: Porting your macOS apps to Apple silicon
  - <https://developer.apple.com/documentation/apple-silicon/porting-your-macos-apps-to-apple-silicon>
- Apple: Supporting universal binaries
  - <https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary>
- Apple: NSStatusBar / NSStatusItem
  - <https://developer.apple.com/documentation/appkit/nsstatusbar>
- Apple: WidgetKit
  - <https://developer.apple.com/documentation/widgetkit>
- Apple: SMAppService
  - <https://developer.apple.com/documentation/servicemanagement/smappservice/loginitem%28identifier%3A%29>
- Apple: IOPowerSources
  - <https://developer.apple.com/documentation/iokit/iopowersources_h>
