class FluxRequestInfo {
  late DateTime hitAt;
  late DateTime leftAt;

  Duration get timeTaken {
    return leftAt.difference(hitAt);
  }
}
