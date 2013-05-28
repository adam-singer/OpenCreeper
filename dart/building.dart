part of creeper;

class Building {
  Vector position, moveTargetPosition, weaponTargetPosition, speed = new Vector(0, 0);
  String imageID;
  bool operating = false, selected = false, hovered = false, built = false, active = true, moving = false, canMove = false, needsEnergy = false;
  num health = 0, maxHealth = 0, energy = 0, maxEnergy = 0, energyTimer = 0, healthRequests = 0, energyRequests = 0, requestTimer = 0, weaponRadius = 0, targetAngle = 0, size = 0, collectedEnergy = 0;
  Ship ship;

  Building(this.position, this.imageID);

  bool updateHoverState() {
    Vector position = Helper.tiled2screen(this.position);
    this.hovered = (engine.mouse.x > position.x && engine.mouse.x < position.x + game.tileSize * this.size * game.zoom - 1 && engine.mouse.y > position.y && engine.mouse.y < position.y + game.tileSize * this.size * game.zoom - 1);

    return this.hovered;
  }

  void drawBox() {
    if (this.hovered || this.selected) {
      Vector position = Helper.tiled2screen(this.position);
      engine.canvas["buffer"].context.lineWidth = 2 * game.zoom;
      engine.canvas["buffer"].context.strokeStyle = "#000";
      engine.canvas["buffer"].context.strokeRect(position.x, position.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
    }
  }

  void move() {
    if (this.moving) {
      this.position.x += this.speed.x;
      this.position.y += this.speed.y;
      if (this.position.x * game.tileSize > this.moveTargetPosition.x * game.tileSize - 3 && this.position.x * game.tileSize < this.moveTargetPosition.x * game.tileSize + 3 && this.position.y * game.tileSize > this.moveTargetPosition.y * game.tileSize - 3 && this.position.y * game.tileSize < this.moveTargetPosition.y * game.tileSize + 3) {
        this.moving = false;
        this.position.x = this.moveTargetPosition.x;
        this.position.y = this.moveTargetPosition.y;
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
    if (!this.moving) {

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

  void drawMovementIndicators() {
    if (this.moving) {
      Vector center = Helper.real2screen(this.getCenter());
      Vector target = Helper.tiled2screen(this.moveTargetPosition);
      // draw box
      engine.canvas["buffer"].context.fillStyle = "rgba(0,255,0,0.5)";
      engine.canvas["buffer"].context.fillRect(target.x, target.y, this.size * game.tileSize * game.zoom, this.size * game.tileSize * game.zoom);
      // draw line
      engine.canvas["buffer"].context.strokeStyle = "rgba(255,255,255,0.5)";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(center.x, center.y);
      engine.canvas["buffer"].context.lineTo(target.x + (game.tileSize / 2) * this.size * game.zoom, target.y + (game.tileSize / 2) * this.size * game.zoom);
      engine.canvas["buffer"].context.stroke();
    }
  }

  void drawRepositionInfo() {
    if (this.built && this.selected && this.canMove) {
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * game.tileSize + (game.tileSize / 2) * this.size, positionScrolled.y * game.tileSize + (game.tileSize / 2) * this.size);
      Vector drawPositionCenter = Helper.real2screen(positionScrolledCenter);

      Vector center = Helper.real2screen(this.getCenter());

      game.drawRangeBoxes(positionScrolled, this.imageID, this.weaponRadius, this.size);

      if (game.canBePlaced(positionScrolled, this.size, this))engine.canvas["buffer"].context.strokeStyle = "rgba(0,255,0,0.5)"; else
        engine.canvas["buffer"].context.strokeStyle = "rgba(255,0,0,0.5)";

      // draw rectangle
      engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
      // draw line
      engine.canvas["buffer"].context.strokeStyle = "rgba(255,255,255,0.5)";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(center.x, center.y);
      engine.canvas["buffer"].context.lineTo(drawPositionCenter.x, drawPositionCenter.y);
      engine.canvas["buffer"].context.stroke();
    }
  }

  void shield() {
    if (this.built && this.imageID == "shield" && !this.moving) {
      Vector center = this.getCenter();

      for (int i = this.position.x - 9; i < this.position.x + 10; i++) {
        for (int j = this.position.y - 9; j < this.position.y + 10; j++) {
          if (game.withinWorld(i, j)) {
            num distance = Math.pow((i * game.tileSize + game.tileSize / 2) - center.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - center.y, 2);
            if (distance < Math.pow(game.tileSize * 10, 2)) {
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

  void draw() {
    Vector position = Helper.tiled2screen(this.position);
    Vector center = Helper.real2screen(this.getCenter());

    if (engine.isVisible(position, new Vector(engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom))) {
      if (!this.built) {
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;
        engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        if (this.imageID == "cannon") {
          engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        }
        engine.canvas["buffer"].context.restore();
      } else {
        engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        if (this.imageID == "cannon") {
          engine.canvas["buffer"].context.save();
          engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
          engine.canvas["buffer"].context.rotate(this.targetAngle);
          engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
          engine.canvas["buffer"].context.restore();
        }
      }

      // draw energy bar
      if (this.needsEnergy) {
        engine.canvas["buffer"].context.fillStyle = '#f00';
        engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
      }

      // draw health bar (only if health is below maxHealth)
      if (this.health < this.maxHealth) {
        engine.canvas["buffer"].context.fillStyle = '#0f0';
        engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + game.tileSize * game.zoom * this.size - 3, ((game.tileSize * game.zoom * this.size - 8) / this.maxHealth) * this.health, 3);
      }

      // draw inactive sign
      if (!this.active) {
        engine.canvas["buffer"].context.strokeStyle = "#F00";
        engine.canvas["buffer"].context.lineWidth = 2;

        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.arc(center.x, center.y, (game.tileSize / 2) * this.size, 0, Math.PI * 2, true);
        engine.canvas["buffer"].context.closePath();
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(position.x, position.y + game.tileSize * this.size);
        engine.canvas["buffer"].context.lineTo(position.x + game.tileSize * this.size, position.y);
        engine.canvas["buffer"].context.stroke();
      }
    }

    // draw shots
    if (this.operating) {
      if (this.imageID == "cannon") {
        Vector targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = "#f00";
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();
      }
      if (this.imageID == "beam") {
        Vector targetPosition = Helper.real2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = '#f00';
        engine.canvas["buffer"].context.lineWidth = 4;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.strokeStyle = '#fff';
        engine.canvas["buffer"].context.lineWidth = 2;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();
      }
      if (this.imageID == "shield") {
        engine.canvas["buffer"].context.drawImageScaled(engine.images["forcefield"], center.x - 168 * game.zoom, center.y - 168 * game.zoom, 336 * game.zoom, 336 * game.zoom);
      }
      if (this.imageID == "terp") {
        Vector targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = '#f00';
        engine.canvas["buffer"].context.lineWidth = 4;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x + 8, targetPosition.y + 8);
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.strokeStyle = '#fff';
        engine.canvas["buffer"].context.lineWidth = 2;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x + 8, targetPosition.y + 8);
        engine.canvas["buffer"].context.stroke();
      }
    }

  }
}