# 站外分发（2026-10-26）

用户取消 Mac App Store 上架，改用 Developer ID 签名和 Apple 公证。商店 build 7 被服务端校验拒绝，未提交审核。

## 当前产物

- 版本 1.1.0，build 8；归档 `dist/developer-id/build-8/MacState.xcarchive`。
- 补齐 Widget 的 `CFBundleDisplayName`。
- 签名团队 Hou yanming / 662TJCCT5J，Developer ID Application 证书；私钥保留本机钥匙串。
- 使用 StoreRelease 的沙盒及团队前缀 App Group 配置构建，通过 `method=developer-id` 导出，分发渠道为站外。
- 主应用、Widget、登录 helper 均包含 arm64/x86_64，最低系统 macOS 11.0，启用 Hardened Runtime、安全时间戳且无调试授权。
- Xcode 提交公证并通过 `-exportNotarizedApp` 导出到 `dist/developer-id/build-8/notarized/MacStateApp.app`。
- `stapler validate` 成功；Gatekeeper 检查返回 `accepted / source=Notarized Developer ID`。
- ZIP：`dist/developer-id/build-8/mac-state-1.1.0-build-8-developer-id.zip`，包含已附加公证票据的应用、安装说明及 MIT 许可证。
- DMG：`dist/dmg/mac-state-1.1.0-build-8-developer-id.dmg`，独立公证状态 Accepted，票据附加及验证成功，Gatekeeper 返回 `accepted / Notarized Developer ID`。
- 公证提交 ID：`b36d77eb-ca09-4908-b1a4-10173b3ae70a`。
- DMG SHA-256：`a6720da3fb9fb809320154bd4a9d2083ef1684320c394f1f5d19bccb5e02f516`。
- 只读挂载后复验包内 App 签名、公证票据与 Gatekeeper 均通过；镜像包含 Applications 快捷方式、安装说明和 MIT 许可证。

## DMG 完成命令

```sh
MACSTATE_NOTARY_PROFILE=mac-state-notary scripts/package-dmg.sh \
  "$PWD/dist/developer-id/build-8/notarized/MacStateApp.app" developer-id
```

脚本验证三个组件的签名、双架构及 Hardened Runtime，加入许可证，签名 DMG、提交公证、附加并验证票据，通过 Gatekeeper 后才输出最终文件及 SHA-256。

不提交私钥、密码或公证凭据。用户随后授权发布 GitHub：源码及新版主页已推送 main，`v1.1.0` Release 已公开，包含 DMG、SHA-256 和 ZIP；主页及 README 下载入口均指向本次 DMG。签名与公证验证不等同于已完成 Intel 真机、旧版 macOS、Widget 系统刷新及整机重启测试。
