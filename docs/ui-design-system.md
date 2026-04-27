# Tryzeon UI Design System Spec

**Date:** 2026-04-26
**Version:** 1.0
**Status:** Approved

---

## 1. 設計哲學

### 風格方向：Clean Luxe

Tryzeon 的目標受眾是對時尚有品味的 Gen Z 用戶。UI 設計的核心哲學是「高質感、簡約不花俏」——讓服裝和使用者的試穿結果成為視覺主角，UI 本身盡量退到背景。

設計靈感參考：SSENSE、Matches Fashion、Arket 等精品電商，以及 TOTEME、COS 等品牌的官網美學。

### 三個設計原則

1. **留白優先（Whitespace First）** — 寬鬆的 padding 與 margin，元件之間給予充足呼吸空間，避免視覺擁擠。
2. **排版即設計（Typography as Design）** — 字型的選擇、字重的對比、letter-spacing 的控制，是創造層次感的主要手段，而非顏色或裝飾元素。
3. **克制的色彩（Restrained Color）** — 全站只使用一個彩色 accent，其餘均為中性色。不使用漸層、陰影盡量輕柔。

---

## 2. 色彩系統

### Light Mode（當前版本）

| Token | 色票 | Hex | 用途 |
|-------|------|-----|------|
| `background` | 純白 | `#FFFFFF` | 頁面底色、Scaffold |
| `surface` | 淺灰白 | `#F7F7F7` | 卡片、輸入框底色 |
| `surfaceVariant` | 中性灰 | `#EFEFEF` | 次要卡片、選中狀態底色 |
| `outline` | 邊框灰 | `#E5E5E5` | Divider、Border、輸入框邊框 |
| `onSurfaceVariant` | 靜音灰 | `#9E9E9E` | 次要文字、佔位符、Icon |
| `onSurface` | 炭黑 | `#1A1A1A` | 主要文字、標題、重要 UI 元素 |
| `primary` | Terracotta | `#B5674A` | 主要 CTA 按鈕、Active 狀態、價格、Accent |
| `primaryLight` | 淺陶土 | `#C8856C` | Hover 狀態、Tag 背景 |
| `primaryDark` | 深陶土 | `#924F37` | Pressed 狀態 |
| `primaryContainer` | 陶土底色 | `#F5EDE9` | 低強度 accent 背景（Ghost button、Tag） |

> **Dark Mode 預留：** Token 命名已對齊 Flutter Material 3 ColorScheme，日後新增 Dark Mode 只需替換 token 值，組件無需修改。

### 色彩使用原則

- **全站只有 Terracotta 一個彩色**，所有其他顏色均為暖灰/中性。
- 不使用色彩漸層（gradient）。
- 禁止在同一畫面出現兩個不同的彩色 accent。
- `primary` 僅用於：主要 CTA、Active 篩選 pill、價格文字、重要 badge。

---

## 3. 字型系統

### 字型選擇

| 用途 | 字型 | Flutter 套件 |
|------|------|-------------|
| 顯示標題（英文） | **Playfair Display** | `google_fonts` |
| UI 文字（英文 / 數字） | **Outfit** | `google_fonts` |
| 中文內容 | **Noto Sans TC** | `google_fonts` |

### 字型排版規則

**Playfair Display** 用於：
- 品牌名稱「Tryzeon」
- 頁面主標題（displayLarge / displayMedium）
- 商品名稱（可選，視頁面設計）
- 強調語句（Italic 變體）

**Outfit** 用於：
- 所有 UI 標籤（按鈕文字、導航標籤、篩選 Pill、Badge）
- 數字（價格、計數）
- Uppercase letter-spaced 標籤（`font-size: 10px, letter-spacing: 0.2em`）

**Noto Sans TC** 用於：
- 所有中文正文、描述、提示文字
- 商品名稱（中文版本）

### 字型比例（Typography Scale）

| Role | 字型 | 大小 | 字重 | 用途 |
|------|------|------|------|------|
| `displayLarge` | Playfair Display | 48px | 400 | 頁面主視覺標題 |
| `displayMedium` | Playfair Display | 36px | 400 | Section 大標題 |
| `displaySmall` | Playfair Display | 28px / Italic | 400 | 強調標題、品牌名 |
| `headlineLarge` | Outfit | 22px | 600 | 卡片 / 區塊主標題 |
| `headlineMedium` | Outfit | 18px | 600 | 次級標題 |
| `titleLarge` | Outfit | 20px | 600 | 清單標題 |
| `titleMedium` | Outfit | 16px | 500 | 中等強調文字 |
| `bodyLarge` | Noto Sans TC | 15px | 400 | 主要正文 |
| `bodyMedium` | Noto Sans TC | 13px | 400 | 次要正文 |
| `bodySmall` | Noto Sans TC | 11px | 400 | 說明文字、備注 |
| `labelLarge` | Outfit | 12px / UC | 700 | 按鈕文字 |
| `labelMedium` | Outfit | 10px / UC | 700 | Badge、Tag |
| `labelSmall` | Outfit | 9px / UC | 700 | 導航標籤、細節標記 |

