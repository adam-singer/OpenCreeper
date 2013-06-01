part of creeper;

class Emitter {
  Vector position;
  String imageID;
  num strength;
  Building building;

  Emitter(this.position, this.strength) {
    this.imageID = "emitter";
  }
  
  Vector getCenter() {
    return new Vector(this.position.x * game.tileSize + 24, this.position.y * game.tileSize + 24);
  }

  void spawn() {
    // only spawn creeper if not targeted by an analyzer
    if (this.building == null)
      game.world.tiles[this.position.x + 1][this.position.y + 1][0].creep += this.strength;
  }
  
  void draw() {
    Vector position = Helper.tiled2screen(this.position);
    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
    }
  }
}

/**
 * Sporetower
 */

class Sporetower {
  Vector position;
  String imageID;
  num health = 100, sporeTimer = 0;

  Sporetower(this.position) {
    this.imageID = "sporetower";
  }

  void reset() {
    this.sporeTimer = Helper.randomInt(7500, 12500);
  }

  Vector getCenter() {
    return new Vector(this.position.x * game.tileSize + 24, this.position.y * game.tileSize + 24);
  }

  void update() {
    this.sporeTimer -= 1;
    if (this.sporeTimer <= 0) {
      this.reset();
      this.spawn();
    }
  }

  void spawn() {
    Building target = null;
    do {
      target = game.buildings[Helper.randomInt(0, game.buildings.length)];
    } while (!target.built);
    Spore spore = new Spore(this.getCenter(), target.getCenter());
    spore.init();
    game.spores.add(spore);
  }
  
  void draw() {
    Vector position = Helper.tiled2screen(this.position);
    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
    }
  }
}

class Smoke {
  Vector position;
  num frame;
  String imageID;

  Smoke(Vector position) {
    this.position = new Vector(position.x, position.y);
    this.frame = 0;
    this.imageID = "smoke";
  }

  void draw() {
    Vector position = Helper.real2screen(this.position);
    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images[this.imageID], (this.frame % 8) * 128, (this.frame / 8).floor() * 128, 128, 128, position.x - 24 * game.zoom, position.y - 24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
    }
  }
}

class Explosion {
  Vector position;
  num frame;
  String imageID;

  Explosion(Vector position) {
    this.position = new Vector(position.x, position.y);
    this.frame = 0;
    this.imageID = "explosion";
  }

  void draw() {
    Vector position = Helper.real2screen(this.position);
    if (engine.isVisible(position, new Vector(64 * game.zoom, 64 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images[this.imageID], (this.frame % 8) * 64, (this.frame / 8).floor() * 64, 64, 64, position.x - 32 * game.zoom, position.y - 32 * game.zoom, 64 * game.zoom, 64 * game.zoom);
    }
  }
}

class Tile {
  num index, creep, newcreep;
  bool full;
  Building collector;

  Tile() {
    this.index = -1;
    this.full = false;
    this.creep = 0;
    this.newcreep = 0;
    this.collector = null;
  }
}

class Vector {
  num x, y;

  Vector(this.x, this.y);

  Vector operator +(Vector other) => new Vector(x + other.x, y + other.y);
}

class Vector3 {
  num x, y, z;

  Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) => new Vector3(x + other.x, y + other.y, z + other.z);
}

/**
 * Route object used in A*
 */

class Route {
  num distanceTravelled = 0, distanceRemaining = 0;
  List<Building> nodes = new List<Building>();
  bool remove = false;
  
  Route();
}

/**
 * Object to store canvas information
 */

class Canvas {
  CanvasElement element;
  CanvasRenderingContext2D context;
  num top, left, bottom, right;

  Canvas(this.element, width, height) {
    this.updateRect(width, height);
    this.element.style.position = "absolute";
    this.context = this.element.getContext('2d');
  }

  void clear() {
    this.context.clearRect(0, 0, this.element.width, this.element.height);
  }
  
  void updateRect(int width, int height) {
    //this.element.attributes['width'] = width.toString();
    //this.element.attributes['height'] = height.toString();
    this.element.width = width;
    this.element.height = height;
    this.top = this.element.offset.top;
    this.left = this.element.offset.left;
    this.bottom = this.element.offset.top + this.element.offset.height;
    this.right = this.element.offset.left + this.element.offset.width;
  }
}