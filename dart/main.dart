/*!
 * Open Creeper v1.2.9
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
  engine.loadImages(() {
    game = new Game();
    game.run();
  });
}