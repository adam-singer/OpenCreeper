part of creeper;

class Ship {
  Vector position, speed = new Vector(0, 0), targetPosition = new Vector(0, 0);
  String imageID, type, status = "IDLE"; // ATTACKING, RETURNING, RISING, FALLING
  bool remove = false, hovered = false, selected = false;
  num angle = 0, maxEnergy = 15, energy = 0, trailTimer = 0, weaponTimer = 0, scale = 1, flightCounter = 0;
  Building home;

  Ship(this.position, this.imageID, this.type, this.home);

  Vector getCenter() {
    return new Vector(position.x + 24, position.y + 24);
  }

  bool updateHoverState() {
    Vector realPosition = Helper.real2screen(position);
    hovered = (engine.mouse.x > realPosition.x && engine.mouse.x < realPosition.x + 47 && engine.mouse.y > realPosition.y && engine.mouse.y < realPosition.y + 47);
    return hovered;
  }

  void turnToTarget() {
    Vector delta = new Vector(targetPosition.x - position.x, targetPosition.y - position.y);
    double angleToTarget = Helper.rad2deg(atan2(delta.y, delta.x));

    num turnRate = 1.5;
    num absoluteDelta = (angleToTarget - angle).abs();

    if (absoluteDelta < turnRate)
      turnRate = absoluteDelta;

    if (absoluteDelta <= 180)
      if (angleToTarget < angle)
        angle -= turnRate;
      else
        angle += turnRate;
    else
      if (angleToTarget < angle)
        angle += turnRate;
      else
        angle -= turnRate;

    if (angle > 180)
      angle -= 360;
    if (angle < -180)
      angle += 360;
  }

  void calculateVector() {
    num x = cos(Helper.deg2rad(angle));
    num y = sin(Helper.deg2rad(angle));

    speed.x = x * game.shipSpeed * game.speed;
    speed.y = y * game.shipSpeed * game.speed;
  }
  
  void control(Vector position) {
    // select ship
    if (hovered)
      selected = true;
    
    // control if selected
    if (selected) {
      game.mode = "SHIP_SELECTED";

      if (status == "IDLE") {
        if (position.x - 1 != home.position.x && position.y - 1 != home.position.y) {         
          // leave home
          energy = home.energy;
          home.energy = 0;
          targetPosition.x = position.x * game.tileSize;
          targetPosition.y = position.y * game.tileSize;
          status = "RISING"; 
        }
      }
      
      if (status == "ATTACKING" || status == "RETURNING") {      
        if (position.x - 1 == home.position.x && position.y - 1 == home.position.y) {
          // return home
          targetPosition.x = (position.x - 1) * game.tileSize;
          targetPosition.y = (position.y - 1) * game.tileSize;
          status = "RETURNING";
        }
        else {
          // attack again
          targetPosition.x = (position.x - 1) * game.tileSize;
          targetPosition.y = (position.y - 1) * game.tileSize;
          status = "ATTACKING";
        }
      }

    }
  }

  void move() {

    if (status == "ATTACKING" || status == "RETURNING") {
      trailTimer++;
      if (trailTimer == 10) {
        trailTimer = 0;
        game.smokes.add(new Smoke(getCenter()));
      }
    }

    if (status == "RISING") {
      if (flightCounter < 25) {
        flightCounter++;
        scale *= 1.01;
      }
      if (flightCounter == 25) {
        status = "ATTACKING";
      }
    }
    
    else if (status == "FALLING") {
      if (flightCounter > 0) {
        flightCounter--;
        scale /= 1.01;
      }
      if (flightCounter == 0) {
        status = "IDLE";
        position.x = home.position.x * game.tileSize;
        position.y = home.position.y * game.tileSize;
        targetPosition.x = 0;
        targetPosition.y = 0;
        energy = 5;
        scale = 1;
      }
    }
    
    else if (status == "ATTACKING") {
      weaponTimer++;

      turnToTarget();
      calculateVector();

      position += speed;

      if (position.x > targetPosition.x - 2 && position.x < targetPosition.x + 2 && position.y > targetPosition.y - 2 && position.y < targetPosition.y + 2) {
        if (weaponTimer >= 10) {
          weaponTimer = 0;
          game.explosions.add(new Explosion(targetPosition));
          energy -= 1;

          for (int i = (targetPosition.x / game.tileSize).floor() - 3; i < (targetPosition.x / game.tileSize).floor() + 5; i++) {
            for (int j = (targetPosition.y / game.tileSize).floor() - 3; j < (targetPosition.y / game.tileSize).floor() + 5; j++) {
              if (game.withinWorld(i, j)) {
                num distance = pow((i * game.tileSize + game.tileSize / 2) - (targetPosition.x + game.tileSize), 2) + pow((j * game.tileSize + game.tileSize / 2) - (targetPosition.y + game.tileSize), 2);
                if (distance < pow(game.tileSize * 3, 2)) {
                  game.world.tiles[i][j].creep -= 5;
                  if (game.world.tiles[i][j].creep < 0) {
                    game.world.tiles[i][j].creep = 0;
                  }
                }
              }
            }
          }

          if (energy == 0) {
            // return to base
            status = "RETURNING";
            targetPosition.x = home.position.x * game.tileSize;
            targetPosition.y = home.position.y * game.tileSize;
          }
        }
      }
    }
    
    else if (status == "RETURNING") {
      turnToTarget();
      calculateVector();

      position += speed;

      if (position.x > targetPosition.x - 2 && position.x < targetPosition.x + 2 && position.y > targetPosition.y - 2 && position.y < targetPosition.y + 2) {
        status = "FALLING";
      }
    }
    
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector realPosition = Helper.real2screen(position);

    if (hovered) {
      context
        ..strokeStyle = "#f00"
        ..beginPath()
        ..arc(realPosition.x + 24 * game.zoom, realPosition.y + 24 * game.zoom, 24 * game.zoom * scale, 0, PI * 2, true)
        ..closePath()
        ..stroke();
    }

    if (selected) {
      context
        ..strokeStyle = "#fff"
        ..beginPath()
        ..arc(realPosition.x + 24 * game.zoom, realPosition.y + 24 * game.zoom, 24 * game.zoom * scale, 0, PI * 2, true)
        ..closePath()
        ..stroke();

      if (status == "ATTACKING" || status == "IDLE") {
        Vector cursorPosition = Helper.real2screen(targetPosition);
        context
          ..save()
          ..globalAlpha = .5
          ..drawImageScaled(engine.images["targetcursor"], cursorPosition.x - game.tileSize * game.zoom, cursorPosition.y - game.tileSize * game.zoom, 48 * game.zoom, 48 * game.zoom)
          ..restore();
      }
    }

    if (engine.isVisible(realPosition, new Vector(48 * game.zoom, 48 * game.zoom))) {
      // draw ship
      context
        ..save()
        ..translate(realPosition.x + 24 * game.zoom, realPosition.y + 24 * game.zoom)
        ..rotate(Helper.deg2rad(angle + 90))
        ..drawImageScaled(engine.images[imageID], -24 * game.zoom * scale, -24 * game.zoom * scale, 48 * game.zoom * scale, 48 * game.zoom * scale)
        ..restore();

      // draw energy bar
      context
        ..fillStyle = '#f00'
        ..fillRect(realPosition.x + 2, realPosition.y + 1, (44 * game.zoom / maxEnergy) * energy, 3);
    }
  }
}