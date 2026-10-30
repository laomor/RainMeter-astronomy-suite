# Astronomy Suite

> 把日月升降时间变成四种可视化视图：**地球光照球、天体轨迹、事件时间轴、视位置模拟**。
> <br>`本README中只展示地球光照球、视位置模拟两种预览效果的展示。`

---

## 效果预览

<table>
<tr>
<td><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" alt="地球光照球"><br><sub></b>2026-10-27_21-50</sub></td>
<td><img src="EffectPreviewImage_Globe/Globe_2026-10-30_11-23.png" alt="地球光照球"><br><sub></b>2026-10-30_11-23</sub></td>
<td><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" alt="地球光照球"><br><sub></b>2026-10-27_21-50</sub></td>
<tr>
<tr>
<td><sub><b>地球光照球</b> — 太阳/月亮双模式，360 张序列插值还原晨昏线</sub></td>
</tr>
<tr>
<td><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" alt="位置模拟"><br><sub></b>2026-10-28_09-00.png</sub></td>
<td><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" alt="位置模拟"><br><sub></b>2026-10-28_09-00.png</sub></td>
<td><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" alt="位置模拟"><br><sub></b>2026-10-28_09-00.png</sub></td>
<tr>
<tr>
<td><sub><b>位置模拟</b> — 四事件周期内的天体视位置</sub></td>
</tr>
</table>

> 更多的截图保存在 `EffectPreviewImage_*/` 文件夹中。

---

## 仓库结构

```text
.
├── AstronomicalEvents.xml          # Windows 任务计划配置文件
├── GlobePicture.zip                # 360张地球图片的压缩包（方便单独下载，仓库内已有解压版）
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
1. 右键点击系统托盘的 Rainmeter 图标，选择 **“皮肤” → “打开皮肤目录”**。
2. 在打开的 `Skins` 文件夹中，新建一个名为 **`Astronomy Suite`** 的文件夹。

### 第二步：按结构组合文件
从本仓库下载文件，并严格按照以下结构放入 `Astronomy Suite` 文件夹中。
*(注：`@Resources` 是 Rainmeter 的共享资源目录，所有 `.ini` 都可以读取里面的图片和 Lua 脚本)*

```text
.
Rainmeter/Skins/Astronomy Suite/
│
├── @Resources/                     # 共享资源（图片、脚本）
│   ├── globe/                      # 解压 GlobePicture.zip 到这里 (360张图)
│   │   ├── globe_000.png
│   │   ├── globe_001.png
│   │   └── ... (一直到 globe_359.png)
│   │
│   ├── Background_double.png       # 来自仓库的 Background/ 文件夹
│   ├── Tracker_mark.png            # 来自仓库的 icon/ 文件夹
│   ├── Tracker_moon.png            # 来自仓库的 icon/ 文件夹
│   ├── Tracker_sun.png             # 来自仓库的 icon/ 文件夹
│   │
│   ├── Globe.lua                   # 来自仓库的 Script_Globe/ 文件夹
│   ├── Globe_Combine.lua           # 来自仓库的 Script_Globe/ 文件夹
│   ├── Event Tracker.lua           # 来自仓库的 Script_SunMoonTracker/ 文件夹
│   ├── Position Simulator.lua      # 来自仓库的 Script_SunMoonTracker/ 文件夹
│   └── Trajectory Viewer.lua       # 来自仓库的 Script_SunMoonTracker/ 文件夹
│
├── Globe/                          # 地球光照球皮肤（来自 Skins_Globe/）
│   ├── BodyType.inc
│   ├── Globe.ini
│   ├── Globe_Combine.ini
│   ├── Globe_Moon.ini
│   └── Globe_Sun.ini
│
└── SunMoonTracker/                 # 轨迹与事件皮肤（来自 Skins_SunMoonTracker/）
    ├── Event Tracker.ini
    ├── Position Simulator.ini
    └── Trajectory Viewer.ini
