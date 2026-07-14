class ZegoLiveConfig {
  const ZegoLiveConfig._();

  static const appId = int.fromEnvironment('ZEGO_APP_ID');
  static const appSign = String.fromEnvironment('ZEGO_APP_SIGN');

  static bool get isConfigured => appId > 0 && appSign.length > 20;
}
