enum TryonDislikeReason {
  identityMismatch('identity_mismatch'),
  garmentUnfaithful('garment_unfaithful'),
  garmentDeformed('garment_deformed'),
  handsPose('hands_pose'),
  bodyShape('body_shape');

  const TryonDislikeReason(this.value);
  final String value;
}
