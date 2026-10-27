-- ============================================================
-- EventTracker.lua - Rainmeter天体事件时间追踪脚本
-- 功能：以当前时间为中心，滚动展示太阳和月亮在一段时间内的升降事件发生时刻
-- 设计理念：专注于事件时间点的精确记录与展示
-- ============================================================


-- ===================== 脚本级变量定义 =====================
-- 这些变量在整个脚本中共享，但不是全局变量（避免命名冲突）

-- 核心配置变量
local SUN_FILE, MOON_FILE                                       -- 事件文件路径
local SkinWidth, SkinHeight, IconSize, Length, OffsetValue      -- 皮肤和显示参数
local ContainerH, ContainerW, ContainerX, ContainerY            -- 容器位置和尺寸
local boundaryU, boundaryD, HorizonY, XAxisStart                -- 容器内坐标系统

-- 天体状态变量
local sunX, sunY, moonX, moonY                                  -- 天体在容器内的坐标
local sunState, moonState                                       -- 天体当前运动状态

-- 文件缓存变量
local cachedSunEvents, cachedMoonEvents                         -- 解析后的事件列表
local lastFileCheckTime                                         -- 上次文件检查时间戳

-- 数学计算参数：用于抛物线模型计算
local DayApexHigh, DayApexMid, DayApexLow                       -- 日间顶点高度参数（太阳在天空中的最高点）
local NightNadirHigh, NightNadirMid, NightNadirLow              -- 夜间底点高度参数（太阳在地平线下的最低点）
local MaxYOffsetPerSecond                                       -- 高度变化率(像素/秒)

-- 事件位置缓存
local sunEventsX, moonEventsX                                   -- 天体事件在时间轴上的X坐标
-- 事件时间缓存
local sunEventTimes, moonEventTimes                             -- 天体事件的格式化时间字符串

-- 时间轴参数
local SecondPerPixel                                            -- 时间轴缩放：每像素代表的秒数
local TimeOffsetInPixels                                        -- 当前时间在时间轴上的像素偏移
local TotalSeconds                                              -- 时间轴显示的总秒数范围


-- ===================== 配置与参数初始化 =====================
-- Rainmeter皮肤加载时执行，完成以下任务：
-- 1. 读取INI配置文件路径和参数
-- 2. 计算容器位置和大小
-- 3. 初始化坐标系统和天体位置
-- 4. 设置初始状态和缓存

