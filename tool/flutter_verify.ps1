param(
    [string]$FlutterRoot = "D:\Flutter-SDK\flutter",
    [string]$Org = "com.moyu"
)

$ErrorActionPreference = "Stop"

$flutter = Join-Path $FlutterRoot "bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    throw "Flutter command not found: $flutter. Please make sure the SDK is fully downloaded."
}

function Invoke-Flutter {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$FlutterArgs
    )

    & $flutter @FlutterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter command failed: flutter $($FlutterArgs -join ' ')"
    }
}

Write-Host "Using Flutter: $flutter"
Invoke-Flutter --version

Write-Host "Creating Android/iOS platform folders..."
Invoke-Flutter create "--platforms=android,ios" --org $Org .

Write-Host "Resolving dependencies..."
Invoke-Flutter pub get

Write-Host "Running static analysis..."
Invoke-Flutter analyze

Write-Host "Running tests..."
Invoke-Flutter test

Write-Host "Verification complete."
