[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$dc2Dir = "C:\walt\software\4.utils\display changer II"
$dc2Exe = Join-Path $dc2Dir "dc2.exe"

if (-not (Test-Path $dc2Exe)) {
    Write-Host "[错误] 未找到 dc2.exe，请检查路径: $dc2Dir" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit 1
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          屏幕配置切换菜单" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  [1] 单屏配置(大屏) (config-1.xml)"
Write-Host "  [2] 双屏配置(大屏+笔记本) (config-12.xml)"
Write-Host "  [3] 双屏配置(大屏+小屏) (config-12.1.xml)"
Write-Host "  [4] 三屏配置 (config-123.xml)"
Write-Host "  [0] 退出"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "请按数字键选择对应模式 [1-4, 0退出]: " -NoNewline

$key = ''
if ([Console]::IsInputRedirected) {
    $line = [Console]::ReadLine()
    if ($line -and $line.Length -gt 0) { $key = $line.Substring(0,1) }
} else {
    try {
        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $key = $keyInfo.Character
        Write-Host $key
    } catch {
        $line = Read-Host
        if ($line -and $line.Length -gt 0) { $key = $line.Substring(0,1) }
    }
}

switch ($key) {
    '1' {
        Write-Host "`n正在应用配置: config-1.xml ..." -ForegroundColor Green
        Start-Process -FilePath $dc2Exe -ArgumentList '-configure="config-1.xml"' -WorkingDirectory $dc2Dir -Wait
        Write-Host "配置应用完成。" -ForegroundColor Green
    }
    '2' {
        Write-Host "`n正在应用配置: config-12.xml ..." -ForegroundColor Green
        Start-Process -FilePath $dc2Exe -ArgumentList '-configure="config-12.xml"' -WorkingDirectory $dc2Dir -Wait
        Write-Host "配置应用完成。" -ForegroundColor Green
    }
    '3' {
        Write-Host "`n正在应用配置: config-12.xml ..." -ForegroundColor Green
        Start-Process -FilePath $dc2Exe -ArgumentList '-configure="config-12.1.xml"' -WorkingDirectory $dc2Dir -Wait
        Write-Host "配置应用完成。" -ForegroundColor Green
    }
    '4' {
        Write-Host "`n正在应用配置: config-123.xml ..." -ForegroundColor Green
        Start-Process -FilePath $dc2Exe -ArgumentList '-configure="config-123.xml"' -WorkingDirectory $dc2Dir -Wait
        Write-Host "配置应用完成。" -ForegroundColor Green
    }
    '0' {
        Write-Host "`n已退出。"
        exit 0
    }
    default {
        Write-Host "`n无效选项，已退出。" -ForegroundColor Yellow
        exit 0
    }
}
