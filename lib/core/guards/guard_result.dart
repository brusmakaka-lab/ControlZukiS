class GuardResult {
  const GuardResult._(this.allowed, this.reason);

  final bool allowed;
  final String? reason;

  const GuardResult.allow() : this._(true, null);
  const GuardResult.deny(String reason) : this._(false, reason);
}
