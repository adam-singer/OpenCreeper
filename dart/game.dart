part of creeper;

class World {
  List tiles;
  Vector size;
  List terraform;
  
  World(int seed) {
    this.size = new Vector(Helper.randomInt(64, 127, seed), Helper.randomInt(64, 127, seed));
  }
}

class Game {
  int seed, tileSize = 16, currentEnergy = 0, maxEnergy = 0, collection = 0, activeSymbol = -1, terraformingHeight = 0;
  num speed = 1, zoom = 1, creeperTimer = 0, energyTimer = 0, spawnTimer = 0, damageTimer = 0, smokeTimer = 0, explosionTimer = 0, shieldTimer = 0, packetSpeed = 1, shellSpeed = 1, sporeSpeed = 1, buildingSpeed = .5, shipSpeed = 1;
  var running;
  String mode;
  bool paused = false, scrollingUp = false, scrollingDown = false, scrollingLeft = false, scrollingRight = false;
  List<Vector> ghosts = new List<Vector>();
  List<Packet> packetQueue = new List<Packet>();
  List<Sporetower> sporetowers = new List<Sporetower>();
  List<Emitter> emitters = new List<Emitter>();
  List<UISymbol> symbols = new List<UISymbol>();
  List<Explosion> explosions = new List<Explosion>();
  List<Smoke> smokes = new List<Smoke>();
  List<Spore> spores = new List<Spore>();
  List<Building> buildings = new List<Building>();
  List<Packet> packets = new List<Packet>();
  List<Shell> shells = new List<Shell>();
  List<Ship> ships = new List<Ship>();
  World world;
  Vector scroll = new Vector(0, 0);
  Building base;
  Map keyMap = {
      "k81": "Q", "k87": "W", "k69": "E", "k82": "R", "k84": "T", "k90": "Z", "k85": "U", "k73": "I", "k65": "A", "k83": "S", "k68": "D", "k70": "F", "k71": "G", "k72": "H"
  };
  Stopwatch stopwatch = new Stopwatch();

  Game() {
    this.seed = 0; //Helper.randomInt(0, 10000);
    this.world = new World(this.seed);
    this.init();
    this.drawTerrain();
    this.copyTerrain();
  }

  void init() {
    this.buildings = [];
    this.packets = [];
    this.shells = [];
    this.spores = [];
    this.ships = [];
    this.smokes = [];
    this.explosions = [];
    this.symbols = [];
    this.emitters = [];
    this.sporetowers = [];
    this.packetQueue = [];
    this.reset();
    this.setupUI();
    //engine.sounds["music"].loop = true;
    //engine.sounds["music"].play();
  }

  void reset() {
    this.stopwatch.reset();
    this.stopwatch.start();
    var oneSecond = new Duration(seconds:1);
    new Timer.periodic(oneSecond, this.updateTime);
    query('#lose').style.display = 'none';
    query('#win').style.display = 'none';

    this.mode = "DEFAULT";
    this.buildings.clear();
    this.packets.clear();
    this.shells.clear();
    this.spores.clear();
    this.ships.clear();
    this.smokes.clear();
    this.explosions.clear();
    //this.symbols.length = 0;
    this.emitters.clear();
    this.sporetowers.clear();
    this.packetQueue.clear();

    this.maxEnergy = 20;
    this.currentEnergy = 20;
    this.collection = 0;

    this.creeperTimer = 0;
    this.energyTimer = 0;
    this.spawnTimer = 0;
    this.damageTimer = 0;
    this.smokeTimer = 0;
    this.explosionTimer = 0;
    this.shieldTimer = 0;

    this.packetSpeed = 3;
    this.shellSpeed = 1;
    this.sporeSpeed = 1;
    this.buildingSpeed = .5;
    this.shipSpeed = 1;
    this.speed = 1;
    this.activeSymbol = -1;
    this.updateEnergyElement();
    this.updateSpeedElement();
    this.updateZoomElement();
    this.updateCollectionElement();
    this.clearSymbols();
    this.createWorld();
  }
  
  void updateTime(Timer _) {
    var s = game.stopwatch.elapsedMilliseconds~/1000;
    var m = 0;
    
    if (s >= 60) { m = s ~/ 60; s = s % 60; }
    
    String minute = (m <= 9) ? '0$m' : '$m';
    String second = (s <= 9) ? '0$s' : '$s';
    query('#time').innerHtml = 'Time: $minute:$second';
  }

  /**
   * Checks if the given position is within the world
   *
   * @param   {int}   x
   * @param   {int}   y
   * @return  {Boolean}   boolean
   */

  bool withinWorld(num x, num y) {
    return (x > -1 && x < this.world.size.x && y > -1 && y < this.world.size.y);
  }

  // Returns the position of the tile the mouse is hovering above
  Vector getHoveredTilePosition() {
    return new Vector(((engine.mouse.x - engine.halfWidth) / (this.tileSize * this.zoom)).floor() + this.scroll.x, ((engine.mouse.y - engine.halfHeight) / (this.tileSize * this.zoom)).floor() + this.scroll.y);
  }

  /**
   * @param {Vector} pVector The position of the tile to check
   */

  int getHighestTerrain(pVector) {
    int height = -1;
    for (int i = 9; i > -1; i--) {
      if (this.world.tiles[pVector.x][pVector.y][i].full) {
        height = i;
        break;
      }
    }
    return height;
  }

  void pause() {
    query('#pause').style.display = 'none';
    query('#resume').style.display = 'inline';
    query('#paused').style.display = 'block';
    this.paused = true;
    this.stopwatch.stop();
  }

  void resume() {
    query('#pause').style.display = 'inline';
    query('#resume').style.display = 'none';
    query('#paused').style.display = 'none';
    this.paused = false;
    this.stopwatch.start();
  }

  void stop() {
    this.running.cancel();
  }

  void run() {
    this.running = new Timer.periodic(new Duration(milliseconds: (1000 / this.speed / engine.FPS).floor()), (Timer timer) => this.updateAll());
    engine.animationRequest = window.requestAnimationFrame(this.draw);
  }
  
  void updateAll() {
    //engine.update();
    game.update();
  }

  void restart() {
    this.stop();
    this.reset();
    this.run();
  }

  void toggleTerraform() {
    if (this.mode == "TERRAFORM") {
      this.mode = "DEFAULT";
      query("#terraform").attributes['value'] = "Terraform Off";
    } else {
      this.mode = "TERRAFORM";
      query("#terraform").attributes['value'] = "Terraform On";
    }
  }

  void faster() {
    query('#slower').style.display = 'inline';
    query('#faster').style.display = 'none';
    if (this.speed < 2) {
      this.speed *= 2;
      this.stop();
      this.run();
      this.updateSpeedElement();
    }
  }

  void slower() {
    query('#slower').style.display = 'none';
    query('#faster').style.display = 'inline';
    if (this.speed > 1) {
      this.speed /= 2;
      this.stop();
      this.run();
      this.updateSpeedElement();
    }
  }

  void zoomIn() {
    if (this.zoom < 1.6) {
      this.zoom += .2;
      this.zoom = double.parse(this.zoom.toStringAsFixed(2));
      this.copyTerrain();
      this.drawCollection();
      this.drawCreeper();
      this.updateZoomElement();
    }
  }

  void zoomOut() {
    if (this.zoom > .4) {
      this.zoom -= .2;
      this.zoom = double.parse(this.zoom.toStringAsFixed(2));
      this.copyTerrain();
      this.drawCollection();
      this.drawCreeper();
      this.updateZoomElement();
    }
  }

