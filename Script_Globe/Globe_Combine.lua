-- ============================================================
-- Globe.lua - Rainmeter地球光照计算脚本（合并太阳与月亮）
-- 功能：基于太阳位置计算地球光照模型，同时独立计算月亮升降进度
-- ============================================================


-- ===================== 脚本级变量定义 =====================
-- 这些变量在整个脚本中共享，但不是全局变量（避免命名冲突）

local SUN_FILE                                     -- 太阳事件文件路径
local MOON_FILE                                    -- 月亮事件文件路径
local LOCAL_LONGITUDE                              -- 本地经度（东经为正，西经为负）

-- 图片显示缓存（太阳）
local cachedSunEarthImage, cachedSunImageIndex     -- 当前太阳地球图片名称和索引
-- 图片显示缓存（月亮）
local cachedMoonEarthImage, cachedMoonImageIndex   -- 当前月亮地球图片名称和索引

-- 文件解析缓存
local cachedSunEvents, lastSunCheckTime            -- 日出日落事件列表和最后检查时间
local cachedMoonEvents, lastMoonCheckTime          -- 月出月落事件列表和最后检查时间

-- 地球状态缓存（太阳）
local cachedSunLongitude                           -- 当前太阳直射经度(-180到180)
local cachedSunTimeRatioT                          -- 当前太阳时间比例t(0→1→2)
local cachedTimeStatus                             -- 当前时间状态(白天/夜晚)
-- 地球状态缓存（月亮）
local cachedMoonLongitude                          -- 当前月亮“直射经度”(逻辑值)
local cachedMoonTimeRatioT                         -- 当前月亮时间比例t(0→1→2)

-- 静态计算缓存（太阳）
local cachedSunriseImageIndex, cachedSunsetImageIndex  -- 日出日落图片索引
-- 静态计算缓存（月亮）
local cachedMoonriseImageIndex, cachedMoonsetImageIndex -- 月出月落图片索引

-- 更新控制
local lastUpdateTime                               -- 上次更新时间戳


-- ===================== 配置与参数初始化 =====================
-- Rainmeter皮肤加载时执行，完成以下任务：
-- 1. 读取配置文件中的太阳事件文件路径
-- 2. 获取并规范化本地经度参数
-- 3. 初始化图片显示和状态缓存
-- 4. 预计算日出日落图片索引

function Initialize()
    -- === 文件路径配置 ===
    SUN_FILE = SELF:GetOption('SunFile') or "C:\\Users\\Public\\Documents\\Rainmeter Data\\SunTimeStampEvent.txt"
    MOON_FILE = SELF:GetOption('MoonFile') or "C:\\Users\\Public\\Documents\\Rainmeter Data\\MoonTimeStampEvent.txt"

    -- === 本地经度参数 ===
    LOCAL_LONGITUDE = tonumber(SELF:GetOption('LocalLongitude')) or 114 -- 默认114°E
    
    -- 确保经度在[-180, 180]范围内
    LOCAL_LONGITUDE = NormalizeLongitude(LOCAL_LONGITUDE)  -- 调用NormalizeLongitude函数规范化经度
    
    -- === 图片显示缓存（太阳） ===
    cachedSunEarthImage = "globe_000"  -- 当前太阳地球图片名称缓存（默认图片）
    cachedSunImageIndex = 0            -- 当前太阳图片索引缓存（0至359）
    -- === 图片显示缓存（月亮） ===
    cachedMoonEarthImage = "globe_000" -- 当前月亮地球图片名称缓存（默认图片）
    cachedMoonImageIndex = 0           -- 当前月亮图片索引缓存（0至359）
    
    -- === 文件解析缓存 ===
    cachedSunEvents = nil              -- 日出日落事件列表缓存
    cachedMoonEvents = nil             -- 月出月落事件列表缓存
    lastSunCheckTime = 0               -- 上次检查太阳事件文件时间戳
    lastMoonCheckTime = 0              -- 上次检查月亮事件文件时间戳
    
    -- === 地球状态缓存（太阳） ===
    cachedSunLongitude = 0             -- 当前太阳直射经度缓存(-180到180)
    cachedSunTimeRatioT = 0            -- 当前太阳时间比例t缓存(0(日出) → 1(日落) → 2(次日日出))
    cachedTimeStatus = "Day"           -- 当前时间状态缓存："Day"白天 / "Night"夜晚
    -- === 地球状态缓存（月亮） ===
    cachedMoonLongitude = 0            -- 当前月亮“直射经度”缓存(仅用于显示)
    cachedMoonTimeRatioT = 0           -- 当前月亮时间比例t缓存(0(月出) → 1(月落) → 2(次日月出))
    
    -- === 静态计算缓存 ===
    -- 调用GetMorningImageForLongitude和GetEveningImageForLongitude函数计算日出日落图片索引
    cachedSunriseImageIndex = GetMorningImageForLongitude(LOCAL_LONGITUDE)  -- 日出图片索引缓存
    cachedSunsetImageIndex = GetEveningImageForLongitude(LOCAL_LONGITUDE)   -- 日落图片索引缓存
    -- 月亮使用相同的图片索引（共用地球纹理），但独立存储以便未来扩展
    cachedMoonriseImageIndex = GetMorningImageForLongitude(LOCAL_LONGITUDE)  -- 月升图片索引缓存
    cachedMoonsetImageIndex = GetEveningImageForLongitude(LOCAL_LONGITUDE)   -- 月落图片索引缓存
    
    -- === 更新控制 ===
    lastUpdateTime = 0               -- 上次更新时间戳
    
    return true                      -- 初始化成功