```

### 第三步：准备天文数据

皮肤读取的是纯文本数据，统一存放在 `C:\Users\Public\Documents\Rainmeter Data\` 目录下。请根据你的需求选择以下一种方式：

#### 🟢 方案 A：开箱即用（只想看效果）
直接下载本仓库 `Event Time Case` 文件夹内的 4 个 `.txt` 文件，复制到 `Rainmeter Data` 目录中即可。
> **提示**：该文件夹的数据由 GitHub Actions 每天自动更新。但请注意，云端服务器默认使用的是**北京经度**。

#### 🔵 方案 B：本地自动化（长期使用，自定义城市）
1. 将仓库 `Users Public Documents` 文件夹里的 `AstronomicalEvents.ps1` 和 `WeatherApiKeys.json` 复制到 `C:\Users\Public\Documents\` 目录下。
2. **申请免费 API 密钥**：
   - [和风天气 API 控制台](https://id.qweather.com/#/login)
   - [百度地图 API 控制台](https://lbsyun.baidu.com/apiconsole/becomedev/selection)
3. 用记事本打开 `WeatherApiKeys.json`，填入申请到的密钥并保存。
4. 右键 `AstronomicalEvents.ps1` 选择“使用 PowerShell 运行”。确认能正常生成数据后，双击 `AstronomicalEvents.xml` 导入 Windows 任务计划，实现本地每 4 小时自动拉取更新。

### 第四步：加载皮肤
刷新 Rainmeter，在管理器中展开 Astronomy Suite，加载你想要的皮肤即可：

- Globe\Globe_Combine.ini （日月双球）
- SunMoonTracker\Trajectory Viewer.ini （轨迹视图）

---

## 核心原理（平台无关）

整个项目的数据流可以抽象为：**输入时间点 → 计算时间比例 → 映射到不同视图的坐标或图片**。由于不同视图的展示需求不同，它们对时间的计算逻辑也有所差异。

### 共用基础：相邻事件对与时间比例 t

无论展示哪种视图，第一步都需要找到当前时间 `now` 处于哪两个**相邻事件**（`prevEvent` 与 `nextEvent`）之间。我们据此计算一个比例值 `t`。

- **输入**：`(time, type)` 列表，按时间升序。
- **计算公式**：
  ```text
  ratio = (now - prevEvent.time) / (nextEvent.time - prevEvent.time)
  
  // 判断当前处于可见期还是隐藏期
  if (prevEvent 是升起 AND nextEvent 是落下):  
      t = ratio        // t ∈ [0, 1]
  else:              
      t = 1 + ratio    // t ∈ [1, 2]
  ```

**关于 t 的物理意义（消除歧义）：**
`t` 的具体含义完全取决于你取到的是哪两个事件，它并**不固定**代表某一特定的方向：
- 当 `prev` 是升起、`next` 是落下（即**可见期**），`t` 从 0 变到 1，代表天体从**升到落**。
- 当 `prev` 是落下、`next` 是升起（即**隐藏期**），`t` 从 1 变到 2，代表天体从**落到升**。

---

### 专属一：Globe 系列（地球光照球）

Globe 系列只关心图片索引，它直接利用上述的 `t` 值进行插值计算，得出 `0~359` 的图片编号。

**核心逻辑**：
- 当 `t ≤ 1`（可见期）时，在日出和日落的图片索引之间插值。
- 当 `t > 1`（隐藏期）时，在日落和次日日出的图片索引之间插值。

*(注：具体锚点索引公式见项目内的 `Globe.lua`，此处不作赘述。)*

---

### 专属二：SunMoonTracker 系列（轨迹/事件视图）

Tracker 系列需要计算天体在屏幕上的 `(X, Y)` 坐标。**在这里，`t` 仅用于计算 Y 轴高度，不参与 X 轴的计算。** X 轴位置由各个视图独立的绝对时间逻辑决定。

#### 1. Y 轴：抛物线模型（依赖 t）
天体在空中的高度用抛物线近似。代码通过判断 `t` 的范围来决定使用哪种抛物线（上开口或下开口），并计算具体高度：

```text
可见期（t ∈ [0,1]）:  y = HorizonY - (HorizonY - apex)  * (1 - (2t - 1)²)
隐藏期（t ∈ [1,2]）:  y = HorizonY + (nadir - HorizonY) * (1 - (2(t-1) - 1)²)
```

- `t=0` 或 `t=1` 时，`y = HorizonY`，刚好在地平线上。
- `t=0.5` 或 `t=1.5` 时，达到抛物线的顶点/底点。

#### 2. X 轴：三种视图的独立设计
X 轴的计算完全不依赖 `t`，而是由不同的时间轴逻辑驱动：

| 视图 | X 轴计算逻辑 |
|---|---|
| **Trajectory Viewer（日轨迹）** | 基于自然日计算：`x = xStart + (now - todayStart) / secondPerPixel` <br>一天 24 小时固定铺满整个宽度。 |
| **Event Tracker（事件追踪）** | 天体 X 固定在偏左位置。事件按 `(eventTime - axisStart) / secondPerPixel` 映射，形成滚动轴。 |
| **Position Simulator（位置模拟）** | 基于“四事件周期”计算 X 坐标。 |

> **什么是四事件周期？**
> 在 `Position Simulator.lua` 中，为了表现天体运动的连贯性，它不只取前后两个事件，而是取完整的四个事件 `[Set₁, Rise₁, Set₂, Rise₂]`。
> - `cycle.startTime` = 前两个事件的中点（即 Set₁ 和 Rise₁ 的中点）
> - `cycle.endTime` = 后两个事件的中点（即 Set₂ 和 Rise₂ 的中点）
> 
> X 轴进度 `x = xStart + (now - cycle.startTime) / (cycle.endTime - cycle.startTime) * length`。
> 在这种模式下，一个完整的 X 轴跨度**既包含了天体的隐藏期（Set₁ 到 Rise₁），也包含了可见期（Rise₁ 到 Set₂）**。太阳和月亮各自用自己的周期，因此它们的 X 轴进度是不同步的。

---

## 移植参考与进阶建议

如果你计划将本项目的核心逻辑移植到其他平台（如 Android 小组件、Web、原生桌面应用等），以下是关于数据、算法和异常处理的详细参考。

### 1. 数据源与 API 接入
- **API 替换**：原版使用的是和风天气 API。虽然理论上可以替换为其他天气服务，但目前市面上能稳定且免费提供**月升月落**时间数据的 API 非常少，和风天气是极佳的选择。
- **密钥配置**：由于 API 请求量过大可能会产生计费，强烈建议移植时**提供配置接口**（如设置页面或环境变量），让最终用户填入自己申请的 API Key，避免开发者公共 Key 被滥用。

### 2. 图像素材与视角进阶（3D 渲染）
- **静态图片的局限**：目前项目提供的 360 张地球光照图是基于**赤道视角**生成的。如果你的应用场景需要面向高纬度地区，直接使用这套图片会导致晨昏线的倾斜角度不准确。
- **动态渲染替代方案**：移植时完全可以抛弃静态图片。你可以使用 Three.js、Canvas 或原生 3D 引擎，只需要准备地球的贴图，通过编写 Shader（着色器）结合太阳直射经纬度的算法，**实时计算并渲染出任意视角下完美的晨昏线状态**。

### 3. 轨迹算法的替代方案
- **抛物线只是妥协**：当前 Y 轴使用的 `1 - (2t-1)²` 抛物线模型，是为了适应 Rainmeter 较弱的曲线绘制能力而采用的轻量级近似方案。**后来我发现 Rainmeter 无法很好地显示曲线，所以放弃了绘制曲线的想法，但采用了抛物线这个模型。**
- **可替换算法**：移植时完全可以抛弃此方案。你可以利用原生的 `Canvas`、`SVG` 路径或 `UIBezierPath`，采用正弦函数（`sin`）、贝塞尔曲线，甚至直接引入真实的天文学球面三角公式来绘制天体的真实运动轨迹。

### 4. 时间轴与区间定位
- **参考四事件周期**：对于任何需要按时间推进的动画或 UI 状态，建议参考 `Position Simulator` 中的 **四事件周期**（`[Set₁, Rise₁, Set₂, Rise₂]`）。这是一个很好的区间判定方案，能帮助你确定当前时间处于周期的哪一个相对位置，从而避免升起/落下瞬间的坐标跳变。

### 5. 异常数据处理与排查
- **缺失事件的原因**：在请求真实数据时，必须注意**月亮事件**。因为月亮的循环周期略大于 24 小时（约 24 小时 50 分钟），所以当月亮运行到某个特定周期时，某一天可能只会出现月出而缺失月落，或者只有月落而缺失月出。
- **容错机制**：移植代码中必须加入严格的错误排查。如果解析到类似 `nullMoonset` 或事件时间为空，应当跳过该事件，并在 UI 上做好降级处理，防止抛出空指针异常（NullPointerException）导致程序崩溃。

---

## 常见问题

- **txt 没生成？** 检查 `WeatherApiKeys.json` 是否在 PS1 同目录、字段名是否正确；手动跑看控制台报错。
- **地球空白/图片错乱？** 确认 `GlobePicture` 文件夹内包含 `globe_000.png ~ 359.png` 共 360 张图。
- **光照位置不对？** `LocalLongitude` 与数据城市经度不一致，改成实际值。
- **轨迹/事件不在容器内？** 减小 `OffsetValue`、`SecondPerPixel`，或增大 `SkinHeight`。
- **任务计划跑了但没数据？** 查历史记录返回码；SYSTEM 账户桌面路径不可写时，改错误日志到公共目录。

---

## 已知限制

- `LocalLongitude` 不自动同步，需手动保持一致。
- Lua 解析用 `line:sub(1, 10)`，2038 年后失效。
- 月亮顶点固定，未考虑月相/赤纬。
- 事件不足时位置模拟会退化。
