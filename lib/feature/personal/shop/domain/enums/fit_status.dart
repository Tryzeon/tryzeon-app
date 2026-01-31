enum FitStatus {
  perfect,
  good,
  poor;

  bool get isPoor => this == FitStatus.poor;
}