end


-- ===================== 主更新循环 =====================
-- Rainmeter定期调用（UpdateDivider等于N），完成以下任务：
-- 1. 更新事件文件缓存（每天检查一次）
-- 2. 控制更新频率（每分钟最多更新一次）
-- 3. 查找当前时间最近的日出日落事件（太阳）
-- 4. 计算时间比例、图片索引和太阳直射经度
-- 5. 查找当前时间最近的月出月落事件（月亮）
-- 6. 计算月亮时间比例和图片索引
-- 7. 更新地球图片和状态缓存

function Update()
    local now = os.time()  -- 获取本地当前时间的时间戳

    -- === 太阳文件缓存更新策略（每天或缓存为空时更新） ===
    if not cachedSunEvents or (now - lastSunCheckTime) > 86400 then   -- 超过24小时未检查文件
        cachedSunEvents = ParseEvents(SUN_FILE)    -- 调用ParseEvents函数解析太阳事件文件
        lastSunCheckTime = now                     -- 记录最后检查时间
    end
    
    -- === 月亮文件缓存更新策略（每天或缓存为空时更新） ===
    if not cachedMoonEvents or (now - lastMoonCheckTime) > 86400 then   -- 超过24小时未检查文件
        cachedMoonEvents = ParseEvents(MOON_FILE)  -- 调用ParseEvents函数解析月亮事件文件
        lastMoonCheckTime = now                    -- 记录最后检查时间
    end
    
    -- 更新频率控制：每分钟最多更新一次
    if (now - lastUpdateTime) < 60 then return end
    
    -- ========== 处理太阳 ==========
    -- 事件数据无效时使用默认图片
    if not cachedSunEvents or #cachedSunEvents == 0 then
        cachedSunEarthImage = "globe_000"          -- 默认地球图片
        cachedSunImageIndex = 0                    -- 默认图片索引
        cachedSunLongitude = 0                     -- 默认太阳直射经度
        cachedSunTimeRatioT = 0                    -- 默认时间比例
        cachedTimeStatus = "Day"                   -- 默认时间状态
    else
        -- 调用FindNearestEvents函数查找当前时间的前后事件
        local prevEvent, nextEvent = FindNearestEvents(cachedSunEvents, now)

        -- 检查事件是否有效
        if not prevEvent or not nextEvent then
            cachedSunEarthImage = "globe_000"      -- 默认地球图片
            cachedSunImageIndex = 0                -- 默认图片索引
            cachedSunLongitude = 0                 -- 默认太阳直射经度
            cachedSunTimeRatioT = 0                -- 默认时间比例
            cachedTimeStatus = "Day"               -- 默认时间状态
        else
            -- 调用GetTimeRatioT函数计算当前时间在日出日落周期中的比例t
            cachedSunTimeRatioT = GetTimeRatioT(now, prevEvent, nextEvent, "Sun")
            
            -- 调用CalculateCurrentImageIndex函数计算当前地球图片索引
            cachedSunImageIndex = CalculateCurrentImageIndex(cachedSunTimeRatioT, cachedSunriseImageIndex, cachedSunsetImageIndex)
            
            -- 调用CalculateSunLongitude函数计算当前太阳直射经度
            cachedSunLongitude = CalculateSunLongitude(cachedSunTimeRatioT, cachedSunriseImageIndex, cachedSunsetImageIndex)
            
            -- 确定当前时间状态（白天或夜晚）
            if cachedSunTimeRatioT <= 1 then
                cachedTimeStatus = "Day"    -- t小于等于1表示白天（日出到日落）
            else
                cachedTimeStatus = "Night"  -- t大于1表示夜晚（日落到次日日出）
            end
            
            -- 更新太阳图片缓存：将索引转换为三位数格式的图片名称
            cachedSunEarthImage = string.format("globe_%03d", cachedSunImageIndex)
        end
    end

    -- ========== 处理月亮（独立于太阳） ==========
    if not cachedMoonEvents or #cachedMoonEvents == 0 then
        cachedMoonEarthImage = "globe_000"         -- 默认地球图片
        cachedMoonImageIndex = 0                   -- 默认图片索引
        cachedMoonLongitude = 0                    -- 默认月亮直射经度
        cachedMoonTimeRatioT = 0                   -- 默认时间比例
    else
        -- 查找月亮的前后事件
        local prevEvent, nextEvent = FindNearestEvents(cachedMoonEvents, now)

        if not prevEvent or not nextEvent then
            cachedMoonEarthImage = "globe_000"     -- 默认地球图片
            cachedMoonImageIndex = 0               -- 默认图片索引
            cachedMoonLongitude = 0                -- 默认月亮直射经度
            cachedMoonTimeRatioT = 0               -- 默认时间比例
        else
            -- 计算月亮时间比例（月出→月落为可见期）
            cachedMoonTimeRatioT = GetTimeRatioT(now, prevEvent, nextEvent, "Moon")
            
            -- 计算月亮对应的图片索引（逻辑值，可用于显示进度）
            cachedMoonImageIndex = CalculateCurrentImageIndex(cachedMoonTimeRatioT, cachedMoonriseImageIndex, cachedMoonsetImageIndex)
            
            -- 计算月亮“直射经度”（仅用于显示）
            cachedMoonLongitude = CalculateSunLongitude(cachedMoonTimeRatioT, cachedMoonriseImageIndex, cachedMoonsetImageIndex)
            
            -- 更新月亮图片缓存
            cachedMoonEarthImage = string.format("globe_%03d", cachedMoonImageIndex)
        end
    end

    lastUpdateTime = now    -- 更新最后更新时间
