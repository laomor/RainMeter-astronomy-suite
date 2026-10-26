-- ============================================================
-- Globe.lua - Rainmeter地球光照计算脚本
-- 功能：基于日月升降时刻计算基于天体方向的地球可见面
-- ============================================================


-- ===================== 脚本级变量定义 =====================
-- 这些变量在整个脚本中共享，但不是全局变量（避免命名冲突）

local BODY_TYPE                                 -- 天体类型
local CALCULATE_FILE                            -- 天体升降事件文件路径
local LOCAL_LONGITUDE                           -- 本地经度（东经为正，西经为负）

-- 图片显示缓存
local cachedEarthImage, cachedImageIndex        -- 当前地球图片名称和索引

-- 文件解析缓存
local cachedEvents, lastFileCheckTime           -- 天体升降事件列表和最后检查时间

-- 地球状态缓存
local cachedCalculateLongitude                  -- 当前天体直射经度(-180到180)
local cachedTimeRatioT                          -- 当前时间比例t(0→1→2)
local cachedTimeStatus                          -- 当前天体可见状态(暴露/隐藏)

-- 静态计算缓存
local cachedCalculateriseImageIndex             -- 天体升起图片索引
local cachedCalculatesetImageIndex              -- 天体落下图片索引

-- 更新控制
local lastUpdateTime                            -- 上次更新时间戳


-- ===================== 配置与参数初始化 =====================
-- Rainmeter皮肤加载时执行，完成以下任务：
-- 1. 读取配置文件中的天体事件文件路径
-- 2. 获取并规范化本地经度参数
-- 3. 初始化图片显示和状态缓存
-- 4. 预计算天体升降图片索引

function Initialize()
    -- === 读取天体类型 ===
    BODY_TYPE = SELF:GetOption('BodyType') or 'Sun'                         -- 默认 Sun，防止留空

    -- === 文件路径配置 ===
    CALCULATE_FILE = SELF:GetOption('CalculateFile')                        -- 获取天体升降事件文件路径

    -- === 本地经度参数 ===
    LOCAL_LONGITUDE = tonumber(SELF:GetOption('LocalLongitude')) or 114     -- 默认114°E
    
    -- 确保经度在[-180, 180]范围内
    LOCAL_LONGITUDE = NormalizeLongitude(LOCAL_LONGITUDE)                   -- 调用NormalizeLongitude函数规范化经度
    
    -- === 图片显示缓存 ===
    cachedEarthImage = "globe_000"  -- 当前地球图片名称缓存（默认图片）
    cachedImageIndex = 0            -- 当前地球图片索引缓存（0至359）
    
    -- === 文件解析缓存 ===
    cachedEvents = nil              -- 天体升降事件列表缓存
    lastFileCheckTime = 0           -- 上次检查事件文件时间戳
    
    -- === 地球状态缓存 ===
    cachedCalculateLongitude = 0    -- 当前天体直射经度缓存(-180到180)
    cachedTimeRatioT = 0            -- 当前时间比例t缓存(0(升起) → 1(落下) → 2(次日升起))
    cachedTimeStatus = "Exposed"    -- 当前天体可见状态缓存："Exposed"暴露期间 / "Concealed"隐藏期间
    
    -- === 静态计算缓存 ===
    -- 调用GetMorningImageForLongitude和GetEveningImageForLongitude函数计算天体升降图片索引
    cachedCalculateriseImageIndex = GetMorningImageForLongitude(LOCAL_LONGITUDE)  -- 升起图片索引缓存
    cachedCalculatesetImageIndex = GetEveningImageForLongitude(LOCAL_LONGITUDE)   -- 落下图片索引缓存
    
    -- === 更新控制 ===
    lastUpdateTime = 0               -- 上次更新时间戳
    
    return true                      -- 初始化成功
end


-- ===================== 主更新循环 =====================
-- Rainmeter定期调用（UpdateDivider等于N），完成以下任务：
-- 1. 更新事件文件缓存（每天检查一次）
-- 2. 控制更新频率（每分钟最多更新一次）
-- 3. 查找当前时间最近的天体升降事件
-- 4. 计算时间比例、图片索引和天体直射经度
-- 5. 更新地球图片和状态缓存

