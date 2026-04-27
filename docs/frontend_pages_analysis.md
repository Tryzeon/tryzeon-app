# Frontend Pages Analysis

> 遵循 Clean Architecture，所有 UI 檔案位於各 feature 的 `presentation/` 層

---

## 目錄結構概覽

```
lib/
├── core/
├── feature/
│   ├── auth/
│   ├── common/
│   ├── personal/
│   │   ├── account/
│   │   ├── chat/
│   │   ├── home/
│   │   ├── onboarding/
│   │   ├── settings/
│   │   ├── shop/
│   │   ├── subscription/
│   │   └── wardrobe/
│   └── store/
│       ├── home/
│       ├── onboarding/
│       ├── products/
│       └── settings/
├── main.dart
└── firebase_options.dart
```

---

## 統計摘要

| Feature | Pages | Widgets | 其他組件 |
|---------|------:|--------:|--------:|
| Auth | 4 | 1 | - |
| Personal > Account | 1 | - | - |
| Personal > Chat | 1 | - | 1 constant |
| Personal > Home | 1 | 4 | - |
| Personal > Onboarding | 1 | 3 | 3 providers |
| Personal > Settings | 3 | - | 2 controllers |
| Personal > Shop | 3 | 13 | 1 dialog |
| Personal > Subscription | 1 | - | 2 providers |
| Personal > Wardrobe | 1 | 1 | 1 dialog + 1 mapper |
| Store > Home | 1 | 3 | - |
| Store > Onboarding | 1 | - | - |
| Store > Products | 2 | 9 | 1 controller + 2 hooks + 1 dialog + 1 extension + 1 mapper + 2 state |
| Store > Settings | 2 | - | 2 controllers |
| **Total** | **22** | **34** | **18** |

---

## Auth（認證模組）

**路徑:** `lib/feature/auth/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/login_page.dart` | 主登入頁（選擇個人 / 店家） |
| `pages/email_login_page.dart` | Email 登入頁 |
| `pages/personal_login_page.dart` | 個人用戶登入 |
| `pages/store_login_page.dart` | 店家用戶登入 |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/login_scaffold.dart` | 登入頁共用 Scaffold |

---

## Personal > Account（個人帳戶）

**路徑:** `lib/feature/personal/account/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/my_page.dart` | 個人帳戶頁（My Page） |

---

## Personal > Chat（個人聊天）

**路徑:** `lib/feature/personal/chat/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/chat_page.dart` | AI 聊天諮詢頁 |

### Other

| 檔案 | 說明 |
|------|------|
| `constants/qa_config.dart` | QA 問答設定常數 |

---

## Personal > Home（個人首頁）

**路徑:** `lib/feature/personal/home/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/home_page.dart` | 個人首頁（Try-On 核心功能） |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/try_on_action_button.dart` | Try-On 操作按鈕 |
| `widgets/try_on_gallery.dart` | Try-On 圖片展示 |
| `widgets/try_on_indicator.dart` | Try-On 狀態指示器 |
| `widgets/try_on_more_options_button.dart` | Try-On 更多選項按鈕 |

---

## Personal > Onboarding（個人引導）

**路徑:** `lib/feature/personal/onboarding/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/personal_onboarding_page.dart` | 個人用戶引導流程頁 |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/age_step.dart` | 年齡輸入步驟 |
| `widgets/gender_selection_step.dart` | 性別選擇步驟 |
| `widgets/style_preference_step.dart` | 風格偏好步驟 |

### Providers

| 檔案 | 說明 |
|------|------|
| `providers/onboarding_notifier.dart` | Onboarding 狀態管理 |
| `providers/onboarding_notifier.freezed.dart` | Freezed 產生檔 |
| `providers/onboarding_notifier.g.dart` | Riverpod 產生檔 |

---

## Personal > Settings（個人設定）

**路徑:** `lib/feature/personal/settings/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/settings_page.dart` | 個人設定頁 |
| `pages/profile_setting_page.dart` | 個人資料編輯頁 |
| `pages/preferences_page.dart` | 偏好設定頁 |

### Providers

| 檔案 | 說明 |
|------|------|
| `providers/personal_settings_controller.dart` | 個人設定 Controller |
| `providers/personal_settings_controller.g.dart` | Riverpod 產生檔 |

---

## Personal > Shop（個人購物）

**路徑:** `lib/feature/personal/shop/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/shop_page.dart` | 購物首頁（品牌 / 商品列表） |
| `pages/store_page.dart` | 店家頁面 |
| `pages/product_detail_page.dart` | 商品詳情頁（個人視角） |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/ad_banner.dart` | 廣告橫幅 |
| `widgets/category_filter.dart` | 品類篩選器 |
| `widgets/product_card.dart` | 商品卡片 |
| `widgets/product_category_filter.dart` | 商品分類篩選 |
| `widgets/product_detail_body.dart` | 商品詳情內容區 |
| `widgets/product_grid.dart` | 商品格狀列表 |
| `widgets/product_header.dart` | 商品頁 Header |
| `widgets/product_image_viewer.dart` | 商品圖片檢視器 |
| `widgets/product_info_section.dart` | 商品資訊區塊 |
| `widgets/product_size_table.dart` | 尺寸表格 |
| `widgets/product_store_info.dart` | 商品店家資訊 |
| `widgets/search_bar.dart` | 搜尋欄 |
| `widgets/tryon_mode_sheet.dart` | Try-On 模式 Bottom Sheet |
| `widgets/video_prompt_customize_sheet.dart` | 影片提示自訂 Bottom Sheet |

