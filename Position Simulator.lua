-- ============================================================
-- PositionSimulator.lua - Rainmeter天体视位置模拟脚本
-- 功能：基于地面固定观察点，模拟太阳和月亮在天空中的实际视位置
-- 设计理念：专注于地面观测者视角的精确位置模拟
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
local cachedSunriseX, cachedSunsetX                             -- 日出与日落事件的X轴坐标
local cachedMoonriseX, cachedMoonsetX                           -- 月出与月落事件的X轴坐标
-- 事件时间缓存
local cachedSunriseTime, cachedSunsetTime                       -- 日出与日落的时间字符串
local cachedMoonriseTime, cachedMoonsetTime                     -- 月出与月落的时间字符串

-- 周期计算参数
local sunCycle, moonCycle                                       -- 天体当前四事件周期数据
local lastCycleCheck                                            -- 上次周期检查时间戳


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
    SkinWidth = tonumber(SELF:GetOption('SkinWidth')) or 210            -- 皮肤总宽度（像素）
    SkinHeight = tonumber(SELF:GetOption('SkinHeight')) or 108          -- 皮肤总高度（像素）
    IconSize = tonumber(SELF:GetOption('IconSize')) or 13               -- 天体图标大小（像素）
    Length = tonumber(SELF:GetOption('Length')) or 144                  -- 时间轴可视部分长度（像素）
    OffsetValue = tonumber(SELF:GetOption('OffsetValue')) or 4          -- 昼夜时长动态高低点与基准点相差高度（像素）
    
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
    boundaryU = 0                            -- 上边界（容器内）
    boundaryD = ContainerH - 1               -- 下边界（容器内）
    HorizonY = (ContainerH - 1) / 2          -- 地平线位置（容器内）
    XAxisStart = ContainerW / 2 - Length / 2 -- 时间轴起点（容器内）
    
    -- === 计算图标半高 ===
    local iconSizeHalf = (IconSize + 1) / 2  -- 图标半高（用于边界计算）
    
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
    
    -- === 状态缓存 ===
    sunState, moonState = "unknown", "unknown"  -- 当前天体状态(上升/下降/未知)
    sunX, sunY = XAxisStart, HorizonY           -- 当前太阳位置（容器内坐标）
    moonX, moonY = XAxisStart, HorizonY         -- 当前月亮位置（容器内坐标）
    
    -- === 事件位置缓存 ===
    cachedSunriseX, cachedSunsetX = 0, 0        -- 日出日落事件在时间轴上的X坐标（容器内X坐标）
    cachedMoonriseX, cachedMoonsetX = 0, 0      -- 月出月落事件在时间轴上的X坐标（容器内X坐标）
    
    -- === 事件时间缓存 ===
    cachedSunriseTime, cachedSunsetTime = "N/A", "N/A"      -- 日出与日落的时间(HH:MM)
    cachedMoonriseTime, cachedMoonsetTime = "N/A", "N/A"    -- 月出与月落的时间(HH:MM)
    
    -- === 文件解析缓存 ===
    cachedSunEvents, cachedMoonEvents = nil, nil    -- 解析后的事件列表
    lastFileCheckTime = 0                           -- 上次文件检查时间戳
    
    -- === 周期缓存 ===
    sunCycle = {}       -- 太阳的当前四事件周期（包含四个关键事件时间点）
    moonCycle = {}      -- 月亮的当前四事件周期（包含四个关键事件时间点）
    lastCycleCheck = 0  -- 上次检查周期的时间戳（用于控制周期更新频率）
end


-- ===================== 主更新循环 =====================
-- Rainmeter定期调用（UpdateDivider等于N），完成以下任务：
-- 1. 更新事件文件缓存（每天检查一次）
-- 2. 计算太阳和月亮的四事件周期
-- 3. 计算天体在时间轴上的位置和状态
-- 4. 更新事件标记位置和时间