end


-- ===================== 辅助函数 =====================
-- 供主更新循环调用的通用数学计算函数

-- 解析事件文件  参数：事件文件路径  返回：事件列表 {time=时间戳,type=事件类型}
function ParseEvents(filePath)
    local events = {}                   -- 初始化事件列表
    local file = io.open(filePath, 'r') -- 以只读模式打开文件
    if not file then return events end  -- 文件无法打开，返回空列表
    
    for line in file:lines() do                     -- 逐行读取文件内容
        local timestamp = tonumber(line:sub(1, 10)) -- 前10字符为本地时间的时间戳
        if timestamp then                           -- 确保时间戳有效
            local eventType = line:sub(11)          -- 剩余部分为事件类型字符串
            table.insert(events, {time = timestamp, type = eventType})  -- 插入事件对象到列表
        end
    end
    file:close()                                                    -- 关闭文件
    table.sort(events, function(a, b) return a.time < b.time end)   -- 按时间排序事件列表
    return events                                                   -- 返回解析后的事件列表
end

-- 查找当前时间最近的前后事件  参数：事件列表，当前时间戳  返回：前事（最近过去的事件），后事件（最近未来的事件）
function FindNearestEvents(events, currentTime)
    if not events or #events == 0 then          -- 检查事件列表是否为空或无效
        return nil, nil                         -- 返回nil表示未找到事件
    end
    
    local prevEvent, nextEvent = nil, nil       -- 初始化前后事件变量
    
    -- 遍历事件列表查找最近事件
    for i = 1, #events do
        local event = events[i]                 -- 当前事件

        if event.time <= currentTime then       -- 查找前事件
            prevEvent = event                   -- 更新最近的前事件
        end
        if event.time > currentTime then        -- 查找后事件
            nextEvent = event                   -- 更新最近的后事件
            break                               -- 找到后事件后退出循环
        end
    end
    
    return prevEvent, nextEvent                 -- 返回找到的前后事件
