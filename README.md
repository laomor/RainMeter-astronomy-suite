# Astronomy Suite

> 把我自己折腾的日月升降数据，变成 Rainmeter 里能看的四个小视图：**地球光照球、每日轨迹、天空位置模拟、事件时间轴**。
> 
> 写这份说明主要有两个目的：
> - **你想直接用**：照着“快速部署”走一遍，就能在桌面上看到效果。
> - **你想移植到别的平台**：我把四个视图分别在看什么、数据怎么流、核心公式是什么、我当时踩过哪些坑，都尽量讲清楚，方便你搬到 Web、App 或者别的桌面工具里。
> 
> 先交个底：我不是专业程序员。这个项目就是我边查资料、边试错、边改代码攒出来的。里面有不少“当时够用就行”的妥协，我都写在后面了。大佬轻喷，能跑、能看、能让我自己觉得好玩，是我最大的目标。

---

## 效果预览

<table align="center">
  <tr>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" width="200"><br><sub><b>2026-10-27_21-50</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-30_11-23.png" width="200"><br><sub><b>2026-10-30_11-23</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Globe/Globe_2026-10-27_21-50.png" width="200"><br><sub><b>2026-10-27_21-50</b></sub></td>
  </tr>
  <tr>
    <td align="center" colspan="3"><sub><b>地球光照球</b> — 太阳和月亮双模式，用 360 张图平滑插值出真实的太阳直射经度图片</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" width="200"><br><sub><b>2026-10-28_09-00</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-30_22-35.png" width="200"><br><sub><b>2026-10-30_22-35</b></sub></td>
    <td align="center"><img src="EffectPreviewImage_Position/Position_2026-10-28_09-00.png" width="200"><br><sub><b>2026-10-28_09-00</b></sub></td>
  </tr>
  <tr>
    <td align="center" colspan="3"><sub><b>位置模拟</b> — 看看天体在天空中在哪个位置</sub></td>
  </tr>
</table>

> 想看更多截图？去 `EffectPreviewImage_*/` 文件夹里溜达一圈吧。（以后我会往里面放更多图，但这篇说明里就先放这几张啦）。

---

## 四种视图分别在看什么？

| 视图 | 一句话 | 适合谁 |
|---|---|---|
| **Globe 地球光照球** | 用 360 张地球图按时间插值，让晨昏线跟着本地日出日落转起来 | 想看“现在地球被照成什么样” |
| **Trajectory Viewer** | 呈现每天中太阳和月亮的运行轨迹 | 想看“今天太阳和月亮一天里是怎么走的” |
| **Event Tracker** | 呈现未来升降事件发生的时间点 | 想看“接下来几次日出日落、月出月落大概在什么时候” |
| **Position Simulator** | 呈现太阳和月亮在天空中的位置 | 想看“现在这个周期里，太阳/月亮现在大概在天空的什么位置” |

这四个视图共用同一批数据文件，只是拿数据的方式和画图的方式不一样。

---

## 快速部署（如果你只想直接用）

### 第一步：建个皮肤文件夹
1. 在电脑右下角找到 Rainmeter 的小雨滴图标，右键它，选 **“皮肤” → “打开皮肤目录”**。
2. 在弹出的 `Skins` 文件夹里，新建一个名叫 **`Astronomy Suite`** 的文件夹。

### 第二步：把文件对号入座
从仓库下载文件后，按下面的结构摆放。*(小提示：`@Resources` 是个共享文件夹，所有的皮肤都会去这里找图片和脚本。)*

