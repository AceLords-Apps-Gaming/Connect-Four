class BoardSetting {
  final int rows;
  final int cols;

  BoardSetting({
    required this.rows,
    required this.cols,
  });

  int totalTiles() {
    return rows * cols;
  }
}
