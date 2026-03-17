const pageTranslations = {
  "zh-CN": {
    pageTitle: "mac-state 1.0.2",
    metaDescription:
      "mac-state 1.0.2 是一个原生 macOS 菜单栏状态监测工具，修正了内存读数口径，让百分比更贴近真实系统压力。",
    navFeatures: "功能",
    navModules: "模块",
    navDownload: "下载",
    eyebrowVersion: "版本 1.0.2",
    heroTitle: "一个原生的 macOS 菜单栏状态监测工具，轻、准、可控。",
    heroLede:
      "mac-state 把实时系统指标放回菜单栏该有的位置。先看最关键的信息，再按需打开细节，不把桌面变成一个喧闹的大屏监控台。",
    heroPrimaryCta: "直接下载 PKG",
    heroSecondaryCta: "查看源码",
    communityStarKicker: "支持项目",
    communityStarTitle: "给项目一个 Star",
    communityStarBody: "如果你喜欢它，这是最直接的支持方式。",
    communityForkKicker: "参与贡献",
    communityForkTitle: "Fork 并开始改进",
    communityForkBody: "把你需要的监控模块和界面体验直接做进来。",
    communityReleaseKicker: "获取构建",
    communityReleaseTitle: "打开 Releases",
    communityReleaseBody: "下载 1.0.2 构建、校验值，并查看这次内存读数修正。",
    heroStarLead: "如果你喜欢这个项目，",
    heroStarLink: "欢迎给它一个 Star。",
    highlightOne: "macOS 11+",
    highlightTwo: "Intel + Apple Silicon",
    highlightThree: "菜单栏优先",
    highlightFour: "模块可配置",
    stageMemory: "内存",
    stageNetwork: "网络",
    stageModulesTitle: "面板模块",
    moduleBattery: "电池",
    moduleNetwork: "网络",
    moduleSensors: "传感器",
    moduleAlerts: "告警",
    featuresEyebrow: "为什么它感觉不一样",
    featuresTitle: "它是为菜单栏设计的，不是把大屏监控缩小后塞进去。",
    featureOneTitle: "总览优先",
    featureOneBody:
      "弹出面板顶部先显示关键图表。用户不需要展开一堆区域，才能知道这台机器现在是什么状态。",
    featureTwoTitle: "模块按需显示",
    featureTwoBody:
      "面板卡片是可配置的。用户可以只显示自己关心的模块、调整顺序，并决定哪些区域默认展开。",
    featureThreeTitle: "原生采样栈",
    featureThreeBody:
      "CPU、内存、磁盘、网络、电池、告警、Widget 和登录启动都建立在 Swift、SwiftUI 与 AppKit 上，而不是跨端壳。",
    brandEyebrow: "品牌方向",
    brandTitle: "克制的中性色，只保留一个“活着”的信号色。",
    brandBody:
      "这套视觉系统故意不做“监控大屏风格”。logo 和页面都只让一个信号绿承担“实时状态”的含义，其余部分保持安静、技术感和原生工具感。",
    shipsEyebrow: "1.0.2 更新了什么",
    shipsTitle: "这一版重点修正内存读数口径，让可回收缓存不再被误判成接近打满的硬压力。",
    moduleTagPerCore: "每核心 CPU",
    moduleTagMemory: "内存",
    moduleTagDisk: "磁盘",
    moduleTagNetwork: "网络",
    moduleTagBattery: "电池",
    moduleTagSensors: "传感器",
    moduleTagAlerts: "告警",
    moduleTagHistory: "历史",
    moduleTagWidgets: "Widget",
    moduleTagLaunchAtLogin: "登录启动",
    moduleTagLanguages: "English / 简体中文",
    storyOneTitle: "内存读数更贴近系统体感",
    storyOneBody:
      "可回收缓存不再直接推高内存百分比，所以看到 100% 的概率会明显下降，读数和“机器有没有卡”会更一致。",
    storyTwoTitle: "告警与历史沿用同一修正口径",
    storyTwoBody:
      "新的内存计算会同时反映在实时面板、历史曲线和高内存告警里，避免不同界面对同一台机器给出冲突印象。",
    storyThreeTitle: "1.0.2 安装包与页面同步更新",
    storyThreeBody:
      "本次发布同步更新了 PKG、ZIP、校验值、官网文案和更新日志，下载入口会直接指向新的 1.0.2 资产。",
    downloadEyebrow: "发布",
    downloadBody:
      "1.0.2 修正了内存占用读数，避免把可回收缓存误算成接近 100% 的硬压力。支持 macOS 11+，兼容 Intel 与 Apple Silicon。",
    downloadPrimaryCta: "直接下载 PKG",
    downloadSecondaryCta: "下载 ZIP",
    downloadChangelogCta: "查看更新日志",
    downloadTertiaryCta: "打开 Releases",
    downloadStarLead: "如果这个项目对你有帮助，",
    downloadStarLink: "欢迎在 GitHub 上点亮 Star。",
  },
  en: {
    pageTitle: "mac-state 1.0.2",
    metaDescription:
      "mac-state 1.0.2 is a native macOS menu bar monitor with refined memory reporting that tracks real system pressure more closely.",
    navFeatures: "Features",
    navModules: "Modules",
    navDownload: "Download",
    eyebrowVersion: "Version 1.0.2",
    heroTitle: "A native macOS menu bar monitor that stays light, clear, and under control.",
    heroLede:
      "mac-state puts live system telemetry back where it belongs. See the essentials first, expand details only when you need them, and avoid turning the desktop into a noisy wall of monitoring panels.",
    heroPrimaryCta: "Download PKG",
    heroSecondaryCta: "View Source",
    communityStarKicker: "Support",
    communityStarTitle: "Star the project",
    communityStarBody: "If you like it, this is the simplest way to help it grow.",
    communityForkKicker: "Contribute",
    communityForkTitle: "Fork and build on it",
    communityForkBody: "Add the monitoring modules and interface changes you want to see.",
    communityReleaseKicker: "Get Builds",
    communityReleaseTitle: "Open Releases",
    communityReleaseBody: "Download the 1.0.2 builds, checksums, and the memory reporting fix in this release.",
    heroStarLead: "If you like this project,",
    heroStarLink: "please give it a star on GitHub.",
    highlightOne: "macOS 11+",
    highlightTwo: "Intel + Apple Silicon",
    highlightThree: "Menu bar first",
    highlightFour: "Configurable modules",
    stageMemory: "Memory",
    stageNetwork: "Network",
    stageModulesTitle: "Dashboard Modules",
    moduleBattery: "Battery",
    moduleNetwork: "Network",
    moduleSensors: "Sensors",
    moduleAlerts: "Alerts",
    featuresEyebrow: "Why It Feels Different",
    featuresTitle: "Designed for the menu bar instead of shrinking a big dashboard into it.",
    featureOneTitle: "Overview first",
    featureOneBody:
      "Critical charts appear at the top of the popover, so users do not need to expand a stack of sections just to understand the machine.",
    featureTwoTitle: "Modules on demand",
    featureTwoBody:
      "Popover cards are configurable. People can show only the modules they care about, reorder them, and decide which sections open expanded.",
    featureThreeTitle: "Native telemetry stack",
    featureThreeBody:
      "CPU, memory, disk, network, battery, alerts, widgets, and login items are built with Swift, SwiftUI, and AppKit rather than a cross-platform shell.",
    brandEyebrow: "Brand Direction",
    brandTitle: "Quiet neutrals, one live accent, and none of the usual dashboard theater.",
    brandBody:
      "The visual system intentionally avoids the wall-of-monitors aesthetic. The logo and page let a single signal green carry the idea of live status while the rest stays calm, technical, and native.",
    shipsEyebrow: "What Changed In 1.0.2",
    shipsTitle: "This release tightens memory reporting so reclaimable cache no longer reads like near-saturated memory pressure.",
    moduleTagPerCore: "Per-core CPU",
    moduleTagMemory: "Memory",
    moduleTagDisk: "Disk",
    moduleTagNetwork: "Network",
    moduleTagBattery: "Battery",
    moduleTagSensors: "Sensors",
    moduleTagAlerts: "Alerts",
    moduleTagHistory: "History",
    moduleTagWidgets: "Widgets",
    moduleTagLaunchAtLogin: "Launch at Login",
    moduleTagLanguages: "English / Simplified Chinese",
    storyOneTitle: "Memory readings now match macOS behavior better",
    storyOneBody:
      "Reclaimable cache no longer drives the memory percentage toward 100%, so the number is much closer to whether the machine actually feels under pressure.",
    storyTwoTitle: "Alerts and history use the same corrected baseline",
    storyTwoBody:
      "The refined memory calculation now flows through the live dashboard, history charts, and high-memory alerts, avoiding mixed signals across surfaces.",
    storyThreeTitle: "1.0.2 assets and site copy ship together",
    storyThreeBody:
      "This release refreshes the PKG, ZIP, checksums, site copy, and changelog at the same time, so every download entry points at the new 1.0.2 assets.",
    downloadEyebrow: "Release",
    downloadBody:
      "1.0.2 fixes memory usage reporting so reclaimable cache does not look like near-100% hard pressure. Built for macOS 11 and later, with support for both Intel and Apple Silicon.",
    downloadPrimaryCta: "Download PKG",
    downloadSecondaryCta: "Download ZIP",
    downloadChangelogCta: "Read Changelog",
    downloadTertiaryCta: "Open Releases",
    downloadStarLead: "If this project helps you,",
    downloadStarLink: "please star it on GitHub.",
  },
};