```text
Rainmeter/Skins/Astronomy Suite/
│
├── @Resources/                     # 共享资源
│   ├── globe/                      # 把 GlobePicture.zip 解压到这里
│   │   ├── globe_000.png
│   │   └── ... (一直到 globe_359.png)
│   ├── Background_double.png       # 从 Background/ 里拿
│   ├── Tracker_*.png               # 从 icon/ 里拿
│   ├── Globe.lua                   
│   ├── Globe_Combine.lua           
│   ├── Event Tracker.lua           
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

### 第三步：搞点天文数据来
皮肤是个“空壳”，它得去 `C:\Users\Public\Documents\Rainmeter Data\` 读数据。你有两条路：

**路子 A：只想看看效果（极速版）**
直接从仓库的 `Event Time Case` 文件夹里，把 4 个 `.txt` 文件掏出来，扔进上面的目录里。（这个文件夹里的数据会每天自动更新，默认用的是北京的经度）。

**路子 B：想自己长期用，看自己城市的（折腾版）**
1. 把 `Users Public Documents` 里的 `AstronomicalEvents.ps1` 和 `WeatherApiKeys.json` 挪到 `C:\Users\Public\Documents\`。注意：这俩要放一起，脚本会在它自己所在目录找配置文件。
2. 去这两个地方白嫖一下免费的 API 密钥：[和风天气](https://id.qweather.com/#/login) 和 [百度地图](https://lbsyun.baidu.com/apiconsole/becomedev/selection)。
3. 把密钥填进 `WeatherApiKeys.json` 里保存好。
4. 右键那个 `.ps1` 文件，选“使用 PowerShell 运行”，看它能不能吐出数据。如果没问题，双击 `AstronomicalEvents.xml` 导进系统的任务计划，以后每 4 小时它就会自己帮你抓数据啦。
   *(小提示：这里用 SYSTEM 账户运行，是为了保证不管电脑当前是谁登录，任务都能顺利启动，准时去拿数据。)*

### 第四步：开玩！
刷新一下 Rainmeter，展开 `Astronomy Suite`，挑个顺眼的加载吧：
- `Globe\Globe_Combine.ini`：日月双球同屏。
- `Globe\Globe.ini`：单球，点 S/M 可以在太阳和月亮之间切。
- `SunMoonTracker\Trajectory Viewer.ini`：看今天一天的运动轨迹。
- `SunMoonTracker\Event Tracker.ini`：看当前状态 + 未来几个事件的时间条。
- `SunMoonTracker\Position Simulator.ini`：看太阳/月亮现在大概在天空的什么位置。

---

## 想移植到别的平台？先看数据长什么样

移植这件事，最怕数据格式没搞明白。这个项目只有两种数据文件，格式都很简单。

### 1. 本地时间格式：`SunEvents.txt` / `MoonEvents.txt`
```text
202610291716Sunset
202610300640Sunrise
```
前 8 位是日期，接着 4 位是时间，后面是事件名。给人看的，也方便你肉眼检查。

### 2. Unix 时间戳格式：`SunTimeStampEvent.txt` / `MoonTimeStampEvent.txt`
```text
1793265360Sunset
1793313600Sunrise
```
前 10 位是 Unix 时间戳（秒），后面是事件名。Lua 只读这一套，因为直接比大小、做减法最方便。

### 3. 月亮数据可能长这样（原始数据，未排序、未修剪）
```text
202610291937Moonrise
202610291018Moonset
202610302044Moonrise
202610301124Moonset
202610312156Moonrise
202610311219Moonset
202611012310Moonrise
202611011304Moonset
Moonrise
202611021340Moonset
202611030021Moonrise
202611031410Moonset
202611040129Moonrise
202611041437Moonset
```

注意两件事：
- **原始数据不一定按时间排序。** 比如 `19:37 Moonrise` 排在 `10:18 Moonset` 前面，但 10:18 更早。
- **月亮偶尔缺事件。** 上面中间有一行只有 `Moonrise`，没有有效时间戳。它可能是 `nullMoonrise`，也可能就是只有事件名。

PS1 生成端会先排序，再删掉首尾各一条，尽量把边缘无效行挤掉；Lua 解析时用 `tonumber` 检查前 10 位，转不成数字的行直接跳过。**但这套流程不能保证最终数据严格“一升一落”成对**，只是尽量让前端可用。移植时如果你想要更稳，最好在数据层就把“只有月出”或“只有月落”的日子标出来，前端再决定怎么处理。

---

## 核心原理与算法模型

这玩意儿到底是怎么转起来的？其实它靠的是一个大杀器：**时间比例 `t`**，然后兵分两路去画图。

### 基础：算出一个时间比例 `t`
不管你想画什么，系统首先得知道“现在”是在哪两个事件中间。找到前后的 `prevEvent` 和 `nextEvent` 后，掏出这个公式：

```text
ratio = (now - prevEvent.time) / (nextEvent.time - prevEvent.time)

if (prevEvent 是升起 AND nextEvent 是落下):  
    t = ratio        // 可见期，t ∈ [0, 1]
else:              
    t = 1 + ratio    // 隐藏期，t ∈ [1, 2]