function Initialize()
    -- === 文件路径配置 ===
    SUN_FILE = SELF:GetOption('SunFile') or 'C:\\Users\\Public\\Documents\\Rainmeter Data\\SunTimeStampEvent.txt'
    MOON_FILE = SELF:GetOption('MoonFile') or 'C:\\Users\\Public\\Documents\\Rainmeter Data\\MoonTimeStampEvent.txt'
    
    -- === 从INI获取基础参数 ===
    SkinWidth = tonumber(SELF:GetOption('SkinWidth')) or 210                    -- 皮肤总宽度（像素）
    SkinHeight = tonumber(SELF:GetOption('SkinHeight')) or 108                  -- 皮肤总高度（像素）
    IconSize = tonumber(SELF:GetOption('IconSize')) or 13                       -- 天体图标大小（像素）
    Length = tonumber(SELF:GetOption('Length')) or 144                          -- 时间轴可视部分长度（像素）
    SecondPerPixel = tonumber(SELF:GetOption('SecondPerPixel')) or 900          -- 每像素代表的秒数（控制时间轴缩放）
    TimeOffsetInPixels = tonumber(SELF:GetOption('TimeOffsetInPixels')) or 24   -- 当前时间在时间轴上的偏移量（像素）
    OffsetValue = tonumber(SELF:GetOption('OffsetValue')) or 4                  -- 昼夜时长动态高低点与基准点相差高度（像素）
    
    -- === 获取或计算容器高度 ===
    local containerHFromOption = SELF:GetOption('ContainerH')           -- 从选项获取ContainerH
    if containerHFromOption and containerHFromOption ~= "" then         -- 如果传入了ContainerH，则使用该值
        ContainerH = tonumber(containerHFromOption)                     -- 转换为数字
    else                                                                -- 如果没有传入ContainerH，使用默认计算公式
        ContainerH = SkinHeight - 14 - 39                               -- 计算容器高度，使其顶、底部与皮肤边界具有安全距离(14;39)
    end

    -- === 计算容器参数 ===
    ContainerW = SkinWidth - 20                    -- 计算容器宽度，使容器小于皮肤宽度20像素
    ContainerX = (SkinWidth/2 - ContainerW/2) - 1  -- 计算容器X坐标，使其水平居中
    ContainerY = SkinHeight - 14 - ContainerH      -- 计算容器Y坐标，使其底部距离皮肤底部14像素
    
    -- === 计算容器内坐标系统 ===
    -- 注意：容器内坐标从（0，0）开始，到（ContainerW，ContainerH减1）结束
    boundaryU = 0                               -- 上边界（容器内）
    boundaryD = ContainerH - 1                  -- 下边界（容器内）
    HorizonY = (ContainerH - 1) / 2             -- 地平线位置（容器内）
    XAxisStart = ContainerW / 2 - Length / 2    -- 时间轴起点（容器内）
    
    -- === 计算天体固定位置(基于时间轴比例) ===
    local CelestialX = XAxisStart + TimeOffsetInPixels  -- 天体在容器内的X坐标
    
    -- === 计算图标半高 ===
    local iconSizeHalf = (IconSize + 1) / 2       -- 图标半高（用于边界计算）
    
    -- === 计算日间高度参数(使用boundaryU) ===
    DayApexHigh = boundaryU + iconSizeHalf + OffsetValue - OffsetValue  -- 日顶点最高高度 = DayApexMid - OffsetValue
    DayApexMid = boundaryU + iconSizeHalf + OffsetValue                 -- 日顶点基准高度
    DayApexLow = boundaryU + iconSizeHalf + OffsetValue + OffsetValue   -- 日顶点最低高度 = DayApexMid + OffsetValue
    
    -- === 计算夜间高度参数(使用boundaryD) ===
    NightNadirHigh = boundaryD - iconSizeHalf - OffsetValue - OffsetValue   -- 夜底点最高高度 = NightNadirMid - OffsetValue
    NightNadirMid = boundaryD - iconSizeHalf - OffsetValue                  -- 夜底点基准高度
    NightNadirLow = boundaryD - iconSizeHalf - OffsetValue + OffsetValue    -- 夜底点最低高度 = NightNadirMid + OffsetValue
    
    -- === 计算地平线距离变化率 ===
    MaxYOffsetPerSecond = 7200 / (OffsetValue)  -- 7200秒（2小时）对应OffsetValue像素的高度变化
    
    -- === 计算时间轴范围 ===
    TotalSeconds = Length * SecondPerPixel  -- 时间轴显示的总秒数（用于事件位置计算）

    -- === 状态缓存 ===
    sunState, moonState = "unknown", "unknown"  -- 当前天体状态(上升/下降/未知)
    
    -- === 天体位置缓存 ===
    sunX = CelestialX                   -- 太阳固定X坐标（容器内）
    moonX = CelestialX                  -- 月亮固定X坐标（容器内）
    sunY, moonY = HorizonY, HorizonY    -- Y坐标动态计算（容器内）
    
    -- === 事件标记缓存 ===
    sunEventsX = {0, 0, 0, 0, 0}    -- 太阳事件X坐标（容器内）
    moonEventsX = {0, 0, 0, 0, 0}   -- 月亮事件X坐标（容器内）
    
    -- === 事件时间格式化缓存 ===
    sunEventTimes = {"N/A", "N/A", "N/A", "N/A", "N/A"}     -- 太阳事件时间
    moonEventTimes = {"N/A", "N/A", "N/A", "N/A", "N/A"}    -- 月亮事件时间
    
    -- === 文件解析缓存 ===
    cachedSunEvents, cachedMoonEvents = nil, nil  -- 解析后的事件列表
    lastFileCheckTime = 0                         -- 上次检查文件时间戳
end


-- ===================== 主更新循环 =====================
-- Rainmeter定期调用（UpdateDivider等于N），完成以下任务：
-- 1. 更新事件文件缓存（每天检查一次）
-- 2. 计算当前时间在时间轴上的位置
-- 3. 更新太阳和月亮的位置和状态
-- 4. 计算事件标记在时间轴上的位置

