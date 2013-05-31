/*!
 * Open Creeper v1.2.4
 * http://alexanderzeillinger.github.com/OpenCreeper/
 *
 * Copyright 2012, Alexander Zeillinger
 * Dual licensed under the MIT or GPL licenses.
 */

library creeper;

import 'dart:html';
import 'dart:math';
import 'dart:async';

part 'classes.dart';
part 'game.dart';
part 'engine.dart';
part 'heightmap.dart';
part 'helper.dart';
part 'uisymbol.dart';
part 'building.dart';
part 'packet.dart';
part 'shell.dart';
part 'spore.dart';
part 'ship.dart';
part 'events.dart';

Engine engine;
Game game;

void main() {
  engine = new Engine();
  engine.init();
  engine.loadImages(() {
    game = new Game();
    game.init();
    game.drawTerrain();
    game.copyTerrain();
    game.stop();
    game.run();
  });
}

void updates() {
  //engine.update();
  game.update();
}

void updateTime(Timer _) {
  var s = game.stopwatch.elapsedMilliseconds~/1000;
  var m = 0;
  
  if (s >= 60) { m = s ~/ 60; s = s % 60; }
    
  String minute = (m <= 9) ? '0$m' : '$m';
  String second = (s <= 9) ? '0$s' : '$s';
  query('#time').innerHtml = 'Time: $minute:$second';
}