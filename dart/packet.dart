part of creeper;

class Packet {
  Vector position, speed = new Vector(0, 0);
  String imageID, type;
  bool remove = false;
  num speedMultiplier = 1;
  Building target, currentTarget;

  Packet(this.position, this.imageID, this.type);

  void move() {
    this.calculateVector();

    this.position.x += this.speed.x;
    this.position.y += this.speed.y;

    Vector centerTarget = this.currentTarget.getCenter();
    if (this.position.x > centerTarget.x - 1 && this.position.x < centerTarget.x + 1 && this.position.y > centerTarget.y - 1 && this.position.y < centerTarget.y + 1) {
      this.position.x = centerTarget.x;
      this.position.y = centerTarget.y;
      // if the final node was reached deliver and remove
      if (this.currentTarget == this.target) {
      //console.log("target node reached!");
        this.remove = true;
        // deliver package
        if (this.type == "health") {
          this.target.health += 1;
          this.target.healthRequests--;
          if (this.target.health >= this.target.maxHealth) {
            this.target.health = this.target.maxHealth;
            if (!this.target.built) {
              this.target.built = true;
              if (this.target.imageID == "collector") {
                game.updateCollection(this.target, "add");
                engine.playSound("energy", this.target.position);
              }
              if (this.target.imageID == "storage")game.maxEnergy += 20;
              if (this.target.imageID == "speed")game.packetSpeed *= 1.01;
              if (this.target.imageID == "bomber") {
                Ship ship = new Ship(new Vector(this.target.position.x * game.tileSize, this.target.position.y * game.tileSize), "bombership", "Bomber", this.target);
                this.target.ship = ship;
                game.ships.add(ship);
              }
            }
          }
        } else if (this.type == "energy") {
          this.target.energy += 4;
          this.target.energyRequests -= 4;
          if (this.target.energy > this.target.maxEnergy)
            this.target.energy = this.target.maxEnergy;
        } else if (this.type == "collection") {
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
    Vector targetPosition = this.currentTarget.getCenter();
    Vector delta = new Vector(targetPosition.x - this.position.x, targetPosition.y - this.position.y);
    num distance = Helper.distance(targetPosition, this.position);

    num packetSpeed = game.packetSpeed;
    // reduce speed for collection
    if (this.type == "collection")
      packetSpeed /= 4;

    this.speed.x = (delta.x / distance) * packetSpeed * game.speed * this.speedMultiplier;
    this.speed.y = (delta.y / distance) * packetSpeed * game.speed * this.speedMultiplier;

    if (this.speed.x.abs() > delta.x.abs())
      this.speed.x = delta.x;
    if (this.speed.y.abs() > delta.y.abs())
      this.speed.y = delta.y;
  }

  void draw() {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector position = Helper.real2screen(this.position);
    if (engine.isVisible(new Vector(position.x - 8, position.y - 8), new Vector(16 * game.zoom, 16 * game.zoom))) {
      context.drawImageScaled(engine.images[this.imageID], position.x - 8 * game.zoom, position.y - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
    }
  }
}