function Update()
    local now = os.time()  -- 本地当前时间的时间戳
    
    -- 文件缓存更新策略（每天或缓存为空时更新）
    if not cachedSunEvents or not cachedMoonEvents or (now - lastFileCheckTime) > 86400 then    -- 超过24小时未检查文件
        cachedSunEvents = ParseEvents(SUN_FILE)     -- 调用ParseEvents函数解析SunTimeStampEvent文件
        cachedMoonEvents = ParseEvents(MOON_FILE)   -- 调用ParseEvents函数解析MoonTimeStampEvent文件
        lastFileCheckTime = now                     -- 记录最后检查时间
    end
    
    -- 计算时间轴范围
    local axisStartTime = now - TimeOffsetInPixels * SecondPerPixel   -- 计算时间轴起始时间
    local axisEndTime = axisStartTime + TotalSeconds                  -- 计算时间轴结束时间    

    -- 重置事件数组
    ResetEventArrays()  -- 调用ResetEventArrays函数重置事件数组
    
    -- 获取当前时间点最近的前后事件
    local sunPrev, sunNext = FindNearestEvents(cachedSunEvents, now)    -- 调用FindNearestEvents函数获取太阳事件对：（前事件，后事件）
    local moonPrev, moonNext = FindNearestEvents(cachedMoonEvents, now) -- 调用FindNearestEvents函数获取月亮事件对：（前事件，后事件）
    
    -- 计算太阳位置和状态
    if sunPrev and sunNext then
        -- 调用CalculateY函数计算Y坐标（基于抛物线模型）
        sunY = CalculateY(now, sunPrev.time, sunNext.time, sunPrev.type, sunNext.type, true)
        -- 调用CalculateState函数计算太阳是处在上升状态还是下降状态
        sunState = CalculateState(now, sunPrev.time, sunNext.time, sunPrev.type, sunNext.type)
    else
        sunY = HorizonY         -- 默认位置（地平线中央）
        sunState = "unknown"    -- 默认状态（未知）
    end

    -- 计算月亮位置和状态
    if moonPrev and moonNext then
        -- 调用CalculateY函数计算Y坐标（基于抛物线模型）
        moonY = CalculateY(now, moonPrev.time, moonNext.time, moonPrev.type, moonNext.type, false)
        -- 调用CalculateState函数计算月亮是处在上升状态还是下降状态
        moonState = CalculateState(now, moonPrev.time, moonNext.time, moonPrev.type, moonNext.type)
    else
        moonY = HorizonY        -- 默认位置（地平线中央）
        moonState = "unknown"   -- 默认状态（未知）
    end

    -- 查找需要的太阳事件
    if cachedSunEvents and #cachedSunEvents > 0 then
        -- Event1：当前时间之前最近的一个事件
        for i = #cachedSunEvents, 1, -1 do      -- 从事件列表末尾向前遍历（从最新事件向最早事件查找）
            local event = cachedSunEvents[i]    -- 获取当前遍历到的事件对象
            if event.time <= now then           -- 检查事件时间是否早于或等于当前时间
                -- 调用CalculateEventPosition函数计算事件在时间轴上的位置
                sunEventsX[1] = CalculateEventPosition(event.time, axisStartTime, axisEndTime)
                -- 调用FormatEventTime函数格式化事件时间
                sunEventTimes[1] = FormatEventTime(event.time)
                break   -- 找到最近的前事件后立即停止查找
            end
        end
        
        -- Event2至Event5：当前时间之后的四个事件
        local eventCount = 2
        for i = 1, #cachedSunEvents do          -- 从事件列表开头向后遍历（从最早事件向最新事件查找）
            if eventCount > 5 then break end    -- 事件计数器超过5，停止查找
            local event = cachedSunEvents[i]    -- 获取当前遍历到的事件对象
            if event.time > now then            -- 检查事件时间是否晚于当前时间
                -- 调用CalculateEventPosition函数计算事件在时间轴上的位置
                sunEventsX[eventCount] = CalculateEventPosition(event.time, axisStartTime, axisEndTime)
                -- 调用FormatEventTime函数格式化事件时间
                sunEventTimes[eventCount] = FormatEventTime(event.time)
                eventCount = eventCount + 1 -- 递增事件计数器，准备查找下一个后事件
            end
        end
    end

    -- 查找需要的月亮事件
    if cachedMoonEvents and #cachedMoonEvents > 0 then
        -- Event1：当前时间之前最近的一个事件
        for i = #cachedMoonEvents, 1, -1 do     -- 从事件列表末尾向前遍历（从最新事件向最早事件查找）
            local event = cachedMoonEvents[i]   -- 获取当前遍历到的事件对象
            if event.time <= now then           -- 检查事件时间是否早于或等于当前时间
                -- 调用CalculateEventPosition函数计算事件在时间轴上的位置
                moonEventsX[1] = CalculateEventPosition(event.time, axisStartTime, axisEndTime)
                -- 调用FormatEventTime函数格式化事件时间
                moonEventTimes[1] = FormatEventTime(event.time)
                break   -- 找到最近的前事件后立即停止查找
            end
        end
        
        -- Event2至Event5：当前时间之后的四个事件
        local eventCount = 2
        for i = 1, #cachedMoonEvents do         -- 从事件列表开头向后遍历（从最早事件向最新事件查找）
            if eventCount > 5 then break end    -- 事件计数器超过5，停止查找            
            local event = cachedMoonEvents[i]   -- 获取当前遍历到的事件对象
            if event.time > now then            -- 检查事件时间是否晚于当前时间
                -- 调用CalculateEventPosition函数计算事件在时间轴上的位置
                moonEventsX[eventCount] = CalculateEventPosition(event.time, axisStartTime, axisEndTime)
                -- 调用FormatEventTime函数格式化事件时间
                moonEventTimes[eventCount] = FormatEventTime(event.time)
                eventCount = eventCount + 1 -- 递增事件计数器，准备查找下一个后事件
            end
        end
    end
