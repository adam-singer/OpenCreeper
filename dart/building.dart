part of creeper;

class Building {
  Vector position, moveTargetPosition, weaponTargetPosition, speed = new Vector(0, 0);
  String imageID, status = "IDLE"; // MOVING, RISING, FALLING
  bool operating = false, selected = false, hovered = false, built = false, active = true, canMove = false, needsEnergy = false, rotating = false;
  num health = 0, maxHealth = 0, energy = 0, maxEnergy = 0, energyTimer = 0, healthRequests = 0, energyRequests = 0, requestTimer = 0, weaponRadius = 0, size = 0, collectedEnergy = 0, flightCounter = 0, scale = 1;
  int angle = 0, targetAngle;
  Ship ship;

  Building(this.position, this.imageID);

  bool updateHoverState() {
    Vector realPosition = Helper.tiled2screen(position);
    hovered = (engine.mouse.x > realPosition.x &&
              engine.mouse.x < realPosition.x + game.tileSize * size * game.zoom - 1 &&
              engine.mouse.y > realPosition.y &&
              engine.mouse.y < realPosition.y + game.tileSize * size * game.zoom - 1);

    return hovered;
  }

  void move() {
    if (status == "RISING") {
      if (flightCounter < 25) {
        flightCounter++;
        scale *= 1.01;
      }
      if (flightCounter == 25) {
        status = "MOVING";
      }
    }
    
    else if (status == "FALLING") {
      if (flightCounter > 0) {
        flightCounter--;
        scale /= 1.01;
      }
      if (flightCounter == 0) {
        status = "IDLE";
        position.x = moveTargetPosition.x;
        position.y = moveTargetPosition.y;
        scale = 1;
      }
    }

    if (status == "MOVING") {
      
      position += speed;
      
      if (position.x * game.tileSize > moveTargetPosition.x * game.tileSize - 2 &&
          position.x * game.tileSize < moveTargetPosition.x * game.tileSize + 2 &&
          position.y * game.tileSize > moveTargetPosition.y * game.tileSize - 2 &&
          position.y * game.tileSize < moveTargetPosition.y * game.tileSize + 2) {
        status = "FALLING";
      }
    }
  }

  void calculateVector() {
    if (moveTargetPosition.x != position.x || moveTargetPosition.y != position.y) {
      Vector targetPosition = new Vector(moveTargetPosition.x * game.tileSize, moveTargetPosition.y * game.tileSize);
      Vector ownPosition = new Vector(position.x * game.tileSize, position.y * game.tileSize);
      Vector delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
      num distance = Helper.distance(targetPosition, ownPosition);

      speed.x = (delta.x / distance) * game.buildingSpeed * game.speed / game.tileSize;
      speed.y = (delta.y / distance) * game.buildingSpeed * game.speed / game.tileSize;
    }
  }

  Vector getCenter() {
    return new Vector(position.x * game.tileSize + (game.tileSize / 2) * size, position.y * game.tileSize + (game.tileSize / 2) * size);
  }

  void takeDamage() {
    // buildings can only be damaged while not moving
    if (status == "IDLE") {

      for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
          if (game.world.tiles[position.x + i][position.y + j][0].creep > 0) {
            health -= game.world.tiles[position.x + i][position.y + j][0].creep;
          }
        }
      }

