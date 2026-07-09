# 架构说明

本项目是 `E:\github\MoYuStock` 的 Flutter 跨平台迁移版本，目标平台为 Android 与 iOS。`design-proj/` 只作为视觉参考保留，不在其中继续开发。

## 分层结构

- `lib/src/core/`：主题、网络、格式化等跨功能基础能力。
- `lib/src/features/market/domain/`：行情领域模型，包括股票、分组、分时点、K 线点。
- `lib/src/features/market/data/`：行情数据源和仓储，统一封装东方财富、Binance、Yahoo Finance、本地持久化和导入导出。
- `lib/src/features/watchlist/application/`：自选股状态控制器，负责分组、搜索、轮询、排序、主题和持久化。
- `lib/src/features/watchlist/presentation/`：自选列表、分组管理、详情页等界面。
- `lib/src/features/chart/presentation/`：Canvas 自绘分时图和 K 线图。

## 数据源设计

- 东方财富：股票搜索、股票批量报价、分时图、日/周/月 K 线。
- Binance：加密货币搜索、24 小时报价、分时与 K 线。
- Yahoo Finance：补充带 Yahoo 后缀的海外市场标的，移动端使用 HTTP 会话和 crumb/cookie 降级，不依赖 Chrome 扩展。

`MarketRepository` 是 UI 层唯一直接使用的数据入口。这样后续替换数据源、增加缓存或改为 WebSocket 推送时，不需要大面积改动界面代码。

## 状态与持久化

应用使用 Riverpod 的 `StateNotifier` 管理自选列表状态。分组、自选、当前分组和主题偏好写入 `shared_preferences`。导入导出使用 MoYuStock 原有 JSON 结构，导入时按分组合并并去重。

轮询策略当前与原项目保持一致：应用处于前台时每秒刷新当前分组行情，进入后台时暂停。后续可以在仓储层增加更细的退避、缓存过期和失败重试策略。

## 图表策略

图表暂时使用 Flutter `CustomPainter` 自绘，以减少运行时依赖并保持移动端性能可控：

- 分时图：价格线、均价线、昨收虚线、渐变填充。
- K 线图：最近 72 根蜡烛、MA5/10/20/30/60。

后续增强可以继续在 Canvas 层加入十字光标、手势缩放和 Tooltip。
