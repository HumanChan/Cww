param(
    [string]$FlutterRoot = "D:\Flutter-SDK\flutter",
    [string]$Org = "com.moyu"
)

$ErrorActionPreference = "Stop"

$flutter = Join-Path $FlutterRoot "bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    throw "未找到 Flutter 命令：$flutter。请确认 SDK 已下载并解压完成。"
}

Write-Host "使用 Flutter：$flutter"
& $flutter --version

Write-Host "生成 Android/iOS 平台目录..."
& $flutter create --platforms android,ios --org $Org .

Write-Host "获取依赖..."
& $flutter pub get

Write-Host "静态分析..."
& $flutter analyze

Write-Host "运行测试..."
& $flutter test

Write-Host "验证完成。"