  void createWorld() {
    this.world.tiles = new List(this.world.size.x);
    this.world.terraform = new List(this.world.size.x);
    for (int i = 0; i < this.world. size.x; i++) {
      this.world.tiles[i] = new List(this.world.size.y);
      this.world.terraform[i] = new List(this.world.size.y);
      for (int j = 0; j < this.world.size.y; j++) {
        this.world.tiles[i][j] = [];
        for (int k = 0; k < 10; k++) {
          this.world.tiles[i][j].add(new Tile());
        }
        this.world.terraform[i][j] = {
            "target": -1, "progress": 0
        };
      }
    }

    var heightmap = new HeightMap(this.seed, 129, 0, 90);
    heightmap.run();

    for (int i = 0; i < this.world.size.x; i++) {
      for (int j = 0; j < this.world.size.y; j++) {
        int height = (heightmap.map[i][j] / 10).round();
        if (height > 10)
          height = 10;
        for (int k = 0; k < height; k++) {
          this.world.tiles[i][j][k].full = true;
        }
      }
    }

    // create base
    Vector randomPosition = new Vector(
        Helper.randomInt(0, this.world.size.x - 9, this.seed + 1),
        Helper.randomInt(0, this.world.size.y - 9, this.seed + 1));

    this.scroll.x = randomPosition.x + 4;
    this.scroll.y = randomPosition.y + 4;

    Building building = new Building(randomPosition, "base");
    building.health = 40;
    building.maxHealth = 40;
    building.built = true;
    building.size = 9;
    this.buildings.add(building);
    this.base = building;

    int height = this.getHighestTerrain(new Vector(building.position.x + 4, building.position.y + 4));
    if (height < 0)height = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        for (int k = 0; k < 10; k++) {
          this.world.tiles[building.position.x + i][building.position.y + j][k].full = (k <= height);
        }
      }
    }

    this.calculateCollection();

    // create emitter
    randomPosition = new Vector(
        Helper.randomInt(0, this.world.size.x - 3, this.seed + 2),
        Helper.randomInt(0, this.world.size.y - 3, this.seed + 2));

    Emitter emitter = new Emitter(randomPosition, 5);
    this.emitters.add(emitter);

    height = this.getHighestTerrain(new Vector(emitter.position.x + 1, emitter.position.y + 1));
    if (height < 0)height = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 10; k++) {
          this.world.tiles[emitter.position.x + i][emitter.position.y + j][k].full = (k <= height);
        }
      }
    }

    // create sporetower
    randomPosition = new Vector(
        Helper.randomInt(0, this.world.size.x - 3, this.seed + 3),
        Helper.randomInt(0, this.world.size.y - 3, this.seed + 3));

    Sporetower sporetower = new Sporetower(randomPosition);
    sporetower.reset();
    this.sporetowers.add(sporetower);

    height = this.getHighestTerrain(new Vector(sporetower.position.x + 1, sporetower.position.y + 1));
    if (height < 0)height = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 10; k++) {
          this.world.tiles[sporetower.position.x + i][sporetower.position.y + j][k].full = (k <= height);
        }
      }
    }

  }

  /**
     * @param {Vector} position The position of the new building
     * @param {String} type The type of the new building
     */

  void addBuilding(Vector position, String type) {
    Building building = new Building(position, type);
    building.health = 0;

    if (building.imageID == "analyzer") {
      building.maxHealth = 5;
      building.maxEnergy = 20;
      building.energy = 0;
      building.size = 3;
      building.canMove = true;
      building.needsEnergy = true;
      building.weaponRadius = 10;
    }
    if (building.imageID == "terp") {
      building.maxHealth = 5; //60
      building.maxEnergy = 20;
      building.energy = 0;
      building.size = 3;
      building.canMove = true;
      building.needsEnergy = true;
      building.weaponRadius = 12;
    }
    if (building.imageID == "shield") {
      building.maxHealth = 5; //75
      building.maxEnergy = 20;
      building.energy = 0;
      building.size = 3;
      building.canMove = true;
      building.needsEnergy = true;
    }
    if (building.imageID == "bomber") {
      building.maxHealth = 5; // 75
      building.maxEnergy = 15;
      building.energy = 0;
      building.size = 3;
      building.needsEnergy = true;
    }
    if (building.imageID == "storage") {
      building.maxHealth = 8;
      building.size = 3;
    }
    if (building.imageID == "reactor") {
      building.maxHealth = 50;
      building.size = 3;
    }
    if (building.imageID == "collector") {
      building.maxHealth = 5;
      building.size = 3;
    }
    if (building.imageID == "relay") {
      building.maxHealth = 10;
      building.size = 3;
    }
    if (building.imageID == "cannon") {
      building.maxHealth = 25;
      building.maxEnergy = 40;
      building.energy = 0;
      building.weaponRadius = 8;
      building.canMove = true;
      building.needsEnergy = true;
      building.size = 3;
    }
    if (building.imageID == "mortar") {
      building.maxHealth = 40;
      building.maxEnergy = 20;
      building.energy = 0;
      building.weaponRadius = 12;
      building.canMove = true;
      building.needsEnergy = true;
      building.size = 3;
    }
    if (building.imageID == "beam") {
      building.maxHealth = 20;
      building.maxEnergy = 10;
      building.energy = 0;
      building.weaponRadius = 12;
      building.canMove = true;
      building.needsEnergy = true;
      building.size = 3;
    }

    this.buildings.add(building);
  }

  /**
     * @param {Building} building The building to remove
     */

  void removeBuilding(Building building) {

    // only explode building when it has been built
    if (building.built) {
      this.explosions.add(new Explosion(building.getCenter()));
      engine.playSound("explosion", building.position);
    }

    if (building.imageID == "base") {
      query('#lose').style.display = "block";
      this.stopwatch.stop();
      this.stop();
    }
    if (building.imageID == "collector") {
      this.updateCollection(building, "remove");
    }
    if (building.imageID == "storage") {
      this.maxEnergy -= 10;
      this.updateEnergyElement();
    }
    if (building.imageID == "speed") {
      this.packetSpeed /= 1.01;
    }

    // find all packets with this building as target and remove them
    for (int i = this.packets.length - 1; i >= 0; i--) {
      if (this.packets[i].currentTarget == building || this.packets[i].target == building) {
        this.packets.removeAt(i);
      }
    }
    for (int i = this.packetQueue.length - 1; i >= 0; i--) {
      if (this.packetQueue[i].currentTarget == building || this.packetQueue[i].target == building) {
        this.packetQueue.removeAt(i);
      }
    }

    int index = this.buildings.indexOf(building);
    this.buildings.removeAt(index);
  }

  void activateBuilding() {
    for (int i = 0; i < this.buildings.length; i++) {
      if (this.buildings[i].selected)this.buildings[i].active = true;
    }
  }

  void deactivateBuilding() {
    for (int i = 0; i < this.buildings.length; i++) {
      if (this.buildings[i].selected)this.buildings[i].active = false;
    }
  }

  void updateEnergyElement() {
    query('#energy').innerHtml = "Energy: ${this.currentEnergy.toString()}/${this.maxEnergy.toString()}";
  }

  void updateSpeedElement() {
    query("#speed").innerHtml = "Speed: ${this.speed.toString()}x";
  }

  void updateZoomElement() {
    query("#speed").innerHtml = "Zoom: ${this.zoom.toString()}x";
  }

  void updateCollectionElement() {
    query('#collection').innerHtml = "Collection: ${this.collection.toString()}";
  }

  void clearSymbols() {
    this.activeSymbol = -1;
    for (int i = 0; i < this.symbols.length; i++)
      this.symbols[i].active = false;
    engine.canvas["main"].element.style.cursor = "default";
  }

  void setupUI() {
    this.symbols.add(new UISymbol(new Vector(0, 0), "cannon", "Q", 3, 25, 8));
    this.symbols.add(new UISymbol(new Vector(81, 0), "collector", "W", 3, 5, 6));
    this.symbols.add(new UISymbol(new Vector(2 * 81, 0), "reactor", "E", 3, 50, 0));
    this.symbols.add(new UISymbol(new Vector(3 * 81, 0), "storage", "R", 3, 8, 0));
    this.symbols.add(new UISymbol(new Vector(4 * 81, 0), "shield", "T", 3, 50, 10));
    this.symbols.add(new UISymbol(new Vector(5 * 81, 0), "analyzer", "Z", 3, 80, 10));

    this.symbols.add(new UISymbol(new Vector(0, 56), "relay", "A", 3, 10, 8));
    this.symbols.add(new UISymbol(new Vector(81, 56), "mortar", "S", 3, 40, 12));
    this.symbols.add(new UISymbol(new Vector(2 * 81, 56), "beam", "D", 3, 20, 12));
    this.symbols.add(new UISymbol(new Vector(3 * 81, 56), "bomber", "F", 3, 75, 0));
    this.symbols.add(new UISymbol(new Vector(4 * 81, 56), "terp", "G", 3, 60, 12));
  }

  void drawTerrain() {
    for (int i = 0; i < 10; i++) {
      engine.canvas["level$i"].clear();
    }

    // 1st pass - draw masks
    for (int i = 0; i < this.world.size.x; i++) {
      for (int j = 0; j < this.world.size.y; j++) {
        for (int k = 9; k > -1; k--) {

          if (this.world.tiles[i][j][k].full) {

            // calculate index
            int up = 0, down = 0, left = 0, right = 0;
            if (j - 1 < 0)up = 0; else if (this.world.tiles[i][j - 1][k].full)up = 1;
            if (j + 1 > this.world.size.y - 1)down = 0; else if (this.world.tiles[i][j + 1][k].full)down = 1;
            if (i - 1 < 0)left = 0; else if (this.world.tiles[i - 1][j][k].full)left = 1;
            if (i + 1 > this.world.size.x - 1)right = 0; else if (this.world.tiles[i + 1][j][k].full)right = 1;

            // save index for later use
            this.world.tiles[i][j][k].index = (8 * down) + (4 * left) + (2 * up) + right;

            int index = this.world.tiles[i][j][k].index;

            // skip tiles that are identical to the one above
            if (k + 1 < 10 && index == this.world.tiles[i][j][k + 1].index)
              continue;

            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);

            // don't draw anymore under tiles that don't have transparent parts
            //if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
          }
        }
      }
    }

    // 2nd pass - draw textures
    for (int i = 0; i < 10; i++) {
      CanvasPattern  pattern = engine.canvas["level$i"].context.createPattern(engine.images["level$i"], 'repeat');
      engine.canvas["level$i"].context.globalCompositeOperation = 'source-in';
      engine.canvas["level$i"].context.fillStyle = pattern;
      engine.canvas["level$i"].context.fillRect(0, 0, engine.canvas["level$i"].element.width, engine.canvas["level$i"].element.height);
      engine.canvas["level$i"].context.globalCompositeOperation = 'source-over';
    }

    // 3rd pass - draw borders
    for (int i = 0; i < this.world.size.x; i++) {
      for (int j = 0; j < this.world.size.y; j++) {
        for (int k = 9; k > -1; k--) {

          if (this.world.tiles[i][j][k].full) {

            int index = this.world.tiles[i][j][k].index;

            if (k + 1 < 10 && index == this.world.tiles[i][j][k + 1].index)continue;

            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["borders"], index * (this.tileSize + 6) + 2, 2, this.tileSize + 2, this.tileSize + 2, i * this.tileSize, j * this.tileSize, (this.tileSize + 2), (this.tileSize + 2));

            if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
          }
        }
      }
    }

    engine.canvas["levelbuffer"].clear();
    for (int k = 0; k < 10; k++) {
      engine.canvas["levelbuffer"].context.drawImage(engine.canvas["level$k"].element, 0, 0);
    }
    query('#loading').style.display = 'none';
  }

  void copyTerrain() {
    engine.canvas["levelfinal"].clear();

    Vector delta = new Vector(0,0);
    var left = this.scroll.x * this.tileSize - (engine.width / 2) * (1 / this.zoom);
    var top = this.scroll.y * this.tileSize - (engine.height / 2) * (1 / this.zoom);
    if (left < 0) {
      delta.x = -left * this.zoom;
      left = 0;
    }
    if (top < 0) {
      delta.y = -top * this.zoom;
      top = 0;
    }

    Vector delta2 = new Vector(0, 0);
    var width = engine.width * (1 / this.zoom);
    var height = engine.height * (1 / this.zoom);
    if (left + width > this.world.size.x * this.tileSize) {
      delta2.x = (left + width - this.world.size.x * this.tileSize) * this.zoom;
      width = this.world.size.x * this.tileSize - left;
    }
    if (top + height > this.world.size.y * this.tileSize) {
      delta2.y = (top + height - this.world.size.y * this.tileSize) * this.zoom;
      height = this.world.size.y * this.tileSize - top ;
    }

    engine.canvas["levelfinal"].context.drawImageScaledFromSource(engine.canvas["levelbuffer"].element, left, top, width, height, delta.x, delta.y, engine.width - delta2.x, engine.height - delta2.y);
  }

  /**
     * @param {List} tilesToRedraw An array of tiles to redraw
     */

  void redrawTile(List tilesToRedraw) {
    List tempCanvas = [];
    List tempContext = [];
    for (int t = 0; t < 10; t++) {
      tempCanvas.add(new CanvasElement());
      tempCanvas[t].width = this.tileSize;
      tempCanvas[t].height = this.tileSize;
      tempContext.add(tempCanvas[t].getContext('2d'));
    }

    for (int i = 0; i < tilesToRedraw.length; i++) {

      int iS = tilesToRedraw[i].x;
      int jS = tilesToRedraw[i].y;
      int k = tilesToRedraw[i].z;

      // recalculate index
      if (this.world.tiles[iS][jS][k].full) {

        int up = 0, down = 0, left = 0, right = 0;
        if (jS - 1 < 0)up = 0; else if (this.world.tiles[iS][jS - 1][k].full)up = 1;
        if (jS + 1 > this.world.size.y - 1)down = 0; else if (this.world.tiles[iS][jS + 1][k].full)down = 1;
        if (iS - 1 < 0)left = 0; else if (this.world.tiles[iS - 1][jS][k].full)left = 1;
        if (iS + 1 > this.world.size.x - 1)right = 0; else if (this.world.tiles[iS + 1][jS][k].full)right = 1;

        // save index for later use
        this.world.tiles[iS][jS][k].index = (8 * down) + (4 * left) + (2 * up) + right;
      } else
        this.world.tiles[iS][jS][k].index = -1;

      // redraw mask
      for (int t = 9; t > -1; t--) {
        tempContext[t].clearRect(0, 0, this.tileSize, this.tileSize);

        if (this.world.tiles[iS][jS][t].full) {
          int index = this.world.tiles[iS][jS][t].index;

          // skip tiles that are identical to the one above
          if (t + 1 < 10 && index == this.world.tiles[iS][jS][t + 1].index)
            continue;

          tempContext[t].drawImageScaledFromSource(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 0, 0, this.tileSize, this.tileSize);

          // don't draw anymore under tiles that don't have transparent parts
          if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
        }
      }

      // redraw pattern
      for (int t = 9; t > -1; t--) {

        if (this.world.tiles[iS][jS][t].full) {
          var pattern = tempContext[t].createPattern(engine.images["level$t"], 'repeat');

          tempContext[t].globalCompositeOperation = 'source-in';
          tempContext[t].fillStyle = pattern;

          tempContext[t].save();
          Vector translation = new Vector((iS * this.tileSize).floor(), (jS * this.tileSize).floor());
          tempContext[t].translate(-translation.x, -translation.y);

          //tempContext[t].fill();
          tempContext[t].fillRect(translation.x, translation.y, this.tileSize, this.tileSize);
          tempContext[t].restore();

          tempContext[t].globalCompositeOperation = 'source-over';
        }
      }

      // redraw borders
      for (int t = 9; t > -1; t--) {
        if (this.world.tiles[iS][jS][t].full) {
          int index = this.world.tiles[iS][jS][t].index;

          if (index < 0 || (t + 1 < 10 && index == this.world.tiles[iS][jS][t + 1].index))continue;

          tempContext[t].drawImageScaledFromSource(engine.images["borders"], index * (this.tileSize + 6) + 2, 2, this.tileSize + 2, this.tileSize + 2, 0, 0, (this.tileSize + 2), (this.tileSize + 2));

          if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
        }
      }

      engine.canvas["levelbuffer"].context.clearRect(iS * this.tileSize, jS * this.tileSize, this.tileSize, this.tileSize);
      for (int t = 0; t < 10; t++) {
        engine.canvas["levelbuffer"].context.drawImageScaledFromSource(tempCanvas[t], 0, 0, this.tileSize, this.tileSize, iS * this.tileSize, jS * this.tileSize, this.tileSize, this.tileSize);
      }
    }
    this.copyTerrain();
  }

  void checkOperating() {
    for (int t = 0; t < this.buildings.length; t++) {
      this.buildings[t].operating = false;
      if (this.buildings[t].needsEnergy && this.buildings[t].active && !this.buildings[t].moving) {

        this.buildings[t].energyTimer++;
        Vector position = this.buildings[t].position;
        Vector center = this.buildings[t].getCenter();

        if (this.buildings[t].imageID == "analyzer" && this.buildings[t].energy > 0) {
          // find emitter
          if (this.buildings[t].weaponTargetPosition == null) {
            for (int i = 0; i < this.emitters.length; i++) {
              Vector emitterCenter = this.emitters[i].getCenter();
              
              num distance = pow(emitterCenter.x - center.x, 2) + pow(emitterCenter.y - center.y, 2);

              if (distance <= pow(this.buildings[t].weaponRadius * this.tileSize, 2)) {
                if (this.emitters[i].building == null) {
                  this.emitters[i].building = this.buildings[t];
                  this.buildings[t].weaponTargetPosition = this.emitters[i].position;
                  break;
                }
              }
                
            }
          }
          else {
            if (this.buildings[t].energyTimer > 20) {
              this.buildings[t].energyTimer = 0;
              this.buildings[t].energy -= 1;
            }
  
            this.buildings[t].operating = true;
          }
        }
        
        if (this.buildings[t].imageID == "terp" && this.buildings[t].energy > 0) {
          // find lowest target
          if (this.buildings[t].weaponTargetPosition == null) {

            // find lowest tile
            Vector target = null;
            int lowestTile = 10;
            for (int i = position.x - this.buildings[t].weaponRadius; i <= position.x + this.buildings[t].weaponRadius; i++) {
              for (int j = position.y - this.buildings[t].weaponRadius; j <= position.y + this.buildings[t].weaponRadius; j++) {

                if (this.withinWorld(i, j)) {
                  var distance = pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);
                  var tileHeight = this.getHighestTerrain(new Vector(i, j));

                  if (distance <= pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.terraform[i][j]["target"] > -1 && tileHeight <= lowestTile) {
                    lowestTile = tileHeight;
                    target = new Vector(i, j);
                  }
                }
              }
            }
            if (target != null) {
              this.buildings[t].weaponTargetPosition = target;
            }
          } else {
            if (this.buildings[t].energyTimer > 20) {
              this.buildings[t].energyTimer = 0;
              this.buildings[t].energy -= 1;
            }

            this.buildings[t].operating = true;
            var terraformElement = this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y];
            terraformElement["progress"] += 1;
            if (terraformElement["progress"] == 100) {
              terraformElement["progress"] = 0;

              int height = this.getHighestTerrain(this.buildings[t].weaponTargetPosition);
              List tilesToRedraw = new List();

              if (height < terraformElement["target"]) {
                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height + 1].full = true;
                // reset index around tile
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y, height + 1));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x - 1, this.buildings[t].weaponTargetPosition.y, height + 1));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y - 1, height + 1));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x + 1, this.buildings[t].weaponTargetPosition.y, height + 1));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y + 1, height + 1));
              } else {
                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height].full = false;
                // reset index around tile
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y, height));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x - 1, this.buildings[t].weaponTargetPosition.y, height));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y - 1, height));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x + 1, this.buildings[t].weaponTargetPosition.y, height));
                tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x, this.buildings[t].weaponTargetPosition.y + 1, height));
              }

              this.redrawTile(tilesToRedraw);

              height = this.getHighestTerrain(this.buildings[t].weaponTargetPosition);
              if (height == terraformElement["target"]) {
                this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y]["progress"] = 0;
                this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y]["target"] = -1;
              }

              this.buildings[t].weaponTargetPosition = null;
              this.buildings[t].operating = false;
            }
          }
        }

        else if (this.buildings[t].imageID == "shield" && this.buildings[t].energy > 0) {
          if (this.buildings[t].energyTimer > 20) {
            this.buildings[t].energyTimer = 0;
            this.buildings[t].energy -= 1;
          }
          this.buildings[t].operating = true;
        }

        else if (this.buildings[t].imageID == "cannon" && this.buildings[t].energy > 0 && this.buildings[t].energyTimer > 10) {
            this.buildings[t].energyTimer = 0;

            int height = this.getHighestTerrain(this.buildings[t].position);

            // find closest random target
            for (int r = 0; r < this.buildings[t].weaponRadius + 1; r++) {
              List targets = new List();
              int radius = r * this.tileSize;
              for (int i = position.x - this.buildings[t].weaponRadius; i <= position.x + this.buildings[t].weaponRadius; i++) {
                for (int j = position.y - this.buildings[t].weaponRadius; j <= position.y + this.buildings[t].weaponRadius; j++) {

                  // cannons can only shoot at tiles not higher than themselves
                  if (this.withinWorld(i, j)) {
                    int tileHeight = this.getHighestTerrain(new Vector(i, j));
                    if (tileHeight <= height) {
                      var distance = pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                      if (distance <= pow(radius, 2) && this.world.tiles[i][j][0].creep > 0) {
                        targets.add(new Vector(i, j));
                      }
                    }
                  }
                }
              }
              if (targets.length > 0) {
                Helper.shuffle(targets);

                this.world.tiles[targets[0].x][targets[0].y][0].creep -= 10;
                if (this.world.tiles[targets[0].x][targets[0].y][0].creep < 0)
                  this.world.tiles[targets[0].x][targets[0].y][0].creep = 0;

                var dx = targets[0].x * this.tileSize + this.tileSize / 2 - center.x;
                var dy = targets[0].y * this.tileSize + this.tileSize / 2 - center.y;
                this.buildings[t].targetAngle = atan2(dy, dx) + PI / 2;
                this.buildings[t].weaponTargetPosition = new Vector(targets[0].x, targets[0].y);
                this.buildings[t].energy -= 1;
                this.buildings[t].operating = true;
                this.smokes.add(new Smoke(new Vector(targets[0].x * this.tileSize + this.tileSize / 2, targets[0].y * this.tileSize + this.tileSize / 2)));
                engine.playSound("laser", position);
                break;
              }
            }
          }

          else if (this.buildings[t].imageID == "mortar" && this.buildings[t].energy > 0 && this.buildings[t].energyTimer > 200) {
              this.buildings[t].energyTimer = 0;

              // find most creep in range
              Vector target = null;
              var highestCreep = 0;
              for (int i = position.x - this.buildings[t].weaponRadius; i <= position.x + this.buildings[t].weaponRadius; i++) {
                for (int j = position.y - this.buildings[t].weaponRadius; j <= position.y + this.buildings[t].weaponRadius; j++) {
                  if (this.withinWorld(i, j)) {
                    var distance = pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);
  
                    if (distance <= pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.tiles[i][j][0].creep > 0 && this.world.tiles[i][j][0].creep >= highestCreep) {
                      highestCreep = this.world.tiles[i][j][0].creep;
                      target = new Vector(i, j);
                    }
                  }
                }
              }
              if (target != null) {
                engine.playSound("shot", position);
                Shell shell = new Shell(center, "shell", new Vector(target.x * this.tileSize + this.tileSize / 2, target.y * this.tileSize + this.tileSize / 2));
                shell.init();
                this.shells.add(shell);
                this.buildings[t].energy -= 1;
              }
            }

            else if (this.buildings[t].imageID == "beam" && this.buildings[t].energy > 0 && this.buildings[t].energyTimer > 0) {
                this.buildings[t].energyTimer = 0;

                // find spore in range
                for (int i = 0; i < this.spores.length; i++) {
                  Vector sporeCenter = this.spores[i].getCenter();
                  var distance = pow(sporeCenter.x - center.x, 2) + pow(sporeCenter.y - center.y, 2);

                  if (distance <= pow(this.buildings[t].weaponRadius * this.tileSize, 2)) {
                    this.buildings[t].weaponTargetPosition = sporeCenter;
                    this.buildings[t].energy -= .1;
                    this.buildings[t].operating = true;
                    this.spores[i].health -= 2;
                    if (this.spores[i].health <= 0) {
                      this.spores[i].remove = true;
                      engine.playSound("explosion", Helper.real2tiled(this.spores[i].position));
                      this.explosions.add(new Explosion(sporeCenter));
                    }
                  }
                }
              }
      }
    }
  }

  /**
     * @param {Building} building The building to update
     * @param {String} action Add or Remove action
     */

  void updateCollection(Building building, String action) {
    int height = this.getHighestTerrain(building.position);
    Vector centerBuilding = building.getCenter();

    for (int i = -5; i < 7; i++) {
      for (int j = -5; j < 7; j++) {

        Vector positionCurrent = new Vector(building.position.x + i, building.position.y + j);

        if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
          Vector positionCurrentCenter = new Vector(positionCurrent.x * this.tileSize + (this.tileSize / 2), positionCurrent.y * this.tileSize + (this.tileSize / 2));
          int tileHeight = this.getHighestTerrain(positionCurrent);

          if (action == "add") {
            if (pow(positionCurrentCenter.x - centerBuilding.x, 2) + pow(positionCurrentCenter.y - centerBuilding.y, 2) < pow(this.tileSize * 6, 2)) {
              if (tileHeight == height) {
                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = building;
              }
            }
          } else if (action == "remove") {

            if (pow(positionCurrentCenter.x - centerBuilding.x, 2) + pow(positionCurrentCenter.y - centerBuilding.y, 2) < pow(this.tileSize * 6, 2)) {
              if (tileHeight == height) {
                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = null;
              }
            }

            for (int k = 0; k < this.buildings.length; k++) {
              if (this.buildings[k] != building && this.buildings[k].imageID == "collector") {
                int heightK = this.getHighestTerrain(new Vector(this.buildings[k].position.x, this.buildings[k].position.y));
                Vector centerBuildingK = this.buildings[k].getCenter();
                if (pow(positionCurrentCenter.x - centerBuildingK.x, 2) + pow(positionCurrentCenter.y - centerBuildingK.y, 2) < pow(this.tileSize * 6, 2)) {
                  if (tileHeight == heightK) {
                    this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = this.buildings[k];
                  }
                }
              }
            }
          }

        }

      }
    }

    this.drawCollection();

    this.calculateCollection();
  }

  void calculateCollection() {
    this.collection = 0;

    for (int i = 0; i < this.world.size.x; i++) {
      for (int j = 0; j < this.world.size.y; j++) {
        for (int k = 0; k < 10; k++) {
          if (this.world.tiles[i][j][k].collector != null)this.collection += 1;
        }
      }
    }

    // decrease collection of collectors
    this.collection = (this.collection * .1).floor();

    for (int t = 0; t < this.buildings.length; t++) {
      if (this.buildings[t].imageID == "reactor" || this.buildings[t].imageID == "base") {
        this.collection += 1;
      }
    }

    this.updateCollectionElement();
  }

  void updateCreeper() {
    for (int i = 0; i < this.sporetowers.length; i++)
      this.sporetowers[i].update();

    this.spawnTimer++;
    if (this.spawnTimer >= (25 / this.speed)) { // 125
      for (int i = 0; i < this.emitters.length; i++)
        this.emitters[i].spawn();
      this.spawnTimer = 0;
    }

    num minimum = .01;

    this.creeperTimer++;
    if (this.creeperTimer > (25 / this.speed)) {
      this.creeperTimer -= (25 / this.speed);

      for (int i = 0; i < this.world.size.x; i++) {
        for (int j = 0; j < this.world.size.y; j++) {
          this.world.tiles[i][j][0].newcreep = this.world.tiles[i][j][0].creep;
        }
      }

      for (int i = 0; i < this.world.size.x; i++) {
        for (int j = 0; j < this.world.size.y; j++) {

          int height = this.getHighestTerrain(new Vector(i, j));
          //if (i - 1 > -1 && i + 1 < this.world.size.x && j - 1 > -1 && j + 1 < this.world.size.y) {
            //if (height >= 0) {
            // right neighbour
            if (i + 1 < this.world.size.x) {
              int height2 = this.getHighestTerrain(new Vector(i + 1, j));
              this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i + 1][j][0]);
            }
            // bottom right neighbour
            if (i - 1 > -1) {
              int height2 = this.getHighestTerrain(new Vector(i - 1, j));
              this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i - 1][j][0]);
            }
            // bottom neighbour
            if (j + 1 < this.world.size.y) {
              int height2 = this.getHighestTerrain(new Vector(i, j + 1));
              this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i][j + 1][0]);
            }
            // bottom left neighbour
            if (j - 1 > -1) {
              int height2 = this.getHighestTerrain(new Vector(i, j - 1));
              this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i][j - 1][0]);
            }
          //}

        }
      }

      for (int i = 0; i < this.world.size.x; i++) {
        for (int j = 0; j < this.world.size.y; j++) {
          this.world.tiles[i][j][0].creep = this.world.tiles[i][j][0].newcreep;
          if (this.world.tiles[i][j][0].creep > 10)this.world.tiles[i][j][0].creep = 10;
          if (this.world.tiles[i][j][0].creep < minimum)this.world.tiles[i][j][0].creep = 0;
        }
      }

      this.drawCreeper();

    }
  }

  void transferCreeper(num height, num height2, Tile source, Tile target) {
    num transferRate = .25;

    num sourceAmount = source.creep;
    num sourceTotal = height + source.creep;

    if (height2 > -1) {
      num targetAmount = target.creep;
      if (sourceAmount > 0 || targetAmount > 0) {
        num targetTotal = height2 + target.creep;
        num delta = 0;
        if (sourceTotal > targetTotal) {
          delta = sourceTotal - targetTotal;
          if (delta > sourceAmount)delta = sourceAmount;
          num adjustedDelta = delta * transferRate;
          source.newcreep -= adjustedDelta;
          target.newcreep += adjustedDelta;
        }
    /*else {
                      delta = targetTotal - sourceTotal;
                      if (delta > targetAmount)
                          delta = targetAmount;
                      var adjustedDelta = delta * transferRate;
                      source.newcreep += adjustedDelta;
                      target.newcreep -= adjustedDelta;
                  }*/
      }
    }
  }

  /**
     * Used for A*, finds all neighbouring nodes of a given node.
     *
     * @param {Building} node The current node
     * @param {Building} target The target node
     */

  List getNeighbours(Building node, Building target) {
    List neighbours = new List();
    Vector centerI, centerNode;
    //if (node.built) {
    for (int i = 0; i < this.buildings.length; i++) {
      if (this.buildings[i].position.x == node.position.x && this.buildings[i].position.y == node.position.y) {
        // console.log("is me");
      } else {
        // if the node is not the target AND built it is a valid neighbour
        // also the neighbour must not be moving
        if (!this.buildings[i].moving) {
          // && this.buildings[i].imageID != "base") {
          if (this.buildings[i] != target) {
            if (this.buildings[i].built) {
              centerI = this.buildings[i].getCenter();
              centerNode = node.getCenter();
              num distance = Helper.distance(centerI, centerNode);

              int allowedDistance = 10 * this.tileSize;
              if (node.imageID == "relay" && this.buildings[i].imageID == "relay") {
                allowedDistance = 20 * this.tileSize;
              }
              if (distance <= allowedDistance) {
                neighbours.add(this.buildings[i]);
              }
            }
          }
          // if it is the target it is a valid neighbour
          else {
            centerI = this.buildings[i].getCenter();
            centerNode = node.getCenter();
            num distance = Helper.distance(centerI, centerNode);

            int allowedDistance = 10 * this.tileSize;
            if (node.imageID == "relay" && this.buildings[i].imageID == "relay") {
              allowedDistance = 20 * this.tileSize;
            }
            if (distance <= allowedDistance) {
              neighbours.add(this.buildings[i]);
            }
          }
        }
      }
    }
    //}
    return neighbours;
  }

  /**
     * Used for A*, checks if a node is already in a given route.
     *
     * @param {Building} neighbour The node to check
     * @param {Array} route The route to check
     */

  bool inRoute(Building neighbour, List route) {
    bool found = false;
    for (int i = 0; i < route.length; i++) {
      if (neighbour.position.x == route[i].position.x && neighbour.position.y == route[i].position.y) {
        found = true;
        break;
      }
    }
    return found;
  }

  /**
     * Main function of A*, finds a path to the target node.
     *
     * @param {Packet} packet The packet to find a path for
     */

  void findRoute(Packet packet) {
  // A* using Branch and Bound with dynamic programming and underestimates, thanks to: http://ai-depot.com/Tutorial/PathFinding-Optimal.html

    // this holds all routes
    List<Route> routes = new List<Route>();

    // create a new route and add the current node as first element
    Route route = new Route();
    route.nodes.add(packet.currentTarget);
    routes.add(route);

    /*
      As long as there is any route AND
      the last node of the route is not the end node try to get to the end node

      If there is no route the packet will be removed
     */
    while (routes.length > 0) {

      if (routes[0].nodes[routes[0].nodes.length - 1] == packet.target) {
        //console.log("6) target node found");
        break;
      }

      // remove the first route from the list of routes
      Route oldRoute = routes.removeAt(0);

      // get the last node of the route
      Building lastNode = oldRoute.nodes[oldRoute.nodes.length - 1];
      //console.log("1) currently at: " + lastNode.type + ": " + lastNode.x + "/" + lastNode.y + ", route length: " + oldRoute.nodes.length);

      // find all neighbours of this node
      List neighbours = this.getNeighbours(lastNode, packet.target);
      //console.log("2) neighbours found: " + neighbours.length);

      int newRoutes = 0;
      // extend the old route with each neighbour creating a new route each
      for (int i = 0; i < neighbours.length; i++) {

        // if the neighbour is not already in the list..
        if (!this.inRoute(neighbours[i], oldRoute.nodes)) {

          newRoutes++;

          // create new route
          Route newRoute = new Route();

          // copy current list of nodes from old route to new route
          newRoute.nodes = Helper.clone(oldRoute.nodes);

          // add the new node to the new route
          newRoute.nodes.add(neighbours[i]);

          // copy distance travelled from old route to new route
          newRoute.distanceTravelled = oldRoute.distanceTravelled;

          // increase distance travelled
          Vector centerA = newRoute.nodes[newRoute.nodes.length - 1].getCenter();
          Vector centerB = newRoute.nodes[newRoute.nodes.length - 2].getCenter();
          newRoute.distanceTravelled += Helper.distance(centerA, centerB);

          // update underestimate of distance remaining
          Vector centerC = packet.target.getCenter();
          newRoute.distanceRemaining = Helper.distance(centerC, centerA);

          // finally push the new route to the list of routes
          routes.add(newRoute);
        }

      }
      
      //console.log("3) new routes: " + newRoutes);
      //console.log("4) total routes: " + routes.length);

      // find routes that end at the same node, remove those with the longer distance travelled
      for (int i = 0; i < routes.length; i++) {
        for (int j = 0; j < routes.length; j++) {
          if (i != j) {
            if (routes[i].nodes[routes[i].nodes.length - 1] == routes[j].nodes[routes[j].nodes.length - 1]) {
              //console.log("5) found duplicate route to " + routes[i].nodes[routes[i].nodes.length - 1].type + ", removing longer");
              if (routes[i].distanceTravelled < routes[j].distanceTravelled) {
                routes[j].remove = true;
              } else if (routes[i].distanceTravelled > routes[j].distanceTravelled) {
                routes[i].remove = true;
              }

            }
          }
        }
      }
      for (int i = routes.length - 1; i >= 0; i--) {
        if (routes[i].remove)
          routes.removeAt(i);
      }

      // sort routes by total underestimate so that the possibly shortest route gets checked first
      routes.sort((Route a, Route b) {
        return (a.distanceTravelled + a.distanceRemaining) - (b.distanceTravelled + b.distanceRemaining);
      });
    }

    // if a route is left set the second element as the next node for the packet
    if (routes.length > 0) {
      // adjust speed if packet is travelling between relays
      if (routes[0].nodes[1].imageID == "relay") {
        packet.speedMultiplier = 2;
      } else {
        packet.speedMultiplier = 1;
      }

      packet.currentTarget = routes[0].nodes[1];
    } else {
      packet.currentTarget = null;
      if (packet.type == "energy") {
        packet.target.energyRequests -= 4;
        if (packet.target.energyRequests < 0)packet.target.energyRequests = 0;
      } else if (packet.type == "health") {
        packet.target.healthRequests--;
        if (packet.target.healthRequests < 0)packet.target.healthRequests = 0;
      }
      packet.remove = true;
    }
  }

  /**
     * @param {Building} building The packet target building
     * @param {String} type The type of the packet
     */

  void queuePacket(Building building, String type) {
    String img = "packet_" + type;
    Vector center = this.base.getCenter();
    Packet packet = new Packet(center, img, type);
    packet.target = building;
    packet.currentTarget = this.base;
    this.findRoute(packet);
    if (packet.currentTarget != null) {
      if (packet.type == "health")packet.target.healthRequests++;
      if (packet.type == "energy")packet.target.energyRequests += 4;
      this.packetQueue.add(packet);
    }
  }

  /**
     * Checks if a building can be placed on the current tile.
     *
     * @param {Vector} position The position to place the building
     * @param {int} size The size of the building
     * @param {Building} building The building to place
     */

  bool canBePlaced(Vector position, num size, [Building building]) {
    bool collision = false;

    if (position.x > -1 && position.x < this.world.size.x - size + 1 && position.y > -1 && position.y < this.world.size.y - size + 1) {
      int height = this.getHighestTerrain(position);

      // 1. check for collision with another building
      for (int i = 0; i < this.buildings.length; i++) {
        // don't check for collision with moving buildings
        if (this.buildings[i].moving)
          continue;
        if (building != null && building == this.buildings[i])
          continue;
        int x1 = this.buildings[i].position.x * this.tileSize;
        int x2 = this.buildings[i].position.x * this.tileSize + this.buildings[i].size * this.tileSize - 1;
        int y1 = this.buildings[i].position.y * this.tileSize;
        int y2 = this.buildings[i].position.y * this.tileSize + this.buildings[i].size * this.tileSize - 1;

        int cx1 = position.x * this.tileSize;
        int cx2 = position.x * this.tileSize + size * this.tileSize - 1;
        int cy1 = position.y * this.tileSize;
        int cy2 = position.y * this.tileSize + size * this.tileSize - 1;

        if (((cx1 >= x1 && cx1 <= x2) || (cx2 >= x1 && cx2 <= x2)) && ((cy1 >= y1 && cy1 <= y2) || (cy2 >= y1 && cy2 <= y2))) {
          collision = true;
          break;
        }
      }

      // 2. check if all tiles have the same height and are not corners
      if (!collision) {
        for (int i = position.x; i < position.x + size; i++) {
          for (int j = position.y; j < position.y + size; j++) {
            if (this.withinWorld(i, j)) {
              int tileHeight = this.getHighestTerrain(new Vector(i, j));
              if (tileHeight < 0) {
                collision = true;
                break;
              }
              if (tileHeight != height) {
                collision = true;
                break;
              }
              if (!(this.world.tiles[i][j][tileHeight].index == 7 || this.world.tiles[i][j][tileHeight].index == 11 || this.world.tiles[i][j][tileHeight].index == 13 || this.world.tiles[i][j][tileHeight].index == 14 || this.world.tiles[i][j][tileHeight].index == 15)) {
                collision = true;
                break;
              }
            }
          }
        }
      }
    } else {
      collision = true;
    }

    return (!collision);
  }

  void updatePacketQueue() {
    for (int i = this.packetQueue.length - 1; i >= 0; i--) {
      if (this.currentEnergy > 0) {
        this.currentEnergy--;
        this.updateEnergyElement();
        Packet packet = this.packetQueue.removeAt(0);
        this.packets.add(packet);
      }
    }
  }

  void updateBuildings() {
    this.checkOperating();

    // move
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].move();
    }

    // push away creeper (shield)
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].shield();
    }

    // take damage
    this.damageTimer++;
    if (this.damageTimer > 100) {
      this.damageTimer = 0;
      for (int i = 0; i < this.buildings.length; i++) {
        this.buildings[i].takeDamage();
      }
    }

    // request packets
    for (int i = 0; i < this.buildings.length; i++) {
      if (this.buildings[i].active && !this.buildings[i].moving) {
        this.buildings[i].requestTimer++;
        // request health
        if (this.buildings[i].imageID != "base") {
          num healthAndRequestDelta = this.buildings[i].maxHealth - this.buildings[i].health - this.buildings[i].healthRequests;
          if (healthAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
            this.buildings[i].requestTimer = 0;
            this.queuePacket(this.buildings[i], "health");
          }
        }
        // request energy
        if (this.buildings[i].needsEnergy && this.buildings[i].built) {
          num energyAndRequestDelta = this.buildings[i].maxEnergy - this.buildings[i].energy - this.buildings[i].energyRequests;
          if (energyAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
            this.buildings[i].requestTimer = 0;
            this.queuePacket(this.buildings[i], "energy");
          }
        }
      }
    }

  }

  void updateEnergy() {
    this.energyTimer++;
    if (this.energyTimer > (250 / this.speed)) {
      this.energyTimer -= (250 / this.speed);
      for (int k = 0; k < this.buildings.length; k++) {
        if (this.buildings[k].imageID == "collector" && this.buildings[k].built) {
          int height = this.getHighestTerrain(this.buildings[k].position);
          Vector centerBuilding = this.buildings[k].getCenter();

          for (int i = -5; i < 7; i++) {
            for (int j = -5; j < 7; j++) {
              Vector positionCurrent = new Vector(this.buildings[k].position.x + i, this.buildings[k].position.y + j);

              if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
                Vector positionCurrentCenter = new Vector(positionCurrent.x * this.tileSize + (this.tileSize / 2), positionCurrent.y * this.tileSize + (this.tileSize / 2));
                int tileHeight = this.getHighestTerrain(positionCurrent);
                
                if (pow(positionCurrentCenter.x - centerBuilding.x, 2) + pow(positionCurrentCenter.y - centerBuilding.y, 2) < pow(this.tileSize * 6, 2)) {
                  if (tileHeight == height) {
                    if (this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector == this.buildings[k])this.buildings[k].collectedEnergy += 1;
                  }
                }
              }
            }
          }
        }
      }
    }

    for (int i = 0; i < this.buildings.length; i++) {
      if (this.buildings[i].collectedEnergy >= 100) {
        this.buildings[i].collectedEnergy -= 100;
        String img = "packet_collection";
        Vector center = this.buildings[i].getCenter();
        Packet packet = new Packet(center, img, "collection");
        packet.target = this.base;
        packet.currentTarget = this.buildings[i];
        this.findRoute(packet);
        if (packet.currentTarget != null)this.packets.add(packet);
      }
    }
  }

  void updatePackets() {
    for (int i = this.packets.length - 1; i >= 0; i--) {
      if (this.packets[i].remove)
        this.packets.removeAt(i);
      else
        this.packets[i].move();
    }
  }

  void updateShells() {
    for (int i = this.shells.length - 1; i >= 0; i--) {
      if (this.shells[i].remove)
        this.shells.removeAt(i);
      else
        this.shells[i].move();
    }
  }

  void updateSpores() {
    for (int i = this.spores.length - 1; i >= 0; i--) {
      if (this.spores[i].remove)
        this.spores.removeAt(i);
      else
        this.spores[i].move();
    }
  }

  void updateSmokes() {
    this.smokeTimer++;
    if (this.smokeTimer > 3) {
      this.smokeTimer = 0;
      for (int i = this.smokes.length - 1; i >= 0; i--) {
        if (this.smokes[i].frame == 36)
          this.smokes.removeAt(i);
        else
          this.smokes[i].frame++;
      }
    }
  }

  void updateExplosions() {
    this.explosionTimer++;
    if (this.explosionTimer == 1) {
      this.explosionTimer = 0;
      for (int i = this.explosions.length - 1; i >= 0; i--) {
        if (this.explosions[i].frame == 44)
          this.explosions.removeAt(i);
        else
          this.explosions[i].frame++;
      }
    }
  }

  void updateShips() {
    // move
    for (int i = 0; i < this.ships.length; i++) {
      this.ships[i].move();
    }
  }

  void update() {
    // check for winning condition
    int emittersChecked = 0;
    for (int i = 0; i < this.emitters.length; i++) {
      if (this.emitters[i].building != null)
        emittersChecked++;
    }
    if (emittersChecked == this.emitters.length) {
      // TODO: 10 seconds countdown
      query('#win').style.display = "block";
      this.stopwatch.stop();
      this.stop();
    }  
    
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].updateHoverState();
    }
    for (int i = 0; i < this.ships.length; i++) {
      this.ships[i].updateHoverState();
    }
    if (!this.paused) {
      this.updatePacketQueue();
      this.updateShells();
      this.updateSpores();
      this.updateCreeper();
      this.updateBuildings();
      this.updateEnergy();
      this.updatePackets();
      this.updateSmokes();
      this.updateExplosions();
      this.updateShips();
    }

    // scroll left
    if (this.scrollingLeft) {
      if (this.scroll.x > 0)
        this.scroll.x -= 1;
    }

    // scroll right 
    else if (this.scrollingRight) {
      if (this.scroll.x < this.world.size.x)
        this.scroll.x += 1;
    }

    // scroll up
    if (this.scrollingUp) {
      if (this.scroll.y > 0)
        this.scroll.y -= 1;
    }

    // scroll down
    else if (this.scrollingDown) {
      if (this.scroll.y < this.world.size.y)
        this.scroll.y += 1;

    }

    if (this.scrollingLeft || this.scrollingRight || this.scrollingUp || this.scrollingDown) {
      this.copyTerrain();
      this.drawCollection();
      this.drawCreeper();
    }
  }

  /**
     * @param {Vector} position The position of the building
     * @param {String} type The type of the building
     * @param {int} radius The radius of the building
     * @param {int} size The size of the building
     */

  void drawRangeBoxes(Vector position, String type, num rad, num size) {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector positionCenter = new Vector(position.x * this.tileSize + (this.tileSize / 2) * size, position.y * this.tileSize + (this.tileSize / 2) * size);
    int positionHeight = this.getHighestTerrain(position);

    if (this.canBePlaced(position, size, null) && (type == "collector" || type == "cannon" || type == "mortar" || type == "shield" || type == "beam" || type == "terp")) {

      context.save();
      context.globalAlpha = .25;

      int radius = rad * this.tileSize;

      for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {

          Vector positionCurrent = new Vector(position.x + i, position.y + j);
          Vector positionCurrentCenter = new Vector(positionCurrent.x * this.tileSize + (this.tileSize / 2), positionCurrent.y * this.tileSize + (this.tileSize / 2));

          Vector drawPositionCurrent = Helper.tiled2screen(positionCurrent);

          if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
            int positionCurrentHeight = this.getHighestTerrain(positionCurrent);

            if (pow(positionCurrentCenter.x - positionCenter.x, 2) + pow(positionCurrentCenter.y - positionCenter.y, 2) < pow(radius, 2)) {
              if (type == "collector") {
                if (positionCurrentHeight == positionHeight) {
                  context.fillStyle = "#fff";
                } else {
                  context.fillStyle = "#f00";
                }
              }
              if (type == "cannon") {
                if (positionCurrentHeight <= positionHeight) {
                  context.fillStyle = "#fff";
                } else {
                  context.fillStyle = "#f00";
                }
              }
              if (type == "mortar" || type == "shield" || type == "beam" || type == "terp") {
                context.fillStyle = "#fff";
              }
              context.fillRect(drawPositionCurrent.x, drawPositionCurrent.y, this.tileSize * this.zoom, this.tileSize * this.zoom);
            }

          }
        }
      }
      context.restore();
    }
  }

  /**
     * Draws the green collection areas of collectors.
     */

  void drawCollection() {
    engine.canvas["collection"].clear();
    engine.canvas["collection"].context.save();
    engine.canvas["collection"].context.globalAlpha = .5;

    int timesX = (engine.halfWidth / this.tileSize / this.zoom).ceil();
    int timesY = (engine.halfHeight / this.tileSize / this.zoom).ceil();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + this.scroll.x;
        int jS = j + this.scroll.y;

        if (this.withinWorld(iS, jS)) {

          for (int k = 0 ; k < 10; k++) {
            if (this.world.tiles[iS][jS][k].collector != null) {
              int up = 0, down = 0, left = 0, right = 0;
              if (jS - 1 < 0)
                up = 0;
              else
                up = this.world.tiles[iS][jS - 1][k].collector != null ? 1 : 0;
              if (jS + 1 > this.world.size.y - 1)
                down = 0;
              else
                down = this.world.tiles[iS][jS + 1][k].collector != null ? 1 : 0;
              if (iS - 1 < 0)
                left = 0;
              else
                left = this.world.tiles[iS - 1][jS][k].collector != null ? 1 : 0;
              if (iS + 1 > this.world.size.x - 1)
                right = 0;
              else
                right = this.world.tiles[iS + 1][jS][k].collector != null ? 1 : 0;

              int index = (8 * down) + (4 * left) + (2 * up) + right;
              engine.canvas["collection"].context.drawImageScaledFromSource(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * this.zoom, engine.halfHeight + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
            }
          }
        }
      }
    }
    engine.canvas["collection"].context.restore();
  }

  void drawCreeper() {
    engine.canvas["creeper"].clear();

    int timesX = (engine.halfWidth / this.tileSize / this.zoom).ceil();
    int timesY = (engine.halfHeight / this.tileSize / this.zoom).ceil();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + this.scroll.x;
        int jS = j + this.scroll.y;

        if (this.withinWorld(iS, jS)) {

          if (this.world.tiles[iS][jS][0].creep > 0) {
            num creep = (this.world.tiles[iS][jS][0].creep).ceil();

            int up = 0, down = 0, left = 0, right = 0;
            if (jS - 1 < 0)up = 0; else if ((this.world.tiles[iS][jS - 1][0].creep).ceil() >= creep)up = 1;
            if (jS + 1 > this.world.size.y - 1)down = 0; else if ((this.world.tiles[iS][jS + 1][0].creep).ceil() >= creep)down = 1;
            if (iS - 1 < 0)left = 0; else if ((this.world.tiles[iS - 1][jS][0].creep).ceil() >= creep)left = 1;
            if (iS + 1 > this.world.size.x - 1)right = 0; else if ((this.world.tiles[iS + 1][jS][0].creep).ceil() >= creep)right = 1;

            int index = (8 * down) + (4 * left) + (2 * up) + right;
            engine.canvas["creeper"].context.drawImageScaledFromSource(engine.images["creep"], index * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * this.zoom, engine.halfHeight + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
          }

        // creep value
        //engine.canvas["buffer"].context.textAlign = 'left';
        //engine.canvas["buffer"].context.fillText((this.world.tiles[i][j].creep).floor(), i * this.tileSize + 2, j * this.tileSize + 10);
        
        // height value
        //engine.canvas["buffer"].context.textAlign = 'left';
        //engine.canvas["buffer"].context.fillText(this.world.tiles[i][j].height, i * this.tileSize + 2, j * this.tileSize + 10);
        }
      }
    }
  }

  /**
     * When a building from the GUI is selected this draws some info whether it can be build on the current tile,
     * the range as white boxes and connections to other buildings
     */

  void drawPositionInfo() {
    this.ghosts = new List(); // ghosts are all the placeholders to build
    if (engine.mouse.dragStart != null) {

      Vector start = engine.mouse.dragStart;
      Vector end = engine.mouse.dragEnd;
      Vector delta = new Vector(end.x - start.x, end.y - start.y);
      num distance = Helper.distance(start, end);
      num times = (distance / 10).floor() + 1;

      this.ghosts.add(start);

      for (int i = 1; i < times; i++) {
        num newX = (start.x + (delta.x / distance) * i * 10).floor();
        num newY = (start.y + (delta.y / distance) * i * 10).floor();

        if (this.withinWorld(newX, newY)) {
          Vector ghost = new Vector(newX, newY);
          this.ghosts.add(ghost);
        }
      }
      if (this.withinWorld(end.x, end.y)) {
        this.ghosts.add(end);
      }
    } else {
      if (engine.mouse.active) {
        Vector position = this.getHoveredTilePosition();
        if (this.withinWorld(position.x, position.y)) {
          this.ghosts.add(position);
        }
      }
    }

    for (int j = 0; j < this.ghosts.length; j++) {
      Vector positionScrolled = new Vector(this.ghosts[j].x, this.ghosts[j].y); //this.getHoveredTilePosition();
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * this.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size, positionScrolled.y * this.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size);

      this.drawRangeBoxes(positionScrolled, this.symbols[this.activeSymbol].imageID, this.symbols[this.activeSymbol].radius, this.symbols[this.activeSymbol].size);

      if (this.withinWorld(positionScrolled.x, positionScrolled.y)) {
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;

        // draw building
        engine.canvas["buffer"].context.drawImageScaled(engine.images[this.symbols[this.activeSymbol].imageID], drawPosition.x, drawPosition.y, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom);
        if (this.symbols[this.activeSymbol].imageID == "cannon")engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], drawPosition.x, drawPosition.y, 48 * this.zoom, 48 * this.zoom);

        // draw green or red box
        // make sure there isn't a building on this tile yet
        if (this.canBePlaced(positionScrolled, this.symbols[this.activeSymbol].size, null)) {
          engine.canvas["buffer"].context.strokeStyle = "#0f0";
        } else {
          engine.canvas["buffer"].context.strokeStyle = "#f00";
        }
        engine.canvas["buffer"].context.lineWidth = 4 * this.zoom;
        engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom);

        engine.canvas["buffer"].context.restore();

        // draw lines to other buildings
        for (int i = 0; i < this.buildings.length; i++) {
          Vector center = this.buildings[i].getCenter();
          Vector drawCenter = Helper.real2screen(center);

          int allowedDistance = 10 * this.tileSize;
          if (this.buildings[i].imageID == "relay" && this.symbols[this.activeSymbol].imageID == "relay") {
            allowedDistance = 20 * this.tileSize;
          }

          if (pow(center.x - positionScrolledCenter.x, 2) + pow(center.y - positionScrolledCenter.y, 2) <= pow(allowedDistance, 2)) {
            Vector lineToTarget = Helper.real2screen(positionScrolledCenter);
            engine.canvas["buffer"].context.strokeStyle = '#000';
            engine.canvas["buffer"].context.lineWidth = 2;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
            engine.canvas["buffer"].context.lineTo(lineToTarget.x, lineToTarget.y);
            engine.canvas["buffer"].context.stroke();

            engine.canvas["buffer"].context.strokeStyle = '#fff';
            engine.canvas["buffer"].context.lineWidth = 1;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
            engine.canvas["buffer"].context.lineTo(lineToTarget.x, lineToTarget.y);
            engine.canvas["buffer"].context.stroke();
          }
        }
        // draw lines to other ghosts
        for (int k = 0; k < this.ghosts.length; k++) {
          if (k != j) {
            Vector center = new Vector(this.ghosts[k].x * this.tileSize + (this.tileSize / 2) * 3, this.ghosts[k].y * this.tileSize + (this.tileSize / 2) * 3);
            Vector drawCenter = Helper.real2screen(center);

            int allowedDistance = 10 * this.tileSize;
            if (this.symbols[this.activeSymbol].imageID == "relay") {
              allowedDistance = 20 * this.tileSize;
            }

            if (pow(center.x - positionScrolledCenter.x, 2) + pow(center.y - positionScrolledCenter.y, 2) <= pow(allowedDistance, 2)) {
              Vector lineToTarget = Helper.real2screen(positionScrolledCenter);
              engine.canvas["buffer"].context.strokeStyle = '#000';
              engine.canvas["buffer"].context.lineWidth = 2;
              engine.canvas["buffer"].context.beginPath();
              engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
              engine.canvas["buffer"].context.lineTo(lineToTarget.x, lineToTarget.y);
              engine.canvas["buffer"].context.stroke();

              engine.canvas["buffer"].context.strokeStyle = '#fff';
              engine.canvas["buffer"].context.lineWidth = 1;
              engine.canvas["buffer"].context.beginPath();
              engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
              engine.canvas["buffer"].context.lineTo(lineToTarget.x, lineToTarget.y);
              engine.canvas["buffer"].context.stroke();
            }
          }
        }
      }
    }

  }

  /**
     * Draws the attack symbols of ships.
     */

  void drawAttackSymbol() {
    if (this.mode == "SHIP_SELECTED") {
      Vector position = Helper.tiled2screen(this.getHoveredTilePosition());
      engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], position.x - this.tileSize, position.y - this.tileSize);
    }
  }

  /**
     * Draws the GUI with symbols, height and creep meter.
     */

  void drawGUI() {
    CanvasRenderingContext2D context = engine.canvas["gui"].context;
    
    Vector position = this.getHoveredTilePosition();

    engine.canvas["gui"].clear();
    for (int i = 0; i < this.symbols.length; i++) {
      this.symbols[i].draw();
    }

    if (this.withinWorld(position.x, position.y)) {

      num total = this.world.tiles[position.x][position.y][0].creep;

      // draw height and creep meter
      context.fillStyle = '#fff';
      context.font = '9px';
      context.textAlign = 'right';
      context.strokeStyle = '#fff';
      context.lineWidth = 1;
      context.fillStyle = "rgba(205, 133, 63, 1)";
      context.fillRect(555, 110, 25, -this.getHighestTerrain(this.getHoveredTilePosition()) * 10 - 10);
      context.fillStyle = "rgba(100, 150, 255, 1)";
      context.fillRect(555, 110 - this.getHighestTerrain(this.getHoveredTilePosition()) * 10 - 10, 25, -total * 10);
      context.fillStyle = "rgba(255, 255, 255, 1)";
      for (int i = 1; i < 11; i++) {
        context.fillText(i.toString(), 550, 120 - i * 10);
        context.beginPath();
        context.moveTo(555, 120 - i * 10);
        context.lineTo(580, 120 - i * 10);
        context.stroke();
      }
      context.textAlign = 'left';
      context.fillText(total.toStringAsFixed(2), 605, 10);
    }
  }
  
  void draw(num _) {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    this.drawGUI();

    // clear canvas
    engine.canvas["buffer"].clear();
    engine.canvas["main"].clear();

    // draw terraform numbers
    int timesX = (engine.halfWidth / this.tileSize / this.zoom).floor();
    int timesY = (engine.halfHeight / this.tileSize / this.zoom).floor();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + this.scroll.x;
        int jS = j + this.scroll.y;

        if (this.withinWorld(iS, jS)) {
          if (this.world.terraform[iS][jS]["target"] > -1) {
            context.drawImageScaledFromSource(engine.images["numbers"], this.world.terraform[iS][jS]["target"] * 16, 0, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * this.zoom, engine.halfHeight + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
          }
        }
      }
    }

    // draw emitters
    for (int i = 0; i < this.emitters.length; i++) {
      this.emitters[i].draw();
    }

    // draw spore towers
    for (int i = 0; i < this.sporetowers.length; i++) {
      this.sporetowers[i].draw();
    }

    // draw node connections
    for (int i = 0; i < this.buildings.length; i++) {
      Vector centerI = this.buildings[i].getCenter();
      Vector drawCenterI = Helper.real2screen(centerI);
      for (int j = 0; j < this.buildings.length; j++) {
        if (i != j) {
          if (!this.buildings[i].moving && !this.buildings[j].moving) {
            Vector centerJ = this.buildings[j].getCenter();
            Vector drawCenterJ = Helper.real2screen(centerJ);

            num allowedDistance = 10 * this.tileSize;
            if (this.buildings[i].imageID == "relay" && this.buildings[j].imageID == "relay") {
              allowedDistance = 20 * this.tileSize;
            }

            if (pow(centerJ.x - centerI.x, 2) + pow(centerJ.y - centerI.y, 2) <= pow(allowedDistance, 2)) {
              context.strokeStyle = '#000';
              context.lineWidth = 3;
              context.beginPath();
              context.moveTo(drawCenterI.x, drawCenterI.y);
              context.lineTo(drawCenterJ.x, drawCenterJ.y);
              context.stroke();

              context.strokeStyle = '#fff';
              if (!this.buildings[i].built || !this.buildings[j].built)
                context.strokeStyle = '#777';
              context.lineWidth = 2;
              context.beginPath();
              context.moveTo(drawCenterI.x, drawCenterI.y);
              context.lineTo(drawCenterJ.x, drawCenterJ.y);
              context.stroke();
            }
          }
        }
      }
    }

    // draw movement indicators
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].drawMovementIndicators();
    }

    // draw buildings
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].draw();
    }

    // draw shells
    for (int i = 0; i < this.shells.length; i++) {
      this.shells[i].draw();
    }

    // draw smokes
    for (int i = 0; i < this.smokes.length; i++) {
      this.smokes[i].draw();
    }

    // draw explosions
    for (int i = 0; i < this.explosions.length; i++) {
      this.explosions[i].draw();
    }

    // draw spores
    for (int i = 0; i < this.spores.length; i++) {
      this.spores[i].draw();
    }

    if (engine.mouse.active) {

      // if a building is built and selected draw a green box and a line at mouse position as the reposition target
      for (int i = 0; i < this.buildings.length; i++) {
        this.buildings[i].drawRepositionInfo();
      }

      // draw attack symbol
      this.drawAttackSymbol();

      if (this.activeSymbol != -1) {
        this.drawPositionInfo();
      }

      if (this.mode == "TERRAFORM") {
        Vector positionScrolled = this.getHoveredTilePosition();
        Vector drawPosition = Helper.tiled2screen(positionScrolled);
        context.drawImageScaledFromSource(engine.images["numbers"], this.terraformingHeight * this.tileSize, 0, this.tileSize, this.tileSize, drawPosition.x, drawPosition.y, this.tileSize * this.zoom, this.tileSize * this.zoom);

        context.strokeStyle = '#fff';
        context.lineWidth = 1;

        context.beginPath();
        context.moveTo(0, drawPosition.y);
        context.lineTo(engine.width, drawPosition.y);
        context.stroke();

        context.beginPath();
        context.moveTo(0, drawPosition.y + this.tileSize * this.zoom);
        context.lineTo(engine.width, drawPosition.y + this.tileSize * this.zoom);
        context.stroke();

        context.beginPath();
        context.moveTo(drawPosition.x, 0);
        context.lineTo(drawPosition.x, engine.halfHeight * 2);
        context.stroke();

        context.beginPath();
        context.moveTo(drawPosition.x + this.tileSize * this.zoom, 0);
        context.lineTo(drawPosition.x + this.tileSize * this.zoom, engine.halfHeight * 2);
        context.stroke();

        context.stroke();

      }
    }

    // draw packets
    for (int i = 0; i < this.packets.length; i++) {
      this.packets[i].draw();
    }

    // draw ships
    for (int i = 0; i < this.ships.length; i++) {
      this.ships[i].draw();
    }

    // draw building hover/selection box
    for (int i = 0; i < this.buildings.length; i++) {
      this.buildings[i].drawBox();
    }

    engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element, 0, 0);

    window.requestAnimationFrame(this.draw);
  }
}