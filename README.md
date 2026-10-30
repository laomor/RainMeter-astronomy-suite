# Astronomy Suite

> 把日月升降时间变成四种可视化视图：**地球光照球、天体轨迹、事件时间轴、视位置模拟**。
> <br>`本README中只展示地球光照球、视位置模拟两种预览效果的展示。`

---

## 效果预览

<table>
<tr>
<td><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" alt="地球光照球"><br><sub></b>2026-10-27_21-50</sub></td>
<td><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" alt="地球光照球"><br><sub></b>2026-10-27_21-50</sub></td>
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

整个项目的数据流可以抽象为：**输入时间点 → 计算时间比例 → 映射到不同视图的坐标或图片**。

### 共用基础：时间比例 t

无论展示哪种视图，第一步都是找出当前时间 `now` 处于哪两个相邻事件之间，并计算一个 0~2 之间的比例值 `t`。

- **输入**：`(time, type)` 列表，type ∈ `Sunrise/Sunset/Moonrise/Moonset`，按时间升序。
- **公式**：
  ```text
  ratio = (now - prev.time) / (next.time - prev.time)
  if prev是升起 and next是落下:  t = ratio        // 可见期/白天 [0,1]
  else:                          t = 1 + ratio    // 隐藏期/夜晚 [1,2]
  ```
- `t = 0` 是升起瞬间，`t = 1` 是落下瞬间，`t = 2` 是次日升起。**后续所有视觉计算都基于这个 `t` 值。**

---

### 专属一：Globe 系列（地球光照球）
Globe 系列只需要根据 `t` 算出一个 `0~359` 的**图片索引**，用来切换地球的贴图。

**输入**：时间比例 `t`，本地经度 `lon`（东经正、西经负）。

**图片索引计算公式**：
```text
// 1. 预计算日出/日落的锚点索引
riseIdx = ((-lon - 90) % 360 + 360) % 360
setIdx  = (( 90 - lon) % 360 + 360) % 360

// 2. 根据 t 进行插值
t ≤ 1:  idx = lerp360(riseIdx, setIdx, t)       // 白天：日出索引 → 日落索引
t > 1:  idx = lerp360(setIdx, riseIdx, t - 1)   // 夜晚：日落索引 → 次日日出索引
最终:   round(idx) % 360                        // 最终得到的图片编号

// lerp360 处理循环边界：如果起点大于终点，给终点加 360 再插值
lerp360(a, b, r) = a <= b ? a + (b - a) * r : a + (b + 360 - a) * r
```

> **验证**（`lon=114`）：`riseIdx=156`, `setIdx=336`。正午 `t=0.5` 时，`idx=246`，直射经度 `-246 mod 360 = 114`，刚好是本地经度。

---

### 专属二：SunMoonTracker 系列（轨迹/事件视图）
SunMoonTracker 系列需要计算天体在屏幕上的 `(X, Y)` 坐标，两者的公式取决于你加载的皮肤。

#### 1. Y 轴：抛物线模型
天体在空中的高度用抛物线近似。根据 `t` 计算 Y 坐标：

```text
可见期（t ∈ [0,1]）:  y = HorizonY - (HorizonY - apex)  * (1 - (2t - 1)²)
隐藏期（t ∈ [1,2]）:  y = HorizonY + (nadir - HorizonY) * (1 - (2(t-1) - 1)²)
```
- `t=0.5`（正午/午夜）时达到抛物线的顶点/底点。
- `t=0` 或 `t=1`（升落瞬间）时，`y = HorizonY`，刚好在地平线上。
- 太阳的 `apex` 会随白昼时长动态调整（夏季弧线高，冬季低）；月亮为简化模型，顶点固定。

#### 2. X 轴：三种视图设计
X 轴的计算逻辑取决于你想展示什么：

| 视图 | X 轴计算逻辑 |
|---|---|
| **Trajectory Viewer（日轨迹）** | `x = xStart + (now - todayStart) / secondPerPixel` <br>一天 24 小时固定铺满整个宽度。 |
| **Event Tracker（事件追踪）** | 天体 X 固定在偏左位置。事件按 `(eventTime - axisStart) / secondPerPixel` 映射，形成滚动轴。 |
| **Position Simulator（位置模拟）** | `x = xStart + (now - cycle.start) / (cycle.end - cycle.start) * length` <br>用“四事件周期”作为时间轴。 |

> **四事件周期**：取事件流中的 `[Set₁, Rise₁, Set₂, Rise₂]`，前两个事件的中点作起点，后两个事件的中点作终点。太阳和月亮各自用自己的周期，因此它们的 X 轴进度是不同步的。

