# ===================== 文件功能说明 ====================
# 日月升降数据获取脚本 (优化版)
# 功能：从天气API获取未来7天的日月升降数据，并生成四种格式的事件文件
# 输出文件：
#   SunEvents.txt          - 格式: yyyyMMddHHmmssEventType
#   MoonEvents.txt         - 格式: yyyyMMddHHmmssEventType
#   SunTimeStampEvent.txt  - 格式: Unix时间戳EventType
#   MoonTimeStampEvent.txt - 格式: Unix时间戳EventType
# 文件位置: C:\Users\Public\Documents\
# =======================================================

# 读取配置文件
$configPath = Join-Path $PSScriptRoot "WeatherApiKeys.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $script:weatherApiKey = $config.weatherApiKey
        $script:baiduAk = $config.baiduAk
        Write-Host "成功读取配置文件" -ForegroundColor Green
    }
    catch {
        Write-Error "读取配置文件失败: $_"
        exit 1
    }
}
else {
    Write-Error "未找到配置文件，请确保 config.json 与脚本放在同一目录下。"
    exit 1
}

# 辅助函数：安全调用 Web API
# 参数：Uri(API地址), RetryCount(重试次数), TimeoutSec(超时秒数)
# 返回：API响应内容
function Invoke-SafeWebRequest {
    param(
        [string]$Uri,
        [int]$RetryCount = 2,
        [int]$TimeoutSec = 10
    )
    # === 重试机制 ===
    $attempt = 0
    while ($attempt -le $RetryCount) {
        try {
            # 核心请求逻辑
            $response = Invoke-RestMethod -Uri $Uri -ErrorAction Stop -TimeoutSec $TimeoutSec
            return $response
        } catch {
            # === 异常处理 ===
            $attempt++
            if ($attempt -gt $RetryCount) {
                Write-Warning "API请求失败: $_ (URL: $Uri)"
                throw
            }
            # 指数退避等待
            Start-Sleep -Milliseconds (500 * $attempt)
        }
    }
}

# 1. 获取城市编码 (多服务冗余设计)
# 逻辑：通过5个备选IP服务获取公网IP -> 百度API解析位置 -> 天气API获取城市编码
# 返回：城市编码字符串 (默认值: 101010100 北京)
function Get-CityCode {
    # === IP查询服务列表 ===
    $ipServices = @(
        "https://ipinfo.io/ip",
        "https://checkip.amazonaws.com/",
        "https://v4.ident.me/",
        "https://ip.liquidweb.com/",
        "https://myexternalip.com/raw"
    )
    
    # === 公网IP获取 ===
    $publicIP = $null
    foreach ($service in $ipServices) {
        try {
            $publicIP = (Invoke-SafeWebRequest -Uri $service).Trim()
            if (-not [string]::IsNullOrWhiteSpace($publicIP)) {
                Write-Host "成功获取公网IP: $publicIP" -ForegroundColor Green
                break
            }
        } catch {
            Write-Verbose "IP服务 $service 访问失败: $_"
        }
    }
    
    # === 默认城市编码 (北京) ===
    $cityCode = "101010100"
    
    if (-not [string]::IsNullOrWhiteSpace($publicIP)) {
        try {
            # === 地理位置解析 ===
            $locationUrl = "https://api.map.baidu.com/location/ip?ip=$publicIP&coor=bd09ll&ak=$script:baiduAk"
            $locationData = Invoke-SafeWebRequest -Uri $locationUrl
            
            if ($locationData.content.point) {
                # 精度处理：保留2位小数
                $lon = [math]::Round($locationData.content.point.x, 2)
                $lat = [math]::Round($locationData.content.point.y, 2)
                Write-Host "解析到地理位置: 经度 $lon, 纬度 $lat" -ForegroundColor Cyan
                
                # === 城市编码查询 ===
                $geoUrl = "https://kk436g9nfm.re.qweatherapi.com/geo/v2/city/lookup?location=${lon},${lat}&key=$script:weatherApiKey"
                $geoData = Invoke-SafeWebRequest -Uri $geoUrl
                
                if ($geoData.location.Count -gt 0) {
                    $cityCode = $geoData.location[0].id
                    Write-Host "获取到城市编码: $cityCode" -ForegroundColor Green
                }
            }
        } catch {
            Write-Warning "位置查询失败，使用默认城市编码: $_"
        }
    } else {
        Write-Warning "无法获取公网IP，使用默认城市编码"
    }
    
    return $cityCode
}

