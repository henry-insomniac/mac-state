# mac-state Xcode 工程结构与初始化方案

更新日期：`2026-03-16`

## 1. 目标

这份文档用于回答三个问题：

- Xcode 工程应该怎么组织
- target 应该怎么拆，哪些现在就建，哪些后置
- 第一批代码骨架应该怎么落，避免后面返工

项目约束：

- 平台：`macOS 11.0+`
- 架构：`Universal 2`（`arm64 + x86_64`）
- 形态：菜单栏原生 App
- 主线分发：优先按官网分发 / notarization 设计

## 2. 工程组织建议

不建议一开始上复杂生成工具。第一阶段建议：

- 直接使用 `Xcode workspace + xcodeproj`
- 公共能力放到本地 `Swift Package`
- 主业务仍由 `macOS app target` 承载

原因：

- 初始心智成本低
- 调试链路简单
- 对多 target 和多架构支持更直接
- 后续如果需要，再切到 `Tuist` 或其他工程生成方案也不晚

## 3. 推荐工程结构

```text
mac-state/
  docs/
  MacState.xcworkspace
  App/
    MacStateApp.xcodeproj
    MacStateApp/
      App/
      Bootstrap/
      Shell/
      Features/
      Resources/
      Config/
    MacStateLoginHelper/
      App/
      Resources/
      Config/
    MacStateWidgetExtension/
      Timeline/
      Views/
      Resources/
    MacStateAppTests/
    MacStateAppUITests/
  Packages/
    MacStateFoundation/
      Package.swift
      Sources/
      Tests/
    MacStateMetrics/
      Package.swift
      Sources/
      Tests/
    MacStateStorage/
      Package.swift
      Sources/
      Tests/
    MacStateUI/
      Package.swift
      Sources/
      Tests/
  Tools/
  Scripts/
```

说明：

- `App/` 只放 Xcode targets
- `Packages/` 放可复用核心模块
- `docs/` 放方案与决策
- `Tools/` 和 `Scripts/` 先预留，不急着填内容

## 4. Target 划分

### 4.1 第一阶段必须创建的 target

| Target | 类型 | 是否首批创建 | 作用 |
| --- | --- | --- | --- |
| `MacStateApp` | macOS App | 是 | 主应用，菜单栏入口和全部主逻辑装配 |
| `MacStateAppTests` | Unit Test Bundle | 是 | App 装配层和轻量集成测试 |
| `MacStateAppUITests` | UI Test Bundle | 是 | 菜单栏基础交互和关键流程 UI 测试 |
| `MacStateLoginHelper` | Login Item Helper | 是 | 用于 `macOS 11-12` 登录启动兼容 |

### 4.2 第二阶段创建的 target

| Target | 类型 | 创建时机 | 作用 |
| --- | --- | --- | --- |
| `MacStateWidgetExtension` | Widget Extension | 阶段 B | Widget 和通知中心展示 |
| `MacStateSensorBridge` | Helper / XPC / Agent | 阶段 C | 深层传感器和更底层硬件能力 |

结论：

- `LoginHelper` 需要第一天就纳入工程设计
- `WidgetExtension` 和 `SensorBridge` 不要在 M1 之前创建真实 target
- 但要在包和接口层预留抽象边界

## 5. 本地 Swift Package 划分

### 5.1 `MacStateFoundation`

职责：

- 基础类型
- 日志
- 错误定义
- 平台能力探测
- 版本兼容工具
- 共享常量

不应承载：

- 具体采样逻辑
- 具体 UI

### 5.2 `MacStateMetrics`

职责：

- 各类 sampler
- 采样调度
- 实时 snapshot
- capability 感知
- 告警计算核心

建议包含模块：

- `CPU`
- `Memory`
- `Disk`
- `Network`
- `Battery`
- `Processes`
- `Alerts`

### 5.3 `MacStateStorage`

职责：

- `SQLite` 历史存储
- `UserDefaults` / 配置持久化
- App Group 共享快照
- 迁移逻辑

### 5.4 `MacStateUI`

职责：

- 可复用卡片组件
- 图表组件
- 主题与配色
- 空状态 / 错误状态组件

建议：

- 只放“通用 UI”
- 业务页组合仍先放在 `MacStateApp` target 里

这是为了避免一开始就把 Feature 包拆得过细。

## 6. Target 与 Package 依赖关系

建议依赖图：

