# Rainmeter Sun & Moon Tracker

> 基于 Rainmeter 的日月天文可视化套件。PowerShell 定时从和风天气 API 采集日月升降数据，Lua 驱动地球光照球体、天体运动轨迹与事件时间轴四类视图。

![screenshot](docs/screenshot.png)

## 目录

- [功能特性](#功能特性)
- [套件组成](#套件组成)
- [工作原理](#工作原理)
- [快速开始](#快速开始)
- [文件放置位置](#文件放置位置)
- [配置说明](#配置说明)
- [皮肤使用指南](#皮肤使用指南)
- [自定义修改](#自定义修改)
- [数据格式](#数据格式)
- [常见问题](#常见问题)
- [已知限制](#已知限制)
- [License](#license)
- [致谢](#致谢)

---

## 功能特性

### 数据层

- 自动获取公网 IP → 百度地图定位 → 和风天气城市编码，无需手动配置城市
- 一次性拉取过去 2 天 + 未来 4 天共 7 天的日月升降数据
- 同时输出「日期时间格式」和「Unix 时间戳格式」两种文件，兼顾人读与程序计算
- Windows 任务计划：开机延迟 15 秒 + 每 4 小时自动刷新，SYSTEM 权限运行
- 多 IP 服务冗余、API 请求重试、预报数据缓存，网络波动不中断

### 展示层

| 视图 | 说明 |
|---|---|
| **地球光照球** | 360 张地球图片序列插值，太阳/月亮两种模式，实时还原晨昏线位置 |
| **天体轨迹** | 一天内太阳/月亮的连续抛物线运动曲线，含日出/日落/月出/月落标记 |
| **事件追踪** | 以当前时间为中心滚动展示 5 个未来事件，鼠标悬停查看具体时刻 |
| **位置模拟** | 以"四事件周期"为 X 轴的视位置模拟，还原天体的实际运动节奏 |

### 视觉与交互

- 四种皮肤可单独或并排加载
- S/M 标签一键切换太阳/月亮视图
- 鼠标悬停显示/隐藏事件时间文字
- 所有资源使用 `@Resources` 相对路径，整套皮肤可整体迁移

---

## 套件组成

```
rainmeter-sun-moon-tracker/
├── README.md
├── LICENSE
├── .gitignore
│
├── scripts/                                # 数据采集端（PowerShell）
│   ├── AstronomicalEvents.ps1              # 主脚本
│   ├── AstronomicalEvents.xml              # 任务计划定义
│   └── WeatherApiKeys.example.json         # API 密钥模板
│
├── Skin/                                   # Rainmeter 皮肤
│   ├── @Resources/
│   │   ├── Globe.lua                       # 通用地球光照计算
│   │   ├── Globe_Combine.lua               # 双球并行计算
│   │   ├── Position Simulator.lua          # 视位置模拟计算
│   │   ├── Event Tracker.lua               # 事件追踪计算
│   │   ├── Trajectory Viewer.lua           # 日轨迹计算
│   │   ├── Globe/                          # 360 张地球图片
│   │   │   ├── globe_000.png
│   │   │   ├── globe_001.png
│   │   │   └── ... 至 globe_359.png
│   │   ├── Tracker_mark.png                # 事件标记图标
│   │   ├── Tracker_sun.png                 # 太阳图标
│   │   ├── Tracker_moon.png                # 月亮图标
│   │   ├── Background.png                  # 单球背景
│   │   └── Background_double.png           # 双球背景
│   │
│   ├── BodyType.inc                        # 太阳/月亮切换变量
│   ├── Globe.ini                           # 通用光照球（可切换）
│   ├── Globe_Sun.ini                       # 太阳光照球（固定）
│   ├── Globe_Moon.ini                      # 月亮光照球（固定）
│   ├── Globe_Combine.ini                   # 日月光照球并排
│   ├── Trajectory Viewer.ini               # 日轨迹视图
│   ├── Event Tracker.ini                   # 事件追踪视图
│   └── Position Simulator.ini              # 位置模拟视图
│
└── docs/                                   # 截图与说明
    └── screenshot.png
```

---

## 工作原理

### 三层数据流

```mermaid
graph LR
    A[和风天气 API] -->|PowerShell 定时拉取| B[SunTimeStampEvent.txt<br/>MoonTimeStampEvent.txt<br/>SunEvents.txt<br/>MoonEvents.txt]
    B -->|Lua 解析与插值| C[时间比例 t<br/>图片索引<br/>天体坐标]
    C -->|Rainmeter INI| D[地球光照球<br/>轨迹视图<br/>事件视图]
```

### 第 1 层：数据采集（PowerShell）

`AstronomicalEvents.ps1` 每 4 小时运行一次，流程：

1. **获取公网 IP**：依次尝试 `ipinfo.io`、`checkip.amazonaws.com` 等 5 个服务
2. **定位城市**：百度地图 IP 定位接口返回经纬度 → 和风天气 GeoAPI 查询城市编码
3. **生成 7 天窗口**：以今天为基准，取 `[-2, +4]` 共 7 天
4. **获取日月数据**：
   - 过去日期 → `/v7/historical/weather` 历史接口
   - 今天及未来 → `/v7/weather/7d` 预报接口（首次调用后缓存）
5. **格式化输出**：
   - `SunEvents.txt` / `MoonEvents.txt`：`yyyyMMddHHmmEventType`
   - `SunTimeStampEvent.txt` / `MoonTimeStampEvent.txt`：`Unix秒EventType`
6. **排序与裁剪**：按时间升序排序，删除首尾各一条，形成连续事件流

### 第 2 层：计算（Lua）

所有 Lua 脚本共享同一套核心模型：**最近事件对 + 抛物线**。

#### 时间比例 t

给定当前时间 `now`，找到最近的一对升起/落下事件 `(prev, next)`：

```
t = (now - prev.time) / (next.time - prev.time)   ∈ [0, 1]
```

- `prev = Sunrise, next = Sunset` → 白天周期，t ∈ [0,1]
- `prev = Sunset, next = Sunrise` → 夜晚周期，t = 1 + ratio ∈ [1,2]

#### 抛物线 Y 坐标

```
地平线以上：y = HorizonY - (HorizonY - apex) * (1 - (2t-1)²)
地平线以下：y = HorizonY + (nadir - HorizonY) * (1 - (2t-1)²)
```

- `t = 0.5` 达到顶点/底点，对应正午/午夜
- `t = 0` 或 `1` 时 `y = HorizonY`，即天体正好在地平线上
- 太阳根据白昼时长动态调整 `apex`，夏季弧线更高、冬季更低
- 月亮使用固定顶点，简化处理

#### 地球光照图片索引

初始化时根据本地经度预计算两个锚点：

```
日出图片索引 = (-LocalLongitude - 90) mod 360
日落图片索引 = ( 90 - LocalLongitude) mod 360
```

白天用 `lerp(日出索引, 日落索引, t)` 插值，夜晚用 `lerp(日落索引, 日出索引, t-1)`，自动处理 360° 循环边界。

以默认经度 `114°E` 为例：日出索引 156 → 正午 246 → 日落 336，直射经度对应 204° → 114° → 24°，物理上自洽。

### 第 3 层：展示（Rainmeter INI）

INI 通过 `Measure=Script` 调用 Lua 接口：

```ini
[MeasureLua]
Measure=Script
ScriptFile=#@#Globe.lua
CalculateFile=C:\Users\Public\Documents\Rainmeter Data\SunTimeStampEvent.txt
LocalLongitude=114
BodyType=Sun
```

再用 `[MeasureLua:GetEarthImage()]` 拿到 `globe_246` 这样的字符串，赋给 `Meter=Image` 的 `ImageName` 即可渲染。

---

## 快速开始

### 前置要求

| 依赖 | 版本 | 用途 |
|---|---|---|
| Windows | 10 / 11 | 运行环境 |
| Rainmeter | 4.5+ | 皮肤引擎 |
| PowerShell | 5.1+ | 数据采集 |
| 和风天气 API Key | 免费版即可 | 日月数据 |
| 百度地图 AK | 免费版即可 | IP 定位 |

### 三步启动

```powershell
# 1. 克隆仓库到 Rainmeter Skins 目录
cd "$env:USERPROFILE\Documents\Rainmeter\Skins"
git clone https://github.com/<yourname>/rainmeter-sun-moon-tracker.git

# 2. 配置 API 密钥
copy scripts\WeatherApiKeys.example.json scripts\WeatherApiKeys.json
notepad scripts\WeatherApiKeys.json   # 填入自己的 key 和 ak

# 3. 部署采集脚本
copy scripts\AstronomicalEvents.ps1 C:\Users\Public\Documents\
# 手动运行一次，确认 4 个 txt 已生成
powershell -ExecutionPolicy Bypass -File C:\Users\Public\Documents\AstronomicalEvents.ps1
```

然后：

1. 双击 `scripts\AstronomicalEvents.xml` 导入任务计划（或以管理员运行 `schtasks /Create /XML ...`）
2. 右键 Rainmeter 托盘图标 → 刷新全部
3. 在管理器中加载 `Skin\Globe_Combine.ini` 或任意皮肤

---

## 文件放置位置

### 数据采集端（必须放在固定路径）

PowerShell 脚本和任务计划 XML **硬编码**了以下路径，移动文件需要同步修改：

| 文件 | 必须放置于 | 说明 |
|---|---|---|
| `AstronomicalEvents.ps1` | `C:\Users\Public\Documents\AstronomicalEvents.ps1` | XML 中硬编码 |
| `WeatherApiKeys.json` | `C:\Users\Public\Documents\WeatherApiKeys.json` | 脚本自动读取同目录 |

脚本运行后会在以下目录生成 4 个 txt：

```
C:\Users\Public\Documents\Rainmeter Data\
├── SunEvents.txt
├── MoonEvents.txt
├── SunTimeStampEvent.txt
└── MoonTimeStampEvent.txt
```

> 如果不想用 `C:\Users\Public\Documents`，需要同时修改三处：PS1 内的输出路径、INI 内 `CalculateFile/SunFile/MoonFile` 路径、XML 内的脚本路径。

### 展示端（Rainmeter Skins 目录）

`Skin\` 目录整体放入 Rainmeter 的 Skins 根目录即可，例如：

```
%USERPROFILE%\Documents\Rainmeter\Skins\rainmeter-sun-moon-tracker\
├── @Resources\
├── Globe.ini
├── Globe_Combine.ini
└── ...
```

**关键点**：`.ini` 中的 `#@#Globe.lua` 是相对 `@Resources` 的路径，所以 **`@Resources` 必须与 `.ini` 文件同级**，不能拆开。

### 图片资源

`@Resources\Globe\` 下的 360 张图片必须严格按 `globe_000.png ~ globe_359.png` 命名。

**图片含义**：`globe_NNN.png` 表示"太阳直射经度 = -NNN 度"时地球被照亮的样子。`globe_000.png` 是直射 0°（本初子午线）的状态，`globe_180.png` 是直射 180°（国际日期变更线）。

如果只用 Tracker 系列（不使用 Globe 系列），可以不下载这 360 张图。

---

## 配置说明

### 采集端：`WeatherApiKeys.json`

```json
{
  "weatherApiKey": "YOUR_QWEATHER_KEY",
  "baiduAk": "YOUR_BAIDU_AK"
}
```

| 字段 | 获取方式 |
|---|---|
| `weatherApiKey` | [和风天气控制台](https://dev.qweather.com/) → 项目管理 → 创建项目 → API KEY |
| `baiduAk` | [百度地图开放平台](https://lbsyun.baidu.com/) → 控制台 → 应用管理 → AK |

> ⚠️ **不要提交此文件到 Git**。仓库只提供 `WeatherApiKeys.example.json`，`.gitignore` 已排除真实配置。

### 展示端：INI 参数

所有 INI 共享以下关键参数（在 `[Variables]` 或 `[MeasureLua]` 中）：

| 参数 | 文件 | 默认值 | 说明 |
|---|---|---|---|
| `LocalLongitude` | Globe 系列 | `114` | 本地经度，东经正、西经负 |
| `CalculateFile` | Globe_Sun/Moon | 太阳/月亮时间戳文件 | 单个天体的事件文件 |
| `SunFile` / `MoonFile` | Globe.ini、Tracker 系列 | 两个时间戳文件 | 双天体的路径 |
| `BodyType` | Globe.ini | `Sun` | 通过 `BodyType.inc` 切换 |
| `SecondPerPixel` | Trajectory Viewer | `240` | 时间轴缩放，每像素秒数 |
| `SecondPerPixel` | Event Tracker | `480` | 时间轴缩放 |
| `TimeOffsetInPixels` | Event Tracker | `60` | 当前时间距轴起点的像素偏移 |
| `Length` | Tracker 系列 | `360` | 时间轴长度（像素） |
| `OffsetValue` | Tracker 系列 | `15` | 昼夜顶点/底点的浮动幅度 |
| `IconSize` | Tracker 系列 | `21` | 天体图标尺寸 |
| `SkinWidth` / `SkinHeight` | Tracker 系列 | `420` / `256` | 皮肤尺寸 |
| `UpdateDivider` | `[MeasureLua]` | `60` | Lua 计算间隔（秒） |

---

## 皮肤使用指南

### 地球光照球系列

| 皮肤 | 用途 | 特点 |
|---|---|---|
| `Globe_Sun.ini` | 只看太阳光照 | 硬编码 `BodyType=Sun` |
| `Globe_Moon.ini` | 只看月亮光照 | 硬编码 `BodyType=Moon` |
| `Globe.ini` | 通用，可切换 | 点击 S/M 标签切换，通过 `BodyType.inc` 保存状态 |
| `Globe_Combine.ini` | 日月并排 | 左右各一个 180×180 球，同时显示 |

**切换方式**（仅 `Globe.ini`）：右上角 `S` / `M` 小字，点击后立即刷新。

### 轨迹/事件/位置系列

| 皮肤 | 回答的问题 | X 轴含义 |
|---|---|---|
| `Trajectory Viewer.ini` | 今天一整天天体怎么动的 | 00:00 → 24:00 |
| `Event Tracker.ini` | 接下来 5 个事件在什么时候 | 滚动时间轴 |
| `Position Simulator.ini` | 天体现在在四事件周期哪一段 | 当前周期比例 |

**交互**：`Event Tracker` 鼠标悬停 `S` 或 `M` 标签，隐藏另一天体的事件标记，只显示当前天体的 5 个事件时刻。

---

## 自定义修改

### 1. 改本地经度

**症状**：地球光照球晨昏线位置不对，或 Tracker 系列天体位置与日出日落不同步。

**修改**：

```ini
; Globe 系列、Tracker 系列所有 INI 的 [MeasureLua] 段
LocalLongitude=114     ; 改为你的经度，例如上海 121.5、乌鲁木齐 87.6
```

经度取值：东经正（0 ~ 180），西经负（-180 ~ 0）。

> 城市编码由 PS1 自动定位，但经度不会自动回填到 INI，需要手动保持一致。

### 2. 改时间轴缩放

**Trajectory Viewer**：

```ini
Length=360
SecondPerPixel=240    ; 360 × 240 = 86400 秒 = 24 小时
```

> 想显示"半天"就把 `SecondPerPixel` 改为 120（12 小时），但**不建议改**，因为 24 小时是它的设计语义。

**Event Tracker**：

```ini
Length=360
SecondPerPixel=480          ; 360 × 480 = 172800 秒 ≈ 2 天
TimeOffsetInPixels=60       ; 当前时间在轴起点后 60 像素（约 8 小时）
```

- 想让当前时间居中 → `TimeOffsetInPixels = Length / 2 = 180`
- 想多看未来 → 减小 `TimeOffsetInPixels`

### 3. 改天体图标大小

```ini
; Tracker 系列 INI
IconSize=21     ; 改大或改小，会自动影响边距计算
```

### 4. 改颜色

```ini
; Tracker 系列 INI 的 [Variables]
SunColor=255,215,0,255          ; 太阳图标色
MoonColor=30,144,255,255        ; 月亮图标色
HorizonColor=128,128,128,128    ; 地平线色
SunRiseColor=255,215,0,180      ; 日出标记
SunSetColor=255,215,0,150       ; 日落标记
MoonRiseColor=30,144,255,180    ; 月出标记
MoonSetColor=30,144,255,150     ; 月落标记
```

格式为 `R,G,B,A`，A 是透明度（0 全透明，255 不透明）。

### 5. 改刷新频率

**采集端**（`AstronomicalEvents.xml`）：

```xml
<Repetition>
  <Interval>PT4H</Interval>    <!-- 改成 PT6H 或 PT12H 可减少 API 调用 -->
</Repetition>
```

**展示端**（所有 INI）：

```ini
[MeasureLua]
UpdateDivider=60    ; 改为 30 更流畅，改为 300 更省 CPU
```

### 6. 改 API 服务商

如果和风天气不可用，替换 PS1 中的 3 个 URL：

```powershell
# 城市查询
$geoUrl = "https://kk436g9nfm.re.qweatherapi.com/geo/v2/city/lookup?..."

# 历史数据
$url = "https://kk436g9nfm.re.qweatherapi.com/v7/historical/weather?..."

# 预报数据
$url = "https://kk436g9nfm.re.qweatherapi.com/v7/weather/7d?..."
```

替换后需同步修改返回字段的解析（`$data.weatherDaily.sunrise` 等）。

### 7. 改输出文件名或目录

三处需同步：

1. PS1 内 `$publicDocuments = "C:\Users\Public\Documents\Rainmeter Data"`
2. 所有 INI 内 `CalculateFile` / `SunFile` / `MoonFile` 的路径
3. 任务计划 XML 内 `<Arguments>` 的脚本路径（如脚本也移动）

---

## 数据格式

### SunEvents.txt / MoonEvents.txt

```
yyyyMMddHHmmEventType
```

| 示例 | 含义 |
|---|---|
| `202610221736Sunset` | 2026-10-22 17:36 日落 |
| `202610230637Sunrise` | 2026-10-23 06:37 日出 |
| `nullMoonrise` | 当日无月出（异常或极地） |

### SunTimeStampEvent.txt / MoonTimeStampEvent.txt

```
Unix秒EventType
```

| 示例 | 含义 |
|---|---|
| `1792661760Sunset` | 对应 `202610221736Sunset` |
| `1792708620Sunrise` | 对应 `202610230637Sunrise` |

**注意**：时间戳基于运行机器的本地时区转 UTC，跨时区使用需确认一致性。2038 年后时间戳变成 11 位，Lua 的 `line:sub(1, 10)` 解析会失效（见[已知限制](#已知限制)）。

---

## 常见问题

### Q1：脚本运行后 4 个 txt 没有生成

按顺序排查：

1. `WeatherApiKeys.json` 是否在 PS1 同目录、字段名是否正确
2. 手动运行 PS1，看控制台输出：
   ```powershell
   powershell -ExecutionPolicy Bypass -File C:\Users\Public\Documents\AstronomicalEvents.ps1
   ```
3. 检查桌面或 `C:\Windows\System32\config\systemprofile\Desktop` 下有无 `SunMoonDataError.log`
4. 和风天气控制台确认 API 调用次数未超限

### Q2：任务计划运行了但文件没更新

1. 任务计划程序 → `AstronomicalEvents` → **历史记录**，看返回码是否为 `0x0`
2. SYSTEM 账户的桌面路径问题：把 PS1 错误日志路径改为 `C:\Users\Public\Documents\Rainmeter Data\SunMoonDataError.log`
3. 检查 `StopExisting` 策略是否导致上一次运行被杀

### Q3：加载皮肤后地球是空白/占位图

1. 确认 `@Resources\Globe\globe_000.png ~ globe_359.png` 齐全
2. 确认 `.ini` 与 `@Resources` 同级
3. 检查 `ImagePath=#@#Globe\` 末尾是否有反斜杠

### Q4：地球光照位置不对

`LocalLongitude` 与 PS1 定位的城市经度不一致。用下面的方法查实际经度：

```powershell
# 从生成的 txt 里找日出时刻，与本地实际日出对比
Get-Content "C:\Users\Public\Documents\Rainmeter Data\SunTimeStampEvent.txt" | Select-Object -First 2
```

把 `LocalLongitude` 改为该城市的经度即可。

### Q5：天体轨迹图跳出容器

`OffsetValue` 太大导致顶点超出容器上下边界。减小 `OffsetValue`（如改为 10），或增大 `SkinHeight`。

### Q6：Event Tracker 的多个事件标记叠在一起

当前设计有 5 个事件槽位。如果时间轴范围太大（`SecondPerPixel` 过大），多个事件会挤在容器边缘。减小 `SecondPerPixel`（如改为 300）即可展开。

---

## 已知限制

- **`LocalLongitude` 不会自动同步**：PS1 定位到的经度不会写回 INI，需要手动保持一致。未来版本计划增加自动写入。
- **10 位时间戳假设**：Lua 中 `line:sub(1, 10)` 在 2038 年后会解析失败。
- **地球图片序列需自备**：仓库提供 360 张图，但如缺失需自行渲染，可用 NASA Blue Marble 数据生成。
- **月亮模型简化**：月亮顶点固定，未考虑月相和赤纬变化。
- **四事件周期依赖数据密度**：`Position Simulator` 在事件不足时会退化为固定位置，建议 PS1 至少保留 3 天完整事件。
- **SYSTEM 账户错误日志路径**：`[Environment]::GetFolderPath("Desktop")` 在 SYSTEM 下可能不可写，错误日志会丢失。

---

## License

本项目采用 MIT License，详见 [LICENSE](LICENSE)。

原始 INI 头部标注的 `Creative Commons BY-NC-SA 3.0` 是内容许可，不适用于代码，已统一替换为 MIT。

---

## 致谢

- 数据来源：[和风天气](https://www.qweather.com/)
- IP 定位：[百度地图开放平台](https://lbsyun.baidu.com/)
- 平台：[Rainmeter](https://www.rainmeter.net/)

---

## 相关项目

如果你对完整的"采集-计算-展示"流水线感兴趣，可以按以下顺序阅读源码：

1. `scripts/AstronomicalEvents.ps1` — 数据采集
2. `Skin/@Resources/Globe.lua` — 地球光照计算
3. `Skin/@Resources/Trajectory Viewer.lua` — 轨迹计算
4. `Skin/Globe_Combine.ini` — 最终渲染