# 2. 生成日期范围 (时间窗口策略)
# 策略：获取当前日期前2天到后4天的日期列表
# 返回：日期字符串数组 (格式: yyyyMMdd)
function Get-DateRange {
    $dates = @()
    # 生成7天窗口期 [-2, +4]
    for ($i = -2; $i -le 4; $i++) {
        $dates += (Get-Date).AddDays($i).ToString("yyyyMMdd")
    }
    return $dates
}

# 3. 获取天气数据 (智能缓存优化)
# 参数：cityCode(城市编码), date(日期yyyyMMdd)
# 返回：包含日月升降时间的哈希表
# 策略：历史数据直接获取，预报数据全局缓存避免重复请求
function Get-WeatherData {
    param(
        [string]$cityCode,
        [string]$date
    )
    
    $apiKey = $script:weatherApiKey
    
    try {
        # === 日期类型判断 ===
        $today = (Get-Date).ToString("yyyyMMdd")
        $dateObj = [datetime]::ParseExact($date, "yyyyMMdd", $null)
        $todayObj = [datetime]::ParseExact($today, "yyyyMMdd", $null)
        
        if ($dateObj -lt $todayObj) {
            # === 历史数据路径 ===
            $url = "https://kk436g9nfm.re.qweatherapi.com/v7/historical/weather?location=$cityCode&date=$date&key=$apiKey"
            Write-Host "获取历史数据: $date" -ForegroundColor DarkGray
            $data = Invoke-SafeWebRequest -Uri $url
            return @{
                Date = $date
                Sunrise = $data.weatherDaily.sunrise
                Sunset  = $data.weatherDaily.sunset
                Moonrise = $data.weatherDaily.moonrise
                Moonset  = $data.weatherDaily.moonset
            }
        } else {
            # === 预报数据路径 (带缓存) ===
            if (-not $script:forecastData) {
                $url = "https://kk436g9nfm.re.qweatherapi.com/v7/weather/7d?location=$cityCode&key=$apiKey"
                Write-Host "获取预报数据 (首次调用)" -ForegroundColor DarkGray
                $script:forecastData = Invoke-SafeWebRequest -Uri $url
            }
            
            # 日期格式转换 yyyyMMdd -> yyyy-MM-dd
            $formattedDate = $date.Substring(0, 4) + "-" + $date.Substring(4, 2) + "-" + $date.Substring(6, 2)
            
            # 从缓存中匹配目标日期
            $dailyData = $script:forecastData.daily | Where-Object { $_.fxDate -eq $formattedDate }
            
            if ($dailyData) {
                return @{
                    Date = $date
                    Sunrise = $dailyData.sunrise
                    Sunset  = $dailyData.sunset
                    Moonrise = $dailyData.moonrise
                    Moonset  = $dailyData.moonset
                }
            } else {
                Write-Warning "在预报数据中未找到日期: $date (API格式: $formattedDate)"
            }
        }
    } catch {
        Write-Warning "获取 $date 天气数据失败: $_"
    }
    
    return $null
}

# 4. 生成标准事件格式
# 参数：date(日期yyyyMMdd), time(时间HH:mm), eventType(事件类型)
# 返回：yyyyMMddHHmmEventType 或 nullEventType
function Format-Event {
    param(
        [string]$date,
        [string]$time,
        [string]$eventType
    )
    
    # 空值处理逻辑
    if ([string]::IsNullOrWhiteSpace($time)) {
        return "null$eventType"
    } else {
        $cleanTime = $time -replace ":", ""
        return "${date}${cleanTime}$eventType"
    }
}