```text
MacStateApp
  -> MacStateFoundation
  -> MacStateMetrics
  -> MacStateStorage
  -> MacStateUI

MacStateLoginHelper
  -> MacStateFoundation

MacStateWidgetExtension
  -> MacStateFoundation
  -> MacStateStorage
  -> MacStateUI

MacStateSensorBridge
  -> MacStateFoundation
  -> MacStateMetrics
```

原则：

- `MacStateMetrics` 不能依赖 `MacStateUI`
- `MacStateStorage` 不能依赖 App target
- Widget 不直接依赖在线采样器，而是读共享快照 / 历史缓存

## 7. 主 App 内部目录设计

`MacStateApp` target 内建议按下面方式组织：

```text
MacStateApp/
  App/
    MacStateApp.swift
    AppDelegate.swift
    AppEnvironment.swift
  Bootstrap/
    AppAssembler.swift
    DependencyContainer.swift
    BuildConfiguration.swift
  Shell/
    StatusItemController.swift
    PopoverController.swift
    WindowRouter.swift
    MenuBarPresentationModel.swift
  Features/
    Dashboard/
    CPU/
    Memory/
    Disk/
    Network/
    Battery/
    Processes/
    Alerts/
    Settings/
  Resources/
    Assets.xcassets
    Localizable.strings
  Config/
    Debug.xcconfig
    Release.xcconfig
    MacStateApp.entitlements
    Info.plist
```

说明：

- `Shell/` 只做菜单栏与窗口行为
- `Bootstrap/` 只做依赖装配
- `Features/` 里每个业务模块各自维护 View / ViewModel / Mapper

## 8. 首批模块骨架

### 8.1 App Shell

首批必须落下的文件：

- `MacStateApp.swift`
- `AppDelegate.swift`
- `AppAssembler.swift`
- `DependencyContainer.swift`
- `StatusItemController.swift`
- `PopoverController.swift`
- `WindowRouter.swift`

职责边界：

- `AppDelegate` 只处理生命周期和系统事件
- `StatusItemController` 只负责状态栏项
- `PopoverController` 只负责弹出面板生命周期
- `WindowRouter` 只负责设置页 / 独立窗口
- `AppAssembler` 负责把 Service、Store、ViewModel 装起来

### 8.2 Compatibility

建议在 `MacStateFoundation` 中建立：

- `PlatformCapabilities.swift`
- `SystemVersion.swift`
- `LaunchAtLoginService.swift`
- `ArchitectureSupport.swift`

建议接口：

```swift
public protocol LaunchAtLoginService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
```

再分别提供：

- `LegacyLaunchAtLoginService`
- `ModernLaunchAtLoginService`

这样业务层不需要到处写 `#available`。

### 8.3 Metrics

建议在 `MacStateMetrics` 中建立：

- `MetricSnapshot.swift`
- `MetricSampler.swift`
- `SamplerScheduler.swift`
- `MetricsPipeline.swift`
- `MetricsStore.swift`

然后按模块扩展：

- `CPU/CPUSampler.swift`
- `Memory/MemorySampler.swift`
- `Disk/DiskSampler.swift`
- `Network/NetworkSampler.swift`
- `Battery/BatterySampler.swift`
- `Processes/ProcessSampler.swift`

建议协议：

```swift
public protocol MetricSampler: Sendable {
    associatedtype Output: Sendable
    func sample() async throws -> Output
}
```

建议第一版采用：

- 总线式 `MetricsPipeline`
- 各模块独立采样
- UI 只订阅统一的 `MetricSnapshot`

### 8.4 Storage

建议在 `MacStateStorage` 中建立：

- `SettingsStore.swift`
- `HistoryStore.swift`
- `SharedSnapshotStore.swift`
- `SQLiteMigrator.swift`

这里有一个关键决策：

- Widget 和主 App 未来都需要共享数据
- 所以第一天就应该预留 `App Group` 容器

### 8.5 UI

建议在 `MacStateUI` 中建立：

- `MetricCard.swift`
- `MiniLineChart.swift`
- `SectionHeader.swift`
- `EmptyStateView.swift`
- `Theme.swift`
- `Spacing.swift`

注意：

- `MacStateUI` 只做通用组件
- `DashboardView` 这类页面级 View 仍放在 App target

## 9. App Group 与共享数据

建议在工程初始化时就定下来：

- App Group ID：例如 `group.com.yourcompany.macstate`