---

### 最终输出汇总

| 视图/项目 | 输出的核心数据 | 用途 |
|---|---|---|
| **Globe** | 图片索引（0~359） | `ImageName=globe_246.png` |
| **Tracker** | `(x, y)` 像素坐标 | 控制天体图标在容器内的位置 |
| **通用** | 状态字符串、`HH:MM` | 显示 `Day/Night`、`Rise/Fall` 及事件时间 |

---

## 移植参考

### 需要准备
| 项目 | 用途 |
|---|---|
| 事件时间序列 | 一切计算的基础 |
| 本地经度 | 地球光照球视图 |
| 360 张地球图 | 地球光照球视图 |
| 容器尺寸 | 抛物线/布局计算 |
| 时间轴参数 | 轨迹/事件/位置视图 |

### 必须保留的数学不变量
- **t 的分段**：`[0,1]` 可见期，`[1,2]` 隐藏期，共用同一 `ratio`
- **抛物线形状**：`1 - (2t-1)²` 决定了天体在顶点减速、地平线加速的视觉感
- **索引锚点**：`riseIdx = -lon-90`，`setIdx = 90-lon`
- **循环插值**：`start > finish` 时给 `finish` 加 360
- **周期边界**：用四事件中点作边界，避免瞬间坐标跳变

### 可以自由替换
| 部分 | 可选方案 |
|---|---|
| 数据来源 | 本地天文库 (`suncalc`/`astral`) / 公共 API / 系统 API |
| 事件文件格式 | JSON / CSV / 内存对象 / 数据库 |
| 图片序列 | 360 张真实图 / 24 张整点图+插值 / Canvas 实时绘制 |
| 视图组合 | 四种任选其一或组合 |
| 刷新频率 | 秒级 / 分钟级 / 事件触发 |

### 移植注意事项

**数据**
- **时区一致性**：原版时间戳基于生成机器本地时区转 UTC，跨时区需显式转换。
- **事件交替性**：算法假设升起/落下交替，异常数据需容错。
- **null 事件**：`nullMoonrise` 表示无事件，解析时忽略。
- **数据密度**：位置模拟需前后各 2 个同类事件，至少 3 天窗口。
- **时间戳位数**：2038 年后变成 11 位，建议用正则 `^(%d+)(%a+)$` 匹配，而非定长截取。

**算法**
- 地平线、`apex`、`nadir` 随容器高度联动，不能只改一个。
- 顶点/底点留出 `iconSize/2 + offset` 余量，避免图标贴边被裁。
- `t=0/1` 时天体压地平线，可加微小 epsilon 避免视觉“卡住”。
- 月亮顶点固定，若追求精度可引入赤纬/月相，但不能破坏 t 的分段。

**显示**
- 索引取整在 `359↔0` 可能抖动，可加方向判断或平滑。
- 平台刷新频率受限（如 Android Widget 15分钟）时，事件追踪比连续动画更合适。
- 事件标签在窄容器易重叠，需动态布局或滚动。

**平台**
- 经度决定“晨昏线在哪”，时区决定“当前时间”，两者需分开传参。
- 移动端注意电池和后台保活；沙盒应用注意数据目录不可写问题。

---

## 数据格式

**格式 A（人读）**：`yyyyMMddHHmmEventType` （如 `202610221736Sunset`）
**格式 B（计算）**：`Unix秒EventType` （如 `1792661760Sunset`）

**要求**：按时间升序、升起落下交替、至少覆盖 3 天。缺失事件写 `nullMoonrise`，移植时忽略 `null` 前缀行。

---

## 配置速查（Rainmeter）

**采集端**
- `AstronomicalEvents.xml` 中 `<Interval>PT4H</Interval>` 可改为 `PT6H` / `PT12H` 减少调用。

**展示端关键参数**
| 参数 | 默认值 | 说明 |
|---|---|---|
| `LocalLongitude` | `114` | 本地经度 |
| `SecondPerPixel`（Trajectory） | `240` | 360×240 = 86400s = 24h |
| `SecondPerPixel`（Event） | `480` | 360×480 ≈ 2 天 |
| `TimeOffsetInPixels` | `60` | 当前时间距轴起点像素 |
| `OffsetValue` | `15` | 抛物线顶点浮动幅度 |
| `IconSize` | `21` | 图标尺寸 |
| `UpdateDivider` | `60` | Lua 计算间隔（秒） |

**切换太阳/月亮**：`Globe.ini` 点击 `S`/`M`，状态存 `BodyType.inc`；或手动改 `BodyType=Sun` → `Moon`。

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