end


-- ===================== 辅助函数 =====================
-- 供主更新循环调用的函数

-- 解析事件文件  参数：事件文件路径  返回：按时间排序的事件列表 {time=时间戳,type=事件类型}
function ParseEvents(filePath)
    local events = {}                   -- 初始化空事件列表
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

-- 重置事件数组函数
function ResetEventArrays()
    for i = 1, 5 do                                     -- 遍历事件数组索引
        sunEventsX[i], sunEventTimes[i] = 0, "N/A"      -- 重置太阳事件数组
        moonEventsX[i], moonEventTimes[i] = 0, "N/A"    -- 重置月亮事件数组
    end
end

-- 查找当前时间最近的前后事件  参数：已排序的事件列表，当前时间戳
-- 返回：当前时间之前最近的事件，当前时间之后最近的事件，前事件在列表中的索引，后事件在列表中的索引
function FindNearestEvents(events, currentTime)
    if not events or #events == 0 then  -- 检查事件列表是否为空或无效
        return nil, nil, nil, nil       -- 返回nil表示未找到事件
    end

    local prevEvent, nextEvent, prevIdx, nextIdx  = nil, nil, nil, nil    -- 初始化事件变量
    
    -- 遍历事件列表（利用事件已排序的特性）    
    for i = 1, #events do
        local event = events[i]             -- 当前事件

        if event.time <= currentTime then   -- 更新前事件
            prevEvent = event               -- 更新最近的前事件
            prevIdx = i                     -- 记录前事件索引
        end
        if event.time > currentTime then    -- 找到后事件
            nextEvent = event               -- 更新最近的后事件
            nextIdx = i                     -- 记录后事件索引
            break                           -- 找到后立即退出
        end
    end

    return prevEvent, nextEvent, prevIdx, nextIdx   -- 返回结果
end

