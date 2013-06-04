part of creeper;

class World {
  List tiles;
  Vector size;
  
  World(int seed) {
    size = new Vector(Helper.randomInt(64, 127, seed), Helper.randomInt(64, 127, seed));
  }
}

class Game {
  int seed, tileSize = 16, currentEnergy = 0, maxEnergy = 0, collection = 0, activeSymbol = -1, terraformingHeight = 0;
  num speed = 1, zoom = 1, creeperTimer = 0, energyTimer = 0, spawnTimer = 0, damageTimer = 0, smokeTimer = 0, explosionTimer = 0, shieldTimer = 0, packetSpeed = 1, shellSpeed = 1, projectileSpeed = 5, sporeSpeed = 1, buildingSpeed = .5, shipSpeed = 1;
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
  List<Projectile> projectiles = new List<Projectile>();
  World world;
  Vector scroll = new Vector(0, 0);
  Building base;
  Map keyMap = {
      "k81": "Q", "k87": "W", "k69": "E", "k82": "R", "k84": "T", "k90": "Z", "k85": "U", "k73": "I", "k65": "A", "k83": "S", "k68": "D", "k70": "F", "k71": "G", "k72": "H"
  };
  Stopwatch stopwatch = new Stopwatch();

  Game() {
    seed = Helper.randomInt(0, 10000);
    world = new World(seed);
    init();
    drawTerrain();
    copyTerrain();
  }

  void init() {
    buildings = [];
    packets = [];
    shells = [];
    spores = [];
    ships = [];
    smokes = [];
    explosions = [];
    symbols = [];
    emitters = [];
    sporetowers = [];
    packetQueue = [];
    projectiles = [];
    reset();
    setupUI();
    
    var music = new AudioElement("sounds/music.ogg");
    music.loop = true;
    music.volume = 0.25;
    music.onCanPlay.listen((event) => music.play());
  }

  void reset() {
    stopwatch.reset();
    stopwatch.start();
    var oneSecond = new Duration(seconds:1);
    new Timer.periodic(oneSecond, updateTime);
    query('#lose').style.display = 'none';
    query('#win').style.display = 'none';

    mode = "DEFAULT";
    buildings.clear();
    packets.clear();
    shells.clear();
    spores.clear();
    ships.clear();
    smokes.clear();
    explosions.clear();
    //symbols.length = 0;
    emitters.clear();
    sporetowers.clear();
    packetQueue.clear();
    projectiles.clear();

    maxEnergy = 20;
    currentEnergy = 20;
    collection = 0;

    creeperTimer = 0;
    energyTimer = 0;
    spawnTimer = 0;
    damageTimer = 0;
    smokeTimer = 0;
    explosionTimer = 0;
    shieldTimer = 0;

    packetSpeed = 3;
    shellSpeed = 1;
    sporeSpeed = 1;
    buildingSpeed = .5;
    shipSpeed = 1;
    speed = 1;
    activeSymbol = -1;
    updateEnergyElement();
    updateSpeedElement();
    updateZoomElement();
    clearSymbols();
    createWorld();
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
   * Checks if the given position is within the world.
   */
  bool withinWorld(int x, int y) {
    return (x > -1 && x < world.size.x && y > -1 && y < world.size.y);
  }

  /**
   *  Returns the position of the tile the mouse is hovering above
   */
  Vector getHoveredTilePosition() {
    return new Vector(
        ((engine.mouse.x - engine.halfWidth) / (tileSize * zoom)).floor() + scroll.x,
        ((engine.mouse.y - engine.halfHeight) / (tileSize * zoom)).floor() + scroll.y);
  }

  void pause() {
    query('#paused').style.display = 'block';
    paused = true;
    stopwatch.stop();
  }

  void resume() {
    query('#paused').style.display = 'none';
    paused = false;
    stopwatch.start();
  }

  void stop() {
    running.cancel();
  }

  void run() {
    running = new Timer.periodic(new Duration(milliseconds: (1000 / speed / engine.FPS).floor()), (Timer timer) => updateAll());
    engine.animationRequest = window.requestAnimationFrame(draw);
  }
  
  void updateAll() {
    //engine.update();
    game.update();
  }

  void restart() {
    stop();
    reset();
    run();
  }

  void toggleTerraform() {
    if (mode == "TERRAFORM") {
      mode = "DEFAULT";
      query("#terraform").attributes['value'] = "Terraform Off";
    } else {
      mode = "TERRAFORM";
      query("#terraform").attributes['value'] = "Terraform On";
    }
  }

  void faster() {
    query('#slower').style.display = 'inline';
    query('#faster').style.display = 'none';
    if (speed < 2) {
      speed *= 2;
      stop();
      run();
      updateSpeedElement();
    }
  }

  void slower() {
    query('#slower').style.display = 'none';
    query('#faster').style.display = 'inline';
    if (speed > 1) {
      speed /= 2;
      stop();
      run();
      updateSpeedElement();
    }
  }

  void zoomIn() {
    if (zoom < 1.6) {
      zoom += .2;
      zoom = double.parse(zoom.toStringAsFixed(2));
      copyTerrain();
      drawCollection();
      updateZoomElement();
    }
  }

  void zoomOut() {
    if (zoom > .4) {
      zoom -= .2;
      zoom = double.parse(zoom.toStringAsFixed(2));
      copyTerrain();
      drawCollection();
      updateZoomElement();
    }
  }

  /**
   * Creates a random world with base, emitters and sporetowers.
   */
  void createWorld() {
    world.tiles = new List(world.size.x);
    for (int i = 0; i < world. size.x; i++) {
      world.tiles[i] = new List(world.size.y);
      for (int j = 0; j < world.size.y; j++) {
        world.tiles[i][j] = new Tile();
      }
    }

    var heightmap = new HeightMap(seed, 129, 0, 90);
    heightmap.run();

    for (int i = 0; i < world.size.x; i++) {
      for (int j = 0; j < world.size.y; j++) {
        int height = (heightmap.map[i][j] / 10).round();
        if (height > 10)
          height = 10;
        world.tiles[i][j].height = height;
      }
    }

    // create base
    Vector randomPosition = new Vector(
        Helper.randomInt(0, world.size.x - 9, seed + 1),
        Helper.randomInt(0, world.size.y - 9, seed + 1));

    scroll.x = randomPosition.x + 4;
    scroll.y = randomPosition.y + 4;

    Building building = new Building(randomPosition, "base");
    building.health = 40;
    building.maxHealth = 40;
    building.built = true;
    building.size = 9;
    building.canMove = true;
    buildings.add(building);
    base = building;

    int height = this.world.tiles[building.position.x + 4][building.position.y + 4].height;
    if (height < 0)
      height = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        world.tiles[building.position.x + i][building.position.y + j].height = height;
      }
    }

