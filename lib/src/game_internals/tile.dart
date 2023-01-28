import 'package:connect_four/src/game_internals/board_settings.dart';

class Tile {
  final int row; // x
  final int col; // y

  Tile({
    required this.row,
    required this.col,
  });

  factory Tile.fromBoardIndex(
    int boardIndex,
    BoardSetting setting,
  ) {
    final col = (boardIndex % setting.cols).ceil() + 1;
    final row = setting.rows - ((boardIndex + 1) / setting.cols).ceil() + 1;
    return Tile(row: row, col: col);
  }

  @override
  int get hasCode => Object.hash(col, row);

  @override
  bool operator ==(Object other) {
    return other is Tile && other.col == col && other.row == row;
  }

  @override
  String toString() => "[$col,$row]";
}
