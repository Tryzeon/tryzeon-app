class AdLocalDataSource {
  Future<List<String>> getAdImages({final bool forceRefresh = false}) async {
    // In a real app, logic for forceRefresh would be here (e.g., clearing local cache)
    return [
      'assets/images/ads/brand1.jpg',
      'assets/images/ads/brand2.jpg',
      'assets/images/ads/brand3.jpg',
      'assets/images/ads/brand4.jpg',
      'assets/images/ads/brand5.jpg',
    ];
  }
}
