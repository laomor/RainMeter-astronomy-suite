# Astronomy Suite

> 把日月升降时间变成四种可视化视图：**地球光照球、天体轨迹、事件时间轴、视位置模拟**。
> <br>`本 README 中仅展示地球光照球、视位置模拟两种预览效果。`

---

## 效果预览

<table align="center">
  <tr>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" width="200"><br><sub><b>2026-10-27_21-50</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-30_11-23.png" width="200"><br><sub><b>2026-10-30_11-23</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" width="200"><br><sub><b>2026-10-27_21-50</b></sub></td>
  </tr>
  <tr>
    <td align="center" colspan="3"><sub><b>地球光照球</b> — 太阳/月亮双模式，360 张序列插值还原晨昏线</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" width="200"><br><sub><b>2026-10-28_09-00</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" width="200"><br><sub><b>2026-10-28_09-00</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" width="200"><br><sub><b>2026-10-28_09-00</b></sub></td>
  </tr>
  <tr>
    <td align="center" colspan="3"><sub><b>位置模拟</b> — 四事件周期内的天体视位置</sub></td>
  </tr>
</table>

> 更多截图请查阅 `EffectPreviewImage_*/` 文件夹。

---

## 仓库结构

```text
.
├── AstronomicalEvents.xml          # Windows 任务计划配置文件
├── GlobePicture.zip                # 360张地球图片压缩包（便于单独下载）
├── Background/                     # 皮肤背景图
├── icon/                           # 太阳、月亮及标记图标
├── EffectPreviewImage_*/           # 效果预览图
├── Event Time Case/                # 现成的示例数据（4个 txt 文件）
├── GlobePicture/                   # 360张地球自旋图片序列 (globe_000 ~ 359)
├── Script_Globe/                   # Globe 系列皮肤的 Lua 脚本
├── Script_SunMoonTracker/          # Tracker 系列皮肤的 Lua 脚本
├── Skins_Globe/                    # Globe 系列皮肤 (.ini)
├── Skins_SunMoonTracker/           # Tracker 系列皮肤 (.ini)
└── Users Public Documents/         # 数据采集端（PS1 脚本与 API 配置）
```

---

## 快速部署（Rainmeter）

### 第一步：创建皮肤目录
1. 右键系统托盘的 Rainmeter 图标，选择 **“皮肤” → “打开皮肤目录”**。
2. 在打开的 `Skins` 文件夹中，新建名为 **`Astronomy Suite`** 的文件夹。

### 第二步：按结构组合文件
从本仓库下载文件，严格按以下结构放入 `Astronomy Suite` 文件夹中。
*(注：`@Resources` 为共享资源目录，所有 `.ini` 均从此处读取图片与脚本)*

```text
Rainmeter/Skins/Astronomy Suite/
│
├── @Resources/                     # 共享资源
│   ├── globe/                      # 解压 GlobePicture.zip 至此
│   │   ├── globe_000.png
│   │   └── ... (一直到 globe_359.png)
│   │
│   ├── Background_double.png       # 来自 Background/ 文件夹
│   ├── Tracker_*.png               # 来自 icon/ 文件夹
│   │
│   ├── Globe.lua                   # 来自 Script_Globe/
│   ├── Globe_Combine.lua           
│   ├── Event Tracker.lua           # 来自 Script_SunMoonTracker/
│   ├── Position Simulator.lua      
│   └── Trajectory Viewer.lua       
│
├── Globe/                          # 地球光照球皮肤
│   ├── BodyType.inc
│   ├── Globe.ini
│   ├── Globe_Combine.ini
│   ├── Globe_Moon.ini
│   └── Globe_Sun.ini
│
└── SunMoonTracker/                 # 轨迹与事件皮肤
    ├── Event Tracker.ini
    ├── Position Simulator.ini
    └── Trajectory Viewer.ini
```

### 第三步：准备天文数据
数据文件需统一存放于 `C:\Users\Public\Documents\Rainmeter Data\`。请选择以下方案之一：

**方案 A：开箱即用（推荐用于效果测试）**
下载仓库中 `Event Time Case` 文件夹内的 4 个 `.txt` 文件，复制到上述目录。
> *注：该数据由 GitHub Actions 每日自动更新，默认基于北京经度。*

**方案 B：本地自动化（推荐用于长期使用）**
1. 将 `Users Public Documents` 中的 `AstronomicalEvents.ps1` 和 `WeatherApiKeys.json` 复制到 `C:\Users\Public\Documents\`。
2. 申请并填入 API 密钥（[和风天气](https://id.qweather.com/#/login) / [百度地图](https://lbsyun.baidu.com/apiconsole/becomedev/selection)）。
3. 运行一次 `.ps1` 脚本确认无误，双击 `AstronomicalEvents.xml` 导入任务计划程序，实现每 4 小时自动拉取。

### 第四步：加载皮肤
刷新 Rainmeter，展开 `Astronomy Suite`，加载所需皮肤：
- `Globe\Globe_Combine.ini`（日月双球）
- `SunMoonTracker\Trajectory Viewer.ini`（轨迹视图）

---

## 核心原理与算法模型

本项目将时间点转化为可视化坐标，核心依赖一个基础指标（时间比例 `t`）以及两个平行的视图分支。

### 基础：时间比例 `t` 与事件配对

无论渲染哪种视图，系统首先都需要匹配当前时间 `now` 左右相邻的两个事件（`prevEvent` 与 `nextEvent`），计算出一个用于插值的比例值 `t`：

```text
ratio = (now - prevEvent.time) / (nextEvent.time - prevEvent.time)

