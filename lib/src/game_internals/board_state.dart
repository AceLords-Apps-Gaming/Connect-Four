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

  String noticeMessage = '';
  bool _isLocked = false;

  BoardState({required this.boardSetting});

  final ChangeNotifier playerWon = ChangeNotifier();

  void clearBoard() {
    playerTaken.clear();
    aiTaken.clear();
    winTiles.clear();
    noticeMessage = '';
    _isLocked = false;
    notifyListeners();
  }

  Future<void> makeMove(Tile tile) async {
    assert(
        !_isLocked); // automatically fails if is locked, and no further computation occurs
    Tile? newTile = evaluateMove(tile);
    if (newTile == null) {
      noticeMessage = "Move not possible! Try again.";
      notifyListeners();
      return;
    }

    playerTaken.add(newTile);
    _isLocked = true;

    bool didPlayerWin = checkWin(newTile);
    if (didPlayerWin) {
      playerWon.notifyListeners();
      notifyListeners();
      return; // prevent ai from playing
    }
    notifyListeners();

    // add delay in AI turns
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // make AI move
    Tile? aiTile = makeAiMove();
    if (aiTile == null) {
      noticeMessage = "No moves left! Reset to play again.";
      notifyListeners();
      return;
    }

    aiTaken.add(aiTile);
    bool didAiWin = checkWin(aiTile);
    if (didAiWin) {
      noticeMessage = "You lost! Reset to play again.";
    }

    _isLocked = false;
    notifyListeners();
  }

  Color tilecolor(Tile tile) {
    if (winTiles.contains(tile)) {
      return Colors.green;
    }
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

    List<Tile>? horizontal = horizontalCheck(playTile, takenTiles);
    if (horizontal != null) {
      winTiles = horizontal;
      return true;
    }

    List<Tile>? forwardDiagonal = forwardDiagonalCheck(playTile, takenTiles);
    if (forwardDiagonal != null) {
      winTiles = forwardDiagonal;
      return true;
    }

    List<Tile>? backwardDiagonal = backwardDiagonalCheck(playTile, takenTiles);
    if (backwardDiagonal != null) {
      winTiles = backwardDiagonal;
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

  List<Tile>? horizontalCheck(Tile playTile, List<Tile> takenTiles) {
    // add the player to the list
    List<Tile> tempWinTiles = [playTile];

    // look left, unless playTile is the first tile
    // Start at playTile.col - 1
    if (playTile.col > 1) {
      for (var col = playTile.col - 1; col > 0; col--) {
        Tile tile = Tile(col: col, row: playTile.row);
        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    // look right, unless playTile is the last tile
    // Start at playTile.col -+ 1
    if (playTile.col < boardSetting.cols) {
      for (var col = playTile.col + 1; col < boardSetting.cols + 1; col++) {
        Tile tile = Tile(col: col, row: playTile.row);
        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    if (tempWinTiles.length >= boardSetting.winCondition()) {
      return tempWinTiles;
    }

    return null;
  }

  List<Tile>? forwardDiagonalCheck(Tile playTile, List<Tile> takenTiles) {
    // add the play tile to the list
    List<Tile> tempWinTiles = [playTile];

    // look left & down, unless playTile us the first tile or in row 1
    // start at playTile - 1
    if (playTile.col > 1 && playTile.row > 1) {
      // iterate to check with lower rows
      for (var i = 1; i < playTile.row + 1; i++) {
        Tile tile = Tile(col: playTile.col - i, row: playTile.row - i);

        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    // look right and up, unless playTile is the last tile or in top row
    // start at playtile.col - 1
    if (playTile.col < boardSetting.cols && playTile.row < boardSetting.rows) {
      // iterate to check all upper rows. loop until hitting the top
      // so from (top - playTile.row) times
      for (var i = 1; i < (boardSetting.rows + 1) - playTile.row; i++) {
        Tile tile = Tile(col: playTile.col + i, row: playTile.row + i);

        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    if (tempWinTiles.length >= boardSetting.winCondition()) {
      return tempWinTiles;
    }

    return null;
  }

  List<Tile>? backwardDiagonalCheck(Tile playTile, List<Tile> takenTiles) {
    // add the play tile to the list
    List<Tile> tempWinTiles = [playTile];

    // look left & down, unless playTile us the first tile or in row 1
    // start at playTile - 1
    if (playTile.col > 1 && playTile.row < boardSetting.rows) {
      // iterate to check all upper rows
      for (var i = 1; i < (boardSetting.rows + 1) - playTile.row; i++) {
        Tile tile = Tile(col: playTile.col - i, row: playTile.row + i);

        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    // look right and up, unless playTile is the last tile or in top row
    // start at playtile.col - 1
    if (playTile.col < boardSetting.cols && playTile.row > 1) {
      // iterate to check all upper rows. loop until hitting the top
      // so from (top - playTile.row) times
      for (var i = 1; i < playTile.row + 1; i++) {
        Tile tile = Tile(col: playTile.col + i, row: playTile.row - i);

        if (takenTiles.contains(tile)) {
          tempWinTiles.add(tile);
        } else {
          break;
        }
      }
    }

    if (tempWinTiles.length >= boardSetting.winCondition()) {
      return tempWinTiles;
    }

    return null;
  }
}