function applyPageLanguage(language) {
  const fallbackLanguage = pageTranslations["zh-CN"];
  const copy = pageTranslations[language] ?? fallbackLanguage;

  document.documentElement.lang = language;
  document.title = copy.pageTitle;

  const descriptionNode = document.querySelector('meta[name="description"]');
  if (descriptionNode) {
    descriptionNode.setAttribute("content", copy.metaDescription);
  }

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    const key = node.getAttribute("data-i18n");
    const value = copy[key];

    if (value) {
      node.textContent = value;
    }
  });

  document.querySelectorAll("[data-language-button]").forEach((button) => {
    button.classList.toggle("is-active", button.getAttribute("data-language-button") === language);
  });
}

function setupLanguageSwitch() {
  const storageKey = "mac-state-site-language";
  const preferredLanguage = window.localStorage.getItem(storageKey) || "zh-CN";

  applyPageLanguage(preferredLanguage);

  document.querySelectorAll("[data-language-button]").forEach((button) => {
    button.addEventListener("click", () => {
      const nextLanguage = button.getAttribute("data-language-button") || "zh-CN";
      window.localStorage.setItem(storageKey, nextLanguage);
      applyPageLanguage(nextLanguage);
    });
  });
}

window.addEventListener("DOMContentLoaded", setupLanguageSwitch);
