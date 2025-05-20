class AdsService {
  Future<void> showRewardedAd(Function onReward) async {
    // Simulate watching a rewarded ad (replace with real ad logic later)
    await Future.delayed(Duration(seconds: 1)); // Simulate 1 sec "ad"
    onReward(); // Grant the reward
  }
}
