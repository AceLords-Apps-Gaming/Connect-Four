// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/board_settings.dart';
import '../game_internals/board_state.dart';
import '../game_internals/level_state.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';
import 'game_board.dart';

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  final BoardSetting boardSetting = BoardSetting(rows: 5, cols: 7);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LevelState(
            goal: widget.level.difficulty,
            onWin: _playerWon,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BoardState(boardSetting: boardSetting),
        ),
      ],
      child: IgnorePointer(
        ignoring: _duringCelebration,
        child: Scaffold(
          backgroundColor: palette.backgroundPlaySession,
          body: SafeArea(
            child: Stack(
              children: [
                Builder(builder: (context) {
                  return Center(
                    // This is the entirety of the "game".
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkResponse(
                              onTap: () => GoRouter.of(context).push('/'),
                              child: Image.asset(
                                'assets/images/back.png',
                                semanticLabel: 'Back',
                              ),
                            ),
                            InkResponse(
                              onTap: () =>
                                  GoRouter.of(context).push('/settings'),
                              child: Image.asset(
                                'assets/images/settings.png',
                                semanticLabel: 'Settings',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GameBoard(boardSetting: boardSetting),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<BoardState>().clearBoard(),
                          icon: Icon(
                            Icons.settings_backup_restore_rounded,
                            size: 24,
                          ),
                          label: Text('Reset'),
                        ),
                        const Spacer(),
                        Consumer<BoardState>(
                          builder: (context, value, child) => Column(children: [
                            Text('Player: ${value.playerTaken}'),
                            Text('AI: ${value.aiTaken}'),
                          ]),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                }),
                SizedBox.expand(
                  child: Visibility(
                    visible: _duringCelebration,
                    child: IgnorePointer(
                      child: Confetti(
                        isStopped: !_duringCelebration,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _startOfPlay = DateTime.now();

    // Preload ad for the win screen.
    final adsRemoved =
        context.read<InAppPurchaseController?>()?.adRemoval.active ?? false;
    if (!adsRemoved) {
      final adsController = context.read<AdsController?>();
      adsController?.preloadAd();
    }
  }

  Future<void> _playerWon() async {
    _log.info('Level ${widget.level.number} won');

    final score = Score(
      widget.level.number,
      widget.level.difficulty,
      DateTime.now().difference(_startOfPlay),
    );

    final playerProgress = context.read<PlayerProgress>();
    playerProgress.setLevelReached(widget.level.number);

    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    final gamesServicesController = context.read<GamesServicesController?>();
    if (gamesServicesController != null) {
      // Award achievement.
      if (widget.level.awardsAchievement) {
        await gamesServicesController.awardAchievement(
          android: widget.level.achievementIdAndroid!,
          iOS: widget.level.achievementIdIOS!,
        );
      }

      // Send score to leaderboard.
      await gamesServicesController.submitLeaderboardScore(score);
    }

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }
}