    int number = Helper.randomInt(2, 3, seed);
    for (var l = 0; l < number; l++) {
      // create emitter
      
      randomPosition = new Vector(
          Helper.randomInt(0, world.size.x - 3, seed + Helper.randomInt(1, 1000, seed + l)),
          Helper.randomInt(0, world.size.y - 3, seed + Helper.randomInt(1, 1000, seed + 1 + l)));
  
      Emitter emitter = new Emitter(randomPosition, 25);
      emitters.add(emitter);
  
      height = this.world.tiles[emitter.position.x + 1][emitter.position.y + 1].height;
      if (height < 0)
        height = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          world.tiles[emitter.position.x + i][emitter.position.y + j].height = height;
        }
      }
    }

    number = Helper.randomInt(1, 2, seed + 1);
    for (var l = 0; l < number; l++) {
      // create sporetower
      randomPosition = new Vector(
          Helper.randomInt(0, world.size.x - 3, seed + 3 + Helper.randomInt(1, 1000, seed + 2 + l)),
          Helper.randomInt(0, world.size.y - 3, seed + 3 + Helper.randomInt(1, 1000, seed + 3 + l)));
  
      Sporetower sporetower = new Sporetower(randomPosition);
      sporetowers.add(sporetower);
  
      height = this.world.tiles[sporetower.position.x + 1][sporetower.position.y + 1].height;
      if (height < 0)
        height = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          world.tiles[sporetower.position.x + i][sporetower.position.y + j].height = height;
        }
      }
    }

  }

  /**
   * Adds a building.
   * 
   * @param {Vector} position The position of the new building
   * @param {String} type The type of the new building
   */
  void addBuilding(Vector position, String type) {
    Building building = new Building(position, type);

    if (building.imageID == "analyzer") {
      building.maxHealth = 80;
      building.maxEnergy = 20;
      building.canMove = true;
      building.needsEnergy = true;
      building.weaponRadius = 10;
    }
    else if (building.imageID == "terp") {
      building.maxHealth = 60;
      building.maxEnergy = 20;
      building.canMove = true;
      building.needsEnergy = true;
      building.weaponRadius = 12;
    }
    else if (building.imageID == "shield") {
      building.maxHealth = 75;
      building.maxEnergy = 20;
      building.canMove = true;
      building.needsEnergy = true;
      building.weaponRadius = 9;
    }
    else if (building.imageID == "bomber") {
      building.maxHealth = 75;
      building.maxEnergy = 15;
      building.needsEnergy = true;
    }
    else if (building.imageID == "storage") {
      building.maxHealth = 8;
    }
    else if (building.imageID == "reactor") {
      building.maxHealth = 50;
    }
    else if (building.imageID == "collector") {
      building.maxHealth = 5;
    }
    else if (building.imageID == "relay") {
      building.maxHealth = 10;
    }
    else if (building.imageID == "cannon") {
      building.maxHealth = 1; // 25;
      building.maxEnergy = 40;
      building.weaponRadius = 8;
      building.canMove = true;
      building.needsEnergy = true;
    }
    else if (building.imageID == "mortar") {
      building.maxHealth = 40;
      building.maxEnergy = 20;
      building.weaponRadius = 12;
      building.canMove = true;
      building.needsEnergy = true;
    }
    else if (building.imageID == "beam") {
      building.maxHealth = 20;
      building.maxEnergy = 10;
      building.weaponRadius = 12;
      building.canMove = true;
      building.needsEnergy = true;
    }

    buildings.add(building);
  }

  /**
   * Removes a [building].
   */
  void removeBuilding(Building building) {

    // only explode building when it has been built
    if (building.built) {
      explosions.add(new Explosion(building.getCenter()));
      engine.playSound("explosion", building.position);
    }

    if (building.imageID == "base") {
      query('#lose').style.display = "block";
      stopwatch.stop();
      stop();
    }
    if (building.imageID == "collector") {
      if (building.built)
        updateCollection(building, "remove");
    }
    if (building.imageID == "storage") {
      maxEnergy -= 10;
      updateEnergyElement();
    }
    if (building.imageID == "speed") {
      packetSpeed /= 1.01;
    }

    // find all packets with this building as target and remove them
    for (int i = packets.length - 1; i >= 0; i--) {
      if (packets[i].currentTarget == building || packets[i].target == building) {
        packets.removeAt(i);
      }
    }
    for (int i = packetQueue.length - 1; i >= 0; i--) {
      if (packetQueue[i].currentTarget == building || packetQueue[i].target == building) {
        packetQueue.removeAt(i);
      }
    }

    int index = buildings.indexOf(building);
    buildings.removeAt(index);
  }

  void activateBuilding() {
    for (int i = 0; i < buildings.length; i++) {
      if (buildings[i].selected)
        buildings[i].active = true;
    }
  }

  void deactivateBuilding() {
    for (int i = 0; i < buildings.length; i++) {
      if (buildings[i].selected)
        buildings[i].active = false;
    }
  }

  void clearSymbols() {
    activeSymbol = -1;
    for (int i = 0; i < symbols.length; i++)
      symbols[i].active = false;
    engine.canvas["main"].element.style.cursor = "url('images/Normal.cur') 2 2, pointer";
  }

  void setupUI() {
    symbols
      ..add(new UISymbol(new Vector(0, 0), "cannon", "Q", 3, 25, 8))
      ..add(new UISymbol(new Vector(81, 0), "collector", "W", 3, 5, 6))
      ..add(new UISymbol(new Vector(2 * 81, 0), "reactor", "E", 3, 50, 0))
      ..add(new UISymbol(new Vector(3 * 81, 0), "storage", "R", 3, 8, 0))
      ..add(new UISymbol(new Vector(4 * 81, 0), "shield", "T", 3, 75, 10))
      ..add(new UISymbol(new Vector(5 * 81, 0), "analyzer", "Z", 3, 80, 10))

      ..add(new UISymbol(new Vector(0, 56), "relay", "A", 3, 10, 8))
      ..add(new UISymbol(new Vector(81, 56), "mortar", "S", 3, 40, 12))
      ..add(new UISymbol(new Vector(2 * 81, 56), "beam", "D", 3, 20, 12))
      ..add(new UISymbol(new Vector(3 * 81, 56), "bomber", "F", 3, 75, 0))
      ..add(new UISymbol(new Vector(4 * 81, 56), "terp", "G", 3, 60, 12));
  }

  /**
   * Draws the complete terrain.
   * This method is only called ONCE at the start of the game.
   */
  void drawTerrain() {
    for (int i = 0; i < 10; i++) {
      engine.canvas["level$i"].clear();
    }

    // 1st pass - draw masks
    for (int i = 0; i < world.size.x; i++) {
      for (int j = 0; j < world.size.y; j++) {
        int indexAbove = -1;
        for (int k = 9; k > -1; k--) {
        
          if (k <= world.tiles[i][j].height) {

            // calculate index
            int up = 0, down = 0, left = 0, right = 0;
            if (j - 1 < 0)
              up = 0;
            else if (world.tiles[i][j - 1].height >= k)
              up = 1;
            if (j + 1 > world.size.y - 1)
              down = 0;
            else if (world.tiles[i][j + 1].height >= k)
              down = 1;
            if (i - 1 < 0)
              left = 0;
            else if (world.tiles[i - 1][j].height >= k)
              left = 1;
            if (i + 1 > world.size.x - 1)
              right = 0;
            else if (world.tiles[i + 1][j].height >= k)
              right = 1;

            // save index
            int index = (8 * down) + (4 * left) + (2 * up) + right;
            if (k == world.tiles[i][j].height)
              world.tiles[i][j].index = index;
            
            if (k < 9) {
              // skip tiles that are identical to the one above
              if (index == indexAbove)
                continue;
              // skip tiles that are not visible
              if (indexAbove == 5 || indexAbove == 7 || indexAbove == 10 || indexAbove == 11 ||
                  indexAbove == 13 || indexAbove == 14 || indexAbove == 15)
                continue;
            }
            
            indexAbove = index;

            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["mask"], index * (tileSize + 6) + 3, (tileSize + 6) + 3, tileSize, tileSize, i * tileSize, j * tileSize, tileSize, tileSize);
          }
        }
      }
    }

    // 2nd pass - draw textures
    for (int i = 0; i < 10; i++) {
      CanvasPattern pattern = engine.canvas["level$i"].context.createPattern(engine.images["level$i"], 'repeat');
      engine.canvas["level$i"].context.globalCompositeOperation = 'source-in';
      engine.canvas["level$i"].context.fillStyle = pattern;
      engine.canvas["level$i"].context.fillRect(0, 0, engine.canvas["level$i"].element.width, engine.canvas["level$i"].element.height);
      engine.canvas["level$i"].context.globalCompositeOperation = 'source-over';
    }

    // 3rd pass - draw borders
    for (int i = 0; i < world.size.x; i++) {
      for (int j = 0; j < world.size.y; j++) {
        int indexAbove = -1;
        for (int k = 9; k > -1; k--) {
           
          if (k <= world.tiles[i][j].height) {

            // calculate index
            int up = 0, down = 0, left = 0, right = 0;
            if (j - 1 < 0)
              up = 0;
            else if (world.tiles[i][j - 1].height >= k)
              up = 1;
            if (j + 1 > world.size.y - 1)
              down = 0;
            else if (world.tiles[i][j + 1].height >= k)
              down = 1;
            if (i - 1 < 0)
              left = 0;
            else if (world.tiles[i - 1][j].height >= k)
              left = 1;
            if (i + 1 > world.size.x - 1)
              right = 0;
            else if (world.tiles[i + 1][j].height >= k)
              right = 1;
            
            int index = (8 * down) + (4 * left) + (2 * up) + right;
          
            if (k < 9) {
              // skip tiles that are identical to the one above
              if (index == indexAbove)
                continue;
              // skip tiles that are not visible
              if (indexAbove == 5 || indexAbove == 7 || indexAbove == 10 || indexAbove == 11 ||
                  indexAbove == 13 || indexAbove == 14 || indexAbove == 15)
                continue;
            }
            
            indexAbove = index;
  
            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["borders"], index * (tileSize + 6) + 2, 2, tileSize + 2, tileSize + 2, i * tileSize, j * tileSize, (tileSize + 2), (tileSize + 2));
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

  /**
   * After scrolling, zooming, or tile redrawing the terrain is copied
   * to the visible buffer.
   */
  void copyTerrain() {
    engine.canvas["levelfinal"].clear();

    Vector delta = new Vector(0,0);
    var left = scroll.x * tileSize - (engine.width / 2) * (1 / zoom);
    var top = scroll.y * tileSize - (engine.height / 2) * (1 / zoom);
    if (left < 0) {
      delta.x = -left * zoom;
      left = 0;
    }
    if (top < 0) {
      delta.y = -top * zoom;
      top = 0;
    }

    Vector delta2 = new Vector(0, 0);
    var width = engine.width * (1 / zoom);
    var height = engine.height * (1 / zoom);
    if (left + width > world.size.x * tileSize) {
      delta2.x = (left + width - world.size.x * tileSize) * zoom;
      width = world.size.x * tileSize - left;
    }
    if (top + height > world.size.y * tileSize) {
      delta2.y = (top + height - world.size.y * tileSize) * zoom;
      height = world.size.y * tileSize - top ;
    }

    engine.canvas["levelfinal"].context.drawImageScaledFromSource(engine.canvas["levelbuffer"].element, left, top, width, height, delta.x, delta.y, engine.width - delta2.x, engine.height - delta2.y);
  }

  /**
   * Redraws a tile when its height has changed.
   * 
   * @param {List} tilesToRedraw An array of tiles to redraw
   */
  void redrawTile(List tilesToRedraw) {
    List tempCanvas = [];
    List tempContext = [];
    for (int t = 0; t < 10; t++) {
      tempCanvas.add(new CanvasElement());
      tempCanvas[t].width = tileSize;
      tempCanvas[t].height = tileSize;
      tempContext.add(tempCanvas[t].getContext('2d'));
    }

    for (int i = 0; i < tilesToRedraw.length; i++) {

      int iS = tilesToRedraw[i].x;
      int jS = tilesToRedraw[i].y;

      if (withinWorld(iS, jS)) {
        // recalculate index
        int index = -1;
        int indexAbove = -1;
        for (int t = 9; t > -1; t--) {
          if (t <= world.tiles[iS][jS].height) {
    
            int up = 0, down = 0, left = 0, right = 0;
            if (jS - 1 < 0)
              up = 0;
            else if (world.tiles[iS][jS - 1].height >= t)
              up = 1;
            if (jS + 1 > world.size.y - 1)
              down = 0;
            else if (world.tiles[iS][jS + 1].height >= t)
              down = 1;
            if (iS - 1 < 0)
              left = 0;
            else if (world.tiles[iS - 1][jS].height >= t)
              left = 1;
            if (iS + 1 > world.size.x - 1)
              right = 0;
            else if (world.tiles[iS + 1][jS].height >= t)
              right = 1;
    
            // save index for later use
            index = (8 * down) + (4 * left) + (2 * up) + right;
          }
              
          //if (index > -1) {
            tempContext[t].clearRect(0, 0, tileSize, tileSize);
            
            // redraw mask          
            if (t < 9) {
              // skip tiles that are identical to the one above
              if (index == indexAbove)
                continue;
              // skip tiles that are not visible
              if (indexAbove == 5 || indexAbove == 7 || indexAbove == 10 || indexAbove == 11 ||
                  indexAbove == 13 || indexAbove == 14 || indexAbove == 15)
                continue;
            }
            
            tempContext[t].drawImageScaledFromSource(engine.images["mask"], index * (tileSize + 6) + 3, (tileSize + 6) + 3, tileSize, tileSize, 0, 0, tileSize, tileSize);
  
            // redraw pattern
            var pattern = tempContext[t].createPattern(engine.images["level$t"], 'repeat');
  
            tempContext[t].globalCompositeOperation = 'source-in';
            tempContext[t].fillStyle = pattern;
  
            tempContext[t].save();
            Vector translation = new Vector((iS * tileSize).floor(), (jS * tileSize).floor());
            tempContext[t].translate(-translation.x, -translation.y);
  
            //tempContext[t].fill();
            tempContext[t].fillRect(translation.x, translation.y, tileSize, tileSize);
            tempContext[t].restore();
  
            tempContext[t].globalCompositeOperation = 'source-over';
  
            // redraw borders
            if (t < 9) {
              // skip tiles that are identical to the one above
              if (index == indexAbove)
                continue;
              // skip tiles that are not visible
              if (indexAbove == 5 || indexAbove == 7 || indexAbove == 10 || indexAbove == 11 ||
                  indexAbove == 13 || indexAbove == 14 || indexAbove == 15)
                continue;
            }
            
            tempContext[t].drawImageScaledFromSource(engine.images["borders"], index * (tileSize + 6) + 2, 2, tileSize + 2, tileSize + 2, 0, 0, (tileSize + 2), (tileSize + 2));         
          //}
          
          // set above index
          indexAbove = index;
        }
  
        engine.canvas["levelbuffer"].context.clearRect(iS * tileSize, jS * tileSize, tileSize, tileSize);
        for (int t = 0; t < 10; t++) {
          engine.canvas["levelbuffer"].context.drawImageScaledFromSource(tempCanvas[t], 0, 0, tileSize, tileSize, iS * tileSize, jS * tileSize, tileSize, tileSize);
        }
      }
    }
    copyTerrain();
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
    
    for (int i = 0; i < buildings.length; i++) {
      // must not be the same building
      if (!(buildings[i].position.x == node.position.x && buildings[i].position.y == node.position.y)) {
        // must be idle
        if (buildings[i].status == "IDLE") {
          // it must either be the target or be built
          if (buildings[i] == target || buildings[i].built) {
              centerI = buildings[i].getCenter();
              centerNode = node.getCenter();
              num distance = Helper.distance(centerI, centerNode);

              int allowedDistance = 10 * tileSize;
              if (node.imageID == "relay" && buildings[i].imageID == "relay") {
                allowedDistance = 20 * tileSize;
              }
              if (distance <= allowedDistance) {
                neighbours.add(buildings[i]);
              }
          }
        }
      }
    }
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

      // find all neighbours of this node
      List neighbours = getNeighbours(lastNode, packet.target);

      int newRoutes = 0;
      // extend the old route with each neighbour creating a new route each
      for (int i = 0; i < neighbours.length; i++) {

        // if the neighbour is not already in the list..
        if (!inRoute(neighbours[i], oldRoute.nodes)) {

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
   * Queues a requested packet
   * 
   * @param {Building} building The packet target building
   * @param {String} type The type of the packet
   */
  void queuePacket(Building building, String type) {
    String img = "packet_" + type;
    Vector center = base.getCenter();
    Packet packet = new Packet(center, img, type);
    packet.target = building;
    packet.currentTarget = base;
    findRoute(packet);
    if (packet.currentTarget != null) {
      if (packet.type == "health")packet.target.healthRequests++;
      if (packet.type == "energy")packet.target.energyRequests += 4;
      packetQueue.add(packet);
    }
  }

  /**
   * Checks if a building can be placed on a given [position].
   *
   * @param {Vector} position The position to place the building
   * @param {int} size The size of the building
   * @param {Building} building The building to place
   */
  bool canBePlaced(Vector position, num size, [Building building]) {
    bool collision = false;

    if (position.x > -1 && position.x < world.size.x - size + 1 && position.y > -1 && position.y < world.size.y - size + 1) {
      int height = game.world.tiles[position.x][position.y].height;

      // 1. check for collision with another building
      for (int i = 0; i < buildings.length; i++) {
        // don't check for collision with moving buildings
        if (buildings[i].status != "IDLE")
          continue;
        if (building != null && building == buildings[i])
          continue;
        int x1 = buildings[i].position.x * tileSize;
        int x2 = buildings[i].position.x * tileSize + buildings[i].size * tileSize - 1;
        int y1 = buildings[i].position.y * tileSize;
        int y2 = buildings[i].position.y * tileSize + buildings[i].size * tileSize - 1;

        int cx1 = position.x * tileSize;
        int cx2 = position.x * tileSize + size * tileSize - 1;
        int cy1 = position.y * tileSize;
        int cy2 = position.y * tileSize + size * tileSize - 1;

        if (((cx1 >= x1 && cx1 <= x2) || (cx2 >= x1 && cx2 <= x2)) && ((cy1 >= y1 && cy1 <= y2) || (cy2 >= y1 && cy2 <= y2))) {
          collision = true;
          break;
        }
      }

      // 2. check if all tiles have the same height and are not corners
      if (!collision) {
        for (int i = position.x; i < position.x + size; i++) {
          for (int j = position.y; j < position.y + size; j++) {
            if (withinWorld(i, j)) {
              int tileHeight = game.world.tiles[i][j].height;
              if (tileHeight < 0) {
                collision = true;
                break;
              }
              if (tileHeight != height) {
                collision = true;
                break;
              }
              if (!(world.tiles[i][j].index == 7 || world.tiles[i][j].index == 11 || world.tiles[i][j].index == 13 || world.tiles[i][j].index == 14 || world.tiles[i][j].index == 15)) {
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
  
  void updateCreeper() {
    spawnTimer++;
    if (spawnTimer >= (25 / speed)) { // 125
      for (int i = 0; i < emitters.length; i++)
        emitters[i].spawn();
      spawnTimer = 0;
    }

    creeperTimer++;
    if (creeperTimer > (25 / speed)) {
      creeperTimer -= (25 / speed);

      for (int i = 0; i < world.size.x; i++) {
        for (int j = 0; j < world.size.y; j++) {

          // right neighbour
          if (i + 1 < world.size.x) {
            transferCreeper(world.tiles[i][j], world.tiles[i + 1][j]);
          }
          // left neighbour
          if (i - 1 > -1) {
            transferCreeper(world.tiles[i][j], world.tiles[i - 1][j]);
          }
          // bottom neighbour
          if (j + 1 < world.size.y) {
            transferCreeper(world.tiles[i][j], world.tiles[i][j + 1]);
          }
          // top neighbour
          if (j - 1 > -1) {
            transferCreeper(world.tiles[i][j], world.tiles[i][j - 1]);
          }

        }
      }
      
      // clamp creeper
      for (int i = 0; i < world.size.x; i++) {
        for (int j = 0; j < world.size.y; j++) {
          if (world.tiles[i][j].newcreep > 10)
            world.tiles[i][j].newcreep = 10;
          else if (world.tiles[i][j].newcreep < .01)
            world.tiles[i][j].newcreep = 0;
          world.tiles[i][j].creep = world.tiles[i][j].newcreep;
        }
      }

    }
  }

  /**
   * Transfers creeper from one tile to another.
   */ 
  void transferCreeper(Tile source, Tile target) {
    num transferRate = .2;

    if (source.height > -1 && target.height > -1) {
      num sourceCreeper = source.creep;     
      //num targetCreeper = target.creep;
      if (sourceCreeper > 0 /*|| targetCreeper > 0*/) {
        num sourceTotal = source.height + source.creep;
        num targetTotal = target.height + target.creep;
        num delta = 0;
        if (sourceTotal > targetTotal) {
          delta = sourceTotal - targetTotal;
          if (delta > sourceCreeper)
            delta = sourceCreeper;
          num adjustedDelta = delta * transferRate;
          source.newcreep -= adjustedDelta;
          target.newcreep += adjustedDelta;
        }
      }
    }
  }
  
  void updateEnergyElement() {
    query('#energy').innerHtml = "Energy: ${currentEnergy.toString()}/${maxEnergy.toString()}";
  }

  void updateSpeedElement() {
    query("#speed").innerHtml = "Speed: ${speed.toString()}x";
  }

  void updateZoomElement() {
    query("#speed").innerHtml = "Zoom: ${zoom.toString()}x";
  }
  
  /**
   * Updates the collector property of each tile when a
   * collector is added or removed.
   * 
   * @param {Building} building The building to update
   * @param {String} action Add or Remove action
   */
  void updateCollection(Building building, String action) {
    int height = game.world.tiles[building.position.x][building.position.y].height;
    Vector centerBuilding = building.getCenter();

    for (int i = -5; i < 7; i++) {
      for (int j = -5; j < 7; j++) {

        Vector positionCurrent = new Vector(building.position.x + i, building.position.y + j);

        if (withinWorld(positionCurrent.x, positionCurrent.y)) {
          Vector positionCurrentCenter = new Vector(positionCurrent.x * tileSize + (tileSize / 2), positionCurrent.y * tileSize + (tileSize / 2));
          int tileHeight = game.world.tiles[positionCurrent.x][positionCurrent.y].height;

          if (action == "add") {
            if (pow(positionCurrentCenter.x - centerBuilding.x, 2) + pow(positionCurrentCenter.y - centerBuilding.y, 2) < pow(tileSize * 6, 2)) {
              if (tileHeight == height) {
                world.tiles[positionCurrent.x][positionCurrent.y].collector = building;
              }
            }
          } else if (action == "remove") {

            if (pow(positionCurrentCenter.x - centerBuilding.x, 2) + pow(positionCurrentCenter.y - centerBuilding.y, 2) < pow(tileSize * 6, 2)) {
              if (tileHeight == height) {
                world.tiles[positionCurrent.x][positionCurrent.y].collector = null;
              }
            }

            for (int k = 0; k < buildings.length; k++) {
              if (buildings[k] != building && buildings[k].imageID == "collector") {
                int heightK = game.world.tiles[buildings[k].position.x][buildings[k].position.y].height;
                Vector centerBuildingK = buildings[k].getCenter();
                if (pow(positionCurrentCenter.x - centerBuildingK.x, 2) + pow(positionCurrentCenter.y - centerBuildingK.y, 2) < pow(tileSize * 6, 2)) {
                  if (tileHeight == heightK) {
                    world.tiles[positionCurrent.x][positionCurrent.y].collector = buildings[k];
                  }
                }
              }
            }
          }

        }

      }
    }

    drawCollection();
  }

  /**
   * Updates the packet queue of the base.
   * 
   * If the base has energy the first packet is removed from
   * the queue and sent to its target.
   */
  void updatePacketQueue() {
    for (int i = packetQueue.length - 1; i >= 0; i--) {
      if (currentEnergy > 0) {
        currentEnergy--;
        updateEnergyElement();
        Packet packet = packetQueue.removeAt(0);
        packets.add(packet);
      }
    }
  }

  void updateBuildings() {
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].move();
      buildings[i].checkOperating();
      buildings[i].shield();
      buildings[i].requestPacket();
    }

    // take damage
    damageTimer++;
    if (damageTimer > 10) {
      damageTimer = 0;
      for (int i = 0; i < buildings.length; i++) {
        buildings[i].takeDamage();
      }
    }

    // collect energy
    energyTimer++;
    if (energyTimer > (250 / speed)) {
      energyTimer -= (250 / speed);
      for (int i = 0; i < buildings.length; i++) {
        buildings[i].collectEnergy();
      }
    }
  }

  void updatePackets() {
    for (int i = packets.length - 1; i >= 0; i--) {
      if (packets[i].remove)
        packets.removeAt(i);
      else
        packets[i].move();
    }
  }

  void updateShells() {
    for (int i = shells.length - 1; i >= 0; i--) {
      if (shells[i].remove)
        shells.removeAt(i);
      else
        shells[i].move();
    }
  }
  
  void updateProjectiles() {
    for (int i = projectiles.length - 1; i >= 0; i--) {
      if (projectiles[i].remove)
        projectiles.removeAt(i);
      else
        projectiles[i].move();
    }
  }

  void updateSpores() {
    for (int i = spores.length - 1; i >= 0; i--) {
      if (spores[i].remove)
        spores.removeAt(i);
      else
        spores[i].move();
    }
  }

  void updateSmokes() {
    smokeTimer++;
    if (smokeTimer > 3) {
      smokeTimer = 0;
      for (int i = smokes.length - 1; i >= 0; i--) {
        if (smokes[i].frame == 36)
          smokes.removeAt(i);
        else
          smokes[i].frame++;
      }
    }
  }

  void updateExplosions() {
    explosionTimer++;
    if (explosionTimer == 1) {
      explosionTimer = 0;
      for (int i = explosions.length - 1; i >= 0; i--) {
        if (explosions[i].frame == 44)
          explosions.removeAt(i);
        else
          explosions[i].frame++;
      }
    }
  }

  void updateShips() {
    // move
    for (int i = 0; i < ships.length; i++) {
      ships[i].move();
    }
  }

  /**
   * Main update function which calls all other update functions.
   * Is called by a periodic timer.
   */ 
  void update() {
    // check for winning condition
    int emittersChecked = 0;
    for (int i = 0; i < emitters.length; i++) {
      if (emitters[i].building != null)
        emittersChecked++;
    }
    if (emittersChecked == emitters.length) {
      // TODO: 10 seconds countdown
      query('#win').style.display = "block";
      stopwatch.stop();
      stop();
    }  
    
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].updateHoverState();
    }
    for (int i = 0; i < ships.length; i++) {
      ships[i].updateHoverState();
    }
    for (int i = 0; i < sporetowers.length; i++) {
      sporetowers[i].update();
    }

    if (!paused) {
      updatePacketQueue();
      updateShells();
      updateProjectiles();
      updateSpores();
      updateCreeper();
      updateBuildings();
      updatePackets();
      updateSmokes();
      updateExplosions();
      updateShips();
    }

    // scroll left
    if (scrollingLeft) {
      if (scroll.x > 0)
        scroll.x -= 1;
    }

    // scroll right 
    else if (scrollingRight) {
      if (scroll.x < world.size.x)
        scroll.x += 1;
    }

    // scroll up
    if (scrollingUp) {
      if (scroll.y > 0)
        scroll.y -= 1;
    }

    // scroll down
    else if (scrollingDown) {
      if (scroll.y < world.size.y)
        scroll.y += 1;

    }

    if (scrollingLeft || scrollingRight || scrollingUp || scrollingDown) {
      copyTerrain();
      drawCollection();
    }
  }

  /**
   * Draws the white range boxes when placing a building.
   * 
   * @param {Vector} position The position of the building
   * @param {String} type The type of the building
   * @param {int} radius The radius of the building
   * @param {int} size The size of the building
   */
  void drawRangeBoxes(Vector position, String type, num rad, num size) {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    Vector positionCenter = new Vector(position.x * tileSize + (tileSize / 2) * size, position.y * tileSize + (tileSize / 2) * size);
    int positionHeight = game.world.tiles[position.x][position.y].height;

    if (canBePlaced(position, size, null) && (type == "collector" || type == "cannon" || type == "mortar" || type == "shield" || type == "beam" || type == "terp")) {

      context.save();
      context.globalAlpha = .25;

      int radius = rad * tileSize;

      for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {

          Vector positionCurrent = new Vector(position.x + i, position.y + j);
          Vector positionCurrentCenter = new Vector(positionCurrent.x * tileSize + (tileSize / 2), positionCurrent.y * tileSize + (tileSize / 2));

          Vector drawPositionCurrent = Helper.tiled2screen(positionCurrent);

          if (withinWorld(positionCurrent.x, positionCurrent.y)) {
            int positionCurrentHeight = game.world.tiles[positionCurrent.x][positionCurrent.y].height;

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
              context.fillRect(drawPositionCurrent.x, drawPositionCurrent.y, tileSize * zoom, tileSize * zoom);
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

    int timesX = (engine.halfWidth / tileSize / zoom).ceil();
    int timesY = (engine.halfHeight / tileSize / zoom).ceil();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + scroll.x;
        int jS = j + scroll.y;

        if (withinWorld(iS, jS)) {

          //for (int k = 0 ; k < 10; k++) {
            if (world.tiles[iS][jS].collector != null) {
              int up = 0, down = 0, left = 0, right = 0;
              if (jS - 1 < 0)
                up = 0;
              else
                up = world.tiles[iS][jS - 1].collector != null ? 1 : 0;
              if (jS + 1 > world.size.y - 1)
                down = 0;
              else
                down = world.tiles[iS][jS + 1].collector != null ? 1 : 0;
              if (iS - 1 < 0)
                left = 0;
              else
                left = world.tiles[iS - 1][jS].collector != null ? 1 : 0;
              if (iS + 1 > world.size.x - 1)
                right = 0;
              else
                right = world.tiles[iS + 1][jS].collector != null ? 1 : 0;

              int index = (8 * down) + (4 * left) + (2 * up) + right;
              engine.canvas["collection"].context.drawImageScaledFromSource(engine.images["mask"], index * (tileSize + 6) + 3, (tileSize + 6) + 3, tileSize, tileSize, engine.halfWidth + i * tileSize * zoom, engine.halfHeight + j * tileSize * zoom, tileSize * zoom, tileSize * zoom);
            }
          //}
        }
      }
    }
    engine.canvas["collection"].context.restore();
  }

  void drawCreeper() {
    engine.canvas["creeperbuffer"].clear();

    int timesX = (engine.halfWidth / tileSize / zoom).ceil();
    int timesY = (engine.halfHeight / tileSize / zoom).ceil();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + scroll.x;
        int jS = j + scroll.y;

        if (withinWorld(iS, jS)) {
          
          num creep = (world.tiles[iS][jS].creep).ceil();
          
          for (var t = 0; t <= 9; t++) {

            if (world.tiles[iS][jS].creep > t) {
              
              int up = 0, down = 0, left = 0, right = 0;
              if (jS - 1 < 0)
                up = 0;
              else if ((world.tiles[iS][jS - 1].creep) > t)
                up = 1;
              if (jS + 1 > world.size.y - 1)
                down = 0;
              else if ((world.tiles[iS][jS + 1].creep) > t)
                down = 1;
              if (iS - 1 < 0)
                left = 0;
              else if ((world.tiles[iS - 1][jS].creep) > t)
                left = 1;
              if (iS + 1 > world.size.x - 1)
                right = 0;
              else if ((world.tiles[iS + 1][jS].creep) > t)
                right = 1;
  
              int index = (8 * down) + (4 * left) + (2 * up) + right;
              engine.canvas["creeperbuffer"].context.drawImageScaledFromSource(engine.images["creeper"], index * tileSize, 0, tileSize, tileSize, engine.halfWidth + i * tileSize * zoom, engine.halfHeight + j * tileSize * zoom, tileSize * zoom, tileSize * zoom);
            }
          }
        }
        
      }
    }
    
    engine.canvas["creeper"].clear();
    engine.canvas["creeper"].context.drawImage(engine.canvas["creeperbuffer"].element, 0, 0);
  }

  /**
   * When a building from the GUI is selected this draws some info
   * whether it can be build on the current tile, the range as
   * white boxes and connections to other buildings
   */
  void drawPositionInfo() {
    ghosts = new List(); // ghosts are all the placeholders to build
    if (engine.mouse.dragStart != null) {

      Vector start = engine.mouse.dragStart;
      Vector end = engine.mouse.dragEnd;
      Vector delta = new Vector(end.x - start.x, end.y - start.y);
      num distance = Helper.distance(start, end);
      
      num buildingDistance = 3;
      if (symbols[activeSymbol].imageID == "collector")
        buildingDistance = 9;
      else if (symbols[activeSymbol].imageID == "relay")
        buildingDistance = 18;
    
      num times = (distance / buildingDistance).floor() + 1;

      ghosts.add(start);

      for (int i = 1; i < times; i++) {
        num newX = (start.x + (delta.x / distance) * i * buildingDistance).floor();
        num newY = (start.y + (delta.y / distance) * i * buildingDistance).floor();

        if (withinWorld(newX, newY)) {
          Vector ghost = new Vector(newX, newY);
          ghosts.add(ghost);
        }
      }
      if (withinWorld(end.x, end.y)) {
        ghosts.add(end);
      }
    } else {
      if (engine.mouse.active) {
        Vector position = getHoveredTilePosition();
        if (withinWorld(position.x, position.y)) {
          ghosts.add(position);
        }
      }
    }

    for (int j = 0; j < ghosts.length; j++) {
      Vector positionScrolled = new Vector(ghosts[j].x, ghosts[j].y);
      Vector drawPosition = Helper.tiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * tileSize + (tileSize / 2) * symbols[activeSymbol].size, positionScrolled.y * tileSize + (tileSize / 2) * symbols[activeSymbol].size);

      drawRangeBoxes(positionScrolled, symbols[activeSymbol].imageID, symbols[activeSymbol].radius, symbols[activeSymbol].size);

      if (withinWorld(positionScrolled.x, positionScrolled.y)) {
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;

        // draw building
        engine.canvas["buffer"].context.drawImageScaled(engine.images[symbols[activeSymbol].imageID], drawPosition.x, drawPosition.y, symbols[activeSymbol].size * tileSize * zoom, symbols[activeSymbol].size * tileSize * zoom);
        if (symbols[activeSymbol].imageID == "cannon")engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], drawPosition.x, drawPosition.y, 48 * zoom, 48 * zoom);

        // draw green or red box
        // make sure there isn't a building on this tile yet
        if (canBePlaced(positionScrolled, symbols[activeSymbol].size, null)) {
          engine.canvas["buffer"].context.strokeStyle = "#0f0";
        } else {
          engine.canvas["buffer"].context.strokeStyle = "#f00";
        }
        engine.canvas["buffer"].context.lineWidth = 4 * zoom;
        engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, tileSize * symbols[activeSymbol].size * zoom, tileSize * symbols[activeSymbol].size * zoom);

        engine.canvas["buffer"].context.restore();

        // draw lines to other buildings
        for (int i = 0; i < buildings.length; i++) {
          Vector center = buildings[i].getCenter();
          Vector drawCenter = Helper.real2screen(center);

          int allowedDistance = 10 * tileSize;
          if (buildings[i].imageID == "relay" && symbols[activeSymbol].imageID == "relay") {
            allowedDistance = 20 * tileSize;
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
        for (int k = 0; k < ghosts.length; k++) {
          if (k != j) {
            Vector center = new Vector(ghosts[k].x * tileSize + (tileSize / 2) * 3, ghosts[k].y * tileSize + (tileSize / 2) * 3);
            Vector drawCenter = Helper.real2screen(center);

            int allowedDistance = 10 * tileSize;
            if (symbols[activeSymbol].imageID == "relay") {
              allowedDistance = 20 * tileSize;
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
   * Draws the GUI with symbols, height and creep meter.
   */
  void drawGUI() {
    CanvasRenderingContext2D context = engine.canvas["gui"].context;
    
    Vector position = getHoveredTilePosition();

    engine.canvas["gui"].clear();
    for (int i = 0; i < symbols.length; i++) {
      symbols[i].draw();
    }

    if (withinWorld(position.x, position.y)) {

      num total = world.tiles[position.x][position.y].creep;

      // draw height and creep meter
      context.fillStyle = '#fff';
      context.font = '9px';
      context.textAlign = 'right';
      context.strokeStyle = '#fff';
      context.lineWidth = 1;
      context.fillStyle = "rgba(205, 133, 63, 1)";
      context.fillRect(555, 110, 25, -game.world.tiles[getHoveredTilePosition().x][getHoveredTilePosition().y].height * 10 - 10);
      context.fillStyle = "rgba(100, 150, 255, 1)";
      context.fillRect(555, 110 - game.world.tiles[getHoveredTilePosition().x][getHoveredTilePosition().y].height * 10 - 10, 25, -total * 10);
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
  
  /**
   * Main drawing function which calls all other drawing functions.
   * Is called by requestAnimationFrame every frame.
   */
  void draw(num _) {
    CanvasRenderingContext2D context = engine.canvas["buffer"].context;
    
    drawGUI();

    // clear canvas
    engine.canvas["buffer"].clear();
    engine.canvas["main"].clear();

    // draw terraform numbers
    int timesX = (engine.halfWidth / tileSize / zoom).floor();
    int timesY = (engine.halfHeight / tileSize / zoom).floor();

    for (int i = -timesX; i <= timesX; i++) {
      for (int j = -timesY; j <= timesY; j++) {

        int iS = i + scroll.x;
        int jS = j + scroll.y;

        if (withinWorld(iS, jS)) {
          if (world.tiles[iS][jS].terraformTarget > -1) {
            context.drawImageScaledFromSource(engine.images["numbers"], world.tiles[iS][jS].terraformTarget * 16, 0, tileSize, tileSize, engine.halfWidth + i * tileSize * zoom, engine.halfHeight + j * tileSize * zoom, tileSize * zoom, tileSize * zoom);
          }
        }
      }
    }

    // draw emitters
    for (int i = 0; i < emitters.length; i++) {
      emitters[i].draw();
    }

    // draw spore towers
    for (int i = 0; i < sporetowers.length; i++) {
      sporetowers[i].draw();
    }

    // draw node connections
    for (int i = 0; i < buildings.length; i++) {
      Vector centerI = buildings[i].getCenter();
      Vector drawCenterI = Helper.real2screen(centerI);
      for (int j = 0; j < buildings.length; j++) {
        if (i != j) {
          if (buildings[i].status == "IDLE" && buildings[j].status == "IDLE") {
            Vector centerJ = buildings[j].getCenter();
            Vector drawCenterJ = Helper.real2screen(centerJ);

            num allowedDistance = 10 * tileSize;
            if (buildings[i].imageID == "relay" && buildings[j].imageID == "relay") {
              allowedDistance = 20 * tileSize;
            }

            if (pow(centerJ.x - centerI.x, 2) + pow(centerJ.y - centerI.y, 2) <= pow(allowedDistance, 2)) {
              context.strokeStyle = '#000';
              context.lineWidth = 3;
              context.beginPath();
              context.moveTo(drawCenterI.x, drawCenterI.y);
              context.lineTo(drawCenterJ.x, drawCenterJ.y);
              context.stroke();
              
              if (!buildings[i].built || !buildings[j].built)
                context.strokeStyle = '#777';
              else
                context.strokeStyle = '#fff';
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
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].drawMovementIndicators();
    }

    // draw shells
    for (int i = 0; i < shells.length; i++) {
      shells[i].draw();
    }
    
    // draw projectiles
    for (int i = 0; i < projectiles.length; i++) {
      projectiles[i].draw();
    }
    
    // draw buildings
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].draw();
    }

    // draw smokes
    for (int i = 0; i < smokes.length; i++) {
      smokes[i].draw();
    }

    // draw explosions
    for (int i = 0; i < explosions.length; i++) {
      explosions[i].draw();
    }

    // draw spores
    for (int i = 0; i < spores.length; i++) {
      spores[i].draw();
    }

    if (engine.mouse.active) {

      // if a building is built and selected draw a green box and a line at mouse position as the reposition target
      for (int i = 0; i < buildings.length; i++) {
        buildings[i].drawRepositionInfo();
      }

      // draw attack symbol
      if (mode == "SHIP_SELECTED") {
        Vector position = Helper.tiled2screen(getHoveredTilePosition());
        engine.canvas["buffer"].context.drawImageScaled(engine.images["targetcursor"], position.x - tileSize * zoom, position.y - tileSize * zoom, 48 * zoom, 48 * zoom);
      }

      if (activeSymbol != -1) {
        drawPositionInfo();
      }

      if (mode == "TERRAFORM") {
        Vector positionScrolled = getHoveredTilePosition();
        Vector drawPosition = Helper.tiled2screen(positionScrolled);
        context.drawImageScaledFromSource(engine.images["numbers"], terraformingHeight * tileSize, 0, tileSize, tileSize, drawPosition.x, drawPosition.y, tileSize * zoom, tileSize * zoom);

        context.strokeStyle = '#fff';
        context.lineWidth = 1;

        context.beginPath();
        context.moveTo(0, drawPosition.y);
        context.lineTo(engine.width, drawPosition.y);
        context.stroke();

        context.beginPath();
        context.moveTo(0, drawPosition.y + tileSize * zoom);
        context.lineTo(engine.width, drawPosition.y + tileSize * zoom);
        context.stroke();

        context.beginPath();
        context.moveTo(drawPosition.x, 0);
        context.lineTo(drawPosition.x, engine.halfHeight * 2);
        context.stroke();

        context.beginPath();
        context.moveTo(drawPosition.x + tileSize * zoom, 0);
        context.lineTo(drawPosition.x + tileSize * zoom, engine.halfHeight * 2);
        context.stroke();

        context.stroke();

      }
    }

    // draw packets
    for (int i = 0; i < packets.length; i++) {
      packets[i].draw();
    }

    // draw ships
    for (int i = 0; i < ships.length; i++) {
      ships[i].draw();
    }

    // draw building hover/selection box
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].drawBox();
    }
    
    drawCreeper();

    engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element, 0, 0);

    window.requestAnimationFrame(draw);
  }
}