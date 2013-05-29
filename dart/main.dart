/*!
 * Open Creeper v1.2.3
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

void onResize(evt) {
  // FIXME
  /*clearTimeout(this.id);
  this.id = setTimeout(doneResizing, 100);*/
  doneResizing();
}

void doneResizing() {
  var width = window.innerWidth;
  var height = window.innerHeight;
  engine.width = width;
  engine.height = height;
  engine.halfWidth = (width / 2).floor();
  engine.halfHeight = (height / 2).floor();

  engine.canvas["main"].element[0].height = height;
  engine.canvas["main"].element[0].width = width;
  engine.canvas["buffer"].element[0].height = height;
  engine.canvas["buffer"].element[0].width = width;
  engine.canvas["collection"].element[0].height = height;
  engine.canvas["collection"].element[0].width = width;
  engine.canvas["creeper"].element[0].height = height;
  engine.canvas["creeper"].element[0].width = width;

  engine.canvas["gui"].top = engine.canvas["gui"].element.offset().top;
  engine.canvas["gui"].left = engine.canvas["gui"].element.offset().left;

  game.copyTerrain();
  game.drawCollection();
  game.drawCreeper();
}

void updateTime(Timer _) {
  var s = game.stopwatch.elapsedMilliseconds~/1000;
  var m = 0;
  
  if (s >= 60) { m = s ~/ 60; s = s % 60; }
    
  String minute = (m <= 9) ? '0$m' : '$m';
  String second = (s <= 9) ? '0$s' : '$s';
  query('#time').innerHtml = 'Time: $minute:$second';
}

void onMouseMove(MouseEvent evt) {
  engine.updateMouse(evt);
}

void onMouseMoveGUI(MouseEvent evt) {
  engine.updateMouseGUI(evt);

  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].checkHovered();
  }
}

void onKeyDown(KeyboardEvent evt) {
  // select instruction with keypress
  String key = game.keyMap["k${evt.keyCode}"];
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].active = false;
    if (game.symbols[i].key == key) {
      game.activeSymbol = i;
      game.symbols[i].active = true;
    }
  }

  if (game.activeSymbol != -1) {
    engine.canvas["main"].element.style.cursor = "none";
  }

  // delete building
  if (evt.keyCode == KeyCode.DELETE) {
    for (int i = 0; i < game.buildings.length; i++) {
      if (game.buildings[i].selected) {
        if (game.buildings[i].imageID != "base")
          game.removeBuilding(game.buildings[i]);
      }
    }
  }

  // pause/resume
  if (evt.keyCode == KeyCode.PAUSE) {
    if (game.paused)game.resume(); else
      game.pause();
  }

  // deselect all
  if (evt.keyCode == KeyCode.ESC) {
    game.activeSymbol = -1;
    for (int i = 0; i < game.symbols.length; i++) {
      game.symbols[i].active = false;
    }
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].selected = false;
    }
    engine.canvas["main"].element.style.cursor = "default";
  }

  if (evt.keyCode == KeyCode.LEFT)
    game.scrollingLeft = true;
  if (evt.keyCode == KeyCode.UP)
    game.scrollingUp = true;
  if (evt.keyCode == KeyCode.RIGHT)
    game.scrollingRight = true;
  if (evt.keyCode == KeyCode.DOWN)
    game.scrollingDown = true;

  Vector position = game.getHoveredTilePosition();

  // lower terrain
  if (evt.keyCode == KeyCode.N) {
    int height = game.getHighestTerrain(position);
    if (height > -1) {
      game.world.tiles[position.x][position.y][height].full = false;
      List tilesToRedraw = new List();
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, height));
        }
      }
      game.redrawTile(tilesToRedraw);
      game.copyTerrain();
    }
  }

  // raise terrain
  if (evt.keyCode == KeyCode.M) {
    int height = game.getHighestTerrain(position);
    if (height < 9) {
      game.world.tiles[position.x][position.y][height + 1].full = true;
      List tilesToRedraw = new List();
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, height + 1));
        }
      }
      game.redrawTile(tilesToRedraw);
      game.copyTerrain();
    }
  }

  // clear terrain
  if (evt.keyCode == KeyCode.B) {
    List tilesToRedraw = new List();
    for (int k = 0; k < 10; k++) {
      game.world.tiles[position.x][position.y][k].full = false;
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, k));
        }
      }
    }
    game.redrawTile(tilesToRedraw);
    game.copyTerrain();
  }

  // select height for terraforming
  if (game.mode == "TERRAFORM") {

    // remove terraform number
    if (evt.keyCode == KeyCode.DELETE) {
      game.world.terraform[position.x][position.y]["target"] = -1;
      game.world.terraform[position.x][position.y]["progress"] = 0;
    }

    // set terraform value
    if (evt.keyCode >= 48 && evt.keyCode <= 57) {
      game.terraformingHeight = evt.keyCode - 49;
      if (game.terraformingHeight == -1)game.terraformingHeight = 9;
    }

  }

}

