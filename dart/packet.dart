part of creeper;

class Packet {
  Vector position, speed = new Vector(0, 0);
  String imageID, type;
  bool remove = false;
  num speedMultiplier = 1;
  Building target, currentTarget;
  static num baseSpeed = 3;

  Packet(this.position, this.imageID, this.type);

  void move() {
    calculateVector();
    
    position += speed;

    Vector centerTarget = currentTarget.getCenter();
    if (position.x > centerTarget.x - 1 && position.x < centerTarget.x + 1 && position.y > centerTarget.y - 1 && position.y < centerTarget.y + 1) {
      position.x = centerTarget.x;
      position.y = centerTarget.y;
      // if the final node was reached deliver and remove
      if (currentTarget == target) {
        remove = true;
        // deliver package
        if (type == "health") {
          target.health += 1;
          target.healthRequests--;
          if (target.health >= target.maxHealth) {
            target.health = target.maxHealth;
            if (!target.built) {
              target.built = true;
              if (target.imageID == "collector") {
                game.updateCollection(target, "add");
                engine.playSound("energy", target.position);
              }
              if (target.imageID == "storage")
                game.maxEnergy += 20;
              if (target.imageID == "speed")
                Packet.baseSpeed *= 1.01;
              if (target.imageID == "bomber") {
                Ship ship = new Ship(new Vector(target.position.x * game.tileSize, target.position.y * game.tileSize), "bombership", "Bomber", target);
                target.ship = ship;
                game.ships.add(ship);
              }
            }
          }
        } else if (type == "energy") {
          target.energy += 4;
          target.energyRequests -= 4;
          if (target.energy > target.maxEnergy)
            target.energy = target.maxEnergy;
        } else if (type == "collection") {
          game.currentEnergy += 1;
          if (game.currentEnergy > game.maxEnergy)game.currentEnergy = game.maxEnergy;
          game.updateEnergyElement();
        }
      } else {
        game.findRoute(this);
      }
    }
  }

  void calculateVector() {
    Vector targetPosition = currentTarget.getCenter();
    Vector delta = new Vector(targetPosition.x - position.x, targetPosition.y - position.y);
    num distance = Helper.distance(targetPosition, position);

    speed.x = (delta.x / distance) * Packet.baseSpeed * game.speed * speedMultiplier;
    speed.y = (delta.y / distance) * Packet.baseSpeed * game.speed * speedMultiplier;

    if (speed.x.abs() > delta.x.abs())
      speed.x = delta.x;
    if (speed.y.abs() > delta.y.abs())
      speed.y = delta.y;
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector realPosition = Helper.real2screen(position);
    if (engine.isVisible(new Vector(realPosition.x - 8, realPosition.y - 8), new Vector(16 * game.zoom, 16 * game.zoom))) {
      context.drawImageScaled(engine.images[imageID], realPosition.x - 8 * game.zoom, realPosition.y - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
    }
  }
}