if (prevEvent 是升起 AND nextEvent 是落下):  
    t = ratio        // 可见期，t ∈ [0, 1]
else:              
    t = 1 + ratio    // 隐藏期，t ∈ [1, 2]
```
> **物理意义**：`t` 的定义依赖于具体事件对。可见期时，`t` 从 0 变到 1 代表天体升到落；隐藏期时，`t` 从 1 变到 2 代表天体落到升。

---

基于计算出的基础指标 `t`，不同皮肤系列走向了完全独立的计算分支：

#### 分支一：Globe 系列（地球光照球）
该视图只需要利用 `t` 进行图片索引的映射。系统在预计算的日出/日落图片锚点之间进行插值，得出 `0~359` 的图片编号。
- `t ≤ 1` 时，在日出和日落索引之间插值。
- `t > 1` 时，在日落和次日日出索引之间插值。
*(具体数学推导见 `Globe.lua`)*

#### 分支二：SunMoonTracker 系列（轨迹/事件视图）
该视图需要计算天体在屏幕上的完整 `(X, Y)` 坐标。**其中 Y 轴依赖 `t`，X 轴则依赖绝对时间。**

**1. Y 轴：抛物线模型（依赖 t）**
通过判断 `t` 的区间，决定使用上开口或下开口抛物线计算高度：
```text
可见期（t ∈ [0,1]）:  y = HorizonY - (HorizonY - apex)  * (1 - (2t - 1)²)
隐藏期（t ∈ [1,2]）:  y = HorizonY + (nadir - HorizonY) * (1 - (2(t-1) - 1)²)
```
*(当 t=0 或 1 时，y 刚好在地平线；t=0.5 或 1.5 时达到顶点/底点)*

**2. X 轴：各视图独立的时间轴映射**
X 轴的计算完全不依赖 `t`，而是由各个子视图的独立逻辑决定：
| 视图 | X 轴映射逻辑 |
|---|---|
| **Trajectory Viewer** | `x = xStart + (now - todayStart) / secondPerPixel` (将 24 小时铺满宽度) |
| **Event Tracker** | 天体固定，事件按 `(eventTime - axisStart) / secondPerPixel` 滚动 |
| **Position Simulator** | 基于“四事件周期”比例计算 |

> **关于四事件周期**：在 `Position Simulator` 中，为保持轨迹连贯，采用 `[Set₁, Rise₁, Set₂, Rise₂]` 四个事件。以 `Set₁` 和 `Rise₁` 的中点为起点，`Set₂` 和 `Rise₂` 的中点为终点，计算当前时间在整个周期中的 X 轴进度。

---

## 架构设计与进阶指南

若计划将本项目逻辑移植至其他平台（如 Web、Android、原生桌面），请参考以下架构设计建议：

### 1. 数据源与 API 策略
- **API 依赖**：目前市面鲜有免费提供高精度月升月落数据的 API，和风天气是极佳的选择。
- **密钥隔离**：建议在移植应用中开放配置接口，引导用户填入个人 API Key，以避免公共密钥触及调用频率限制或产生计费。

### 2. 渲染方案的降维与升维
- **静态图片方案（当前降维）**：当前项目基于赤道视角生成了 360 张图片。若需适配不同纬度，靠静态图片会导致晨昏线倾角失真。
- **3D 实时渲染（升维替代）**：推荐抛弃静态图，改用 Three.js 或原生 3D 引擎。仅需一张地球贴图，通过 Shader 结合太阳直射经纬度算法，即可实时演算出任意视角下精准的晨昏线状态。

### 3. 轨迹算法的可替换性
- **抛物线拟合的妥协**：当前的 `1 - (2t-1)²` 抛物线模型，主要是受限于 Rainmeter 的曲线绘制能力（无法平滑渲染真实曲线，退而求其次采用抛物线拟合）。
- **替代方案**：在 Web 或原生端，完全可以使用 SVG、Canvas 或 `UIBezierPath`，直接通过正弦函数（`sin`）或天文学球面三角公式绘制真实的平滑天体轨迹。

### 4. 异常事件处理机制（重要）
- **月亮事件的周期性缺失**：月球公转周期约 24 小时 50 分钟。这种天文现象会导致在特定日期内，某天只有“月出”或只有“月落”。
- **生成端（PS1）的剪枝策略**：本项目在生成端即解决了该问题。遇到 API 返回空值时，脚本将其标记为 `nullMoonset` 等占位符，然后利用**时间排序**将非数字字符串排至文件末尾，最后通过**首尾裁剪机制**直接剔除，确保前端拿到的数据必然严格遵循“一升一降”成对出现。
- **解析端（Lua）的防御设计**：由于生成端保证了数据纯净，前端计算无需针对“落至落”做复杂兜底。仅需在解析时进行基础的 `tonumber` 检查（防篡改历史脏数据），过滤无效行即可。
