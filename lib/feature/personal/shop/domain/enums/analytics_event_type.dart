enum AnalyticsEventType {
  tryOn('try_on'),
  purchaseClick('purchase_click');

  const AnalyticsEventType(this.value);
  final String value;
}
