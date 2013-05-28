part of creeper;

class Spore {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove = false;
  num rotation = 0, health = 100, trailTimer = 0;

  Spore(this.position, this.targetPosition) {
    this.imageID = "spore";
  }

  void init() {
    Vector delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
    num distance = Helper.distance(this.targetPosition, this.position);

    this.speed.x = (delta.x / distance) * game.sporeSpeed * game.speed;
    this.speed.y = (delta.y / distance) * game.sporeSpeed * game.speed;
  }

  Vector getCenter() {
    return new Vector(this.position.x - 16, this.position.y - 16);
  }

  void move() {
    this.trailTimer++;
    if (this.trailTimer == 10) {
      this.trailTimer = 0;
      game.smokes.add(new Smoke(this.getCenter()));
    }
    this.rotation += 10;
    if (this.rotation > 359)this.rotation -= 359;

    this.position.x += this.speed.x;
    this.position.y += this.speed.y;

    if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
      // if the target is reached explode and remove
      this.remove = true;
      engine.playSound("explosion", Helper.real2tiled(this.targetPosition));

      for (int i = (this.targetPosition.x / game.tileSize).floor() - 2; i < (this.targetPosition.x / game.tileSize).floor() + 2; i++) {
        for (int j = (this.targetPosition.y / game.tileSize).floor() - 2; j < (this.targetPosition.y / game.tileSize).floor() + 2; j++) {
          if (game.withinWorld(i, j)) {
            num distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.targetPosition.x + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.targetPosition.y + game.tileSize), 2);
            if (distance < Math.pow(game.tileSize, 2)) {
              game.world.tiles[i][j][0].creep += .05;
            }
          }
        }
      }
    }
  }

  void draw() {
    Vector position = Helper.real2screen(this.position);

    if (engine.isVisible(position, new Vector(32 * game.zoom, 32 * game.zoom))) {
      engine.canvas["buffer"].context.save();
      engine.canvas["buffer"].context.translate(position.x, position.y);
      engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.rotation));
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], -16 * game.zoom, -16 * game.zoom, 32 * game.zoom, 32 * game.zoom);
      engine.canvas["buffer"].context.restore();
    }
  }
}