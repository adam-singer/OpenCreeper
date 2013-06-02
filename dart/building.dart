part of creeper;

class Building {
  Vector position, moveTargetPosition, weaponTargetPosition, speed = new Vector(0, 0);
  String imageID, status = "IDLE"; // MOVING, RISING, FALLING
  bool operating = false, selected = false, hovered = false, built = false, active = true, canMove = false, needsEnergy = false, rotating = false;
  num health = 0, maxHealth = 0, energy = 0, maxEnergy = 0, energyTimer = 0, healthRequests = 0, energyRequests = 0, requestTimer = 0, weaponRadius = 0, angle = 0, targetAngle = 0, size = 0, collectedEnergy = 0, flightCounter = 0, scale = 1;
  Ship ship;

  Building(this.position, this.imageID);

  bool updateHoverState() {
    Vector position = Helper.tiled2screen(this.position);
    this.hovered = (engine.mouse.x > position.x && engine.mouse.x < position.x + game.tileSize * this.size * game.zoom - 1 && engine.mouse.y > position.y && engine.mouse.y < position.y + game.tileSize * this.size * game.zoom - 1);

    return this.hovered;
  }

  void move() {
    if (this.status == "RISING") {
      if (this.flightCounter < 25) {
        this.flightCounter++;
        this.scale *= 1.01;
      }
      if (this.flightCounter == 25) {
        this.status = "MOVING";
      }
    }
    
    else if (this.status == "FALLING") {
      if (this.flightCounter > 0) {
        this.flightCounter--;
        this.scale /= 1.01;
      }
      if (this.flightCounter == 0) {
        this.status = "IDLE";
        this.position.x = this.moveTargetPosition.x;
        this.position.y = this.moveTargetPosition.y;
        this.scale = 1;
      }
    }

    if (this.status == "MOVING") {
      
      this.position += this.speed;
      
      if (this.position.x * game.tileSize > this.moveTargetPosition.x * game.tileSize - 2 && this.position.x * game.tileSize < this.moveTargetPosition.x * game.tileSize + 2 && this.position.y * game.tileSize > this.moveTargetPosition.y * game.tileSize - 2 && this.position.y * game.tileSize < this.moveTargetPosition.y * game.tileSize + 2) {
        this.status = "FALLING";
      }
    }
  }

  void calculateVector() {
    if (this.moveTargetPosition.x != this.position.x || this.moveTargetPosition.y != this.position.y) {
      Vector targetPosition = new Vector(this.moveTargetPosition.x * game.tileSize, this.moveTargetPosition.y * game.tileSize);
      Vector ownPosition = new Vector(this.position.x * game.tileSize, this.position.y * game.tileSize);
      Vector delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
      num distance = Helper.distance(targetPosition, ownPosition);

      this.speed.x = (delta.x / distance) * game.buildingSpeed * game.speed / game.tileSize;
      this.speed.y = (delta.y / distance) * game.buildingSpeed * game.speed / game.tileSize;
    }
  }

  Vector getCenter() {
    return new Vector(this.position.x * game.tileSize + (game.tileSize / 2) * this.size, this.position.y * game.tileSize + (game.tileSize / 2) * this.size);
  }

  void takeDamage() {
    // buildings can only be damaged while not moving
    if (this.status == "IDLE") {

      for (int i = 0; i < this.size; i++) {
        for (int j = 0; j < this.size; j++) {
          if (game.world.tiles[this.position.x + i][this.position.y + j][0].creep > 0) {
            this.health -= game.world.tiles[this.position.x + i][this.position.y + j][0].creep;
          }
        }
      }

      if (this.health < 0) {
        game.removeBuilding(this);
      }
    }
  }
  
