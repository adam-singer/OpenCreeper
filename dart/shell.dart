part of creeper;

class Shell {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove = false;
  num rotation = 0, trailTimer = 0;

  Shell(this.position, this.imageID, this.targetPosition);

  void init() {
    Vector delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
    num distance = Helper.distance(this.targetPosition, this.position);

    this.speed.x = (delta.x / distance) * game.shellSpeed * game.speed;
    this.speed.y = (delta.y / distance) * game.shellSpeed * game.speed;
  }

  Vector getCenter() {
    return new Vector(this.position.x - 8, this.position.y - 8);
  }

  void move() {
    this.trailTimer++;
    if (this.trailTimer == 10) {
      this.trailTimer = 0;
      game.smokes.add(new Smoke(this.getCenter()));
    }

    this.rotation += 20;
    if (this.rotation > 359)this.rotation -= 359;

    this.position += this.speed;

    if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
      // if the target is reached explode and remove
      this.remove = true;

      game.explosions.add(new Explosion(this.targetPosition));
      engine.playSound("explosion", Helper.real2tiled(this.targetPosition));

      for (int i = (this.targetPosition.x / game.tileSize).floor() - 4; i < (this.targetPosition.x / game.tileSize).floor() + 5; i++) {
        for (int j = (this.targetPosition.y / game.tileSize).floor() - 4; j < (this.targetPosition.y / game.tileSize).floor() + 5; j++) {
          if (game.withinWorld(i, j)) {
            num distance = pow((i * game.tileSize + game.tileSize / 2) - this.targetPosition.x, 2) + pow((j * game.tileSize + game.tileSize / 2) - this.targetPosition.y, 2);
            if (distance < pow(game.tileSize * 4, 2)) {
              game.world.tiles[i][j][0].creep -= 10;
              if (game.world.tiles[i][j][0].creep < 0) {
                game.world.tiles[i][j][0].creep = 0;
              }
            }
          }
        }
      }

    }
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector position = Helper.real2screen(this.position);

    if (engine.isVisible(position, new Vector(16 * game.zoom, 16 * game.zoom))) {
      context
        ..save()
        ..translate(position.x + 8 * game.zoom, position.y + 8 * game.zoom)
        ..rotate(Helper.deg2rad(this.rotation))
        ..drawImageScaled(engine.images["shell"], -8 * game.zoom, -8 * game.zoom, 16 * game.zoom, 16 * game.zoom)
        ..restore();
    }
  }
}