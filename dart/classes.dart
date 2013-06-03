part of creeper;

class Emitter {
  Vector position;
  String imageID;
  num strength;
  Building building;

  Emitter(this.position, this.strength) {
    imageID = "emitter";
  }
  
  Vector getCenter() {
    return new Vector(position.x * game.tileSize + 24, position.y * game.tileSize + 24);
  }

  void spawn() {
    // only spawn creeper if not targeted by an analyzer
    if (building == null)
      game.world.tiles[position.x + 1][position.y + 1].creep += strength;
  }
  
  void draw() {
    Vector realPosition = Helper.tiled2screen(position);
    if (engine.isVisible(realPosition, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[imageID], realPosition.x, realPosition.y, 48 * game.zoom, 48 * game.zoom);
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
    imageID = "sporetower";
    reset();
  }

  void reset() {
    sporeTimer = Helper.randomInt(7500, 12500);
  }

  Vector getCenter() {
    return new Vector(position.x * game.tileSize + 24, position.y * game.tileSize + 24);
  }

  void update() {
    sporeTimer -= 1;
    if (sporeTimer <= 0) {
      reset();
      spawn();
    }
  }

  void spawn() {
    Building target = null;
    do {
      target = game.buildings[Helper.randomInt(0, game.buildings.length)];
    } while (!target.built);
    Spore spore = new Spore(getCenter(), target.getCenter());
    spore.init();
    game.spores.add(spore);
  }
  
  void draw() {
    Vector realPosition = Helper.tiled2screen(position);
    if (engine.isVisible(realPosition, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[imageID], realPosition.x, realPosition.y, 48 * game.zoom, 48 * game.zoom);
    }
  }
}

class Smoke {
  Vector position;
  num frame;
  String imageID;

  Smoke(Vector position) {
    position = new Vector(position.x, position.y);
    frame = 0;
    imageID = "smoke";
  }

  void draw() {
    Vector realPosition = Helper.real2screen(position);
    if (engine.isVisible(realPosition, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images[imageID], (frame % 8) * 128, (frame / 8).floor() * 128, 128, 128, realPosition.x - 24 * game.zoom, realPosition.y - 24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
    }
  }
}

class Explosion {
  Vector position;
  num frame;
  String imageID;

  Explosion(Vector position) {
    position = new Vector(position.x, position.y);
    frame = 0;
    imageID = "explosion";
  }

  void draw() {
    Vector realPosition = Helper.real2screen(position);
    if (engine.isVisible(realPosition, new Vector(64 * game.zoom, 64 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images[imageID], (frame % 8) * 64, (frame / 8).floor() * 64, 64, 64, realPosition.x - 32 * game.zoom, realPosition.y - 32 * game.zoom, 64 * game.zoom, 64 * game.zoom);
    }
  }
}

class Tile {
  num creep, newcreep;
  Building collector;
  int height, index, terraformTarget, terraformProgress;

  Tile() {
    index = -1;
    creep = 0;
    newcreep = 0;
    collector = null;
    terraformTarget = -1;
    terraformProgress = 0;
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
    updateRect(width, height);
    element.style.position = "absolute";
    context = element.getContext('2d');
  }

  void clear() {
    context.clearRect(0, 0, element.width, element.height);
  }
  
  void updateRect(int width, int height) {
    element.width = width;
    element.height = height;
    top = element.offset.top;
    left = element.offset.left;
    bottom = element.offset.top + element.offset.height;
    right = element.offset.left + element.offset.width;
  }
}