function Update()
    local now = os.time()  -- 本地当前时间的时间戳
    
    -- 文件缓存更新策略（每天或缓存为空时更新）
    if not cachedSunEvents or not cachedMoonEvents or (now - lastFileCheckTime) > 86400 then    -- 超过24小时未检查文件
        cachedSunEvents = ParseEvents(SUN_FILE)     -- 调用ParseEvents函数解析太阳事件文件
        cachedMoonEvents = ParseEvents(MOON_FILE)   -- 调用ParseEvents函数解析月亮事件文件
        lastFileCheckTime = now  -- 记录最后检查时间
    end
    
    -- 每1分钟检查一次周期是否变化（避免频繁计算）
    if (now - lastCycleCheck) >= 60 then
        -- 调用FindFourEvents函数查找太阳的当前四事件周期
        sunCycle = FindFourEvents(cachedSunEvents, now, "Sun") or sunCycle
        
        -- 调用FindFourEvents函数查找月亮的当前四事件周期
        moonCycle = FindFourEvents(cachedMoonEvents, now, "Moon") or moonCycle
        
        lastCycleCheck = now  -- 更新最后检查时间
    end

    -- 调用FindNearestEvents函数获取太阳当前时间的前后事件
    local sunPrev, sunNext, sunPrevIdx, sunNextIdx = FindNearestEvents(cachedSunEvents, now)
    -- 调用FindNearestEvents函数获取月亮当前时间的前后事件
    local moonPrev, moonNext, moonPrevIdx, moonNextIdx = FindNearestEvents(cachedMoonEvents, now)

    -- === 计算太阳位置和状态 ===
    if sunCycle.startTime and sunCycle.endTime then
        -- 计算太阳在时间轴上的比例位置 [0,1]
        local sunRatio = (now - sunCycle.startTime) / (sunCycle.endTime - sunCycle.startTime)
        sunRatio = math.max(0, math.min(1, sunRatio))  -- 限制在0至1范围内
        
        sunX = XAxisStart + sunRatio * Length          -- 计算X坐标（基于时间轴比例，容器内坐标）
        
        UpdateSunEvents(sunCycle)   -- 调用UpdateSunEvents函数来更新太阳事件标记位置和时间的缓存数据
    else
        sunX = XAxisStart   -- 默认位置
    end

    if sunPrev and sunNext then
        -- 调用CalculateY函数计算太阳在Y轴上的位置（使用抛物线模型）
        sunY = CalculateY(now, sunPrev.time, sunNext.time, sunPrev.type, sunNext.type, true)
    else
        sunY = HorizonY     -- 默认位置
    end

    if sunPrev and sunNext then
        -- 调用CalculateState函数计算太阳是处在上升状态还是下降状态
        sunState = CalculateState(now, sunPrev.time, sunNext.time, sunPrev.type, sunNext.type)
    else
        sunState = "unknown"    -- 默认状态（未知）
    end
    
    -- === 计算月亮位置和状态 ===
    if moonCycle.startTime and moonCycle.endTime then
        -- 计算月亮在时间轴上的比例位置 [0,1]
        local moonRatio = (now - moonCycle.startTime) / (moonCycle.endTime - moonCycle.startTime)
        moonRatio = math.max(0, math.min(1, moonRatio))  -- 限制在0至1范围内
        
        moonX = XAxisStart + moonRatio * Length          -- 计算X坐标（基于时间轴比例，容器内坐标）
        
        UpdateMoonEvents(moonCycle)  -- 调用UpdateMoonEvents函数来更新月亮事件标记位置和时间的缓存数据
    else
        -- 默认位置和状态
        moonX = XAxisStart  -- 默认位置
    end

    if moonPrev and moonNext then
        -- 调用CalculateY函数计算月亮在Y轴上的位置（使用抛物线模型）
        moonY = CalculateY(now, moonPrev.time, moonNext.time, moonPrev.type, moonNext.type, false)
    else
        moonY = HorizonY    -- 默认位置
    end
    
    if moonPrev and moonNext then
        -- 调用CalculateState函数计算月亮是处在上升状态还是下降状态
        moonState = CalculateState(now, moonPrev.time, moonNext.time, moonPrev.type, moonNext.type)
    else
        moonState = "unknown"   -- 默认状态（未知）
    end
end


-- ===================== 辅助函数 =====================
-- 供主更新循环调用的函数

-- 解析事件文件  参数：事件文件路径  返回：事件列表 {time=时间戳,type=事件类型}
function ParseEvents(filePath)
    local events = {}                   -- 初始化事件列表
    local file = io.open(filePath, 'r') -- 以只读模式打开文件
    if not file then return events end  -- 文件打开失败，返回空列表
    
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