# 5. 生成时间戳事件 (精确时间转换)
# 参数：date(日期yyyyMMdd), time(时间HH:mm), eventType(事件类型)
# 返回：Unix时间戳字符串 + 事件类型
# 核心：本地时间 -> UTC时间 -> Unix时间戳
function Format-TimestampEvent {
    param(
        [string]$date,
        [string]$time,
        [string]$eventType
    )
    
    # 空值处理
    if ([string]::IsNullOrWhiteSpace($time)) {
        return "null$eventType"
    } else {
        try {
            # === 时间转换流水线 ===
            # 步骤1: 合并日期时间创建本地时间对象
            $localTime = [datetime]::ParseExact("${date} ${time}", "yyyyMMdd HH:mm", $null)
            
            # 步骤2: 转换为UTC时间 (解决时区问题)
            $utcTime = $localTime.ToUniversalTime()
            
            # 步骤3: 计算Unix时间戳 (精确到秒)
            $epoch = [datetime]::new(1970, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)
            $timestamp = [math]::Floor(($utcTime - $epoch).TotalSeconds)
            
            return "${timestamp}$eventType"
        } catch {
            Write-Warning "时间转换失败: $date $time ($eventType) - $_"
            return "null$eventType"
        }
    }
}

# 辅助函数：安全写入文件 (无结尾换行符)
# 参数：Path(文件路径), Content(内容列表), Encoding(编码格式)
# 特性：自动创建目录、UTF-8无BOM编码
function Write-FileWithoutTrailingNewline {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Content,
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )
    
    # 空内容检查
    if ($Content.Count -eq 0) { return }
    
    # 构建文件内容 (行间换行但结尾无换行)
    $fileContent = $Content -join [Environment]::NewLine
    
    # === 目录创建逻辑 ===
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    if (-not [System.IO.Directory]::Exists($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    
    # 写入文件 (避免追加模式)
    [System.IO.File]::WriteAllText($Path, $fileContent, $Encoding)
}

# ===================== 主执行流程 =====================
try {
    # === 初始化阶段 ===
    $script:forecastData = $null  # 预报数据缓存
    
    # 步骤1: 获取城市编码
    $cityCode = Get-CityCode
    Write-Host "使用城市编码: $cityCode" -ForegroundColor Cyan
    
    # 步骤2: 生成7天日期窗口
    $dates = Get-DateRange
    Write-Host "处理日期范围: $($dates -join ', ')" -ForegroundColor Cyan
    
    # === 数据收集阶段 ===
    # 创建四种事件容器
    $sunEvents = [System.Collections.Generic.List[string]]::new()
    $moonEvents = [System.Collections.Generic.List[string]]::new()
    $sunTimestampEvents = [System.Collections.Generic.List[string]]::new()
    $moonTimestampEvents = [System.Collections.Generic.List[string]]::new()
    
    # 步骤3: 按日期获取天文数据
    foreach ($date in $dates) {
        $weather = Get-WeatherData -cityCode $cityCode -date $date
        
        if ($weather) {
            # 数据质量日志
            $logData = @{
                Date = $weather.Date
                Sunrise = if ([string]::IsNullOrWhiteSpace($weather.Sunrise)) { "null" } else { $weather.Sunrise }
                Sunset = if ([string]::IsNullOrWhiteSpace($weather.Sunset)) { "null" } else { $weather.Sunset }
                Moonrise = if ([string]::IsNullOrWhiteSpace($weather.Moonrise)) { "null" } else { $weather.Moonrise }
                Moonset = if ([string]::IsNullOrWhiteSpace($weather.Moonset)) { "null" } else { $weather.Moonset }
            }
            
            Write-Host "获取到 $($logData.Date) 的天气数据:" -ForegroundColor DarkGray
            Write-Host "  日出: $($logData.Sunrise)" -ForegroundColor DarkGray
            Write-Host "  日落: $($logData.Sunset)" -ForegroundColor DarkGray
            Write-Host "  月出: $($logData.Moonrise)" -ForegroundColor DarkGray
            Write-Host "  月落: $($logData.Moonset)" -ForegroundColor DarkGray
            
            # 步骤4: 格式转换与收集
            # 太阳事件收集
            if ($sunEvent = Format-Event $weather.Date $weather.Sunrise "Sunrise") {
                $sunEvents.Add($sunEvent)
            }
            if ($sunEvent = Format-Event $weather.Date $weather.Sunset "Sunset") {
                $sunEvents.Add($sunEvent)
            }
            
            # 月亮事件收集
            if ($moonEvent = Format-Event $weather.Date $weather.Moonrise "Moonrise") {
                $moonEvents.Add($moonEvent)
            }
            if ($moonEvent = Format-Event $weather.Date $weather.Moonset "Moonset") {
                $moonEvents.Add($moonEvent)
            }
            
            # 时间戳事件收集
            if ($tsEvent = Format-TimestampEvent $weather.Date $weather.Sunrise "Sunrise") {
                $sunTimestampEvents.Add($tsEvent)
            }
            if ($tsEvent = Format-TimestampEvent $weather.Date $weather.Sunset "Sunset") {
                $sunTimestampEvents.Add($tsEvent)
            }
            if ($tsEvent = Format-TimestampEvent $weather.Date $weather.Moonrise "Moonrise") {
                $moonTimestampEvents.Add($tsEvent)
            }
            if ($tsEvent = Format-TimestampEvent $weather.Date $weather.Moonset "Moonset") {
                $moonTimestampEvents.Add($tsEvent)
            }
        } else {
            Write-Warning "未获取到 $date 的天气数据"
        }
    }
    
    # === 数据处理阶段 ===
    # 步骤5: 事件排序 (按时间升序)
    $sunEvents.Sort()
    $moonEvents.Sort()
    $sunTimestampEvents.Sort()
    $moonTimestampEvents.Sort()

    # 辅助函数：移除首尾行 (数据清洗)
    function Remove-FirstAndLastLines {
        param(
            [System.Collections.Generic.List[string]]$List
        )
        # 边界保护：至少需要1条数据
        if ($List.Count -gt 0) { $List.RemoveAt($List.Count - 1) }
        if ($List.Count -gt 0) { $List.RemoveAt(0) }
    }

    # 步骤6: 移除首尾日期数据 (窗口期裁剪)
    Remove-FirstAndLastLines -List $sunEvents
    Remove-FirstAndLastLines -List $moonEvents
    Remove-FirstAndLastLines -List $sunTimestampEvents
    Remove-FirstAndLastLines -List $moonTimestampEvents
    
    # === 文件输出阶段 ===
    $publicDocuments = "C:\Users\Public\Documents\Rainmeter Data"
    $filesWritten = @()
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false  # UTF-8无BOM编码
    
    # 步骤7: 写入四种事件文件
    if ($sunEvents.Count -gt 0) {
        $filePath = Join-Path $publicDocuments "SunEvents.txt"
        Write-FileWithoutTrailingNewline -Path $filePath -Content $sunEvents -Encoding $utf8NoBom
        $filesWritten += $filePath
    }
    if ($moonEvents.Count -gt 0) {
        $filePath = Join-Path $publicDocuments "MoonEvents.txt"
        Write-FileWithoutTrailingNewline -Path $filePath -Content $moonEvents -Encoding $utf8NoBom
        $filesWritten += $filePath
    }
    if ($sunTimestampEvents.Count -gt 0) {
        $filePath = Join-Path $publicDocuments "SunTimeStampEvent.txt"
        Write-FileWithoutTrailingNewline -Path $filePath -Content $sunTimestampEvents -Encoding $utf8NoBom
        $filesWritten += $filePath
    }
    if ($moonTimestampEvents.Count -gt 0) {
        $filePath = Join-Path $publicDocuments "MoonTimeStampEvent.txt"
        Write-FileWithoutTrailingNewline -Path $filePath -Content $moonTimestampEvents -Encoding $utf8NoBom
        $filesWritten += $filePath
    }
    
    # === 结果报告 ===
    Write-Host "`n文件生成成功！" -ForegroundColor Green
    Write-Host "太阳事件: $($sunEvents.Count) 条" -ForegroundColor Cyan
    Write-Host "月亮事件: $($moonEvents.Count) 条" -ForegroundColor Cyan
    Write-Host "太阳时间戳事件: $($sunTimestampEvents.Count) 条" -ForegroundColor Cyan
    Write-Host "月亮时间戳事件: $($moonTimestampEvents.Count) 条" -ForegroundColor Cyan
    Write-Host "文件位置: $publicDocuments" -ForegroundColor Green
    
    if ($filesWritten.Count -gt 0) {
        Write-Host "`n生成的文件:"
        $filesWritten | ForEach-Object { Write-Host "  - $_" }
    }
    
} 

catch {
    # === 全局异常处理 ===
    Write-Error "脚本执行失败: $_"
    # 错误日志路径：用户桌面
    $errorLogPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "SunMoonDataError.log"
    "错误时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $errorLogPath -Append
    $_ | Out-File $errorLogPath -Append
    Write-Host "详细错误信息已保存到: $errorLogPath" -ForegroundColor Red
}