void onKeyUp(KeyboardEvent evt) {
  if (evt.keyCode == KeyCode.LEFT)
    game.scrollingLeft = false;
  if (evt.keyCode == KeyCode.UP)
    game.scrollingUp = false;
  if (evt.keyCode == KeyCode.RIGHT)
    game.scrollingRight = false;
  if (evt.keyCode == KeyCode.DOWN)
    game.scrollingDown = false;
}

void onEnter(evt) {
  engine.mouse.active = true;
}

void onLeave(evt) {
  engine.mouse.active = false;
}

void onLeaveGUI(evt) {
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].hovered = false;
  }
}

void onClickGUI(MouseEvent evt) {
  for (int i = 0; i < game.buildings.length; i++)
    game.buildings[i].selected = false;

  for (int i = 0; i < game.ships.length; i++)
    game.ships[i].selected = false;

  engine.playSound("click");
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].setActive();
  }

  if (game.activeSymbol != -1) {
    engine.canvas["main"].element.style.cursor = "none";
  }
}

void onDoubleClick(MouseEvent evt) {
  bool selectShips = false;
  // select a ship if hovered
  for (int i = 0; i < game.ships.length; i++) {
    if (game.ships[i].hovered) {
      selectShips = true;
      break;
    }
  }
  if (selectShips)for (int i = 0; i < game.ships.length; i++) {
    game.ships[i].selected = true;
  }
}

void onMouseDown(MouseEvent evt) {
  if (evt.which == 1) {
    // left mouse button
    Vector position = game.getHoveredTilePosition();

    if (engine.mouse.dragStart == null) {
      engine.mouse.dragStart = new Vector(position.x, position.y);
    }
  }
}

void onMouseUp(MouseEvent evt) {
  if (evt.which == 1) {

    Vector position = game.getHoveredTilePosition();

    // set terraforming target
    if (game.mode == "TERRAFORM") {
      game.world.terraform[position.x][position.y]["target"] = game.terraformingHeight;
      game.world.terraform[position.x][position.y]["progress"] = 0;
    }

    // control ships
    for (int i = 0; i < game.ships.length; i++) {
      game.ships[i].control(position);
    }

    // reposition building
    for (int i = 0; i < game.buildings.length; i++) {
      if (game.buildings[i].built && game.buildings[i].selected && game.buildings[i].canMove) {
        // check if it can be placed
        if (game.canBePlaced(position, game.buildings[i].size, game.buildings[i])) {
          game.buildings[i].moving = true;
          game.buildings[i].moveTargetPosition = position;
          game.buildings[i].calculateVector();
        }
      }
    }

    // select a building if hovered
    if (game.mode == "DEFAULT") {
      Building buildingSelected = null;
      for (int i = 0; i < game.buildings.length; i++) {
        game.buildings[i].selected = game.buildings[i].hovered;
        if (game.buildings[i].selected) {
          query('#selection')
          ..style.display = "block"
          ..innerHtml = "Type: " + game.buildings[i].imageID + "<br/>" + "Health/HR/MaxHealth: " + game.buildings[i].health.toString() + "/" + game.buildings[i].healthRequests.toString() + "/" + game.buildings[i].maxHealth.toString();
          buildingSelected = game.buildings[i];
        }
      }
      if (buildingSelected != null) {
        if (buildingSelected.active) {
          query('#deactivate').style.display = "block";
          query('#activate').style.display = "none";
        } else {
          query('#deactivate').style.display = "none";
          query('#activate').style.display = "block";
        }
      } else {
        query('#selection').style.display = "none";
        query('#deactivate').style.display = "none";
        query('#activate').style.display = "none";
      }
    }

    engine.mouse.dragStart = null;

    // when there is an active symbol place building
    if (game.activeSymbol != -1) {
      String type = game.symbols[game.activeSymbol].imageID.substring(0, 1).toUpperCase() + game.symbols[game.activeSymbol].imageID.substring(1);
      bool soundSuccess = false;
      for (int i = 0; i < game.ghosts.length; i++) {
        if (game.canBePlaced(game.ghosts[i], game.symbols[game.activeSymbol].size, null)) {
          soundSuccess = true;
          game.addBuilding(game.ghosts[i], game.symbols[game.activeSymbol].imageID);
        }
      }
      if (soundSuccess)engine.playSound("click"); else
        engine.playSound("failure");
    }
  } else if (evt.which == 3) {
    game.mode = "DEFAULT";

    // unselect all currently selected buildings
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].selected = false;
      query('#deactivate').style.display = "none";
      query('#activate').style.display = "none";
    }

    // unselect all currently selected ships
    for (int i = 0; i < game.ships.length; i++) {
      game.ships[i].selected = false;
    }

    query('#selection').innerHtml = "";
    query("#terraform").attributes['value'] = "Terraform Off";
    game.clearSymbols();
  }
}

void onMouseScroll(WheelEvent evt) {
  if (evt.deltaY > 0) {
  //scroll down
    game.zoomOut();
  } else {
  //scroll up
    game.zoomIn();
  }
  //prevent page fom scrolling
  evt.preventDefault();
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
    game.ships[i].draw(engine.canvas["buffer"].context);
  }

  // draw building hover/selection box
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].drawBox();
  }

  engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element, 0, 0);

  window.requestAnimationFrame(draw);
}