      if (health < 0) {
        game.removeBuilding(this);
      }
    }
  }
  
  void shield() {
    if (built && imageID == "shield" && status == "IDLE") {
      Vector center = getCenter();

      for (int i = position.x - 9; i < position.x + 10; i++) {
        for (int j = position.y - 9; j < position.y + 10; j++) {
          if (game.withinWorld(i, j)) {
            num distance = pow((i * game.tileSize + game.tileSize / 2) - center.x, 2) + pow((j * game.tileSize + game.tileSize / 2) - center.y, 2);
            if (distance < pow(game.tileSize * 10, 2)) {
              if (game.world.tiles[i][j][0].creep > 0) {
                game.world.tiles[i][j][0].creep -= distance / game.tileSize * .1; // the closer to the shield the more creep is removed
                if (game.world.tiles[i][j][0].creep < 0) {
                  game.world.tiles[i][j][0].creep = 0;
                }
              }
            }
          }
        }
      }

    }
  }
  
  void drawBox() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    if (hovered || selected) {
      Vector realPosition = Helper.tiled2screen(position);

      context
        ..lineWidth = 2 * game.zoom
        ..strokeStyle = "#000"
        ..strokeRect(realPosition.x, realPosition.y, game.tileSize * size * game.zoom, game.tileSize * size * game.zoom);
    }
  }

  void drawMovementIndicators() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    if (status != "IDLE") {
      Vector center = Helper.real2screen(getCenter());
      Vector target = Helper.tiled2screen(moveTargetPosition);

      // draw box
      context
        ..strokeStyle = "rgba(0,255,0,0.5)"
        ..strokeRect(target.x, target.y, size * game.tileSize * game.zoom, size * game.tileSize * game.zoom);
      // draw line
      context
        ..strokeStyle = "rgba(255,255,255,0.5)"
        ..beginPath()
        ..moveTo(center.x, center.y)
        ..lineTo(target.x + (game.tileSize / 2) * size * game.zoom, target.y + (game.tileSize / 2) * size * game.zoom)
        ..stroke();
    }
  }

  void drawRepositionInfo() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    if (built && selected && canMove) {
      engine.canvas["main"].element.style.cursor = "none";
      
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * game.tileSize + (game.tileSize / 2) * size, positionScrolled.y * game.tileSize + (game.tileSize / 2) * size);
      Vector drawPositionCenter = Helper.real2screen(positionScrolledCenter);

      Vector center = Helper.real2screen(getCenter());

      game.drawRangeBoxes(positionScrolled, imageID, weaponRadius, size);

      if (game.canBePlaced(positionScrolled, size, this))
        context.strokeStyle = "rgba(0,255,0,0.5)";
      else
        context.strokeStyle = "rgba(255,0,0,0.5)";

      // draw rectangle
      context.strokeRect(drawPosition.x, drawPosition.y, game.tileSize * size * game.zoom, game.tileSize * size * game.zoom);
      // draw line
      context
        ..strokeStyle = "rgba(255,255,255,0.5)"
        ..beginPath()
        ..moveTo(center.x, center.y)
        ..lineTo(drawPositionCenter.x, drawPositionCenter.y)
        ..stroke();
    }
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector realPosition = Helper.tiled2screen(position);
    Vector center = Helper.real2screen(getCenter());

    if (engine.isVisible(realPosition, new Vector(engine.images[imageID].width * game.zoom, engine.images[imageID].height * game.zoom))) {
      if (!built) {
        context.save();
        context.globalAlpha = .5;
        context.drawImageScaled(engine.images[imageID], realPosition.x, realPosition.y, engine.images[imageID].width * game.zoom, engine.images[imageID].height * game.zoom);
        if (imageID == "cannon") {
          context.drawImageScaled(engine.images["cannongun"], realPosition.x, realPosition.y, engine.images[imageID].width * game.zoom, engine.images[imageID].height * game.zoom);
        }
        context.restore();
      } else {
        context.drawImageScaled(engine.images[imageID], realPosition.x + size * 8 - size * 8 * scale, realPosition.y + size * 8 - size * 8 * scale, engine.images[imageID].width * game.zoom * scale, engine.images[imageID].height * game.zoom * scale);
        if (imageID == "cannon") {
          context.save();
          context.translate(realPosition.x + 24 * game.zoom, realPosition.y + 24 * game.zoom);
          context.rotate(Helper.deg2rad(angle));
          context.drawImageScaled(engine.images["cannongun"], -24 * game.zoom * scale, -24 * game.zoom * scale, 48 * game.zoom * scale, 48 * game.zoom * scale);
          context.restore();
        }
      }

      // draw energy bar
      if (needsEnergy) {
        context.fillStyle = '#f00';
        context.fillRect(realPosition.x + 2, realPosition.y + 1, (44 * game.zoom / maxEnergy) * energy, 3);
      }

      // draw health bar (only if health is below maxHealth)
      if (health < maxHealth) {
        context.fillStyle = '#0f0';
        context.fillRect(realPosition.x + 2, realPosition.y + game.tileSize * game.zoom * size - 3, ((game.tileSize * game.zoom * size - 8) / maxHealth) * health, 3);
      }

      // draw inactive sign
      if (!active) {
        context.strokeStyle = "#F00";
        context.lineWidth = 2;

        context.beginPath();
        context.arc(center.x, center.y, (game.tileSize / 2) * size, 0, PI * 2, true);
        context.closePath();
        context.stroke();

        context.beginPath();
        context.moveTo(realPosition.x, realPosition.y + game.tileSize * size);
        context.lineTo(realPosition.x + game.tileSize * size, realPosition.y);
        context.stroke();
      }
    }

    // draw shots
    if (operating) {
      if (imageID == "cannon") {
        Vector targetPosition = Helper.tiled2screen(weaponTargetPosition);
        context.strokeStyle = "#f00";
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();
      }
      else if (imageID == "analyzer") {
        Vector targetPosition = Helper.tiled2screen(weaponTargetPosition);
        context.strokeStyle = '#00f';
        context.lineWidth = 4;
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();

        context.strokeStyle = '#fff';
        context.lineWidth = 2;
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();
      }
      else if (imageID == "beam") {
        Vector targetPosition = Helper.real2screen(weaponTargetPosition);
        context.strokeStyle = '#f00';
        context.lineWidth = 4;
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();

        context.strokeStyle = '#fff';
        context.lineWidth = 2;
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();
      }
      else if (imageID == "shield") {
        context.drawImageScaled(engine.images["forcefield"], center.x - 168 * game.zoom, center.y - 168 * game.zoom, 336 * game.zoom, 336 * game.zoom);
      }
      else if (imageID == "terp") {
        Vector targetPosition = Helper.tiled2screen(weaponTargetPosition);

        context
          ..strokeStyle = '#f00'
          ..lineWidth = 4
          ..beginPath()
          ..moveTo(center.x, center.y)
          ..lineTo(targetPosition.x + 8, targetPosition.y + 8)
          ..stroke();

        context
          ..strokeStyle = '#fff'
          ..lineWidth = 2
          ..beginPath()
          ..moveTo(center.x, center.y)
          ..lineTo(targetPosition.x + 8, targetPosition.y + 8)
          ..stroke();
      }
    }

  }
}