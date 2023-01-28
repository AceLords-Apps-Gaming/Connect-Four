import 'package:connect_four/src/play_session/board_tile.dart';
import 'package:flutter/material.dart';

import '../game_internals/board_settings.dart';

class GameBoard extends StatefulWidget {
  final BoardSetting boardSetting;

  const GameBoard({super.key, required this.boardSetting});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Expanded(
          child: GridView.count(
        crossAxisCount: widget.boardSetting.cols,
        children: [
          for (int i = 0; i < widget.boardSetting.totalTiles(); i++)
            BoardTile(
              boardIndex: i,
              boardSetting: widget.boardSetting,
            )
        ],
      )),
    );
  }
}