end

-- 计算当前时间在日出日落或月出月落周期中的比例t
-- 参数：当前时间戳，前事件，后事件，天体类型("Sun"或"Moon")
-- 返回：时间比例t(t值范围：0(升起) → 1(落下) → 2(次日升起))
function GetTimeRatioT(now, prevEvent, nextEvent, bodyType)

    -- 容错检查：确保事件有效且时间不相等
    if not prevEvent or not nextEvent or prevEvent.time == nextEvent.time then
        return 0    -- 事件无效或时间相同，返回默认值
    end
    
    -- 计算时间比例
    local totalDuration = nextEvent.time - prevEvent.time   -- 前后事件时间差
    local elapsed = now - prevEvent.time                    -- 当前时间与前事件时间差
    local ratio = elapsed / totalDuration                   -- 计算比例
    ratio = math.max(0, math.min(1, ratio))                 -- 限制在0至1范围内
    
    local t
    if bodyType == "Sun" then
        if prevEvent.type == 'Sunrise' and nextEvent.type == 'Sunset' then
            t = ratio       -- 白天周期：t从0（日出）到1（日落）
        else
            t = 1 + ratio   -- 夜晚周期：t从1（日落）到2（次日日出）
        end
    elseif bodyType == "Moon" then
        if prevEvent.type == 'Moonrise' and nextEvent.type == 'Moonset' then
            t = ratio       -- 月出至月落为可见期
        else
            t = 1 + ratio   -- 月落至月出为隐藏期
        end
    else
        t = ratio
    end
    
    return t
end

-- 计算当前地球图片索引  参数：时间比例t，起始图片索引，结束图片索引  返回：地球图片索引(0-359)
function CalculateCurrentImageIndex(t, startIndex, endIndex)
    local imageIndex

    -- 判断时间阶段并执行相应插值
    if t <= 1 then
        -- 升起至落下：从起始索引到结束索引
        imageIndex = LinearInterpolate360(startIndex, endIndex, t)
    else
        -- 落下至次日升起：从结束索引到起始索引
        imageIndex = LinearInterpolate360(endIndex, startIndex, t - 1)
    end
    
    local rounded = math.floor(imageIndex + 0.5)    -- 四舍五入
    return rounded % 360                            -- 确保在 0-359 范围内
end

-- 计算当前太阳（或月亮）直射经度  参数：时间比例t，起始图片索引，结束图片索引  返回：经度(-180到180)
function CalculateSunLongitude(t, startIndex, endIndex)
    local imageIndexFloat

    -- 判断时间阶段并执行相应插值
    if t <= 1 then
        imageIndexFloat = LinearInterpolate360(startIndex, endIndex, t)
    else
        imageIndexFloat = LinearInterpolate360(endIndex, startIndex, t - 1)
    end

    local sunLon = -imageIndexFloat     -- 直射经度 = -图片索引
    return NormalizeLongitude(sunLon)   -- 规范化到[-180, 180]范围
end


-- ===================== 工具函数 =====================
-- 协助辅助函数完成相应工作

-- 1、线性插值函数，自动处理360度循环边界：
-- • 如果 起始值 ≤ 结束值: 正常线性插值
-- • 如果 起始值 > 结束值: 跨360度边界，将结束值加上360后插值
-- • 返回结果可能超过360，需要后续取模
-- 参数：起始值，结束值，插值比例(0-1)  返回值：插值结果
function LinearInterpolate360(start, finish, ratio)
    -- 判断是否跨越360度边界
    if start <= finish then
        -- 正常情况: 起始值 <= 结束值    直接线性插值
        return start + (finish - start) * ratio
    else
        -- 跨360度边界情况: 起始值 > 结束值    将结束值加上360，使插值方向正确
        return start + (finish + 360 - start) * ratio
    end
end

-- 2、将经度规范化到[-180, 180]范围：
-- • 确保输入为数字类型
-- • 取模360，得到[-359, 359]范围
-- • 调整到[-180, 180)标准范围
-- 参数：原始经度值  返回：规范化后的经度值
function NormalizeLongitude(lon)
    local lon = tonumber(lon) or 0  -- 确保是数字
    lon = lon % 360                 -- 取模360，得到[-359, 359]范围
    if lon > 180 then
        lon = lon - 360             -- 超过180的减去360，得到[-180, 180)范围
    elseif lon < -180 then
        lon = lon + 360             -- 低于-180的加上360，得到[-180, 180)范围
    end
    return lon
