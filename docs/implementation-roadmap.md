# mac-state 实施路线图

更新日期：`2026-03-16`

## 1. 产品阶段划分

### 阶段 A：可用的菜单栏 MVP

目标：

- 做出可以长期常驻使用的第一版
- 完成核心指标监控
- 建立后续扩展所需的架构基础

范围：

- 菜单栏入口
- 弹出面板
- CPU / 内存 / 磁盘 / 网络 / 电池
- 应用列表
- 基础历史趋势
- 基础阈值通知
- 设置页
- 登录启动

退出标准：

- Intel 和 Apple Silicon 实机均可稳定运行
- `macOS 11`、`12`、`13+` 基础能力一致
- 常驻功耗和内存占用处于可接受范围

### 阶段 B：高价值增强

目标：

- 提升可视化质量和专业用户价值

范围：

- 更完整的历史图表
- 每应用趋势
- 导出能力
- Widget
- 更精细的告警规则

### 阶段 C：深层硬件扩展

目标：

- 补齐温度、风扇和更多硬件指标

范围：

- SensorBridge
- 温度与风扇数据
- 磁盘 I/O
- 可能的 GPU 扩展指标

## 2. 功能优先级矩阵

| 功能 | 用户价值 | 技术风险 | 推荐阶段 | 备注 |
| --- | --- | --- | --- | --- |
| 菜单栏实时展示 | 高 | 低 | A | 产品核心入口 |
| CPU 监控 | 高 | 低 | A | 总览与每核心 |
| 内存监控 | 高 | 低 | A | 压力和构成都要有 |
| 磁盘空间 | 高 | 低 | A | 首版先做容量，不急于做 I/O |
| 网络速率 | 高 | 中 | A | 需处理接口切换 |
| 电池状态 | 高 | 低 | A | 笔记本高频使用 |
| 应用资源列表 | 高 | 中 | A | 需平衡采样成本 |
| 历史趋势图 | 高 | 中 | A | MVP 就要有基本版 |
| 告警通知 | 高 | 中 | A | 支持冷却时间 |
| 登录启动 | 中 | 中 | A | 需要版本兼容层 |
| Widget | 中 | 低 | B | 非主路径，但有展示价值 |
| 导出 CSV | 中 | 低 | B | 有助于分析和分享 |
| 每应用趋势 | 中 | 中 | B | 对开发者价值高 |
| 温度传感器 | 高 | 高 | C | 不建议首版承诺 |
| 风扇转速 | 中 | 高 | C | 依赖底层能力 |
| 磁盘 I/O | 中 | 高 | C | 采样细节需谨慎 |
| 本地 API | 低 | 中 | C | 可后置 |

## 3. 推荐目录结构

当前仓库为空，建议一开始就按模块拆清楚，避免后期重构成本。

```text
mac-state/
  docs/
  MacStateApp/
    App/
    Shell/
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
    Core/
      Metrics/
      Persistence/
      Scheduling/
      Compatibility/
      Logging/
    UI/
      Components/
      Theme/
      Charts/
    Resources/
  MacStateLoginHelper/
  MacStateSensorBridge/
  Packages/
    MacStateFoundation/
    MacStateMetrics/
    MacStateUI/
  Tests/
    Unit/
    Integration/
```

## 4. 模块拆分建议

### 4.1 App 层

职责：

- 应用生命周期
- 菜单栏注入
- 弹出面板管理
- 设置窗口管理
- 模块装配

建议命名：

- `AppDelegate`
- `StatusItemController`
- `PopoverController`
- `WindowRouter`

### 4.2 Compatibility 层

职责：

- 包装系统版本差异
- 登录启动 API 适配
- 兼容旧系统 UI 行为差异

建议接口：

- `LaunchAtLoginService`
- `PlatformCapabilities`
- `SystemVersionSupport`

### 4.3 Metrics 层

职责：

- 统一采样入口
- 调度采样周期
- 标准化输出模型

建议接口：

- `MetricSampler`
- `MetricSample`
- `MetricSnapshot`
- `SamplerScheduler`

建议每个模块单独实现：

- `CPUSampler`
- `MemorySampler`
- `DiskSampler`
- `NetworkSampler`
- `BatterySampler`
- `ProcessSampler`

### 4.4 Alerts 层

职责：

- 规则定义
- 连续阈值判断
- 冷却时间
- 本地通知下发

建议接口：

- `AlertRule`
- `AlertEvaluator`
- `AlertEvent`
- `NotificationDispatcher`

### 4.5 Persistence 层

职责：

- 采样缓存
- 历史聚合
- 配置读写

建议接口：

- `MetricsStore`
- `HistoryRepository`
- `SettingsStore`

## 5. 采样频率建议