function Update()
    local now = os.time()  -- 获取本地当前时间的时间戳

    -- 文件缓存更新策略（每天或缓存为空时更新）
    if not cachedEvents or (now - lastFileCheckTime) > 86400 then   -- 超过24小时未检查文件
        cachedEvents = ParseEvents(CALCULATE_FILE)                  -- 调用ParseEvents函数解析事件文件
        lastFileCheckTime = now                                     -- 记录最后检查时间
    end
    
    -- 更新频率控制：每分钟最多更新一次
    if (now - lastUpdateTime) < 60 then return end
    
    -- 事件数据无效时使用默认图片
    if not cachedEvents or #cachedEvents == 0 then
        cachedEarthImage = "globe_000"              -- 默认地球图片
        cachedImageIndex = 0                        -- 默认图片索引
        cachedCalculateLongitude = 0                -- 默认天体直射经度
        cachedTimeRatioT = 0                        -- 默认时间比例
        cachedTimeStatus = "Exposed"                -- 默认天体可见状态
        lastUpdateTime = now                        -- 更新最后更新时间
        return                                      -- 数据无效，直接返回
    end
    
    -- 调用FindNearestEvents函数查找当前时间的前后事件
    local prevEvent, nextEvent = FindNearestEvents(now)

    -- 检查事件是否有效
    if not prevEvent or not nextEvent then
        cachedEarthImage = "globe_000"          -- 默认地球图片
        cachedImageIndex = 0                    -- 默认图片索引
        cachedCalculateLongitude = 0            -- 默认天体直射经度
        cachedTimeRatioT = 0                    -- 默认时间比例
        cachedTimeStatus = "Exposed"            -- 默认天体可见状态
        lastUpdateTime = now                    -- 更新最后更新时间
        return                                  -- 事件无效，直接返回
    end

    -- 调用GetTimeRatioT函数计算当前时间在天体升降周期中的比例t
    cachedTimeRatioT = GetTimeRatioT(now, prevEvent, nextEvent, BODY_TYPE)
    
    -- 调用CalculateCurrentImageIndex函数计算当前地球图片索引
    cachedImageIndex = CalculateCurrentImageIndex(cachedTimeRatioT)
    
    -- 调用CalculateCalculateLongitude函数计算当前天体直射经度
    cachedCalculateLongitude = CalculateCalculateLongitude(cachedTimeRatioT)
    
    -- 确定天体可见状态（暴露或隐藏）
    if cachedTimeRatioT <= 1 then
        cachedTimeStatus = "Exposed"    -- t小于等于1表示暴露周期（升起到落下）
    else
        cachedTimeStatus = "Concealed"  -- t大于1表示隐藏周期（落下的次日升起）
    end
    
    -- 更新图片缓存：将索引转换为三位数格式的图片名称  格式：globe_001、globe_012、globe_123等
    cachedEarthImage = string.format("globe_%03d", cachedImageIndex)
    lastUpdateTime = now            -- 更新最后更新时间
end


-- ===================== 辅助函数 =====================
-- 供主更新循环调用的通用数学计算函数

-- 解析事件文件  参数：事件文件路径  返回：事件列表 {time=时间戳,type=事件类型}
function ParseEvents(filePath)
    local events = {}                       -- 初始化事件列表
    local file = io.open(filePath, 'r')     -- 以只读模式打开文件
    if not file then return events end      -- 文件无法打开，返回空列表
    
    for line in file:lines() do                         -- 逐行读取文件内容
        local timestamp = tonumber(line:sub(1, 10))     -- 前10字符为本地时间的时间戳
        if timestamp then                               -- 确保时间戳有效
            local eventType = line:sub(11)              -- 剩余部分为事件类型字符串
            table.insert(events, {time = timestamp, type = eventType})  -- 插入事件对象到列表
        end
    end
    file:close()                                                    -- 关闭文件
    table.sort(events, function(a, b) return a.time < b.time end)   -- 按时间排序事件列表
    return events                                                   -- 返回解析后的事件列表
end

-- 查找当前时间最近的前后事件  参数：当前时间戳  返回：前事（最近过去的事件），后事件（最近未来的事件）
function FindNearestEvents(currentTime)
    if not cachedEvents or #cachedEvents == 0 then  -- 检查事件列表是否为空或无效
        return nil, nil                             -- 返回nil表示未找到事件
    end
    
    local prevEvent, nextEvent  = nil, nil  -- 初始化前后事件变量
    
    -- 遍历事件列表查找最近事件
    for i = 1, #cachedEvents do
        local event = cachedEvents[i]       -- 当前事件

        if event.time <= currentTime then   -- 查找前事件
            prevEvent = event               -- 更新最近的前事件
        end
        if event.time > currentTime then    -- 查找后事件
            nextEvent = event               -- 更新最近的后事件
            break                           -- 找到后事件后退出循环
        end
    end
    
    return prevEvent, nextEvent     -- 返回找到的前后事件
