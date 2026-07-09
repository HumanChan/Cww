# CwwFlutter

这是参考 `E:\github\MoYuStock` 与 `design-proj/` 视觉 demo 迁移出的 Flutter 跨平台版本，目标是覆盖原项目的股票/加密货币自选、分组、搜索、实时行情、详情、图表、导入导出与主题能力。

## 当前实现范围

- Flutter + Riverpod 分层架构：模型、行情服务、仓储、状态控制器、页面组件分离。
- 支持东方财富股票搜索/报价/分时/K 线接口。
- 支持 Binance 加密货币搜索/报价/分时/K 线接口。
- 支持 Yahoo Finance 的移动端直连搜索/报价降级实现。
- 支持自选分组、添加/删除/重命名/排序、股票排序、持久化、明暗主题。
- 支持导入导出 JSON 备份。
- 已按移动端体验实现自选列表、搜索面板、详情页和自绘走势图/K 线图。

## 本机工具链说明

如果 Flutter SDK 下载在 `D:\Flutter-SDK`，完成后可在仓库根目录执行：

```powershell
.\tool\flutter_verify.ps1
```

该脚本会使用 `D:\Flutter-SDK\flutter\bin\flutter.bat` 生成 Android/iOS 平台目录，随后执行依赖安装、静态分析和测试。

`design-proj/` 仅作为视觉参考目录保留，迁移实现不修改其中内容。

## 文档

- [架构说明](docs/ARCHITECTURE.md)
- [功能对齐清单](docs/FUNCTION_PARITY.md)