  void shield() {
    if (this.built && this.imageID == "shield" && this.status == "IDLE") {
      Vector center = this.getCenter();

      for (int i = this.position.x - 9; i < this.position.x + 10; i++) {
        for (int j = this.position.y - 9; j < this.position.y + 10; j++) {
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
    
    if (this.hovered || this.selected) {
      Vector position = Helper.tiled2screen(this.position);

      context
        ..lineWidth = 2 * game.zoom
        ..strokeStyle = "#000"
        ..strokeRect(position.x, position.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
    }
  }

  void drawMovementIndicators() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    if (this.status != "IDLE") {
      Vector center = Helper.real2screen(this.getCenter());
      Vector target = Helper.tiled2screen(this.moveTargetPosition);

      // draw box
      context
        ..strokeStyle = "rgba(0,255,0,0.5)"
        ..strokeRect(target.x, target.y, this.size * game.tileSize * game.zoom, this.size * game.tileSize * game.zoom);
      // draw line
      context
        ..strokeStyle = "rgba(255,255,255,0.5)"
        ..beginPath()
        ..moveTo(center.x, center.y)
        ..lineTo(target.x + (game.tileSize / 2) * this.size * game.zoom, target.y + (game.tileSize / 2) * this.size * game.zoom)
        ..stroke();
    }
  }

  void drawRepositionInfo() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    if (this.built && this.selected && this.canMove) {
      engine.canvas["main"].element.style.cursor = "none";
      
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * game.tileSize + (game.tileSize / 2) * this.size, positionScrolled.y * game.tileSize + (game.tileSize / 2) * this.size);
      Vector drawPositionCenter = Helper.real2screen(positionScrolledCenter);

      Vector center = Helper.real2screen(this.getCenter());

      game.drawRangeBoxes(positionScrolled, this.imageID, this.weaponRadius, this.size);

      if (game.canBePlaced(positionScrolled, this.size, this))
        context.strokeStyle = "rgba(0,255,0,0.5)";
      else
        context.strokeStyle = "rgba(255,0,0,0.5)";

      // draw rectangle
      context.strokeRect(drawPosition.x, drawPosition.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
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
    
    Vector position = Helper.tiled2screen(this.position);
    Vector center = Helper.real2screen(this.getCenter());

    if (engine.isVisible(position, new Vector(engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom))) {
      if (!this.built) {
        context.save();
        context.globalAlpha = .5;
        context.drawImageScaled(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        if (this.imageID == "cannon") {
          context.drawImageScaled(engine.images["cannongun"], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        }
        context.restore();
      } else {
        context.drawImageScaled(engine.images[this.imageID], position.x + this.size * 8 - this.size * 8 * this.scale, position.y + this.size * 8 - this.size * 8 * this.scale, engine.images[this.imageID].width * game.zoom * this.scale, engine.images[this.imageID].height * game.zoom * this.scale);
        if (this.imageID == "cannon") {
          context.save();
          context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
          context.rotate(Helper.deg2rad(this.angle));
          context.drawImageScaled(engine.images["cannongun"], -24 * game.zoom * this.scale, -24 * game.zoom * this.scale, 48 * game.zoom * this.scale, 48 * game.zoom * this.scale);
          context.restore();
        }
      }

      // draw energy bar
      if (this.needsEnergy) {
        context.fillStyle = '#f00';
        context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
      }

      // draw health bar (only if health is below maxHealth)
      if (this.health < this.maxHealth) {
        context.fillStyle = '#0f0';
        context.fillRect(position.x + 2, position.y + game.tileSize * game.zoom * this.size - 3, ((game.tileSize * game.zoom * this.size - 8) / this.maxHealth) * this.health, 3);
      }

      // draw inactive sign
      if (!this.active) {
        context.strokeStyle = "#F00";
        context.lineWidth = 2;

        context.beginPath();
        context.arc(center.x, center.y, (game.tileSize / 2) * this.size, 0, PI * 2, true);
        context.closePath();
        context.stroke();

        context.beginPath();
        context.moveTo(position.x, position.y + game.tileSize * this.size);
        context.lineTo(position.x + game.tileSize * this.size, position.y);
        context.stroke();
      }
    }

    // draw shots
    if (this.operating) {
      if (this.imageID == "cannon") {
        Vector targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
        context.strokeStyle = "#f00";
        context.beginPath();
        context.moveTo(center.x, center.y);
        context.lineTo(targetPosition.x, targetPosition.y);
        context.stroke();
      }
      else if (this.imageID == "analyzer") {
        Vector targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
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
      else if (this.imageID == "beam") {
        Vector targetPosition = Helper.real2screen(this.weaponTargetPosition);
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
      else if (this.imageID == "shield") {
        context.drawImageScaled(engine.images["forcefield"], center.x - 168 * game.zoom, center.y - 168 * game.zoom, 336 * game.zoom, 336 * game.zoom);
      }
      else if (this.imageID == "terp") {
        Vector targetPosition = Helper.tiled2screen(this.weaponTargetPosition);

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