-- 查找特定天体的四事件周期  参数：已排序的事件列表，当前时间戳，天体类型 ("Sun" 或 "Moon") 
-- 返回：包含四个事件时间点（startTime，endTime）的周期表
function FindFourEvents(events, currentTime, celestialType)
    -- 获取事件类型前缀 (Sun 或 Moon)
    local setType = celestialType .. "set"
    local riseType = celestialType .. "rise"
    
    -- 查找最近的前后事件及其索引
    local prev, next, prevIdx, nextIdx = FindNearestEvents(events, currentTime)
    if not prev or not next then return nil end
    
    local cycle = {}                             -- 初始化周期表
    local midTime = (prev.time + next.time) / 2  -- 前后事件中点
    
    -- 情况1：Set→Rise且当前时间在中点之后
    if prev.type == setType and next.type == riseType and currentTime > midTime then
        cycle.firstEvent = prev.time                                    -- 当前Set事件
        cycle.secondEvent = next.time                                   -- 当前Rise事件
        cycle.thirdEvent = FindNextEvent(events, nextIdx, setType)      -- 下一个Set事件
        cycle.fourthEvent = FindNextEvent(events, nextIdx, riseType)    -- 下一个Rise事件
    
    -- 情况2或3：Rise→Set（当前在可见周期）
    elseif prev.type == riseType and next.type == setType then
        cycle.firstEvent = FindPrevEvent(events, prevIdx, setType)      -- 前一个Set事件
        cycle.secondEvent = prev.time                                   -- 当前Rise事件
        cycle.thirdEvent = next.time                                    -- 当前Set事件
        cycle.fourthEvent = FindNextEvent(events, nextIdx, riseType)    -- 下一个Rise事件
    
    -- 情况4：Set→Rise且当前时间在中点之前
    elseif prev.type == setType and next.type == riseType and currentTime <= midTime then
        cycle.firstEvent = FindPrevEvent(events, prevIdx, setType)      -- 前一个Set事件
        cycle.secondEvent = FindPrevEvent(events, prevIdx, riseType)    -- 前一个Rise事件
        cycle.thirdEvent = prev.time                                    -- 当前Set事件
        cycle.fourthEvent = next.time                                   -- 当前Rise事件
    else
        return nil                                                      -- 不符合任何已知周期模式，返回nil
    end
    
    -- 计算时间轴起点和终点（中点位置）
    if cycle.firstEvent and cycle.secondEvent then
        cycle.startTime = (cycle.firstEvent + cycle.secondEvent) / 2    -- 起点为前两个事件的中点
    end
    
    if cycle.thirdEvent and cycle.fourthEvent then
        cycle.endTime = (cycle.thirdEvent + cycle.fourthEvent) / 2      -- 终点为后两个事件的中点
    end
    
    return cycle
end

-- 向前查找特定类型的事件
-- 参数：事件列表，起始索引位置，要查找的事件类型，要查找的事件序号（默认为1）  返回：找到的事件时间戳，未找到返回nil
function FindPrevEvent(events, startIndex, eventType, count)
    count = count or 1  -- 默认为查找第一个匹配事件
    local found = 0     -- 已找到的事件计数
    
    -- 从当前位置向前搜索
    for i = startIndex - 1, 1, -1 do            -- 逆序遍历
        if events[i].type == eventType then     -- 匹配事件类型
            found = found + 1                   -- 计数加一
            if found == count then              -- 找到指定序号的事件
                return events[i].time           -- 返回事件时间戳
            end
        end
    end
    
    return nil  -- 未找到指定事件
end

-- 向后查找特定类型的事件
-- 参数：事件列表，起始索引位置，要查找的事件类型，要查找的事件序号（默认为1）  返回：找到的事件时间戳，未找到返回nil
function FindNextEvent(events, startIndex, eventType, count)
    count = count or 1  -- 默认为查找第一个匹配事件
    local found = 0     -- 已找到的事件计数
    
    -- 从当前位置向后搜索
    for i = startIndex + 1, #events do          -- 顺序遍历
        if events[i].type == eventType then     -- 匹配事件类型
            found = found + 1                   -- 计数加一
            if found == count then              -- 找到指定序号的事件
                return events[i].time           -- 返回事件时间戳
            end
        end
    end
    
    return nil  -- 未找到指定事件
end

-- 计算天体的Y坐标（基于抛物线模型）
-- 参数：当前时间戳，前事件时间戳，后事件时间戳，前事件类型，后事件类型，是否是太阳  返回：天体在容器内的Y坐标
function CalculateY(currentTime, prevTime, nextTime, prevType, nextType, isSun)
    -- 计算当前在事件周期中的位置比例[0,1]
    local ratio = (currentTime - prevTime) / (nextTime - prevTime)
    
    -- 判断天体是否在地平线上（可见状态）
    local isAboveHorizon = false
    if isSun then
        isAboveHorizon = (prevType == "Sunrise" and nextType == "Sunset")   -- 太阳可见周期：日出后到日落前
    else
        isAboveHorizon = (prevType == "Moonrise" and nextType == "Moonset") -- 月亮可见周期：月出后到月落前
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
    
    return y
end

-- 判断天体当前运动状态  参数：当前时间戳，前事件时间戳，后事件时间戳，前事件类型，后事件类型  返回：Rise或Fall
function CalculateState(currentTime, prevTime, nextTime, prevType, nextType)
    local midTime = (prevTime + nextTime) / 2  -- 计算周期中点时间戳
    
    -- 可见周期判断(日出→日落 或 月出→月落)
    if (prevType == "Sunrise" and nextType == "Sunset") or (prevType == "Moonrise" and nextType == "Moonset") then
        -- 可见周期：前半段上升，后半段下降
        return (currentTime < midTime) and "Rise" or "Fall"
    else
        -- 不可见周期：前半段下降，后半段上升
        return (currentTime < midTime) and "Fall" or "Rise"
    end