为了兼顾老机器和常驻功耗，建议按场景动态调整：

| 场景 | 采样频率 | 说明 |
| --- | --- | --- |
| 菜单栏空闲态 | 3 到 5 秒 | 低干扰、低功耗 |
| 面板打开 | 1 秒 | 提升即时反馈 |
| 详情页图表交互中 | 0.5 到 1 秒 | 仅对当前模块提升频率 |
| 后台长期历史 | 10 到 30 秒聚合写入 | 避免高频持久化 |

规则：

- 默认低频
- 只在用户关注当前模块时提升局部刷新
- 所有模块都必须支持暂停和降频

## 6. 数据模型建议

### 6.1 Snapshot 模型

用于 UI 实时展示：

```swift
struct MetricSnapshot {
    let timestamp: Date
    let cpu: CPUSnapshot?
    let memory: MemorySnapshot?
    let disk: DiskSnapshot?
    let network: NetworkSnapshot?
    let battery: BatterySnapshot?
    let processes: [ProcessSnapshot]
}
```

### 6.2 History Point 模型

用于历史图表：

```swift
struct HistoryPoint<Value> {
    let timestamp: Date
    let value: Value
}
```

### 6.3 Capability 模型

用于处理不同机型与系统版本的差异：

```swift
struct PlatformCapabilities {
    let supportsWidgets: Bool
    let supportsModernLoginItemAPI: Bool
    let supportsSensorBridge: Bool
    let supportsAdvancedGPUStats: Bool
}
```

## 7. 里程碑计划

### M1：项目骨架

输出：

- Xcode workspace / project
- 主 App target
- 基础模块目录
- 菜单栏空壳
- 设置窗口空壳

验收：

- 在 `macOS 11+` 启动正常
- Intel / Apple Silicon 都能编译通过

### M2：核心采样

输出：

- CPU、内存、磁盘、网络、电池采样器
- 标准化模型
- 实时刷新管线

验收：

- 面板中可稳定显示核心数据
- 数据刷新节奏平稳，无明显卡顿

### M3：UI MVP

输出：

- 菜单栏展示模式
- 弹出面板卡片布局
- 最近 30 分钟趋势图
- 应用列表

验收：

- 菜单栏信息可读
- 面板打开速度和操作流畅度可接受

### M4：持久化与告警

输出：

- 历史存储
- 告警规则
- 通知派发
- 设置持久化

验收：

- 告警不重复轰炸
- 历史数据重启后保留

### M5：兼容与打磨

输出：

- 登录启动兼容层
- 多系统版本适配
- 资源占用优化
- 测试补齐

验收：

- `macOS 11/12/13+`
- `Intel + Apple Silicon`
- 长时间常驻稳定

### M6：SensorBridge 预研

输出：

- 传感器接口抽象
- Intel / Apple Silicon 实验性 provider
- 可用性矩阵

验收：

- 明确哪些指标可稳定提供
- 明确哪些能力需要后续分发策略支持

## 8. 测试策略

### 8.1 必测维度

- 系统版本：
  - `macOS 11`
  - `macOS 12`
  - `macOS 13+`
- 芯片架构：
  - `Intel`
  - `Apple Silicon`
- 设备类型：
  - MacBook
  - 桌面机型

### 8.2 测试重点

- 菜单栏长时间常驻稳定性
- 睡眠唤醒后数据恢复
- 网络接口切换
- 外接磁盘挂载变化
- 电池状态变化
- 高负载场景下 UI 是否抖动

### 8.3 性能门槛建议

首版建议设定硬门槛：

- 空闲态内存占用尽量稳定在较低水平
- 菜单栏空闲采样不造成明显 CPU 持续占用
- 打开面板时的瞬时开销可接受

具体数值可以在有第一版原型后再定。

## 9. 主要风险与对应策略

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| 旧版 macOS 行为差异 | 兼容问题 | 设 Compatibility 层，不在业务层散落版本判断 |
| Intel 老机器性能弱 | 常驻体验变差 | 默认低频采样，按需提升 |
| 深层传感器不稳定 | 功能承诺失真 | 后置为 SensorBridge，并做 capability 降级 |
| 历史写入过频 | 功耗和磁盘写放大 | 内存缓冲 + 聚合写入 |
| 进程采样成本高 | UI 卡顿 | 列表按需刷新，支持限制 Top N |

## 10. 当前推荐实施顺序

建议团队按下面顺序推进：

1. 先做菜单栏壳和核心采样，不要先碰传感器。
2. 把兼容层和能力抽象提前立好，不要等功能做多了再补。
3. MVP 先交付“能常驻使用”的版本，再逐步补齐高级指标。
4. 传感器能力通过独立模块预研，不阻塞主线交付。
