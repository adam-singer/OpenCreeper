part of creeper;

class Ship {
  Vector position, speed, targetPosition;
  String imageID, type;
  bool remove = false, hovered, selected;
  num angle, maxEnergy = 15, energy = 0, status = 0, trailTimer = 0, weaponTimer = 0;
  Building home;

  Ship(this.position, this.imageID, this.type, this.home);

  Vector getCenter() {
    return new Vector(this.position.x + 24, this.position.y + 24);
  }

  bool updateHoverState() {
    Vector position = Helper.real2screen(this.position);
    this.hovered = (engine.mouse.x > position.x && engine.mouse.x < position.x + 47 && engine.mouse.y > position.y && engine.mouse.y < position.y + 47);

    return this.hovered;
  }

  void turnToTarget() {
    Vector delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
    int angleToTarget = Helper.rad2deg(atan2(delta.y, delta.x));

    num turnRate = 1.5;
    num absoluteDelta = (angleToTarget - this.angle).abs();

    if (absoluteDelta < turnRate)
      turnRate = absoluteDelta;

    if (absoluteDelta <= 180)
      if (angleToTarget < this.angle)
        this.angle -= turnRate;
      else
        this.angle += turnRate;
    else
      if (angleToTarget < this.angle)
        this.angle += turnRate;
      else
        this.angle -= turnRate;

    if (this.angle > 180)this.angle -= 360;
    if (this.angle < -180)this.angle += 360;
  }

  void calculateVector() {
    num x = cos(Helper.deg2rad(this.angle));
    num y = sin(Helper.deg2rad(this.angle));

    this.speed.x = x * game.shipSpeed * game.speed;
    this.speed.y = y * game.shipSpeed * game.speed;
  }
  
  void control(Vector position) {
    // select ship
    this.selected = this.hovered;
    
    // control if selected
    if (this.selected) {
      game.mode = "SHIP_SELECTED";
      if (position.x - 1 == this.home.position.x && position.y - 1 == this.home.position.y) {
        this.targetPosition.x = (position.x - 1) * game.tileSize;
        this.targetPosition.y = (position.y - 1) * game.tileSize;
        this.status = 2;
      } else {
        // take energy from base
        this.energy = this.home.energy;
        this.home.energy = 0;
        this.targetPosition.x = position.x * game.tileSize;
        this.targetPosition.y = position.y * game.tileSize;
        this.status = 1;
      }

    }
  }

  void move() {

    if (this.status != 0) {
      this.trailTimer++;
      if (this.trailTimer == 10) {
        this.trailTimer = 0;
        game.smokes.add(new Smoke(this.getCenter()));
      }

      this.weaponTimer++;

      this.turnToTarget();
      this.calculateVector();

      this.position += this.speed;

      if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
        if (this.status == 1) {
          // attacking
          if (this.weaponTimer >= 10) {
            this.weaponTimer = 0;
            game.explosions.add(new Explosion(this.targetPosition));
            this.energy -= 1;

            for (int i = (this.targetPosition.x / game.tileSize).floor() - 3; i < (this.targetPosition.x / game.tileSize).floor() + 5; i++) {
              for (int j = (this.targetPosition.y / game.tileSize).floor() - 3; j < (this.targetPosition.y / game.tileSize).floor() + 5; j++)
                if (game.withinWorld(i, j)) {
                  {
                    num distance = pow((i * game.tileSize + game.tileSize / 2) - (this.targetPosition.x + game.tileSize), 2) + pow((j * game.tileSize + game.tileSize / 2) - (this.targetPosition.y + game.tileSize), 2);
                    if (distance < pow(game.tileSize * 3, 2)) {
                      game.world.tiles[i][j][0].creep -= 5;
                      if (game.world.tiles[i][j][0].creep < 0) {
                        game.world.tiles[i][j][0].creep = 0;
                      }
                    }
                  }
                }
            }

            if (this.energy == 0) {
              // return to base
              this.status = 2;
              this.targetPosition.x = this.home.position.x * game.tileSize;
              this.targetPosition.y = this.home.position.y * game.tileSize;
            }
          }
        } else if (this.status == 2) {
          // if returning set to idle
          this.status = 0;
          this.position.x = this.home.position.x * game.tileSize;
          this.position.y = this.home.position.y * game.tileSize;
          this.targetPosition.x = 0;
          this.targetPosition.y = 0;
          this.energy = 5;
        }
      }
    }
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector position = Helper.real2screen(this.position);

    if (this.hovered) {
      context.strokeStyle = "#f00";
      context.beginPath();
      context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, PI * 2, true);
      context.closePath();
      context.stroke();
    }

    if (this.selected) {
      context.strokeStyle = "#fff";
      context.beginPath();
      context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, PI * 2, true);
      context.closePath();
      context.stroke();

      if (this.status == 1) {
        Vector cursorPosition = Helper.real2screen(this.targetPosition);
        context.save();
        context.globalAlpha = .5;
        context.drawImageScaled(engine.images["targetcursor"], cursorPosition.x - game.tileSize * game.zoom, cursorPosition.y - game.tileSize * game.zoom, 48 * game.zoom, 48 * game.zoom);
        context.restore();
      }
    }

    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      // draw ship
      context.save();
      context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
      context.rotate(Helper.deg2rad(this.angle + 90));
      context.drawImageScaled(engine.images[this.imageID], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
      context.restore();

      // draw energy bar
      context.fillStyle = '#f00';
      context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
    }
  }
}