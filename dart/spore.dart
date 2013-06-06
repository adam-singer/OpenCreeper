part of creeper;

class Spore {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove = false;
  num health = 100;
  int rotation = 0, trailCounter = 0;
  static final int baseSpeed = 1;

  Spore(this.position, this.targetPosition) {
    imageID = "spore";
    init();
  }

  void init() {
    Vector delta = new Vector(targetPosition.x - position.x, targetPosition.y - position.y);
    num distance = Helper.distance(targetPosition, position);

    speed.x = (delta.x / distance) * Spore.baseSpeed * game.speed;
    speed.y = (delta.y / distance) * Spore.baseSpeed * game.speed;
  }

  Vector getCenter() {
    return new Vector(position.x - 16, position.y - 16);
  }

  void move() {
    trailCounter++;
    if (trailCounter == 10) {
      trailCounter = 0;
      game.smokes.add(new Smoke(getCenter()));
    }
    rotation += 10;
    if (rotation > 359)
      rotation -= 359;

    position += speed;

    if (position.x > targetPosition.x - 2 && position.x < targetPosition.x + 2 && position.y > targetPosition.y - 2 && position.y < targetPosition.y + 2) {
      // if the target is reached explode and remove
      remove = true;
      engine.playSound("explosion", Helper.real2tiled(targetPosition));

      for (int i = (targetPosition.x / game.tileSize).floor() - 2; i < (targetPosition.x / game.tileSize).floor() + 2; i++) {
        for (int j = (targetPosition.y / game.tileSize).floor() - 2; j < (targetPosition.y / game.tileSize).floor() + 2; j++) {
          if (game.withinWorld(i, j)) {
            num distance = pow((i * game.tileSize + game.tileSize / 2) - (targetPosition.x + game.tileSize), 2) + pow((j * game.tileSize + game.tileSize / 2) - (targetPosition.y + game.tileSize), 2);
            if (distance < pow(game.tileSize, 2)) {
              game.world.tiles[i][j].creep += .05;
            }
          }
        }
      }
    }
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector realPosition = Helper.real2screen(position);

    if (engine.isVisible(realPosition, new Vector(32 * game.zoom, 32 * game.zoom))) {
      context
        ..save()
        ..translate(realPosition.x, realPosition.y)
        ..rotate(Helper.deg2rad(rotation))
        ..drawImageScaled(engine.images[imageID], -16 * game.zoom, -16 * game.zoom, 32 * game.zoom, 32 * game.zoom)
        ..restore();
    }
  }
}