end

-- 计算当前时间在天体升降周期中的比例t 参数：当前时间戳，前事件，后事件，天体类型（'Sun' / 'Moon'）  返回：时间比例t（0:升起 → 1:落下 → 2:次日升起）
function GetTimeRatioT(now, prevEvent, nextEvent, bodyType)

    -- 容错检查
    if not prevEvent or not nextEvent or prevEvent.time == nextEvent.time then
        return 0    -- 事件无效或时间相同，返回默认值
    end

    -- 计算时间比例
    local totalDuration = nextEvent.time - prevEvent.time               -- 前后事件时间差
    local elapsed = now - prevEvent.time                                -- 当前时间与前事件时间差
    local ratio = math.max(0, math.min(1, elapsed / totalDuration))     -- 计算比例，限制在0至1范围内

    -- 动态拼接事件名称：'Sun' + 'rise' = 'Sunrise'，'Moon' + 'set' = 'Moonset'
    local riseName = bodyType .. 'rise'
    local setName  = bodyType .. 'set'

    local t
    if prevEvent.type == riseName and nextEvent.type == setName then
        t = ratio       -- 白天/暴露周期（升起 → 落下）
    else
        t = 1 + ratio   -- 夜晚/隐藏周期（落下 → 次日升起）
    end

    return t
end

-- 计算当前地球图片索引  参数：时间比例t  返回：地球图片索引(0-359)
function CalculateCurrentImageIndex(t)
    local imageIndex

    -- 判断时间阶段并执行相应插值
    if t <= 1 then
        -- 白天：从升起图片索引到落下图片索引
        imageIndex = LinearInterpolate360(cachedCalculateriseImageIndex, cachedCalculatesetImageIndex, t)
    else
        -- 夜晚：从落下图片索引到次日升起图片索引
        imageIndex = LinearInterpolate360(cachedCalculatesetImageIndex, cachedCalculateriseImageIndex, t - 1)
    end
    
    local rounded = math.floor(imageIndex + 0.5)    -- 四舍五入
    return rounded % 360                            -- 确保在 0-359 范围内
end

-- 计算当前天体直射经度  参数：时间比例t  返回：天体直射经度(-180到180)
function CalculateCalculateLongitude(t)
    local imageIndexFloat

    -- 判断时间阶段并执行相应插值
    if t <= 1 then
        -- 白天：从升起图片索引到落下图片索引
        imageIndexFloat = LinearInterpolate360(cachedCalculateriseImageIndex, cachedCalculatesetImageIndex, t)
    else
        -- 夜晚：从落下图片索引到次日升起图片索引
        imageIndexFloat = LinearInterpolate360(cachedCalculatesetImageIndex, cachedCalculateriseImageIndex, t - 1)
    end

    local sunLon = -imageIndexFloat     -- 太阳直射经度 = -图片索引
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
-- • 晨线经度 = 天体直射点经度 - 90°
-- • 天体直射点经度 = -图片索引
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
-- • 昏线经度 = 天体直射点经度 + 90°
-- • 天体直射点经度 = -图片索引
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

-- 当前天体的直射经度
function GetCurrentCalculateLongitude() return string.format("%.1f", cachedCalculateLongitude or 0) end

-- 当前显示的图片名称及其所处位置（是第几张）
function GetEarthImage() return cachedEarthImage or "globe_000" end
function GetCurrentImageIndex() return string.format("%03d", cachedImageIndex or 0) end

-- 天体升起和落下的图片索引
function GetCalculateRiseImageIndex() return cachedCalculateriseImageIndex or 0 end
function GetCalculateSetImageIndex() return cachedCalculatesetImageIndex or 0 end

-- 晨昏线对应的图片名称
function GetMorningImage() return string.format('%03d', cachedCalculateriseImageIndex) end
function GetEveningImage() return string.format('%03d', cachedCalculatesetImageIndex) end

-- 当前时间在整天范围内的进程概况
function GetCurrentTimeRatioT() return string.format("%.4f", (cachedTimeRatioT or 0) % 1) end
function GetTimeStatus() return cachedTimeStatus or "Exposed" end