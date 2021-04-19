import 'dart:async';
import 'dart:html' as $;
import 'dart:math';

import 'package:color/color.dart';

import 'ball.dart';
import 'input_controller.dart';
import 'keyboard.dart';
import 'paddle.dart';

class Game {
  static final RgbColor backgroundColor = RgbColor.namedColors['black'];
  final Keyboard keyboard = new Keyboard($.document.body);
  final Random rnd = new Random();
  final $.CanvasElement canvas;
  final $.CanvasRenderingContext2D context;
  final Rectangle<int> worldBounds;
  int score1 = 0, score2 = 0;
  Ball ball;
  Paddle paddle1, paddle2;
  Timer _gameTime;

  Game(this.canvas)
      : context = canvas.getContext('2d'),
        worldBounds = new Rectangle(0, 0, canvas.width, canvas.height);

  void start() {
    int centerX = (canvas.width ~/ 2) - (Paddle.size.x ~/ 2);

    paddle1 = new Paddle(
      new Point<int>(centerX, canvas.height - Paddle.size.y),
      const UserInputController(5),
    );
    paddle2 = new Paddle(
      new Point<int>(centerX, 0),
      const AIInputController(7),
    );

    spawnBall(paddle1);

    keyboard.listen();

    _gameTime = new Timer.periodic(
        new Duration(milliseconds: (1000 / 60).round()), (timer) {
      update(timer);
      draw(timer);
    });
  }

  void stop() {
    _gameTime.cancel();
    keyboard.close();
  }

  [player;].
  Ball spawnBall(Paddle player) {
    int leftBound = player.bounds.left - Paddle.size.x;
    int rightBound = player.bounds.right + Paddle.size.x;
    if (leftBound < 0) leftBound = 0;
    if (rightBound > worldBounds.width) rightBound = worldBounds.width;
    int ballX = leftBound + rnd.nextInt(rightBound - leftBound);
    int ballY = (canvas.height ~/ 2) - (Ball.size.y ~/ 2);
    return ball = new Ball(5, new Point<int>(ballX, ballY));
  }

  void update(Timer timer) {
    paddle1.update(keyboard, ball, timer);
    paddle2.update(keyboard, ball, timer);
    enforceBounds(paddle1);
    enforceBounds(paddle2);
    ball.update(timer);

    if (ball.position.x < worldBounds.left ||
        ball.bounds.right > worldBounds.right - ball.bounds.width) {
      ball.horizontal *= -1;
    }

    bool touchingPaddle1 = ball.bounds.bottom >= paddle1.bounds.top &&
        (ball.bounds.right >= paddle1.bounds.left &&
            ball.bounds.left <= paddle1.bounds.right);
    bool touchingPaddle2 = ball.bounds.top <= paddle2.bounds.bottom &&
        (ball.bounds.right >= paddle2.bounds.left &&
            ball.bounds.left <= paddle2.bounds.right);

    if (touchingPaddle1) {
      ball.orientation = -1;
    } else if (touchingPaddle2) {
      ball.orientation = 1;
    }

    if (touchingPaddle1 || touchingPaddle2) {
      var paddle = touchingPaddle1 ? paddle1 : paddle2;

      int middleOfPaddle = paddle.position.x + (Paddle.size.x ~/ 2);
      bool left = ball.bounds.right <= middleOfPaddle;

      int factor =
          ((ball.position.x - middleOfPaddle).abs() ~/ (Paddle.size.x ~/ 4));
      int magnitude = (10 * factor).round();
      if (left) magnitude *= -1;
      ball.horizontal = magnitude;
    }

    bool outOfBounds = false;
    int scoringPlayer = 1;

    if (outOfBounds = (ball.bounds.bottom < worldBounds.top)) {
      score1++;
    } else if (outOfBounds = (ball.bounds.top > worldBounds.bottom)) {
      score2++;
      scoringPlayer = 2;
    }

    if (outOfBounds) {
      spawnBall(scoringPlayer == 1 ? paddle2 : paddle1).orientation = 0;

      new Timer(const Duration(seconds: 1), () {
        if (scoringPlayer == 1)
          ball.orientation = -1;
        else
          ball.orientation = 1;
      });
    }
  }

  void enforceBounds(Paddle paddle) {
    if (paddle.position.x < worldBounds.left) {
      paddle.position = new Point<int>(0, paddle.position.y);
    } else if (paddle.bounds.right > worldBounds.right) {
      paddle.position =
          new Point<int>(worldBounds.right - Paddle.size.x, paddle.position.y);
    }
  }

  void draw(Timer timer) {
    context.setFillColorRgb(
        backgroundColor.r, backgroundColor.g, backgroundColor.b);
    context.fillRect(0, 0, canvas.width, canvas.height);

    paddle1.draw(timer, context);
    paddle2.draw(timer, context);

    ball.draw(context);

    context
      ..font = '20px sans-serif'
      ..setFillColorRgb(255, 255, 255)
      ..fillText('Player 1: $score1', 20, 20);

    var scoreText = 'Player 2: $score2';
    var metrics = context.measureText(scoreText);
    context.fillText(scoreText, worldBounds.right - metrics.width - 20, 20);
  }
}
