-- ============================================================
-- WeekScroller.lua - Rainmeter日期时间轴计算脚本
-- 功能：实现基于日历日期的滚动时间轴，显示连续五天的日期标签及位置
-- ============================================================


-- ===================== 脚本级变量定义 =====================
-- 这些变量在整个脚本中共享，但不是全局变量（避免命名冲突）

local currentTimePosition          -- 当前时间线固定位置（像素）
local dateFormat                   -- 日期格式化字符串
local dayWidth                     -- 每天宽度（像素）
local positions                    -- 日期标签位置数组（像素坐标）
local dayTexts                     -- 日期标签文本数组（格式化后的日期）


-- ===================== 配置与参数初始化 =====================
-- Rainmeter皮肤加载时执行，完成以下任务：
-- 1. 读取INI配置参数
-- 2. 设置日期格式和显示参数
-- 3. 初始化日期标签数组
-- 4. 执行首次计算更新

function Initialize()
    --- === 基础显示参数 ===
    currentTimePosition = tonumber(SELF:GetOption('CurrentTimePosition')) or 35 -- 当前时间线在时间轴上的固定位置
    dayWidth = tonumber(SELF:GetOption('dayWidth')) or 64                       -- 每天在时间轴上占用的宽度（像素），对应86400秒（24小时）

    -- === 日期格式化配置 ===
    -- 获取用户自定义日期格式，处理空字符串或未设置情况
    local formatOption = SELF:GetOption('DateFormat')                                       -- 从INI获取用户设置的日期格式
    dateFormat = (formatOption and formatOption ~= "") and formatOption or "%a.     %w"     -- 使用用户格式或默认格式
    
    -- 日期格式说明：
    -- %Y: 四位数年份 (如 2024)    %y: 两位数年份 (如 24)
    -- %B: 月份全称 (如 January)   %b: 月份缩写 (如 Jan)   %m: 月份数字 (01-12)
    -- %d: 月份中的天数 (01-31)    %e: 月份中的天数 (1-31)
    -- %W: 一年中的第几周 (00-53)  %w: 星期几数字 (0-6，周日=0)
    -- %A: 星期全称 (如 Monday)    %a: 星期缩写 (如 Mon)
    -- %H: 小时 (00-23)           %I: 小时 (01-12)       %M: 分钟 (00-59)
    -- 示例：os.date("%A %d %B %Y", timestamp) 输出 "Monday 01 January 2024"
    
    -- === 初始化日期标签数组 ===
    positions = {0, 0, 0, 0, 0}   -- 五个日期标签的X坐标位置（像素）
    dayTexts = {"", "", "", "", ""}  -- 五个日期标签的格式化文本内容
    
    -- === 执行首次计算更新 ===
    Update()  -- 直接调用Update函数进行初始计算，避免显示空白
end


-- ===================== 主更新循环 =====================
-- Rainmeter定期调用（UpdateDivider等于N），完成以下任务：
-- 1. 计算当前时间与今日零点的距离
-- 2. 根据时间距离计算时间轴的滚动偏移
-- 3. 更新五个日期标签的位置和文本内容

function Update()
    local now = os.time()                     -- 获取当前时间戳
    
    -- === 计算时间基准 ===
    local todayStart = GetDayStart(now)       -- 调用GetDayStart函数获取今天0点时间戳
    local elapsedSeconds = now - todayStart   -- 计算当前时间距离今天0点经过的秒数
    
    -- === 计算滚动偏移 ===
    local scrollOffset = (elapsedSeconds / 86400) * dayWidth    -- 将时间距离转换为像素偏移：每86400秒（24小时）对应64像素
    
    -- === 计算基准位置 ===
    local todayPosition = currentTimePosition - scrollOffset    -- 今天标签的位置：固定时间线位置减去时间滚动偏移
    
    -- === 循环计算五个日期标签 ===
    for i = 1, 5 do
        -- 计算日期偏移: i=2 是今天(偏移0), i=1 是昨天(偏移-1), i=3 是明天(偏移+1)
        local offset = i - 2  -- 得到偏移值：-1, 0, 1, 2, 3
        
        -- 位置计算: 今天位置 + 偏移量 × 每天宽度
        positions[i] = todayPosition + offset * dayWidth
        
        -- 文本计算: 今天基准时间戳 + 偏移量 × 86400秒, 然后格式化为字符串
        dayTexts[i] = os.date(dateFormat, todayStart + offset * 86400)
    end
end


-- ===================== 辅助函数 =====================
-- 供主更新循环调用的函数

-- 获取今天0点的时间戳 参数：时间戳 返回：当天0点时间戳
function GetDayStart(timestamp)
    local t = os.date("*t", timestamp)  -- 将时间戳转换为时间表
    t.hour, t.min, t.sec = 0, 0, 0      -- 将时、分、秒设置为0（午夜）
    return os.time(t)                   -- 返回当天0点的时间戳
end

-- ===================== 供Rainmeter调用的接口函数 =====================

-- 当前时间线固定位置接口
function GetCurrentTimePosition() return currentTimePosition end

-- 日期标签位置
function GetDay1X() return positions[1] end  -- 昨天标签的X坐标（像素）
function GetDay2X() return positions[2] end  -- 今天标签的X坐标（像素）
function GetDay3X() return positions[3] end  -- 明天标签的X坐标（像素）
function GetDay4X() return positions[4] end  -- 后天标签的X坐标（像素）
function GetDay5X() return positions[5] end  -- 大后天标签的X坐标（像素）

-- 日期标签文本
function GetDay1Text() return dayTexts[1] end  -- 昨天标签的格式化文本
function GetDay2Text() return dayTexts[2] end  -- 今天标签的格式化文本
function GetDay3Text() return dayTexts[3] end  -- 明天标签的格式化文本
function GetDay4Text() return dayTexts[4] end  -- 后天标签的格式化文本
function GetDay5Text() return dayTexts[5] end  -- 大后天标签的格式化文本
