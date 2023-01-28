import 'package:flutter/material.dart';

import '../style/palette.dart';
import 'board_settings.dart';
import 'tile.dart';

enum TileOwner {
  blank,
  player,
  ai,
}

class BoardState extends ChangeNotifier {
  final BoardSetting boardSetting;
  final List<Tile> playerTaken = [];
  final List<Tile> aiTaken = [];

  BoardState({required this.boardSetting});

  void makeMove(Tile tile) {
    playerTaken.add(tile);
    notifyListeners();
  }

  void clearBoard() {
    playerTaken.clear();
    aiTaken.clear();
    notifyListeners();
  }

  Color tilecolor(Tile tile) {
    if (getTileOwner(tile) == TileOwner.player) {
      return Colors.amber;
    } else if (getTileOwner(tile) == TileOwner.ai) {
      return Colors.redAccent;
    }

    return Palette().backgroundPlaySession;
  }

  TileOwner getTileOwner(Tile tile) {
    if (playerTaken.contains(tile)) {
      return TileOwner.player;
    } else if (aiTaken.contains(tile)) {
      return TileOwner.ai;
    }

    return TileOwner.blank;
  }
}
