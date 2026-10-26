# DailyLog Glass

用 **SwiftUI + Liquid Glass** 写的每日记录 App。
Windows 上写代码 → 推到 GitHub → Actions 自动编译出**未签名 IPA** → 全能签签名安装。

---

## 一、功能

| 页面 | 内容 |
|---|---|
| **今日** | 玻璃头部卡片、5 个玻璃心情按钮（选中形变+染色）、照片配图、玻璃编辑卡片、玻璃主按钮 |
| **回顾** | 玻璃卡片流，日期 + 心情色条 + 文字 + 照片缩略图 |
| **统计** | 连续记录、累计条数、心情分布条形图 |
| **设置** | 深浅色切换、年度回顾卡片分享、关于 |

### 长按功能

| 长按哪里 | 效果 |
|---|---|
| 心情按钮 | 震动反馈 + 弹出该心情的一句话（"记录下来就好，情绪不需要被解决"） |
| 今日头部卡片 | 把今天的记录复制到剪贴板 |
| 编辑卡片 | 清空当前草稿（带提示） |
| 统计卡片 | 弹出这个数字怎么算的说明 |
| 回顾里的记录 | 菜单：复制文字 / 删除 |

### 深浅色

设置里三选一：**跟随系统 / 浅色 / 深色**，默认深色。

背景的 MeshGradient 有两套配色——深色是暗紫蓝，浅色是柔和的薰衣草/薄荷/蜜桃。玻璃卡片本身会自动跟随系统材质。

### 年度回顾卡片

用 `ImageRenderer` 把一年的记录渲染成一张 1080×1440 的 PNG，可以直接分享。

> 注意：这张卡片**刻意不用 glassEffect**。`ImageRenderer` 渲染材质类效果会出问题（玻璃会变空白），所以分享图用纯渐变+实色，保证导出的图和屏幕上一致。

---

## 二、项目结构

```
iOS-DailyLogGlass/
├── project.yml                      # XcodeGen 工程定义（不手写 pbxproj）
├── Sources/
│   ├── DailyLogApp.swift
│   ├── Models/Entry.swift           # SwiftData 模型 + 心情枚举
│   ├── Shared/SummaryStore.swift    # 统计摘要（为将来的 Widget 预留）
│   ├── Theme/
│   │   ├── ThemeMode.swift          # 主题枚举
│   │   └── GlassBackground.swift    # 双配色渐变 + 玻璃卡片修饰
│   └── Views/
│       ├── RootView.swift           # TabView + 主题注入
│       ├── TodayView.swift          # 今日（含照片、长按）
│       ├── TimelinePage.swift       # 回顾
│       ├── StatsView.swift          # 统计
│       ├── SettingsView.swift       # 设置 + 年度卡片渲染
│       └── ShareCardView.swift      # 年度卡片视图
└── .github/workflows/build-ipa.yml
```

---

## 三、用到的 Liquid Glass / 新 API

| API | 用在哪 |
|---|---|
| `.glassEffect(_:in:)` | 所有卡片、心情按钮、提示气泡、胶囊标签 |
| `GlassEffectContainer` | 心情选择器（同组玻璃可形变） |
| `.glassEffectID(_:in:)` | 切换心情时的玻璃形变动画 |
| `.buttonStyle(.glassProminent)` | 主操作按钮、分享按钮 |
| `.tabBarMinimizeBehavior(.onScrollDown)` | Tab Bar 下滑收起 |
| `MeshGradient` | 背景流动渐变（深浅两套） |
| `PhotosPicker` | 选照片 |
| `ImageRenderer` | 年度卡片导出 PNG |

---

## 四、首次发布

### 1. GitHub 建空仓库

### 2. 本地推送

```bash
cd "iOS-DailyLogGlass"
git init
git add .
git commit -m "init: DailyLog Glass"
git branch -M main
git remote add origin https://github.com/你的用户名/DailyLogGlass.git
git push -u origin main
```

> 密码要用 **Personal Access Token**（GitHub 已不支持账号密码）。
> Settings → Developer settings → Personal access tokens → Fine-grained tokens → 勾 `Contents: Read and write`

### 3. 等 Actions

推上去自动触发，约 3–6 分钟。

### 4. 下载 IPA

Actions → 那次运行 → 页面底部 **Artifacts** → `DailyLogGlass-ipa` → 解压得 `DailyLogGlass.ipa`

### 5. 签名安装

全能签导入 IPA，用开发者证书签名后装到手机。

---

## 五、排错

### `macos-26` runner 不存在

改成 `macos-15`，同时把 `project.yml` 里 `deploymentTarget` 降到 `18.0`——**但玻璃 API 会全部失效**，只能当"能装能跑"的降级验证。

### 找不到 iOS 26 SDK

先看 `xcodebuild -showsdks` 输出。如果只有 `iphoneos18.x`，说明 runner 的 Xcode 太旧，需要指定更新的 Xcode：

```yaml
- name: 列出所有 Xcode
  run: ls -d /Applications/Xcode*.app
```

然后 `sudo xcode-select -s /Applications/Xcode_26.x.app`

### 编译报 `glassEffect` 找不到

同上，SDK 低于 iOS 26。

### 装上闪退

未签名 IPA 必须先签名。用全能签 / Sideloadly 都行。

---

## 六、下一步：Widget（暂缓）

Widget 需要 **App Extension target + App Group 权限**，而 App Group 要求你的签名证书的 provisioning profile 里包含这个 group。

**全能签这类工具签名时，经常不带上自定义 entitlement**，结果就是：App 能编译，但装不上，或者装上了 Widget 拿不到数据。

所以这轮先不加。正确顺序是：

1. 先让主 App 跑通、装到手机上、确认没问题
2. 有了成功基线，再加 Widget target
3. 万一签名失败，能立刻定位是 Widget 的问题，而不是满盘皆输

数据侧已经准备好了：`SummaryStore` 每次保存都会把统计摘要写进 App Group 的 UserDefaults（没有权限时自动退回标准存储）。到时候加 Widget 只需要读这个 key，不用改 App 逻辑。

---

## 七、注意

- IPA 是**未签名**的，只能自己签名自己装
- `deploymentTarget` 是 **iOS 26.0**，iPhone 14 Pro 升到 iOS 27 完全兼容
- 数据存本地 SwiftData，卸载即丢
