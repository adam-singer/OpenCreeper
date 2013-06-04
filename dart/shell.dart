part of creeper;

class Shell {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove = false;
  num rotation = 0;
  int trailTimer = 0;

  Shell(this.position, this.targetPosition) {
    imageID = "shell";
  }

  void init() {
    Vector delta = new Vector(targetPosition.x - position.x, targetPosition.y - position.y);
    num distance = Helper.distance(targetPosition, position);

    speed.x = (delta.x / distance) * game.shellSpeed * game.speed;
    speed.y = (delta.y / distance) * game.shellSpeed * game.speed;
  }

  Vector getCenter() {
    return new Vector(position.x - 8, position.y - 8);
  }

  void move() {
    trailTimer++;
    if (trailTimer == 10) {
      trailTimer = 0;
      game.smokes.add(new Smoke(getCenter()));
    }

    rotation += 20;
    if (rotation > 359)
      rotation -= 359;

    position += speed;

    if (position.x > targetPosition.x - 2 && position.x < targetPosition.x + 2 && position.y > targetPosition.y - 2 && position.y < targetPosition.y + 2) {
      // if the target is reached explode and remove
      remove = true;

      game.explosions.add(new Explosion(targetPosition));
      engine.playSound("explosion", Helper.real2tiled(targetPosition));

      for (int i = (targetPosition.x / game.tileSize).floor() - 4; i < (targetPosition.x / game.tileSize).floor() + 5; i++) {
        for (int j = (targetPosition.y / game.tileSize).floor() - 4; j < (targetPosition.y / game.tileSize).floor() + 5; j++) {
          if (game.withinWorld(i, j)) {
            num distance = pow((i * game.tileSize + game.tileSize / 2) - targetPosition.x, 2) + pow((j * game.tileSize + game.tileSize / 2) - targetPosition.y, 2);
            if (distance < pow(game.tileSize * 4, 2)) {
              game.world.tiles[i][j].creep -= 10;
              if (game.world.tiles[i][j].creep < 0) {
                game.world.tiles[i][j].creep = 0;
              }
            }
          }
        }
      }

    }
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector realPosition = Helper.real2screen(position);

    if (engine.isVisible(realPosition, new Vector(16 * game.zoom, 16 * game.zoom))) {
      context
        ..save()
        ..translate(realPosition.x + 8 * game.zoom, realPosition.y + 8 * game.zoom)
        ..rotate(Helper.deg2rad(rotation))
        ..drawImageScaled(engine.images[imageID], -8 * game.zoom, -8 * game.zoom, 16 * game.zoom, 16 * game.zoom)
        ..restore();
    }
  }
}