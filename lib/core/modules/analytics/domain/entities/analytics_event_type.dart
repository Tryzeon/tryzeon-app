enum AnalyticsEventType {
  purchaseClick('purchase_click'),
  view('view');

  const AnalyticsEventType(this.value);
  final String value;
}
