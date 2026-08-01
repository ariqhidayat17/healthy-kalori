class BuildConfig {
  static const bool enableCodeShrinking = true;
  static const bool enableTreeShaking = true;
  static const bool enableSplitDebugInfo = true;
  static const bool enableResourceOptimization = true;
  static const bool enableAssetCompression = true;
  static const bool enableLazyLoading = true;
  static const bool enableConstConstructors = true;
  static const bool enableCodeSplitting = true;
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const String flavor = 'production';
  static final bool isOptimizedBuild = true;
}