-- 计算天体在时间轴上的位置（基于抛物线模型）
-- 参数：当前时间戳，前事件时间戳，后事件时间戳，前事件类型，后事件类型，是否是太阳  返回：天体在容器内的Y坐标
function CalculateY(currentTime, prevTime, nextTime, prevType, nextType, isSun)
    -- 计算当前在事件周期中的位置比例[0,1]
    local ratio = (currentTime - prevTime) / (nextTime - prevTime)
    
    -- 判断天体是否在地平线上（可见状态）
    local isAboveHorizon = false
    if isSun then
        isAboveHorizon = (prevType == "Sunrise" and nextType == "Sunset")       -- 太阳可见周期：日出后到日落前
    else
        isAboveHorizon = (prevType == "Moonrise" and nextType == "Moonset")     -- 月亮可见周期：月出后到月落前
    end
    
    -- 计算Y轴位置（抛物线模型）
    local y
    if isAboveHorizon then
        -- === 地平线上抛物线(开口向下) ===
        if isSun then
            -- 太阳：根据白昼时长动态调整最高点
            local daytimeDuration = nextTime - prevTime                             -- 白昼时长
            local apexOffset = (daytimeDuration - 43200) / MaxYOffsetPerSecond      -- 43200 = 12小时(基准值)
            local apexHeight = DayApexMid - apexOffset                              -- 夏季顶点较高，冬季较低
            apexHeight = math.max(DayApexHigh, math.min(DayApexLow, apexHeight))    -- 约束在有效范围内
            -- 抛物线公式: y = 地平线 - (地平线-最高点)*(1-(2t-1)^2)
            y = HorizonY - (HorizonY - apexHeight) * (1 - (2 * ratio - 1)^2)        -- 当 t=0.5(正午) 时达到顶点
        else
            -- 月亮：固定最高点（简化模型）
            y = HorizonY - (HorizonY - DayApexMid) * (1 - (2 * ratio - 1)^2)        -- 当 t=0.5(正午) 时达到最高点
        end
    else
        -- === 地平线下抛物线(开口向上) ===
        if isSun then
            -- 太阳：根据黑夜时长动态调整最低点
            local nighttimeDuration = nextTime - prevTime                                   -- 黑夜时长
            local nadirOffset = (nighttimeDuration - 43200) / MaxYOffsetPerSecond           -- 43200 = 12小时(基准值)
            local nadirHeight = NightNadirMid + nadirOffset                                 -- 夏季底点较浅，冬季较深
            nadirHeight = math.max(NightNadirHigh, math.min(NightNadirLow, nadirHeight))    -- 约束在有效范围内
            -- 抛物线公式: y = 地平线 + (最低点-地平线)*(1-(2t-1)^2)
            y = HorizonY + (nadirHeight - HorizonY) * (1 - (2 * ratio - 1)^2)               -- 当 t=0.5(午夜) 时达到底点
        else
            -- 月亮：固定最低点（简化模型）
            y = HorizonY + (NightNadirMid - HorizonY) * (1 - (2 * ratio - 1)^2)             -- 当 t=0.5(午夜) 时达到最低点
        end
    end
    
    return y    -- 返回计算得到的Y坐标
end

-- 判断天体当前运动状态  参数：当前时间戳，前事件时间戳，后事件时间戳，前事件类型，后事件类型  返回：Rise或Fall
function CalculateState(currentTime, prevTime, nextTime, prevType, nextType)
    local midTime = (prevTime + nextTime) / 2   -- 计算周期中点时间戳
    
    -- 可见周期判断(日出→日落 或 月出→月落)
    if (prevType == "Sunrise" and nextType == "Sunset") or (prevType == "Moonrise" and nextType == "Moonset") then
        -- 可见周期：前半段上升，后半段下降
        return (currentTime < midTime) and "Rise" or "Fall"
    else
        -- 不可见周期：前半段下降，后半段上升
        return (currentTime < midTime) and "Fall" or "Rise"
    end
end

-- 计算事件在时间轴上的X坐标位置  参数：事件时间戳，时间轴起始时间戳，时间轴结束时间戳  返回：事件在容器内的X坐标
function CalculateEventPosition(eventTime, axisStartTime, axisEndTime)
    -- 检查事件是否在时间轴范围内
    if eventTime < axisStartTime then
        return -20   -- 事件在时间轴开始之前，返回容器之前20个像素的位置
    elseif eventTime > axisEndTime then
        return ContainerW + 20  -- 事件在时间轴结束之后，返回容器之后20个像素的位置
    else
        -- 事件在时间轴范围内，正常计算坐标
        local timeDiff = eventTime - axisStartTime  -- 计算事件时间与时间轴起始时间的差值（秒数）
        local pixelPos = timeDiff / SecondPerPixel  -- 计算事件相对于时间轴起始位置的像素偏移
        local xPos = XAxisStart + pixelPos          -- 计算事件的X坐标（容器内）
        return xPos                                 -- 返回事件的X坐标
    end
end

-- 格式化事件时间  参数：时间戳  返回：格式化后的时间字符串("HH:MM")
function FormatEventTime(timestamp) return os.date("%H:%M", timestamp) end


-- ===================== 供Rainmeter调用的接口函数 =====================

-- 容器位置和大小接口
function GetContainerX() return ContainerX or 9 end                         -- 容器X坐标
function GetContainerY() return ContainerY or 39 end                        -- 容器Y坐标
function GetContainerW() return ContainerW or 190 end                       -- 容器宽度
function GetContainerH() return ContainerH or (SkinHeight - 14 - 39) end    -- 容器高度