### Dialogs

| 檔案 | 說明 |
|------|------|
| `dialogs/filter_dialog.dart` | 篩選 Dialog |

---

## Personal > Subscription（個人訂閱）

**路徑:** `lib/feature/personal/subscription/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/subscription_page.dart` | 訂閱方案頁 |

### Providers

| 檔案 | 說明 |
|------|------|
| `providers/subscription_capabilities_provider.dart` | 訂閱能力 Provider |
| `providers/subscription_capabilities_provider.g.dart` | Riverpod 產生檔 |

---

## Personal > Wardrobe（個人衣櫃）

**路徑:** `lib/feature/personal/wardrobe/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/wardrobe_page.dart` | 個人衣櫃頁 |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/wardrobe_item_card.dart` | 衣櫃單品卡片 |

### Dialogs

| 檔案 | 說明 |
|------|------|
| `dialogs/upload_wardrobe_item_dialog.dart` | 上傳衣物 Dialog |

### Mappers

| 檔案 | 說明 |
|------|------|
| `mappers/category_ui_mapper.dart` | 分類 UI 映射 |

---

## Store > Home（店家首頁）

**路徑:** `lib/feature/store/home/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/home_page.dart` | 店家首頁（銷售分析 Dashboard） |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/month_filter_widget.dart` | 月份篩選器 |
| `widgets/store_home_header.dart` | 店家首頁 Header |
| `widgets/store_traffic_dashboard.dart` | 流量分析 Dashboard |

---

## Store > Onboarding（店家引導）

**路徑:** `lib/feature/store/onboarding/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/store_onboarding_page.dart` | 店家引導流程頁 |

---

## Store > Products（店家商品管理）

**路徑:** `lib/feature/store/products/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/add_product_page.dart` | 新增商品頁 |
| `pages/product_detail_page.dart` | 商品詳情頁（店家視角） |

### Widgets

| 檔案 | 說明 |
|------|------|
| `widgets/product_basic_info_editor.dart` | 商品基本資訊編輯器 |
| `widgets/product_card.dart` | 商品卡片（店家版） |
| `widgets/product_category_selector.dart` | 商品分類選擇器 |
| `widgets/product_form_layout.dart` | 商品表單佈局 |
| `widgets/product_image_editor.dart` | 商品圖片編輯器 |
| `widgets/product_list_section.dart` | 商品列表區塊 |
| `widgets/product_season_selector.dart` | 商品季節選擇器 |
| `widgets/product_size_list_editor.dart` | 商品尺寸列表編輯器 |
| `widgets/product_style_selector.dart` | 商品風格選擇器 |

### Controllers

| 檔案 | 說明 |
|------|------|
| `controllers/product_size_entry_controller.dart` | 尺寸輸入 Controller |

### Hooks

| 檔案 | 說明 |
|------|------|
| `hooks/use_product_form.dart` | 商品表單 Hook |
| `hooks/use_product_size_manager.dart` | 商品尺寸管理 Hook |

### Dialogs

| 檔案 | 說明 |
|------|------|
| `dialogs/product_sort_dialog.dart` | 商品排序 Dialog |

### Extensions / Mappers / State

| 檔案 | 說明 |
|------|------|
| `extensions/product_attributes_extension.dart` | 商品屬性擴充方法 |
| `mappers/product_sort_field_ui_mapper.dart` | 排序欄位 UI 映射 |
| `state/product_query_state.dart` | 商品查詢狀態 |
| `state/product_query_state.freezed.dart` | Freezed 產生檔 |

---

## Store > Settings（店家設定）

**路徑:** `lib/feature/store/settings/presentation/`

### Pages

| 檔案 | 說明 |
|------|------|
| `pages/settings_page.dart` | 店家設定頁 |
| `pages/profile_setting_page.dart` | 店家資料編輯頁 |

### Providers

| 檔案 | 說明 |
|------|------|
| `providers/store_settings_controller.dart` | 店家設定 Controller |
| `providers/store_settings_controller.g.dart` | Riverpod 產生檔 |

---

## 主要用戶流程

### 個人用戶（Personal）

```
登入流程: login_page → personal_login_page / email_login_page
    ↓
引導流程: personal_onboarding_page
    [gender_selection_step → age_step → style_preference_step]
    ↓
主功能:
├── home_page         (Try-On 試穿)
├── shop_page         (瀏覽商品)
│   └── product_detail_page (商品詳情 → Try-On)
├── wardrobe_page     (我的衣櫃)
├── chat_page         (AI 諮詢)
└── my_page           (帳戶)
    ├── subscription_page   (訂閱方案)
    └── settings_page       (設定)
        ├── profile_setting_page
        └── preferences_page
```

### 店家用戶（Store）

```
登入流程: login_page → store_login_page / email_login_page
    ↓
引導流程: store_onboarding_page
    ↓
主功能:
├── store home_page        (銷售分析 Dashboard)
├── add_product_page       (新增商品)
├── product_detail_page    (商品管理)
└── settings_page          (設定)
    └── profile_setting_page
```
