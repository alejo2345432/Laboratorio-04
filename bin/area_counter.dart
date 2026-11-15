class AreaCounter {
  double _totalArea = 0.0;

  double get totalArea => _totalArea;

  bool addArea(double area) {
    if (!area.isFinite || area <= 0) {
      return false;
    }

    double nextTotal = _totalArea + area;
    if (!nextTotal.isFinite) {
      return false;
    }

    _totalArea = nextTotal;
    return true;
  }

  void reset() {
    _totalArea = 0.0;
  }
}