> `UC` = Uppercase + letter-spacing 0.1em 以上

---

## 4. 間距系統

採用 **8px 基礎格線**，所有 padding / margin / gap 均為 4 的倍數。

| Token | 值 | 用途 |
|-------|----|------|
| `spacing.xs` | 4px | Icon 旁邊的細間距 |
| `spacing.sm` | 8px | 元件內部小間距 |
| `spacing.md` | 16px | 標準 padding、卡片內距 |
| `spacing.lg` | 24px | Section 間距、頁面左右 padding |
| `spacing.xl` | 32px | 大區塊間距 |
| `spacing.xxl` | 48px | 頁面頂部安全區 padding |

---

## 5. 元件風格原則

### 圓角（Border Radius）

| 元件 | 圓角 |
|------|------|
| 卡片（商品卡、設定卡） | `12px` |
| 按鈕（Primary / Secondary） | `8px` |
| Pill / Tag | `100px`（全圓） |
| 輸入框 | `10px` |
| 底部 Sheet | `20px`（頂部） |
| 對話框 | `16px` |
| Icon 容器（方形） | `10–12px` |

### 陰影（Elevation）

- **原則：輕柔、幾乎不可見**，陰影只用於需要浮起感的元件（對話框、Bottom Sheet、Floating 按鈕）。
- 卡片通常只用 `border: 1px solid outline` 而非陰影。
- 陰影顏色：`rgba(0,0,0,0.06)` 到最多 `rgba(0,0,0,0.10)`。

### 按鈕

| 類型 | 外觀 |
|------|------|
| Primary | 實心 Terracotta，白色文字，`labelLarge` |
| Secondary | 透明背景，炭黑邊框，炭黑文字 |
| Ghost / Tonal | `primaryContainer` 背景，Terracotta 文字 |
| Icon Button（圓形） | `surfaceVariant` 背景，無邊框 |

- 按鈕文字一律 **Uppercase + letter-spacing**。
- 禁止使用漸層或複雜陰影在按鈕上。

### 輸入框

- 底色：`surface`
- 邊框：`1.5px solid outline`（focus 時 `onSurface`）
- 無 filled 風格，統一使用 outlined 風格。
- 搜尋框可搭配左側 search icon。

### 分隔線（Divider）

- 顏色：`outline` (`#E0DDD6`)
- 高度：`1px`
- 不使用虛線或多重線條。

### 導航列（Bottom Navigation）

- 背景：`background`，`border-top: 1px solid outline`。
- Active 指示器：寬 `18px`、高 `3px`、`border-radius: 2px`，顏色為 `primary`（Terracotta）。
- 不使用 Material 3 預設的 NavigationBar pill indicator，改用細線指示器。
- 標籤文字：`labelSmall` Uppercase。

---

## 6. 圖像與媒體

- 商品圖片：優先使用 **白底或淺灰底** 的平鋪產品圖，保持一致性。
- Try-On 結果圖：全螢幕展示，無多餘框線。
- 圖片圓角與所在卡片一致（`12px`）。
- 禁止在圖片上疊加複雜漸層遮罩，最多使用底部淡出（`to top, rgba(background, 0.5)`）。

---

## 7. 動態與互動

- **Transition duration:** `200ms`（快速、不拖沓）
- **Curve:** `easeOut`（進場）/ `easeIn`（離場）
- Page 轉場：使用 Fade + Slide（向上），幅度小（`16px`）。
- 按鈕 Tap：輕微 scale down（`0.97`），不加色彩閃爍。
- 列表載入：Skeleton Loader，使用 `surfaceVariant` 底色做脈衝動畫。

---

## 8. Dark Mode（預留，未實作）

- Color token 架構已設計為雙主題相容。
- Dark Mode 預計 `background → #111111`，`surface → #1C1C1C`，`primary` 不變（Terracotta 在暗色下依然適用）。
- 實作時替換 ColorScheme，無需修改任何元件代碼。

---

## 9. 設計決策記錄

| 決策 | 選擇 | 原因 |
|------|------|------|
| 整體風格 | Clean Luxe | Gen Z quiet luxury 趨勢，讓服裝成為主角 |
| Accent 色 | Terracotta #B5674A | 與奶油底色最自然融合，在同類 AI 時尚 app 中辨識度高 |
| 標題字型 | Playfair Display | 時尚雜誌感，比 Cormorant 更端正，適合品牌名稱 |
| UI 字型 | Outfit | 圓潤現代，字重豐富，比 DM Sans 更有個性 |
| 中文字型 | Noto Sans TC | Flutter Google Fonts 支援完整，清晰易讀 |
| 底色 | 純白 #FFFFFF（統一） | 主流電商風格，更乾淨現代；深色留給 Dark Mode 功能 |
| 邊框指示器 | 細線替代 pill | 更精緻，避免 Material 3 預設感 |
