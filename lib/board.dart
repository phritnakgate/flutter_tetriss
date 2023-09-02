import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/piece.dart';
import 'package:flutter_tetris/pixel.dart';
import 'package:flutter_tetris/values.dart';

List<List<Tetromino?>> gameBoard =
    List.generate(columnLength, (i) => List.generate(rowLength, (j) => null));

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Piece currentPiece = Piece(type: Tetromino.L);
  int score = 0;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    Duration frameRate = const Duration(milliseconds: 500);
    gameLoop(frameRate);
  }

  void gameLoop(Duration framerate) {
    Timer.periodic(framerate, (timer) {
      setState(() {
        clearLines();
        checkLanding();
        if (gameOver) {
          timer.cancel();
          showGameOverDialog();
        }
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  void showGameOverDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Game Over'),
              content: Text('Score: $score'),
              actions: [
                TextButton(
                  onPressed: () {
                    resetGame();
                    Navigator.pop(context);
                  },
                  child: const Text('Play Again'),
                )
              ],
            ));
  }

  void resetGame() {
    gameBoard = List.generate(
        columnLength, (i) => List.generate(rowLength, (j) => null));
    score = 0;
    gameOver = false;
    createNewPiece();
    startGame();
  }

  bool checkCollision(Direction direction) {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // Adjust row and col based on direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      //Check if out of bounds
      if (row >= columnLength || col >= rowLength || col < 0) {
        return true;
      }
    }
    return false;
  }

  void checkLanding() {
    if (checkCollision(Direction.down) || checkLanded()) {
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }
      createNewPiece();
    }
  }

  bool checkLanded() {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;
      if (row + 1 < columnLength &&
          row >= 0 &&
          gameBoard[row + 1][col] != null) {
        return true;
      }
    }
    return false;
  }

  void createNewPiece() {
    Random random = Random();

    Tetromino randomType =
        Tetromino.values[random.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if (isgameOver()) {
      gameOver = true;
    }
  }

  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void rotate() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  void clearLines() {
    for (int row = columnLength - 1; row >= 0; row--) {
      bool rowIsFull = true;
      for (int col = 0; col < rowLength; col++) {
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      if (rowIsFull) {
        for (int r = row; r > 0; r--) {
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }
        gameBoard[0] = List.generate(rowLength, (i) => null);
        score++;
      }
    }
  }

  bool isgameOver() {
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            //BOARD
            Expanded(
              child: GridView.builder(
                  itemCount: rowLength * columnLength,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowLength,
                  ),
                  itemBuilder: (context, index) {
                    int row = (index / rowLength).floor();
                    int col = index % rowLength;

                    if (currentPiece.position.contains(index)) {
                      return Pixel(
                        color: currentPiece.color,
                      );
                    } else if (gameBoard[row][col] != null) {
                      final Tetromino? tetrominoType = gameBoard[row][col];
                      return Pixel(
                        color: tetrominoColors[tetrominoType],
                      );
                    } else {
                      return Pixel(
                        color: Colors.grey[900],
                      );
                    }
                  }),
            ),
            //SCORE
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Text(
                'Score: $score',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            //CONTROLS
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: moveLeft,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_ios_new)),
                  IconButton(
                      onPressed: rotate,
                      color: Colors.white,
                      icon: const Icon(Icons.rotate_right)),
                  IconButton(
                      onPressed: moveRight,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_forward_ios))
                ],
              ),
            )
          ],
        ));
  }
}