end

-- 3、计算给定经度位于晨线(左边界)时对应的地球图片索引：
-- • 晨线经度 = 太阳直射点经度 - 90°
-- • 太阳直射点经度 = -图片索引
-- • 推导公式：图片索引 = -经度 - 90
-- • 计算结果规范化到0-359范围并四舍五入
-- 参数：目标经度  返回：地球图片索引(0-359)
function GetMorningImageForLongitude(longitude)
    local lon = NormalizeLongitude(longitude)   -- 调用NormalizeLongitude函数规范化经度到[-180, 180]
    local imageIndex = -lon - 90                -- 推导公式：图片索引 = -经度 - 90

    imageIndex = imageIndex % 360               -- 规范化到0-359范围
    if imageIndex < 0 then
        imageIndex = imageIndex + 360
    end
    
    return math.floor(imageIndex + 0.5) % 360   -- 四舍五入并取模确保在有效范围内
end

-- 4、计算给定经度位于昏线(右边界)时对应的地球图片索引：
-- • 昏线经度 = 太阳直射点经度 + 90°
-- • 太阳直射点经度 = -图片索引
-- • 推导公式：图片索引 = 90 - 经度
-- • 计算结果规范化到0-359范围并四舍五入
-- 参数：目标经度  返回：地球图片索引(0-359)
function GetEveningImageForLongitude(longitude)
    local lon = NormalizeLongitude(longitude)   -- 调用NormalizeLongitude函数规范化经度到[-180, 180]
    local imageIndex = 90 - lon                 -- 推导公式：图片索引 = 90 - 经度
    
    imageIndex = imageIndex % 360               -- 规范化到0-359范围
    if imageIndex < 0 then
        imageIndex = imageIndex + 360
    end
    
    return math.floor(imageIndex + 0.5) % 360   -- 四舍五入并取模确保在有效范围内
end


-- ===================== 供Rainmeter调用的接口函数 =====================

-- 本地经度
function GetLocalLongitude() return LOCAL_LONGITUDE or 0 end

-- 当前太阳、月亮的直射经度
function GetCurrentSunLongitude() return string.format("%.1f", cachedSunLongitude or 0) end
function GetCurrentMoonLongitude() return string.format("%.1f", cachedMoonLongitude or 0) end

-- 当前显示的太阳、月亮图片名称
function GetSunEarthImage() return cachedSunEarthImage or "globe_000" end
function GetMoonEarthImage() return cachedMoonEarthImage or "globe_000" end
-- 当前显示的太阳、月亮图片索引(未启用，未格式化的图标编号)
function GetCurrentSunImageIndex() return string.format("%03d", cachedSunImageIndex or 0) end
function GetCurrentMoonImageIndex() return string.format("%03d", cachedMoonImageIndex or 0) end

-- 日出日落的图片索引(未启用)
function GetSunriseImageIndex() return cachedSunriseImageIndex or 0 end
function GetSunsetImageIndex() return cachedSunsetImageIndex or 0 end
-- 月出月落的图片索引(未启用)
function GetMoonriseImageIndex() return cachedMoonriseImageIndex or 0 end
function GetMoonsetImageIndex() return cachedMoonsetImageIndex or 0 end

-- 晨昏线对应的图片名称(未启用)
function GetSunMorningImage() return string.format('%03d', cachedSunriseImageIndex) end
function GetSunEveningImage() return string.format('%03d', cachedSunsetImageIndex) end
function GetMoonMorningImage() return string.format('%03d', cachedMoonriseImageIndex) end
function GetMoonEveningImage() return string.format('%03d', cachedMoonsetImageIndex) end

-- 当前时间在整天范围内的进程概况(太阳和月亮)
function GetCurrentSunTimeRatioT() return string.format("%.4f", (cachedSunTimeRatioT or 0) % 1) end
function GetCurrentMoonTimeRatioT() return string.format("%.4f", (cachedMoonTimeRatioT or 0) % 1) end
function GetTimeStatus() return cachedTimeStatus or "Day" end
