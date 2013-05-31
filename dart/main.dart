/*!
 * Open Creeper v1.2.4
 * http://alexanderzeillinger.github.com/OpenCreeper/
 *
 * Copyright 2012, Alexander Zeillinger
 * Dual licensed under the MIT or GPL licenses.
 */

library creeper;

import 'dart:html';
import 'dart:math' as Math;
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

    //engine.sounds["music"].loop = true;
    //engine.sounds["music"].play();

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

/**
 * Main drawing function
 * For some reason this may not be a member function of "game" in order to be called by requestAnimationFrame
 */

void draw(num _) {
  game.drawGUI();

  // clear canvas
  engine.canvas["buffer"].clear();
  engine.canvas["main"].clear();

  // draw terraform numbers
  int timesX = (engine.halfWidth / game.tileSize / game.zoom).floor();
  int timesY = (engine.halfHeight / game.tileSize / game.zoom).floor();

  for (int i = -timesX; i <= timesX; i++) {
    for (int j = -timesY; j <= timesY; j++) {

      int iS = i + game.scroll.x;
      int jS = j + game.scroll.y;

      if (game.withinWorld(iS, jS)) {
        if (game.world.terraform[iS][jS]["target"] > -1) {
          engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images["numbers"], game.world.terraform[iS][jS]["target"] * 16, 0, game.tileSize, game.tileSize, engine.halfWidth + i * game.tileSize * game.zoom, engine.halfHeight + j * game.tileSize * game.zoom, game.tileSize * game.zoom, game.tileSize * game.zoom);
        }
      }
    }
  }

  // draw emitters
  for (int i = 0; i < game.emitters.length; i++) {
    game.emitters[i].draw();
  }

  // draw spore towers
  for (int i = 0; i < game.sporetowers.length; i++) {
    game.sporetowers[i].draw();
  }

  // draw node connections
  for (int i = 0; i < game.buildings.length; i++) {
    Vector centerI = game.buildings[i].getCenter();
    Vector drawCenterI = Helper.real2screen(centerI);
    for (int j = 0; j < game.buildings.length; j++) {
      if (i != j) {
        if (!game.buildings[i].moving && !game.buildings[j].moving) {
          Vector centerJ = game.buildings[j].getCenter();
          Vector drawCenterJ = Helper.real2screen(centerJ);

          num allowedDistance = 10 * game.tileSize;
          if (game.buildings[i].imageID == "relay" && game.buildings[j].imageID == "relay") {
            allowedDistance = 20 * game.tileSize;
          }

          if (Math.pow(centerJ.x - centerI.x, 2) + Math.pow(centerJ.y - centerI.y, 2) <= Math.pow(allowedDistance, 2)) {
            engine.canvas["buffer"].context.strokeStyle = '#000';
            engine.canvas["buffer"].context.lineWidth = 3;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenterI.x, drawCenterI.y);
            engine.canvas["buffer"].context.lineTo(drawCenterJ.x, drawCenterJ.y);
            engine.canvas["buffer"].context.stroke();

            engine.canvas["buffer"].context.strokeStyle = '#fff';
            if (!game.buildings[i].built || !game.buildings[j].built)engine.canvas["buffer"].context.strokeStyle = '#777';
            engine.canvas["buffer"].context.lineWidth = 2;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenterI.x, drawCenterI.y);
            engine.canvas["buffer"].context.lineTo(drawCenterJ.x, drawCenterJ.y);
            engine.canvas["buffer"].context.stroke();
          }
        }
      }
    }
  }

  // draw movement indicators
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].drawMovementIndicators();
  }

  // draw buildings
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].draw();
  }

  // draw shells
  for (int i = 0; i < game.shells.length; i++) {
    game.shells[i].draw();
  }

  // draw smokes
  for (int i = 0; i < game.smokes.length; i++) {
    game.smokes[i].draw();
  }

  // draw explosions
  for (int i = 0; i < game.explosions.length; i++) {
    game.explosions[i].draw();
  }

  // draw spores
  for (int i = 0; i < game.spores.length; i++) {
    game.spores[i].draw();
  }

  if (engine.mouse.active) {

    // if a building is built and selected draw a green box and a line at mouse position as the reposition target
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].drawRepositionInfo();
    }

    // draw attack symbol
    game.drawAttackSymbol();

    if (game.activeSymbol != -1) {
      game.drawPositionInfo();
    }

    if (game.mode == "TERRAFORM") {
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images["numbers"], game.terraformingHeight * game.tileSize, 0, game.tileSize, game.tileSize, drawPosition.x, drawPosition.y, game.tileSize * game.zoom, game.tileSize * game.zoom);

      engine.canvas["buffer"].context.strokeStyle = '#fff';
      engine.canvas["buffer"].context.lineWidth = 1;

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(0, drawPosition.y);
      engine.canvas["buffer"].context.lineTo(engine.width, drawPosition.y);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(0, drawPosition.y + game.tileSize * game.zoom);
      engine.canvas["buffer"].context.lineTo(engine.width, drawPosition.y + game.tileSize * game.zoom);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(drawPosition.x, 0);
      engine.canvas["buffer"].context.lineTo(drawPosition.x, engine.halfHeight * 2);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(drawPosition.x + game.tileSize * game.zoom, 0);
      engine.canvas["buffer"].context.lineTo(drawPosition.x + game.tileSize * game.zoom, engine.halfHeight * 2);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.stroke();

    }
  }

  // draw packets
  for (int i = 0; i < game.packets.length; i++) {
    game.packets[i].draw();
  }

  // draw ships
  for (int i = 0; i < game.ships.length; i++) {
    game.ships[i].draw();
  }

  // draw building hover/selection box
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].drawBox();
  }

  engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element, 0, 0);

  window.requestAnimationFrame(draw);
}