end

-- 更新太阳事件标记位置和时间  参数：太阳的四事件周期表
function UpdateSunEvents(cycle)
    -- 日出标记
    if cycle.secondEvent then
        -- 计算日出在时间轴上的比例位置
        local ratio = (cycle.secondEvent - cycle.startTime) / (cycle.endTime - cycle.startTime)
        ratio = math.max(0, math.min(1, ratio))                     -- 限制在0至1范围内
        cachedSunriseX = XAxisStart + ratio * Length                -- 计算X坐标（容器内坐标）
        cachedSunriseTime = os.date("%H:%M", cycle.secondEvent)     -- 格式化时间 (HH:MM)
    else
        -- 无有效事件时使用默认值
        cachedSunriseX = 0
        cachedSunriseTime = "N/A"
    end
    
    -- 日落标记
    if cycle.thirdEvent then
        -- 计算日落在时间轴上的比例位置
        local ratio = (cycle.thirdEvent - cycle.startTime) / (cycle.endTime - cycle.startTime)
        ratio = math.max(0, math.min(1, ratio))                     -- 限制在0至1范围内
        cachedSunsetX = XAxisStart + ratio * Length                 -- 计算X坐标（容器内坐标）
        cachedSunsetTime = os.date("%H:%M", cycle.thirdEvent)       -- 格式化时间 (HH:MM)
    else
        -- 无有效事件时使用默认值
        cachedSunsetX = 0
        cachedSunsetTime = "N/A"
    end
end

-- 更新月亮事件标记位置和时间  参数：月亮的四事件周期表
function UpdateMoonEvents(cycle)
    -- 月出标记
    if cycle.secondEvent then
        -- 计算月出在时间轴上的比例位置
        local ratio = (cycle.secondEvent - cycle.startTime) / (cycle.endTime - cycle.startTime)
        ratio = math.max(0, math.min(1, ratio))                     -- 限制在0至1范围内
        cachedMoonriseX = XAxisStart + ratio * Length               -- 计算X坐标（容器内坐标）
        cachedMoonriseTime = os.date("%H:%M", cycle.secondEvent)    -- 格式化时间 (HH:MM)
    else
        -- 无有效事件时使用默认值
        cachedMoonriseX = 0
        cachedMoonriseTime = "N/A"
    end
    
    -- 月落标记
    if cycle.thirdEvent then
        -- 计算月落在时间轴上的比例位置
        local ratio = (cycle.thirdEvent - cycle.startTime) / (cycle.endTime - cycle.startTime)
        ratio = math.max(0, math.min(1, ratio))                     -- 限制在0至1范围内
        cachedMoonsetX = XAxisStart + ratio * Length                -- 计算X坐标（容器内坐标）
        cachedMoonsetTime = os.date("%H:%M", cycle.thirdEvent)      -- 格式化时间 (HH:MM)
    else
        -- 无有效事件时使用默认值
        cachedMoonsetX = 0
        cachedMoonsetTime = "N/A"
    end
end


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

-- 天体当前位置（容器内坐标）
function GetSunX() return sunX or XAxisStart end        -- 太阳X坐标（容器内）
function GetSunY() return sunY or HorizonY end          -- 太阳Y坐标（容器内）
function GetMoonX() return moonX or XAxisStart end      -- 月亮X坐标（容器内）
function GetMoonY() return moonY or HorizonY end        -- 月亮Y坐标（容器内）

-- 今日事件标记位置（容器内X坐标）
function GetTodaySunrise() return cachedSunriseX or 0 end       -- 日出X坐标（容器内）
function GetTodaySunset() return cachedSunsetX or 0 end         -- 日落X坐标（容器内）
function GetTodayMoonrise() return cachedMoonriseX or 0 end     -- 月出X坐标（容器内）
function GetTodayMoonset() return cachedMoonsetX or 0 end       -- 月落X坐标（容器内）

-- 天体运动状态
function GetSunState() return sunState or "unknown" end     -- "Rise"/"Fall"/"unknown"
function GetMoonState() return moonState or "unknown" end   -- "Rise"/"Fall"/"unknown"

-- 今日事件时间
function GetTodaySunriseTime() return cachedSunriseTime or "N/A" end    -- 日出时间(HH:MM)
function GetTodaySunsetTime() return cachedSunsetTime or "N/A" end      -- 日落时间(HH:MM)
function GetTodayMoonriseTime() return cachedMoonriseTime or "N/A" end  -- 月出时间(HH:MM)
function GetTodayMoonsetTime() return cachedMoonsetTime or "N/A" end    -- 月落时间(HH:MM)