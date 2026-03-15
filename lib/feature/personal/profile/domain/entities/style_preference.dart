enum StylePreference {
  // 🌍 地區 / 國家風格
  japanese('japanese'),
  korean('korean'),
  western('western'),
  british('british'),
  chinese('chinese'),

  // 👕 日常 / 休閒風格
  minimalist('minimalist'),
  casual('casual'),
  sporty('sporty'),
  lazy('lazy'),
  streetwear('streetwear'),

  // 💼 專業 / 場景風格
  business('business'),
  preppy('preppy'),
  functional('functional'),

  // 🕰️ 氣質 / 經典風格
  vintage('vintage'),
  artsy('artsy'),
  literary('literary'),
  elegant('elegant'),

  // ✨ 個人特質 / 氛圍風格
  mature('mature'),
  neutral('neutral'),
  spicy('spicy'),
  sweet('sweet');

  const StylePreference(this.value);
  final String value;

  String get label => switch (this) {
    // 🌍 地區 / 國家風格
    StylePreference.japanese => '日系風',
    StylePreference.korean => '韓系風',
    StylePreference.western => '歐美風',
    StylePreference.british => '英式風',
    StylePreference.chinese => '中式感',

    // 👕 日常 / 休閒風格
    StylePreference.minimalist => '簡約風',
    StylePreference.casual => '休閒風',
    StylePreference.sporty => '運動風',
    StylePreference.lazy => '慵懶風',
    StylePreference.streetwear => '街頭風',

    // 💼 專業 / 場景風格
    StylePreference.business => '商務風',
    StylePreference.preppy => '學院風',
    StylePreference.functional => '機能風',

    // 🕰️ 氣質 / 經典風格
    StylePreference.vintage => '復古風',
    StylePreference.artsy => '文青風',
    StylePreference.literary => '文藝風',
    StylePreference.elegant => '優雅風',

    // ✨ 個人特質 / 氛圍風格
    StylePreference.mature => '輕熟風',
    StylePreference.neutral => '中性風',
    StylePreference.spicy => '辣妹風',
    StylePreference.sweet => '甜美風',
  };

  static StylePreference? tryFromString(final String value) =>
      StylePreference.values.where((final e) => e.value == value).firstOrNull;
}
