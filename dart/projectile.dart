part of creeper;

class Projectile {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove = false;
  num rotation;

  Projectile(this.position, this.targetPosition, this.rotation) {
    imageID = "projectile";
  }

  void calculateVector() {
    Vector delta = new Vector(targetPosition.x - position.x, targetPosition.y - position.y);
    num distance = Helper.distance(targetPosition, position);

    speed.x = (delta.x / distance) * game.projectileSpeed * game.speed;
    speed.y = (delta.y / distance) * game.projectileSpeed * game.speed;
    
    if (speed.x.abs() > delta.x.abs())
      speed.x = delta.x;
    if (speed.y.abs() > delta.y.abs())
      speed.y = delta.y;
  }

  Vector getCenter() {
    return new Vector(position.x - 8, position.y - 8);
  }

  void move() {
    calculateVector();
    
    position += speed;

    if (position.x > targetPosition.x - 2 && position.x < targetPosition.x + 2 && position.y > targetPosition.y - 2 && position.y < targetPosition.y + 2) {
      // if the target is reached smoke and remove
      remove = true;

      game.smokes.add(new Smoke(targetPosition));
      Vector tiledPosition = Helper.real2tiled(targetPosition);
      
      game.world.tiles[tiledPosition.x][tiledPosition.y].creep -= 1;
      if (game.world.tiles[tiledPosition.x][tiledPosition.y].creep < 0) {
        game.world.tiles[tiledPosition.x][tiledPosition.y].creep = 0;
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
        ..drawImageScaled(engine.images[imageID], 8 - 8 * game.zoom, 8 - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom)
        ..restore();
    }
  }
}