import 'dart:math';

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
  List<Tile> playerTaken = [];
  List<Tile> aiTaken = [];
  List<Tile> winTiles = [];

  BoardState({required this.boardSetting});

  final ChangeNotifier playerWon = ChangeNotifier();

  void clearBoard() {
    playerTaken.clear();
    aiTaken.clear();
    notifyListeners();
  }

  void makeMove(Tile tile) {
    Tile? newTile = evaluateMove(tile);
    if (newTile == null) {
      // TODO: alert cant make move
      return;
    }

    playerTaken.add(newTile);
    bool didPlayerWin = checkWin(newTile);
    if (didPlayerWin) {
      playerWon.notifyListeners();
      notifyListeners();
      return; // prevent ai from playing
    }
    notifyListeners();

    // make AI move
    Tile? aiTile = makeAiMove();
    if (aiTile == null) {
      // TODO: alert no move left
      return;
    }

    aiTaken.add(aiTile);
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

  Tile? evaluateMove(Tile tile) {
    for (var bRow = 1; bRow < boardSetting.rows + 1; bRow++) {
      var evalTile = Tile(col: tile.col, row: bRow);
      if (getTileOwner(evalTile) == TileOwner.blank) {
        return evalTile;
      }
    }

    return null;
  }

  Tile? makeAiMove() {
    List<Tile> available = [];

    for (var row = 1; row < boardSetting.rows + 1; row++) {
      for (var col = 1; col < boardSetting.cols + 1; col++) {
        Tile tile = Tile(col: col, row: row);
        if (getTileOwner(tile) == TileOwner.blank) {
          available.add(tile);
        }
      }
    }

    if (available.isEmpty) return null;

    return evaluateMove(available[Random().nextInt(available.length)]);
  }

  TileOwner getTileOwner(Tile tile) {
    if (playerTaken.contains(tile)) {
      return TileOwner.player;
    } else if (aiTaken.contains(tile)) {
      return TileOwner.ai;
    }

    return TileOwner.blank;
  }

  bool checkWin(Tile playTile) {
    List<Tile> takenTiles =
        (getTileOwner(playTile) == TileOwner.player) ? playerTaken : aiTaken;

    List<Tile>? vertical = verticalCheck(playTile, takenTiles);
    if (vertical != null) {
      winTiles = vertical;
      return true;
    }

    return false;
  }

  List<Tile>? verticalCheck(Tile playTile, List<Tile> takenTiles) {
    List<Tile> tempWinTiles = [];

    for (var row = playTile.row; row > 0; row--) {
      Tile tile = Tile(col: playTile.col, row: row);
      if (takenTiles.contains(tile)) {
        tempWinTiles.add(tile);
      } else {
        break;
      }
    }

    if (tempWinTiles.length >= boardSetting.winCondition()) {
      return tempWinTiles;
    }

    return null;
  }
}