```
> **通俗点说**：`t` 就是个进度条。如果在白天（可见期），`t` 从 0 跑到 1，代表从升到落；如果在夜里（隐藏期），`t` 就从 1 跑到 2，代表从落到下一次升。

拿到这个进度条 `t` 之后，两个不同的皮肤系列就各奔东西了：

### 分支一：Globe 系列（地球光照球）
这哥们比较单纯，它只要图片序号。它就拿着 `t` 去日出和日落的图片序号中间找位置，插值出一个 `0~359` 的编号，直接往屏幕上贴。
- 白天（`t ≤ 1`）就在日出和日落的图里找。
- 夜里（`t > 1`）就在日落和第二天日出的图里找。

> **晨昏线的作用是啥？** 360 张图里，晨线和昏线对应的两张图就是“本地日出”和“本地日落”的边界。它们就像一个分拣员，把图分成了白天区间和夜晚区间。**我们不是真把两张图删了，而是把它们当成边界锚点。**

*(注：月亮球借用了同一套纹理和公式，只是用月出月落来驱动。它显示的是“视觉进度”，不是真实的月亮直射经纬度，纯为了好看。)*

### 分支二：SunMoonTracker 系列（三个视图）

Tracker 系列要算 `(X, Y)` 坐标。分工很明确：**Y 轴靠 `t` 算，X 轴靠绝对时间或周期比例算。**

**1. Y 轴：抛物线模型**
可见期用开口向下的抛物线，隐藏期映射后开口向上：
```text
y = HorizonY - (HorizonY - apex) * (1 - (2t - 1)²)
```
效果就是：`t=0` 或 `t=1` 时在地平线，`t=0.5` 到顶点，`t=1.5` 到底点。太阳的顶点/底点会根据白昼/黑夜时长动态调；月亮固定，没做动态高度。

**2. X 轴：三个视图三种算法**
- **Trajectory Viewer（每日轨迹）**：`x = XAxisStart + (now - 今日零点) / SecondPerPixel`。把一天铺满时间轴，从左走到右，每天零点重置。
- **Event Tracker（未来事件）**：计算出一个时间窗口，当前时间固定在偏左的位置，事件按 `(eventTime - axisStart) / SecondPerPixel` 往后排。最多显示 5 个事件。
- **Position Simulator（天空位置）**：找当前“四事件周期”（`Set₁ → Rise₁ → Set₂ → Rise₃`），把当前时间在这个周期里的比例，映射到整条时间轴上。

---

## 移植避坑指南（都是老司机的血泪）

如果你觉得这套逻辑好玩想搬家，下面这几条建议你可以看看：

1. **关于 API 和防扣费**：能提供月升月落数据的 API 真的少，和风天气算一个。千万别把开发者的 Key 塞在代码里。建议一次性拉多点数据（比如一周），让用户刷新少点，请求少了就不会触发计费。给用户留个接口填自己的 Key。
2. **渲染的降维与升维**：现在用 360 张图是因为 Rainmeter 的限制，加上我不会 3D。换到 Web 或 App，强烈建议用 Three.js + Shader，结合经纬度算，不管什么季节晨昏线都完美。另外，轨迹也别死磕抛物线，用 SVG、Canvas 直接画正弦函数，会顺滑得多。
3. **月亮偶尔会旷工（重点）**：因为月亮公转周期是 24小时50分钟，总有那么几天它只升不落，或者只落不升。我的 PS1 后端只是用排序和首尾裁剪**尽量**把它挤掉，Lua 前端遇到没时间戳的行也会跳过，但**无法做到绝对干净**。所以移植时，请在数据层就做好异常标记，前端代码要留个心眼。
4. **Lua 读文件是有缓存的**：为了让皮肤不卡，Lua 超过 24 小时或缓存空了才去重读 txt。如果你刚跑完 PS1 抓了新数据，刷新一下皮肤或者重启 Rainmeter 就能看到了。

---

## 最后

这个项目不是什么专业天文软件，就是一个喜欢折腾桌面的人，拿 Rainmeter 和 Lua 拼出来的小玩具。里面有很多“当时能跑就行”的妥协，也有不少数学公式是我查资料现学的。

发现哪里算得不对、哪里可以更优雅，欢迎提 issue 或者直接改。只要它能让你在桌面上多看两眼地球转、太阳升、月亮落，我就觉得没白折腾。

大佬轻喷，谢谢你看完。