-- 容器内地平线位置
function GetHorizonY() return HorizonY or ((ContainerH - 1)/2) end  -- 地平线位置（容器内）

-- 时间轴参数
function GetXAxisStart() return XAxisStart or 23 end    -- 时间轴起点（容器内）
function GetLength() return Length or 144 end           -- 时间轴长度

-- 太阳固定位置（容器内坐标）
function GetSunX() return sunX or (XAxisStart + 24) end     -- 太阳固定X坐标（容器内）
function GetSunY() return sunY or HorizonY end              -- 太阳Y坐标（容器内）

-- 月亮固定位置（容器内坐标）
function GetMoonX() return moonX or (XAxisStart + 24) end   -- 月亮固定X坐标（容器内）
function GetMoonY() return moonY or HorizonY end            -- 月亮Y坐标（容器内）

-- 天体当前运动状态
function GetSunState() return sunState or "unknown" end     -- "Rise"/"Fall"/"unknown"
function GetMoonState() return moonState or "unknown" end   -- "Rise"/"Fall"/"unknown"

-- 太阳事件标记位置（容器内X坐标）
function GetSunEvent1() return sunEventsX[1] or 0 end   -- 太阳事件1标记位置
function GetSunEvent2() return sunEventsX[2] or 0 end   -- 太阳事件2标记位置
function GetSunEvent3() return sunEventsX[3] or 0 end   -- 太阳事件3标记位置
function GetSunEvent4() return sunEventsX[4] or 0 end   -- 太阳事件4标记位置
function GetSunEvent5() return sunEventsX[5] or 0 end   -- 太阳事件5标记位置

-- 月亮事件标记位置（容器内X坐标）
function GetMoonEvent1() return moonEventsX[1] or 0 end     -- 月亮事件1标记位置
function GetMoonEvent2() return moonEventsX[2] or 0 end     -- 月亮事件2标记位置
function GetMoonEvent3() return moonEventsX[3] or 0 end     -- 月亮事件3标记位置
function GetMoonEvent4() return moonEventsX[4] or 0 end     -- 月亮事件4标记位置
function GetMoonEvent5() return moonEventsX[5] or 0 end     -- 月亮事件5标记位置

-- 太阳事件时间（格式化）
function GetSunEventTime1() return sunEventTimes[1] or "N/A" end    -- 太阳事件1时间
function GetSunEventTime2() return sunEventTimes[2] or "N/A" end    -- 太阳事件2时间
function GetSunEventTime3() return sunEventTimes[3] or "N/A" end    -- 太阳事件3时间
function GetSunEventTime4() return sunEventTimes[4] or "N/A" end    -- 太阳事件4时间
function GetSunEventTime5() return sunEventTimes[5] or "N/A" end    -- 太阳事件5时间

-- 月亮事件时间（格式化）
function GetMoonEventTime1() return moonEventTimes[1] or "N/A" end  -- 月亮事件1时间
function GetMoonEventTime2() return moonEventTimes[2] or "N/A" end  -- 月亮事件2时间
function GetMoonEventTime3() return moonEventTimes[3] or "N/A" end  -- 月亮事件3时间
function GetMoonEventTime4() return moonEventTimes[4] or "N/A" end  -- 月亮事件4时间
function GetMoonEventTime5() return moonEventTimes[5] or "N/A" end  -- 月亮事件5时间

-- 时间轴范围信息
function GetTimeRangeStart()                                                  -- 获取时间轴起始时间字符串
    local now = os.time()                                                     -- 本地当前时间的时间戳
    local axisStartTime = now - TimeOffsetInPixels * SecondPerPixel           -- 计算时间轴起始时间
    return os.date("%H:%M", axisStartTime)                                    -- 返回格式化时间字符串
end

function GetTimeRangeEnd()                                                    -- 获取时间轴结束时间字符串
    local now = os.time()                                                     -- 本地当前时间的时间戳
    local axisStartTime = now - TimeOffsetInPixels * SecondPerPixel           -- 计算时间轴起始时间
    local axisEndTime = axisStartTime + TotalSeconds                          -- 计算时间轴结束时间
    return os.date("%H:%M", axisEndTime)                                      -- 返回格式化时间字符串
end
