# MoYuStock 功能对齐清单

| 原功能 | Flutter 状态 | 说明 |
| --- | --- | --- |
| 自选股分组 | 已实现 | 支持新增、重命名、删除、排序、切换当前分组 |
| 自选标的管理 | 已实现 | 支持股票/币种添加、删除、组内排序 |
| 本地持久化 | 已实现 | 使用 `shared_preferences` 保存分组、当前分组和主题 |
| 股票搜索 | 已实现 | 东方财富 + Yahoo Finance 合并搜索 |
| 加密货币搜索 | 已实现 | 内置主流币对 + Binance 精确查询 |
| 实时行情轮询 | 已实现 | 前台每秒刷新当前分组行情 |
| 股票报价 | 已实现 | 东方财富批量报价，包含涨跌幅、开高低收、成交额、估值指标 |
| 加密货币报价 | 已实现 | Binance 24 小时报价 |
| Yahoo 海外标的 | 已实现降级 | 使用移动端 HTTP 会话，不依赖 Chrome 扩展 |
| 分时图 | 已实现 | Flutter Canvas 自绘 |
| 日/周/月 K 线 | 已实现 | Flutter Canvas 自绘，含 MA 均线 |
| 详情指标弹窗/页面 | 已实现 | Flutter 使用独立详情页展示完整指标 |
| 明暗主题 | 已实现 | 使用 Material 3 主题 |
| 导入导出 JSON | 已实现 | 导出走系统分享，导入走文件选择器 |
| 应用可见性轮询控制 | 已实现 | 前台刷新，后台暂停 |
| Android/iOS 平台工程 | 待 SDK 验证 | 需要 Flutter SDK 下载完成后运行 `tool/flutter_verify.ps1` 生成与验证 |
| 真机/模拟器体验验证 | 待 SDK 验证 | 需要 Flutter SDK、Android/iOS 工具链可用 |

## 当前优先缺口

1. 等 Flutter SDK 下载完成后生成 `android/` 与 `ios/` 平台目录。
2. 运行 `flutter pub get`、`flutter analyze`、`flutter test`。
3. 真机或模拟器检查列表、搜索、详情、导入导出、前后台轮询。
4. 根据真实渲染结果继续补手势缩放、图表十字光标和错误重试体验。