用途：

- Widget 读取最近一次快照
- 主 App 与未来 helper 共享基础配置
- 共享历史聚合结果

不建议等 Widget 开发时再补这个配置，因为那时会牵扯数据路径迁移。

## 10. Entitlements 与配置建议

### 10.1 `MacStateApp`

建议：

- `LSUIElement = YES`
- 隐藏 Dock 图标
- Debug 模式可考虑加一个可切换开关，便于开发时显示主窗口

### 10.2 登录启动

`macOS 11-12`：

- 使用 `LoginHelper`
- 由主 App 通过兼容服务控制启用状态

`macOS 13+`：

- 保留抽象层
- 可切换到现代 ServiceManagement 路径

### 10.3 App Sandbox

当前建议：

- 主线如果按官网分发和 notarization 走，第一阶段不以 App Store 沙箱为前提设计
- 如未来要上架，再单独评估 MAS 变体所需 entitlements

原因：

- 这样更有利于后续进程监控和深层硬件扩展
- 也更贴近产品目标

## 11. Build Config 建议

建议至少保留：

- `Debug`
- `Release`

可以额外预留：

- `Internal`

用途：

- 打开更详细日志
- 启用诊断面板
- 允许显示 Dock 图标
- 打开实验性模块

## 12. 第一批实际要创建的文件清单

如果现在进入工程初始化，建议第一批真实创建这些文件：

```text
App/MacStateApp/MacStateApp/App/MacStateApp.swift
App/MacStateApp/MacStateApp/App/AppDelegate.swift
App/MacStateApp/MacStateApp/Bootstrap/AppAssembler.swift
App/MacStateApp/MacStateApp/Bootstrap/DependencyContainer.swift
App/MacStateApp/MacStateApp/Shell/StatusItemController.swift
App/MacStateApp/MacStateApp/Shell/PopoverController.swift
App/MacStateApp/MacStateApp/Shell/WindowRouter.swift
Packages/MacStateFoundation/Sources/MacStateFoundation/PlatformCapabilities.swift
Packages/MacStateFoundation/Sources/MacStateFoundation/LaunchAtLoginService.swift
Packages/MacStateMetrics/Sources/MacStateMetrics/MetricSnapshot.swift
Packages/MacStateMetrics/Sources/MacStateMetrics/MetricSampler.swift
Packages/MacStateMetrics/Sources/MacStateMetrics/SamplerScheduler.swift
Packages/MacStateStorage/Sources/MacStateStorage/SettingsStore.swift
Packages/MacStateUI/Sources/MacStateUI/MetricCard.swift
Packages/MacStateUI/Sources/MacStateUI/MiniLineChart.swift
```

这批文件足够把工程“立起来”，但还不会过早进入功能细节。

## 13. 初始化顺序建议

建议按下面顺序落地：

### Step 1

- 建立 workspace
- 建立 `MacStateApp` 和 `MacStateLoginHelper`
- 建立 4 个本地 packages

### Step 2

- 跑通菜单栏空壳
- 跑通弹出面板
- 接入依赖装配

### Step 3

- 接入 CPU / Memory / Network 三个核心 sampler
- 先用 mock 数据跑完 UI，再切真数据

### Step 4

- 加入 `SettingsStore`
- 加入历史快照缓存
- 加入告警骨架

### Step 5

- 做 `macOS 11-12` 登录启动兼容
- 再扩展到 Widget 和更多模块

## 14. 不建议的做法

- 不要一开始就上过多 Feature Package
- 不要第一天就把 `SensorBridge` 建成复杂多进程系统
- 不要让 Widget 直接依赖在线采样器
- 不要在 View 层直接访问系统 API
- 不要在多个模块里散落 `#available` 判断

## 15. 当前推荐结论

当前最合适的启动方式是：

- 用 `Xcode workspace` 做宿主
- 创建 `MacStateApp + MacStateLoginHelper`
- 建立 `MacStateFoundation / MacStateMetrics / MacStateStorage / MacStateUI` 四个本地包
- 主 App 只负责装配、菜单栏和页面组合
- 指标采样、存储、兼容逻辑全部下沉到包层

如果按这个方案启动，后面无论是：

- 补 Widget
- 补深层传感器
- 做 Intel / Apple Silicon 差异兼容
- 做多版本 macOS 行为适配

都不会被前期工程结构反噬。
