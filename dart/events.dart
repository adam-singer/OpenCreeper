part of creeper;

void onMouseMove(MouseEvent evt) {
  engine.updateMouse(evt);
  
  if (game != null) {
    game.scrollingLeft = (engine.mouse.x == 0);
    game.scrollingRight = (engine.mouse.x == engine.width -1);  
    game.scrollingUp = (engine.mouse.y == 0);
    game.scrollingDown = (engine.mouse.y == engine.height -1);
  }
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
  
  // increase game speed
  if (evt.keyCode == KeyCode.F1) {
    game.faster();
  }
  
  // decrease game speed
  if (evt.keyCode == KeyCode.F2) {
    game.slower();
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
    for (int i = 0; i < game.ships.length; i++) {
      game.ships[i].selected = false;
    }
    engine.canvas["main"].element.style.cursor = "url('images/Normal.cur') 2 2, pointer";
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
      tilesToRedraw.add(new Vector3(position.x, position.y, height));
      tilesToRedraw.add(new Vector3(position.x - 1, position.y, height));
      tilesToRedraw.add(new Vector3(position.x, position.y - 1, height));
      tilesToRedraw.add(new Vector3(position.x + 1, position.y, height));
      tilesToRedraw.add(new Vector3(position.x, position.y + 1, height));
      game.redrawTile(tilesToRedraw);
    }
  }

  // raise terrain
  if (evt.keyCode == KeyCode.M) {
    int height = game.getHighestTerrain(position);
    if (height < 9) {
      game.world.tiles[position.x][position.y][height + 1].full = true;
      List tilesToRedraw = new List();
      // reset index around tile
      tilesToRedraw.add(new Vector3(position.x, position.y, height + 1));
      tilesToRedraw.add(new Vector3(position.x - 1, position.y, height + 1));
      tilesToRedraw.add(new Vector3(position.x, position.y - 1, height + 1));
      tilesToRedraw.add(new Vector3(position.x + 1, position.y, height + 1));
      tilesToRedraw.add(new Vector3(position.x, position.y + 1, height + 1));
      game.redrawTile(tilesToRedraw);
    }
  }

  // clear terrain
  if (evt.keyCode == KeyCode.B) {
    List tilesToRedraw = new List();
    for (int k = 0; k < 10; k++) {
      game.world.tiles[position.x][position.y][k].full = false;
    }
    // reset index around tile
    tilesToRedraw.add(new Vector3(position.x, position.y, 0));
    tilesToRedraw.add(new Vector3(position.x - 1, position.y, 0));
    tilesToRedraw.add(new Vector3(position.x, position.y - 1, 0));
    tilesToRedraw.add(new Vector3(position.x + 1, position.y, 0));
    tilesToRedraw.add(new Vector3(position.x, position.y + 1, 0));
    game.redrawTile(tilesToRedraw);
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
          engine.canvas["main"].element.style.cursor = "url('images/Normal.cur') 2 2, pointer";
          game.buildings[i].operating = false;
          game.buildings[i].weaponTargetPosition = null;
          game.buildings[i].status = "RISING";
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

void onResize(evt) {
  // delay the resizing to avoid it being called multiple times
  if (engine.resizeTimer != null)
    engine.resizeTimer.cancel();
  engine.resizeTimer = new Timer(new Duration(milliseconds: 250), doneResizing);
}

void doneResizing() {
  var width = window.innerWidth;
  var height = window.innerHeight;
  engine.width = width;
  engine.height = height;
  engine.halfWidth = (width / 2).floor();
  engine.halfHeight = (height / 2).floor();

  engine.canvas["main"].updateRect(width, height);
  engine.canvas["levelfinal"].updateRect(width, height);
  engine.canvas["buffer"].updateRect(width, height);
  engine.canvas["collection"].updateRect(width, height);
  engine.canvas["creeper"].updateRect(width, height);

  engine.canvas["gui"].top = engine.canvas["gui"].element.offsetTop;
  engine.canvas["gui"].left = engine.canvas["gui"].element.offsetLeft;

  if (game != null) {
    game.copyTerrain();
    game.drawCollection();
    game.drawCreeper();
  }
}