library creeper;

import 'dart:html';
import 'dart:math' as Math;
import 'dart:async';

class Mouse {
  int x = 0, y = 0;
  bool active = true;
  Vector dragStart, dragEnd;
  
  Mouse();
}

class Engine {
  num FPS = 60, delta = 1000 / 60, fps_delta, fps_frames, fps_totalTime, fps_updateTime, fps_updateFrames, animationRequest, width, height, halfWidth, halfHeight;
  var fps_lastTime;
  List imageSrcs = [];
  Mouse mouse = new Mouse();
  Mouse mouseGUI = new Mouse();
  Map canvas, sounds, images;

  Engine() {
    this.canvas = new Map();
    this.sounds = new Map();
    this.images = new Map();
  }

  /**
   * Initializes the canvases and mouse, loads sounds and images.
   */

  void init() {
    num width = window.innerWidth;
    num height = window.innerHeight;
    this.width = width;
    this.height = height;
    this.halfWidth = (width / 2).floor();
    this.halfHeight = (height / 2).floor();

    // main
    engine.canvas["main"] = new Canvas(new CanvasElement(), width, height);
    query('#canvasContainer').children.add(engine.canvas["main"].element);
    engine.canvas["main"].top = engine.canvas["main"].element.offsetTop;
    engine.canvas["main"].left = engine.canvas["main"].element.offsetLeft;
    engine.canvas["main"].right = engine.canvas["main"].element.offset.right;
    engine.canvas["main"].bottom = engine.canvas["main"].element.offset.bottom;
    engine.canvas["main"].element.style.zIndex = "1";

    // buffer
    engine.canvas["buffer"] = new Canvas(new CanvasElement(), width, height);

    // gui
    engine.canvas["gui"] = new Canvas(new CanvasElement(), 780, 110);
    query('#gui').children.add(engine.canvas["gui"].element);
    engine.canvas["gui"].top = engine.canvas["gui"].element.offsetTop;
    engine.canvas["gui"].left = engine.canvas["gui"].element.offsetLeft;

    for (int i = 0; i < 10; i++) {
      engine.canvas["level$i"] = new Canvas(new CanvasElement(), 128 * 16 + width * 2, 128 * 16 + height * 2);
    }

    engine.canvas["levelbuffer"] = new Canvas(new CanvasElement(), 128 * 16 + width * 2, 128 * 16 + height * 2);
    engine.canvas["levelfinal"] = new Canvas(new CanvasElement(), width, height);
    query('#canvasContainer').children.add(engine.canvas["levelfinal"].element);

    // collection
    engine.canvas["collection"] = new Canvas(new CanvasElement(), width, height);
    query('#canvasContainer').children.add(engine.canvas["collection"].element);

    // creeper
    engine.canvas["creeper"] = new Canvas(new CanvasElement(), width, height);
    query('#canvasContainer').children.add(engine.canvas["creeper"].element);

    // load sounds
    this.addSound("shot", "wav");
    this.addSound("click", "wav");
    this.addSound("music", "ogg");
    this.addSound("explosion", "wav");
    this.addSound("failure", "wav");
    this.addSound("energy", "wav");
    this.addSound("laser", "wav");

    // load images
    this.imageSrcs = ["numbers", "level0", "level1", "level2", "level3", "level4", "level5", "level6", "level7", "level8", "level9", "borders", "mask", "cannon", "cannongun", "base", "collector", "reactor", "storage", "terp", "packet_collection", "packet_energy", "packet_health", "relay", "emitter", "creep", "mortar", "shell", "beam", "spore", "bomber", "bombership", "smoke", "explosion", "targetcursor", "sporetower", "forcefield", "shield"];

    query('#terraform').onClick.listen((event) => game.toggleTerraform());
    query('#slower').onClick.listen((event) => game.slower());
    query('#faster').onClick.listen((event) => game.faster());
    query('#pause').onClick.listen((event) => game.pause());
    query('#resume').onClick.listen((event) => game.resume());
    query('#restart').onClick.listen((event) => game.restart());
    query('#deactivate').onClick.listen((event) => game.deactivateBuilding());
    query('#activate').onClick.listen((event) => game.activateBuilding());
    query('#zoomin').onClick.listen((event) => game.zoomIn());
    query('#zoomout').onClick.listen((event) => game.zoomOut());

    //jquery('#time').stopwatch().stopwatch('start');
    CanvasElement mainCanvas = engine.canvas["main"].element;
    CanvasElement guiCanvas = engine.canvas["gui"].element;
    mainCanvas.onMouseMove.listen((event) => onMouseMove(event));
    mainCanvas.onDoubleClick.listen((event) => onDoubleClick(event));
    mainCanvas
      ..onMouseDown.listen((event) => onMouseDown(event))
      ..onMouseUp.listen((event) => onMouseUp(event));
    // FIXME: will be implemented in M5: https://code.google.com/p/dart/issues/detail?id=9852
    //mainCanvas
    //  ..onMouseEnter.listen((event) => onEnter)
    //  ..onMouseLeave.listen((event) => onLeave);
    mainCanvas.onMouseWheel.listen((event) => onMouseScroll(event));

    guiCanvas.onMouseMove.listen((event) => onMouseMoveGUI(event));
    guiCanvas.onClick.listen((event) => onClickGUI(event));
    //guiCanvas.onMouseLeave.listen((event) => onLeaveGUI);

    document
      ..onKeyDown.listen((event) => onKeyDown(event))
      ..onKeyUp.listen((event) => onKeyUp(event));
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  /**
   * Loads all images.
   *
   * A callback is used to make sure the game starts after all images have been loaded.
   * Otherwise some images might not be rendered at all.
   */

  void loadImages(callback) {
    int loadedImages = 0;
    int numImages = this.imageSrcs.length - 1;

    for (int i = 0; i < this.imageSrcs.length; i++) {
      this.images[this.imageSrcs[i]] = new ImageElement();
      this.images[this.imageSrcs[i]].onLoad.listen((event) {
        if (++loadedImages >= numImages) {
          callback();
        }
      });
      this.images[this.imageSrcs[i]].src = "images/" + this.imageSrcs[i] + ".png";
    }
  }

  void addSound(name, type) {
    this.sounds[name] = new List();
    for (int i = 0; i < 5; i++) {
      this.sounds[name].add(new AudioElement("sounds/" + name + "." + type));
    }
  }

  void playSound(String name, [Vector position]) {
    // adjust sound volume based on the current zoom as well as the position

    num volume = 1;
    if (position != null) {
      Vector screenCenter = new Vector((this.halfWidth / (game.tileSize * game.zoom)).floor() + game.scroll.x, (this.halfHeight / (game.tileSize * game.zoom)).floor() + game.scroll.y);
      num distance = HelperDistance(screenCenter, position);
      volume = (game.zoom / Math.pow(distance / 20, 2)).clamp(0, 1);
    }

    for (int i = 0; i < 5; i++) {
      if (this.sounds[name][i].ended == true || this.sounds[name][i].currentTime == 0) {
        this.sounds[name][i].volume = volume;
        this.sounds[name][i].play();
        return;
      }
    }
  }

  void updateMouse(MouseEvent evt) {
    //if (evt.pageX > this.canvas["main"].left && evt.pageX < this.canvas["main"].right && evt.pageY > this.canvas["main"].top && evt.pageY < this.canvas["main"].bottom) {
    this.mouse.x = (evt.clientX - this.canvas["main"].element.getBoundingClientRect().left).toInt(); //evt.pageX - this.canvas["main"].left;
    this.mouse.y = (evt.clientY - this.canvas["main"].element.getBoundingClientRect().left).toInt(); //evt.pageY - this.canvas["main"].top;
    if (game != null) {
      Vector position = game.getHoveredTilePosition();
      this.mouse.dragEnd = new Vector(position.x, position.y);
    }

    //$("#mouse").innerHtml = ("Mouse: " + this.mouse.x + "/" + this.mouse.y + " - " + position.x + "/" + position.y);
    //}
  }

  void updateMouseGUI(MouseEvent evt) {
    //if (evt.pageX > this.canvas["gui"].left && evt.pageX < this.canvas["gui"].right && evt.pageY > this.canvas["gui"].top && evt.pageY < this.canvas["gui"].bottom) {
    this.mouseGUI.x = (evt.clientX - this.canvas["gui"].element.getBoundingClientRect().left).toInt();
    this.mouseGUI.y = (evt.clientY - this.canvas["gui"].element.getBoundingClientRect().top).toInt();
    
    query("#mouse").innerHtml = ("Mouse: " + this.mouseGUI.x.toString() + "/" + this.mouseGUI.y.toString());
    
    //}
  }

  void reset() {
    // reset FPS variables
    this.fps_lastTime = new DateTime.now();
    this.fps_frames = 0;
    this.fps_totalTime = 0;
    this.fps_updateTime = 0;
    this.fps_updateFrames = 0;
  }

  void update() { // FIXME
    // update FPS
    var now = new DateTime.now();
    this.fps_delta = now.millisecond - this.fps_lastTime;
    this.fps_lastTime = now;
    this.fps_totalTime += this.fps_delta;
    this.fps_frames++;
    this.fps_updateTime += this.fps_delta;
    this.fps_updateFrames++;

    // update FPS display
    if (this.fps_updateTime > 1000) {
      query("#fps").innerHtml = "FPS: " + (1000 * this.fps_frames / this.fps_totalTime).floor().toString() + " average, " + (1000 * this.fps_updateFrames / this.fps_updateTime).floor().toString() + " currently, " + (game.speed * this.FPS) + " desired";
      this.fps_updateTime -= 1000;
      this.fps_updateFrames = 0;
    }
  }

  /**
   * Checks if an object is visible on the screen
   *
   * @param   position
   * @param   size
   * @return  boolean
   */

  bool isVisible(Vector position, Vector size) {
    num r1_left = position.x;
    num r1_top = position.y;
    num r1_right = position.x + size.x;
    num r1_bottom = position.y + size.y;

    num r2_left = this.canvas["main"].left;
    num r2_top = this.canvas["main"].top;
    num r2_right = this.canvas["main"].right;
    num r2_bottom = this.canvas["main"].bottom;

    return !(r2_left > r1_right ||
        r2_right < r1_left ||
        r2_top > r1_bottom ||
        r2_bottom < r1_top);
  }
}

class World {
  List tiles;
  Vector size = new Vector(128, 128);
  List terraform;
}

class Game {
  num tileSize = 16, speed = 1, zoom = 1, currentEnergy = 0, maxEnergy = 0, collection = 0, creeperTimer = 0, energyTimer = 0, spawnTimer = 0, damageTimer = 0, smokeTimer = 0, explosionTimer = 0, shieldTimer = 0, activeSymbol = -1, packetSpeed = 1, shellSpeed = 1, sporeSpeed = 1, buildingSpeed = .5, shipSpeed = 1, terraformingHeight = 0;
  var running;
  String mode;
  bool paused = false, scrollingUp = false, scrollingDown = false, scrollingLeft = false, scrollingRight = false;
  List spores = [], smokes = [], explosions = [], symbols = [], emitters = [], sporetowers = [], packetQueue = [], ghosts = [];
  List<Building> buildings = new List<Building>();
  List<Packet> packets = new List<Packet>();
  List<Shell> shells = new List<Shell>();
  List<Ship> ships = new List<Ship>();
  World world = new World();
  Vector scroll = new Vector(0, 0);
  Building base;
  Map keyMap = {
      "k81": "Q", "k87": "W", "k69": "E", "k82": "R", "k84": "T", "k90": "Z", "k85": "U", "k73": "I", "k65": "A", "k83": "S", "k68": "D", "k70": "F", "k71": "G", "k72": "H"
  };

  Game();

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
  }

  void reset() {
    // TODO query('#time').stopwatch().stopwatch('reset');
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
  }

  void resume() {
    query('#pause').style.display = 'inline';
    query('#resume').style.display = 'none';
    query('#paused').style.display = 'none';
    this.paused = false;
  }

  void stop() {
    if (this.running != null)this.running.cancel();
  }

  void run() {
    this.running = new Timer.periodic(new Duration(milliseconds: (1000 / this.speed / engine.FPS).floor()), (Timer timer) => updates());
    engine.animationRequest = window.requestAnimationFrame(draw);
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

    //var heightmap = new HeightMap(129, 0, 90);
    //heightmap.run();

    for (int i = 0; i < this.world.size.x; i++) {
      for (int j = 0; j < this.world.size.y; j++) {
        int height = 7; //(heightmap.map[i][j] / 10).round();
        if (height > 10)
          height = 10;
        for (int k = 0; k < height; k++) {
          this.world.tiles[i][j][k].full = true;
        }
      }
    }

  /*for (int i = 0; i < this.world.size.x; i++) {
                for (int j = 0; j < this.world.size.y; j++) {
                    for (int k = 0; k < 10; k++) {

                        if (this.world.tiles[i][j][k].full) {
                            int up = 0, down = 0, left = 0, right = 0;
                            if (j - 1 < 0)
                                up = 0;
                            else if (this.world.tiles[i][j - 1][k].full)
                                up = 1;
                            if (j + 1 > this.world.size.y - 1)
                                down = 0;
                            else if (this.world.tiles[i][j + 1][k].full)
                                down = 1;
                            if (i - 1 < 0)
                                left = 0;
                            else if (this.world.tiles[i - 1][j][k].full)
                                left = 1;
                            if (i + 1 > this.world.size.x - 1)
                                right = 0;
                            else if (this.world.tiles[i + 1][j][k].full)
                                right = 1;

                            // save index for later use
                            this.world.tiles[i][j][k].index = (8 * down) + (4 * left) + (2 * up) + right;;
                        }
                    }

                }
            }

            for (int i = 0; i < this.world.size.x; i++) {
                for (int j = 0; j < this.world.size.y; j++) {
                    bool removeBelow = false;
                    for (int k = 9; k > -1; k--) {
                        if (removeBelow) {
                            this.world.tiles[i][j][k].full = false;
                        }
                        else {
                            int index = this.world.tiles[i][j][k].index;
                            if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
                            removeBelow = true;
                        }
                     }
                }
            }*/

    // create base
    Vector randomPosition = new Vector(
        HelperRandomInt(0, this.world.size.x - 9),
        HelperRandomInt(0, this.world.size.y - 9));

    this.scroll.x = randomPosition.x + 4;
    this.scroll.y = randomPosition.y + 4;

    Building building = new Building(randomPosition, "base");
    building.health = 40;
    building.maxHealth = 40;
    building.built = true;
    building.size = 9;
    this.buildings.add(building);
    game.base = building;

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
        HelperRandomInt(0, this.world.size.x - 3),
        HelperRandomInt(0, this.world.size.x - 3));

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
        HelperRandomInt(0, this.world.size.x - 3),
        HelperRandomInt(0, this.world.size.x - 3));

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
            if (k + 1 < 10 && index == this.world.tiles[i][j][k + 1].index)continue;

            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, engine.width + i * this.tileSize, engine.height + j * this.tileSize, this.tileSize, this.tileSize);

            // don't draw anymore under tiles that don't have transparent parts
            if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
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

            engine.canvas["level$k"].context.drawImageScaledFromSource(engine.images["borders"], index * (this.tileSize + 6) + 2, 2, this.tileSize + 2, this.tileSize + 2, engine.width + i * this.tileSize, engine.height + j * this.tileSize, (this.tileSize + 2), (this.tileSize + 2));

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
    var left = engine.width + this.scroll.x * this.tileSize - (engine.width / this.tileSize / 2) * this.tileSize * (1 / this.zoom);
    var top = engine.height + this.scroll.y * this.tileSize - (engine.height / this.tileSize / 2) * this.tileSize * (1 / this.zoom);
    var width = (engine.width / this.tileSize) * this.tileSize * (1 / this.zoom);
    var height = (engine.height / this.tileSize) * this.tileSize * (1 / this.zoom);
    engine.canvas["levelfinal"].context.drawImageScaledFromSource(engine.canvas["levelbuffer"].element, left, top, width, height, 0, 0, engine.width, engine.height);
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
          if (t + 1 < 10 && index == this.world.tiles[iS][jS][t + 1].index)continue;

          tempContext[t].drawImageScaledFromSource(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 0, 0, this.tileSize, this.tileSize);

          // don't draw anymore under tiles that don't have transparent parts
          if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)break;
        }
      }

      // redraw pattern
      for (int t = 9; t > -1; t--) {
        /*var tCanvas = document.createElement('canvas');
                  tCanvas.width = 256;
                  tCanvas.height = 256;
                  var ctx = tCanvas.getContext('2d');

                  ctx.drawImage(engine.images["level" + t], 0, 0);
                  var pattern = tempContext[t].createPattern(tCanvas, 'repeat');*/

        if (this.world.tiles[iS][jS][t].full) {
          var pattern = tempContext[t].createPattern(engine.images["level$t"], 'repeat');

          tempContext[t].globalCompositeOperation = 'source-in';
          tempContext[t].fillStyle = pattern;

          tempContext[t].save();
          Vector translation = new Vector(engine.width + (iS * this.tileSize).floor(), engine.height + (jS * this.tileSize).floor());
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

      engine.canvas["levelbuffer"].context.clearRect(engine.width + iS * this.tileSize, engine.height + jS * this.tileSize, this.tileSize, this.tileSize);
      for (int t = 0; t < 10; t++) {
        engine.canvas["levelbuffer"].context.drawImageScaledFromSource(tempCanvas[t], 0, 0, this.tileSize, this.tileSize, engine.width + iS * this.tileSize, engine.height + jS * this.tileSize, this.tileSize, this.tileSize);
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

        if (this.buildings[t].imageID == "terp" && this.buildings[t].energy > 0) {
          // find lowest target
          if (this.buildings[t].weaponTargetPosition == null) {

            // find lowest tile
            Vector target = null;
            int lowestTile = 10;
            for (int i = position.x - this.buildings[t].weaponRadius; i <= position.x + this.buildings[t].weaponRadius; i++) {
              for (int j = position.y - this.buildings[t].weaponRadius; j <= position.y + this.buildings[t].weaponRadius; j++) {

                if (this.withinWorld(i, j)) {
                  var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);
                  var tileHeight = this.getHighestTerrain(new Vector(i, j));

                  if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.terraform[i][j]["target"] > -1 && tileHeight <= lowestTile) {
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

              if (height < terraformElement.target) {
                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height + 1].full = true;
                // reset index around tile
                for (int i = -1; i <= 1; i++) {
                  for (int j = -1; j <= 1; j++) {
                    tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x + i, this.buildings[t].weaponTargetPosition.y + j, height + 1));
                  }
                }
              } else {
                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height].full = false;
                // reset index around tile
                for (int i = -1; i <= 1; i++) {
                  for (int j = -1; j <= 1; j++) {
                    tilesToRedraw.add(new Vector3(this.buildings[t].weaponTargetPosition.x + i, this.buildings[t].weaponTargetPosition.y + j, height));
                  }
                }
              }

              this.redrawTile(tilesToRedraw);
              this.copyTerrain();

              height = this.getHighestTerrain(this.buildings[t].weaponTargetPosition);
              if (height == terraformElement.target) {
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
                      var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                      if (distance <= Math.pow(radius, 2) && this.world.tiles[i][j][0].creep > 0) {
                        targets.add(new Vector(i, j));
                      }
                    }
                  }
                }
              }
              if (targets.length > 0) {
                HelperShuffle(targets);

                this.world.tiles[targets[0].x][targets[0].y][0].creep -= 10;
                if (this.world.tiles[targets[0].x][targets[0].y][0].creep < 0)
                  this.world.tiles[targets[0].x][targets[0].y][0].creep = 0;

                var dx = targets[0].x * this.tileSize + this.tileSize / 2 - center.x;
                var dy = targets[0].y * this.tileSize + this.tileSize / 2 - center.y;
                this.buildings[t].targetAngle = Math.atan2(dy, dx) + Math.PI / 2;
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
                  if (game.withinWorld(i, j)) {
                    var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);
  
                    if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.tiles[i][j][0].creep > 0 && this.world.tiles[i][j][0].creep >= highestCreep) {
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
                  var distance = Math.pow(sporeCenter.x - center.x, 2) + Math.pow(sporeCenter.y - center.y, 2);

                  if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2)) {
                    this.buildings[t].weaponTargetPosition = sporeCenter;
                    this.buildings[t].energy -= .1;
                    this.buildings[t].operating = true;
                    this.spores[i].health -= 2;
                    if (this.spores[i].health <= 0) {
                      this.spores[i].remove = true;
                      engine.playSound("explosion", HelperReal2tiled(this.spores[i].position));
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
            if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
              if (tileHeight == height) {
                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = building;
              }
            }
          } else if (action == "remove") {

            if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
              if (tileHeight == height) {
                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = null;
              }
            }

            for (int k = 0; k < this.buildings.length; k++) {
              if (this.buildings[k] != building && this.buildings[k].imageID == "collector") {
                int heightK = this.getHighestTerrain(new Vector(this.buildings[k].position.x, this.buildings[k].position.y));
                Vector centerBuildingK = this.buildings[k].getCenter();
                if (Math.pow(positionCurrentCenter.x - centerBuildingK.x, 2) + Math.pow(positionCurrentCenter.y - centerBuildingK.y, 2) < Math.pow(this.tileSize * 6, 2)) {
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

    num minimum = .001;

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
          if (i - 1 > -1 && i + 1 < this.world.size.x && j - 1 > -1 && j + 1 < this.world.size.y) {
            //if (height >= 0) {
            // right neighbour
            int height2 = this.getHighestTerrain(new Vector(i + 1, j));
            this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i + 1][j][0]);
            // bottom right neighbour
            height2 = this.getHighestTerrain(new Vector(i - 1, j));
            this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i - 1][j][0]);
            // bottom neighbour
            height2 = this.getHighestTerrain(new Vector(i, j + 1));
            this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i][j + 1][0]);
            // bottom left neighbour
            height2 = this.getHighestTerrain(new Vector(i, j - 1));
            this.transferCreeper(height, height2, this.world.tiles[i][j][0], this.world.tiles[i][j - 1][0]);
            //}
          }

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
              num distance = HelperDistance(centerI, centerNode);

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
            num distance = HelperDistance(centerI, centerNode);

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
          newRoute.nodes = HelperClone(oldRoute.nodes);

          // add the new node to the new route
          newRoute.nodes.add(neighbours[i]);

          // copy distance travelled from old route to new route
          newRoute.distanceTravelled = oldRoute.distanceTravelled;

          // increase distance travelled
          Vector centerA = newRoute.nodes[newRoute.nodes.length - 1].getCenter();
          Vector centerB = newRoute.nodes[newRoute.nodes.length - 2].getCenter();
          newRoute.distanceTravelled += HelperDistance(centerA, centerB);

          // update underestimate of distance remaining
          Vector centerC = packet.target.getCenter();
          newRoute.distanceRemaining = HelperDistance(centerC, centerA);

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
    Vector center = game.base.getCenter();
    Packet packet = new Packet(center, img, type);
    packet.target = building;
    packet.currentTarget = game.base;
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
          int healthAndRequestDelta = this.buildings[i].maxHealth - this.buildings[i].health - this.buildings[i].healthRequests;
          if (healthAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
            this.buildings[i].requestTimer = 0;
            this.queuePacket(this.buildings[i], "health");
          }
        }
        // request energy
        if (this.buildings[i].needsEnergy && this.buildings[i].built) {
          int energyAndRequestDelta = this.buildings[i].maxEnergy - this.buildings[i].energy - this.buildings[i].energyRequests;
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
                
                if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
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
        packet.target = game.base;
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
      this.updateBuildings();
      this.updateCreeper();
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
    Vector positionCenter = new Vector(position.x * this.tileSize + (this.tileSize / 2) * size, position.y * this.tileSize + (this.tileSize / 2) * size);
    int positionHeight = this.getHighestTerrain(position);

    if (this.canBePlaced(position, size, null) && (type == "collector" || type == "cannon" || type == "mortar" || type == "shield" || type == "beam" || type == "terp")) {

      engine.canvas["buffer"].context.save();
      engine.canvas["buffer"].context.globalAlpha = .25;

      int radius = rad * this.tileSize;

      for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {

          Vector positionCurrent = new Vector(position.x + i, position.y + j);
          Vector positionCurrentCenter = new Vector(positionCurrent.x * this.tileSize + (this.tileSize / 2), positionCurrent.y * this.tileSize + (this.tileSize / 2));

          Vector drawPositionCurrent = HelperTiled2screen(positionCurrent);

          if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
            int positionCurrentHeight = this.getHighestTerrain(positionCurrent);

            if (Math.pow(positionCurrentCenter.x - positionCenter.x, 2) + Math.pow(positionCurrentCenter.y - positionCenter.y, 2) < Math.pow(radius, 2)) {
              if (type == "collector") {
                if (positionCurrentHeight == positionHeight) {
                  engine.canvas["buffer"].context.fillStyle = "#fff";
                } else {
                  engine.canvas["buffer"].context.fillStyle = "#f00";
                }
              }
              if (type == "cannon") {
                if (positionCurrentHeight <= positionHeight) {
                  engine.canvas["buffer"].context.fillStyle = "#fff";
                } else {
                  engine.canvas["buffer"].context.fillStyle = "#f00";
                }
              }
              if (type == "mortar" || type == "shield" || type == "beam" || type == "terp") {
                engine.canvas["buffer"].context.fillStyle = "#fff";
              }
              engine.canvas["buffer"].context.fillRect(drawPositionCurrent.x, drawPositionCurrent.y, this.tileSize * this.zoom, this.tileSize * this.zoom);
            }

          }
        }
      }
      engine.canvas["buffer"].context.restore();
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

            //if (creep > 1) {
            //    engine.canvas["buffer"].context.drawImage(engine.images["creep"], 15 * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
            //}

            int index = (8 * down) + (4 * left) + (2 * up) + right;
            engine.canvas["creeper"].context.drawImageScaledFromSource(engine.images["creep"], index * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * game.zoom, engine.halfHeight + j * this.tileSize * game.zoom, this.tileSize * game.zoom, this.tileSize * game.zoom);
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
    game.ghosts = new List(); // ghosts are all the placeholders to build
    if (engine.mouse.dragStart != null) {

      Vector start = engine.mouse.dragStart;
      Vector end = engine.mouse.dragEnd;
      Vector delta = new Vector(end.x - start.x, end.y - start.y);
      num distance = HelperDistance(start, end);
      num times = (distance / 10).floor() + 1;

      game.ghosts.add(start);

      for (int i = 1; i < times; i++) {
        num newX = (start.x + (delta.x / distance) * i * 10).floor();
        num newY = (start.y + (delta.y / distance) * i * 10).floor();

        if (this.withinWorld(newX, newY)) {
          Vector ghost = new Vector(newX, newY);
          game.ghosts.add(ghost);
        }
      }
      if (this.withinWorld(end.x, end.y)) {
        game.ghosts.add(end);
      }
    } else {
      if (engine.mouse.active) {
        Vector position = this.getHoveredTilePosition();
        if (this.withinWorld(position.x, position.y)) {
          game.ghosts.add(position);
        }
      }
    }

    for (int j = 0; j < game.ghosts.length; j++) {
      Vector positionScrolled = new Vector(game.ghosts[j].x, game.ghosts[j].y); //this.getHoveredTilePosition();
      Vector drawPosition = HelperTiled2screen(positionScrolled);
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
          Vector drawCenter = HelperReal2screen(center);

          int allowedDistance = 10 * this.tileSize;
          if (this.buildings[i].imageID == "relay" && this.symbols[this.activeSymbol].imageID == "relay") {
            allowedDistance = 20 * this.tileSize;
          }

          if (Math.pow(center.x - positionScrolledCenter.x, 2) + Math.pow(center.y - positionScrolledCenter.y, 2) <= Math.pow(allowedDistance, 2)) {
            Vector lineToTarget = HelperReal2screen(positionScrolledCenter);
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
        for (int k = 0; k < game.ghosts.length; k++) {
          if (k != j) {
            Vector center = new Vector(game.ghosts[k].x * game.tileSize + (game.tileSize / 2) * 3, game.ghosts[k].y * game.tileSize + (game.tileSize / 2) * 3);
            Vector drawCenter = HelperReal2screen(center);

            int allowedDistance = 10 * this.tileSize;
            if (this.symbols[this.activeSymbol].imageID == "relay") {
              allowedDistance = 20 * this.tileSize;
            }

            if (Math.pow(center.x - positionScrolledCenter.x, 2) + Math.pow(center.y - positionScrolledCenter.y, 2) <= Math.pow(allowedDistance, 2)) {
              Vector lineToTarget = HelperReal2screen(positionScrolledCenter);
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
      Vector position = HelperTiled2screen(this.getHoveredTilePosition());
      engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], position.x - this.tileSize, position.y - this.tileSize);
    }
  }

  /**
     * Draws the GUI with symbols, height and creep meter.
     */

  void drawGUI() {
    Vector position = game.getHoveredTilePosition();

    engine.canvas["gui"].clear();
    for (int i = 0; i < this.symbols.length; i++) {
      this.symbols[i].draw(engine.canvas["gui"].context);
    }

    if (this.withinWorld(position.x, position.y)) {

      num total = this.world.tiles[position.x][position.y][0].creep;

      // draw height and creep meter
      engine.canvas["gui"].context.fillStyle = '#fff';
      engine.canvas["gui"].context.font = '9px';
      engine.canvas["gui"].context.textAlign = 'right';
      engine.canvas["gui"].context.strokeStyle = '#fff';
      engine.canvas["gui"].context.lineWidth = 1;
      engine.canvas["gui"].context.fillStyle = "rgba(205, 133, 63, 1)";
      engine.canvas["gui"].context.fillRect(555, 110, 25, -this.getHighestTerrain(this.getHoveredTilePosition()) * 10 - 10);
      engine.canvas["gui"].context.fillStyle = "rgba(100, 150, 255, 1)";
      engine.canvas["gui"].context.fillRect(555, 110 - this.getHighestTerrain(this.getHoveredTilePosition()) * 10 - 10, 25, -total * 10);
      engine.canvas["gui"].context.fillStyle = "rgba(255, 255, 255, 1)";
      for (int i = 1; i < 11; i++) {
        engine.canvas["gui"].context.fillText(i.toString(), 550, 120 - i * 10);
        engine.canvas["gui"].context.beginPath();
        engine.canvas["gui"].context.moveTo(555, 120 - i * 10);
        engine.canvas["gui"].context.lineTo(580, 120 - i * 10);
        engine.canvas["gui"].context.stroke();
      }
      engine.canvas["gui"].context.textAlign = 'left';
      engine.canvas["gui"].context.fillText(total.toStringAsFixed(2), 605, 10);
    }
  }
}

/**
 * Building symbols in the GUI
 */

class UISymbol {
  Vector position;
  String imageID, key;
  num width = 80, height = 55, size, packets, radius;
  bool active = false, hovered = false;

  UISymbol(this.position, this.imageID, this.key, this.size, this.packets, this.radius);

  void draw(pContext) {
    if (this.active) {
      pContext.fillStyle = "#696";
    } else {
      if (this.hovered) {
        pContext.fillStyle = "#232";
      } else {
        pContext.fillStyle = "#454";
      }
    }
    pContext.fillRect(this.position.x + 1, this.position.y + 1, this.width, this.height);

    pContext.drawImageScaled(engine.images[this.imageID], this.position.x + 24, this.position.y + 20, 32, 32); // scale buildings to 32x32
    // draw cannon gun and ships
    if (this.imageID == "cannon")pContext.drawImageScaled(engine.images["cannongun"], this.position.x + 24, this.position.y + 20, 32, 32);
    if (this.imageID == "bomber")pContext.drawImageScaled(engine.images["bombership"], this.position.x + 24, this.position.y + 20, 32, 32);
    pContext.fillStyle = '#fff';
    pContext.font = '10px';
    pContext.textAlign = 'center';
    pContext.fillText(this.imageID.substring(0, 1).toUpperCase() + this.imageID.substring(1), this.position.x + (this.width / 2), this.position.y + 15);
    pContext.textAlign = 'left';
    pContext.fillText("(" + this.key.toString() + ")", this.position.x + 5, this.position.y + 50);
    pContext.textAlign = 'right';
    pContext.fillText(this.packets.toString(), this.position.x + this.width - 5, this.position.y + 50);
  }

  void checkHovered() {
    this.hovered = (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height);
  }

  void setActive() {
    this.active = false;
    if (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height) {
      game.activeSymbol = (this.position.x / 81).floor() + ((this.position.y / 56).floor()) * 5;
      this.active = true;
    }
  }
}

class Building {
  Vector position, moveTargetPosition, weaponTargetPosition, speed = new Vector(0, 0);
  String imageID;
  bool operating = false, selected = false, hovered = false, built = false, active = true, moving = false, canMove = false, needsEnergy = false;
  num health = 0, maxHealth = 0, energy = 0, maxEnergy = 0, energyTimer = 0, healthRequests = 0, energyRequests = 0, requestTimer = 0, weaponRadius = 0, targetAngle = 0, size = 0, collectedEnergy = 0;
  Ship ship;

  Building(this.position, this.imageID);

  bool updateHoverState() {
    Vector position = HelperTiled2screen(this.position);
    this.hovered = (engine.mouse.x > position.x && engine.mouse.x < position.x + game.tileSize * this.size * game.zoom - 1 && engine.mouse.y > position.y && engine.mouse.y < position.y + game.tileSize * this.size * game.zoom - 1);

    return this.hovered;
  }

  void drawBox() {
    if (this.hovered || this.selected) {
      Vector position = HelperTiled2screen(this.position);
      engine.canvas["buffer"].context.lineWidth = 2 * game.zoom;
      engine.canvas["buffer"].context.strokeStyle = "#000";
      engine.canvas["buffer"].context.strokeRect(position.x, position.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
    }
  }

  void move() {
    if (this.moving) {
      this.position.x += this.speed.x;
      this.position.y += this.speed.y;
      if (this.position.x * game.tileSize > this.moveTargetPosition.x * game.tileSize - 3 && this.position.x * game.tileSize < this.moveTargetPosition.x * game.tileSize + 3 && this.position.y * game.tileSize > this.moveTargetPosition.y * game.tileSize - 3 && this.position.y * game.tileSize < this.moveTargetPosition.y * game.tileSize + 3) {
        this.moving = false;
        this.position.x = this.moveTargetPosition.x;
        this.position.y = this.moveTargetPosition.y;
      }
    }
  }

  void calculateVector() {
    if (this.moveTargetPosition.x != this.position.x || this.moveTargetPosition.y != this.position.y) {
      Vector targetPosition = new Vector(this.moveTargetPosition.x * game.tileSize, this.moveTargetPosition.y * game.tileSize);
      Vector ownPosition = new Vector(this.position.x * game.tileSize, this.position.y * game.tileSize);
      Vector delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
      num distance = HelperDistance(targetPosition, ownPosition);

      this.speed.x = (delta.x / distance) * game.buildingSpeed * game.speed / game.tileSize;
      this.speed.y = (delta.y / distance) * game.buildingSpeed * game.speed / game.tileSize;
    }
  }

  Vector getCenter() {
    return new Vector(this.position.x * game.tileSize + (game.tileSize / 2) * this.size, this.position.y * game.tileSize + (game.tileSize / 2) * this.size);
  }

  void takeDamage() {
    // buildings can only be damaged while not moving
    if (!this.moving) {

      for (int i = 0; i < this.size; i++) {
        for (int j = 0; j < this.size; j++) {
          if (game.world.tiles[this.position.x + i][this.position.y + j][0].creep > 0) {
            this.health -= game.world.tiles[this.position.x + i][this.position.y + j][0].creep;
          }
        }
      }

      if (this.health < 0) {
        game.removeBuilding(this);
      }
    }
  }

  void drawMovementIndicators() {
    if (this.moving) {
      Vector center = HelperReal2screen(this.getCenter());
      Vector target = HelperTiled2screen(this.moveTargetPosition);
      // draw box
      engine.canvas["buffer"].context.fillStyle = "rgba(0,255,0,0.5)";
      engine.canvas["buffer"].context.fillRect(target.x, target.y, this.size * game.tileSize * game.zoom, this.size * game.tileSize * game.zoom);
      // draw line
      engine.canvas["buffer"].context.strokeStyle = "rgba(255,255,255,0.5)";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(center.x, center.y);
      engine.canvas["buffer"].context.lineTo(target.x + (game.tileSize / 2) * this.size * game.zoom, target.y + (game.tileSize / 2) * this.size * game.zoom);
      engine.canvas["buffer"].context.stroke();
    }
  }

  void drawRepositionInfo() {
    if (this.built && this.selected && this.canMove) {
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = HelperTiled2screen(positionScrolled);
      Vector positionScrolledCenter = new Vector(positionScrolled.x * game.tileSize + (game.tileSize / 2) * this.size, positionScrolled.y * game.tileSize + (game.tileSize / 2) * this.size);
      Vector drawPositionCenter = HelperReal2screen(positionScrolledCenter);

      Vector center = HelperReal2screen(this.getCenter());

      game.drawRangeBoxes(positionScrolled, this.imageID, this.weaponRadius, this.size);

      if (game.canBePlaced(positionScrolled, this.size, this))engine.canvas["buffer"].context.strokeStyle = "rgba(0,255,0,0.5)"; else
        engine.canvas["buffer"].context.strokeStyle = "rgba(255,0,0,0.5)";

      // draw rectangle
      engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
      // draw line
      engine.canvas["buffer"].context.strokeStyle = "rgba(255,255,255,0.5)";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(center.x, center.y);
      engine.canvas["buffer"].context.lineTo(drawPositionCenter.x, drawPositionCenter.y);
      engine.canvas["buffer"].context.stroke();
    }
  }

  void shield() {
    if (this.built && this.imageID == "shield" && !this.moving) {
      Vector center = this.getCenter();

      for (int i = this.position.x - 9; i < this.position.x + 10; i++) {
        for (int j = this.position.y - 9; j < this.position.y + 10; j++) {
          if (game.withinWorld(i, j)) {
            num distance = Math.pow((i * game.tileSize + game.tileSize / 2) - center.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - center.y, 2);
            if (distance < Math.pow(game.tileSize * 10, 2)) {
              if (game.world.tiles[i][j][0].creep > 0) {
                game.world.tiles[i][j][0].creep -= distance / game.tileSize * .1; // the closer to the shield the more creep is removed
                if (game.world.tiles[i][j][0].creep < 0) {
                  game.world.tiles[i][j][0].creep = 0;
                }
              }
            }
          }
        }
      }

    }
  }

  void draw() {
    Vector position = HelperTiled2screen(this.position);
    Vector center = HelperReal2screen(this.getCenter());

    if (engine.isVisible(position, new Vector(engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom))) {
      if (!this.built) {
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;
        engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        if (this.imageID == "cannon") {
          engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        }
        engine.canvas["buffer"].context.restore();
      } else {
        engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
        if (this.imageID == "cannon") {
          engine.canvas["buffer"].context.save();
          engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
          engine.canvas["buffer"].context.rotate(this.targetAngle);
          engine.canvas["buffer"].context.drawImageScaled(engine.images["cannongun"], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
          engine.canvas["buffer"].context.restore();
        }
      }

      // draw energy bar
      if (this.needsEnergy) {
        engine.canvas["buffer"].context.fillStyle = '#f00';
        engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
      }

      // draw health bar (only if health is below maxHealth)
      if (this.health < this.maxHealth) {
        engine.canvas["buffer"].context.fillStyle = '#0f0';
        engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + game.tileSize * game.zoom * this.size - 3, ((game.tileSize * game.zoom * this.size - 8) / this.maxHealth) * this.health, 3);
      }

      // draw inactive sign
      if (!this.active) {
        engine.canvas["buffer"].context.strokeStyle = "#F00";
        engine.canvas["buffer"].context.lineWidth = 2;

        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.arc(center.x, center.y, (game.tileSize / 2) * this.size, 0, Math.PI * 2, true);
        engine.canvas["buffer"].context.closePath();
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(position.x, position.y + game.tileSize * this.size);
        engine.canvas["buffer"].context.lineTo(position.x + game.tileSize * this.size, position.y);
        engine.canvas["buffer"].context.stroke();
      }
    }

    // draw shots
    if (this.operating) {
      if (this.imageID == "cannon") {
        Vector targetPosition = HelperTiled2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = "#f00";
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();
      }
      if (this.imageID == "beam") {
        Vector targetPosition = HelperReal2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = '#f00';
        engine.canvas["buffer"].context.lineWidth = 4;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.strokeStyle = '#fff';
        engine.canvas["buffer"].context.lineWidth = 2;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
        engine.canvas["buffer"].context.stroke();
      }
      if (this.imageID == "shield") {
        engine.canvas["buffer"].context.drawImageScaled(engine.images["forcefield"], center.x - 168 * game.zoom, center.y - 168 * game.zoom, 336 * game.zoom, 336 * game.zoom);
      }
      if (this.imageID == "terp") {
        Vector targetPosition = HelperTiled2screen(this.weaponTargetPosition);
        engine.canvas["buffer"].context.strokeStyle = '#f00';
        engine.canvas["buffer"].context.lineWidth = 4;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x + 8, targetPosition.y + 8);
        engine.canvas["buffer"].context.stroke();

        engine.canvas["buffer"].context.strokeStyle = '#fff';
        engine.canvas["buffer"].context.lineWidth = 2;
        engine.canvas["buffer"].context.beginPath();
        engine.canvas["buffer"].context.moveTo(center.x, center.y);
        engine.canvas["buffer"].context.lineTo(targetPosition.x + 8, targetPosition.y + 8);
        engine.canvas["buffer"].context.stroke();
      }
    }

  }
}

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
    num distance = HelperDistance(targetPosition, this.position);

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
    Vector position = HelperReal2screen(this.position);
    if (engine.isVisible(new Vector(position.x - 8, position.y - 8), new Vector(16 * game.zoom, 16 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x - 8 * game.zoom, position.y - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
    }
  }
}

/**
 * Shells (fired by Mortars)
 */

class Shell {
  Vector position, targetPosition, speed = new Vector(0, 0);
  String imageID;
  bool remove;
  num rotation = 0, trailTimer = 0;

  Shell(this.position, this.imageID, this.targetPosition);

  void init() {
    Vector delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
    num distance = HelperDistance(this.targetPosition, this.position);

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

    this.position.x += this.speed.x;
    this.position.y += this.speed.y;

    if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
      // if the target is reached explode and remove
      this.remove = true;

      game.explosions.add(new Explosion(this.targetPosition));
      engine.playSound("explosion", HelperReal2tiled(this.targetPosition));

      for (int i = (this.targetPosition.x / game.tileSize).floor() - 4; i < (this.targetPosition.x / game.tileSize).floor() + 5; i++) {
        for (int j = (this.targetPosition.y / game.tileSize).floor() - 4; j < (this.targetPosition.y / game.tileSize).floor() + 5; j++) {
          if (game.withinWorld(i, j)) {
            num distance = Math.pow((i * game.tileSize + game.tileSize / 2) - this.targetPosition.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - this.targetPosition.y, 2);
            if (distance < Math.pow(game.tileSize * 4, 2)) {
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
    Vector position = HelperReal2screen(this.position);

    if (engine.isVisible(position, new Vector(16 * game.zoom, 16 * game.zoom))) {
      engine.canvas["buffer"].context.save();
      engine.canvas["buffer"].context.translate(position.x + 8 * game.zoom, position.y + 8 * game.zoom);
      engine.canvas["buffer"].context.rotate(HelperDeg2rad(this.rotation));
      engine.canvas["buffer"].context.drawImageScaled(engine.images["shell"], -8 * game.zoom, -8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
      engine.canvas["buffer"].context.restore();
    }
  }
}

/**
 * Spore (fired by Sporetower)
 */

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
    num distance = HelperDistance(this.targetPosition, this.position);

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
      engine.playSound("explosion", HelperReal2tiled(this.targetPosition));

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
    Vector position = HelperReal2screen(this.position);

    if (engine.isVisible(position, new Vector(32 * game.zoom, 32 * game.zoom))) {
      engine.canvas["buffer"].context.save();
      engine.canvas["buffer"].context.translate(position.x, position.y);
      engine.canvas["buffer"].context.rotate(HelperDeg2rad(this.rotation));
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], -16 * game.zoom, -16 * game.zoom, 32 * game.zoom, 32 * game.zoom);
      engine.canvas["buffer"].context.restore();
    }
  }
}

/**
 * Ships (Bomber)
 */

class Ship {
  Vector position, speed, targetPosition;
  String imageID, type;
  bool remove = false, hovered, selected;
  num angle, maxEnergy = 15, energy = 0, status = 0, trailTimer = 0, weaponTimer = 0;
  Building home;

  Ship(this.position, this.imageID, this.type, this.home);

  Vector getCenter() {
    return new Vector(this.position.x + 24, this.position.y + 24);
  }

  bool updateHoverState() {
    Vector position = HelperReal2screen(this.position);
    this.hovered = (engine.mouse.x > position.x && engine.mouse.x < position.x + 47 && engine.mouse.y > position.y && engine.mouse.y < position.y + 47);

    return this.hovered;
  }

  void turnToTarget() {
    Vector delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
    int angleToTarget = HelperRad2deg(Math.atan2(delta.y, delta.x));

    num turnRate = 1.5;
    num absoluteDelta = (angleToTarget - this.angle).abs();

    if (absoluteDelta < turnRate)
      turnRate = absoluteDelta;

    if (absoluteDelta <= 180)
      if (angleToTarget < this.angle)
        this.angle -= turnRate;
      else
        this.angle += turnRate;
    else
      if (angleToTarget < this.angle)
        this.angle += turnRate;
      else
        this.angle -= turnRate;

    if (this.angle > 180)this.angle -= 360;
    if (this.angle < -180)this.angle += 360;
  }

  void calculateVector() {
    num x = Math.cos(HelperDeg2rad(this.angle));
    num y = Math.sin(HelperDeg2rad(this.angle));

    this.speed.x = x * game.shipSpeed * game.speed;
    this.speed.y = y * game.shipSpeed * game.speed;
  }

  void move() {

    if (this.status != 0) {
      this.trailTimer++;
      if (this.trailTimer == 10) {
        this.trailTimer = 0;
        game.smokes.add(new Smoke(this.getCenter()));
      }

      this.weaponTimer++;

      this.turnToTarget();
      this.calculateVector();

      this.position.x += this.speed.x;
      this.position.y += this.speed.y;

      if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
        if (this.status == 1) {
          // attacking
          if (this.weaponTimer >= 10) {
            this.weaponTimer = 0;
            game.explosions.add(new Explosion(this.targetPosition));
            this.energy -= 1;

            for (int i = (this.targetPosition.x / game.tileSize).floor() - 3; i < (this.targetPosition.x / game.tileSize).floor() + 5; i++) {
              for (int j = (this.targetPosition.y / game.tileSize).floor() - 3; j < (this.targetPosition.y / game.tileSize).floor() + 5; j++)
                if (game.withinWorld(i, j)) {
                  {
                    num distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.targetPosition.x + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.targetPosition.y + game.tileSize), 2);
                    if (distance < Math.pow(game.tileSize * 3, 2)) {
                      game.world.tiles[i][j][0].creep -= 5;
                      if (game.world.tiles[i][j][0].creep < 0) {
                        game.world.tiles[i][j][0].creep = 0;
                      }
                    }
                  }
                }
            }

            if (this.energy == 0) {
              // return to base
              this.status = 2;
              this.targetPosition.x = this.home.position.x * game.tileSize;
              this.targetPosition.y = this.home.position.y * game.tileSize;
            }
          }
        } else if (this.status == 2) {
          // if returning set to idle
          this.status = 0;
          this.position.x = this.home.position.x * game.tileSize;
          this.position.y = this.home.position.y * game.tileSize;
          this.targetPosition.x = 0;
          this.targetPosition.y = 0;
          this.energy = 5;
        }
      }
    }
  }

  void draw() {
    Vector position = HelperReal2screen(this.position);

    if (this.hovered) {
      engine.canvas["buffer"].context.strokeStyle = "#f00";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, Math.PI * 2, true);
      engine.canvas["buffer"].context.closePath();
      engine.canvas["buffer"].context.stroke();
    }

    if (this.selected) {
      engine.canvas["buffer"].context.strokeStyle = "#fff";
      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, Math.PI * 2, true);
      engine.canvas["buffer"].context.closePath();
      engine.canvas["buffer"].context.stroke();

      if (this.status == 1) {
        Vector cursorPosition = HelperReal2screen(this.targetPosition);
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;
        engine.canvas["buffer"].context.drawImageScaled(engine.images["targetcursor"], cursorPosition.x - game.tileSize * game.zoom, cursorPosition.y - game.tileSize * game.zoom, 48 * game.zoom, 48 * game.zoom);
        engine.canvas["buffer"].context.restore();
      }
    }

    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      // draw ship
      engine.canvas["buffer"].context.save();
      engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
      engine.canvas["buffer"].context.rotate(HelperDeg2rad(this.angle + 90));
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
      engine.canvas["buffer"].context.restore();

      // draw energy bar
      engine.canvas["buffer"].context.fillStyle = '#f00';
      engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
    }
  }
}

class Emitter {
  Vector position;
  String imageID;
  num strength;

  Emitter(this.position, this.strength) {
    this.imageID = "emitter";
  }

  void draw() {
    Vector position = HelperTiled2screen(this.position);
    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
    }
  }

  void spawn() {
    game.world.tiles[this.position.x + 1][this.position.y + 1][0].creep += this.strength;
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
    this.sporeTimer = HelperRandomInt(7500, 12500);
  }

  Vector getCenter() {
    return new Vector(this.position.x * game.tileSize + 24, this.position.y * game.tileSize + 24);
  }

  void draw() {
    Vector position = HelperTiled2screen(this.position);
    if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
      engine.canvas["buffer"].context.drawImageScaled(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
    }
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
      target = game.buildings[HelperRandomInt(0, game.buildings.length)];
    } while (!target.built);
    Spore spore = new Spore(this.getCenter(), target.getCenter());
    spore.init();
    game.spores.add(spore);
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
    Vector position = HelperReal2screen(this.position);
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
    Vector position = HelperReal2screen(this.position);
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
  CanvasRenderingContext2D  context;
  num top, left, bottom, right;

  Canvas(this.element, width, height) {
    this.element.attributes['width'] = width.toString();
    this.element.attributes['height'] = height.toString();
    this.element.style.position = "absolute";
    this.context = this.element.getContext('2d');
    this.top = this.element.offset.top;
    this.left = this.element.offset.left;
    this.bottom = this.element.offset.top + this.element.offset.height;
    this.right = this.element.offset.left + this.element.offset.width;
    this.context.imageSmoothingEnabled = false;
  }

  void clear() {
    this.context.clearRect(0, 0, this.element.width, this.element.height);
  }
}

Engine engine;

Game game;

void main() {
  engine = new Engine();
  engine.init();
  engine.loadImages(() {
    game = new Game();
    game.init();
    game.drawTerrain();
    game.copyTerrain();

    //engine.sounds["music"].loop = true;
    //engine.sounds["music"].play();

    game.stop();
    game.run();
  });
}

void startGame() {
  game = new Game();
  game.init();
  game.drawTerrain();
  game.copyTerrain();

  //engine.sounds["music"].loop = true;
  //engine.sounds["music"].play();

  game.stop();
  game.run();
}

void updates() {
  //engine.update();
  game.update();
}

void onMouseMove(MouseEvent evt) {
  engine.updateMouse(evt);
}

void onMouseMoveGUI(MouseEvent evt) {
  engine.updateMouseGUI(evt);

  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].checkHovered();
  }
}

void onKeyDown(KeyboardEvent evt) {
  // select instruction with keypress
  String key = game.keyMap["k${evt.keyCode}"];
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].active = false;
    if (game.symbols[i].key == key) {
      game.activeSymbol = i;
      game.symbols[i].active = true;
    }
  }

  if (game.activeSymbol != -1) {
    engine.canvas["main"].element.style.cursor = "none";
  }

  // delete building
  if (evt.keyCode == KeyCode.DELETE) {
    for (int i = 0; i < game.buildings.length; i++) {
      if (game.buildings[i].selected) {
        if (game.buildings[i].imageID != "base")game.removeBuilding(game.buildings[i]);
      }
    }
  }

  // pause/resume
  if (evt.keyCode == KeyCode.PAUSE) {
    if (game.paused)game.resume(); else
      game.pause();
  }

  // deselect all
  if (evt.keyCode == KeyCode.ESC) {
    game.activeSymbol = -1;
    for (int i = 0; i < game.symbols.length; i++) {
      game.symbols[i].active = false;
    }
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].selected = false;
    }
    engine.canvas["main"].element.style.cursor = "default";
  }

  if (evt.keyCode == KeyCode.LEFT)
    game.scrollingLeft = true;
  if (evt.keyCode == KeyCode.UP)
    game.scrollingUp = true;
  if (evt.keyCode == KeyCode.RIGHT)
    game.scrollingRight = true;
  if (evt.keyCode == KeyCode.DOWN)
    game.scrollingDown = true;

  Vector position = game.getHoveredTilePosition();

  // lower terrain
  if (evt.keyCode == KeyCode.N) {
    int height = game.getHighestTerrain(position);
    if (height > -1) {
      game.world.tiles[position.x][position.y][height].full = false;
      List tilesToRedraw = new List();
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, height));
        }
      }
      game.redrawTile(tilesToRedraw);
      game.copyTerrain();
    }
  }

  // raise terrain
  if (evt.keyCode == KeyCode.M) {
    int height = game.getHighestTerrain(position);
    if (height < 9) {
      game.world.tiles[position.x][position.y][height + 1].full = true;
      List tilesToRedraw = new List();
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, height + 1));
        }
      }
      game.redrawTile(tilesToRedraw);
      game.copyTerrain();
    }
  }

  // clear terrain
  if (evt.keyCode == KeyCode.B) {
    List tilesToRedraw = new List();
    for (int k = 0; k < 10; k++) {
      game.world.tiles[position.x][position.y][k].full = false;
      // reset index around tile
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          tilesToRedraw.add(new Vector3(position.x + i, position.y + j, k));
        }
      }
    }
    game.redrawTile(tilesToRedraw);
    game.copyTerrain();
  }

  // select height for terraforming
  if (game.mode == "TERRAFORM") {

    // remove terraform number
    if (evt.keyCode == KeyCode.DELETE) {
      game.world.terraform[position.x][position.y]["target"] = -1;
      game.world.terraform[position.x][position.y]["progress"] = 0;
    }

    // set terraform value
    if (evt.keyCode >= 48 && evt.keyCode <= 57) {
      game.terraformingHeight = evt.keyCode - 49;
      if (game.terraformingHeight == -1)game.terraformingHeight = 9;
    }

  }

}

void onKeyUp(KeyboardEvent evt) {
  if (evt.keyCode == KeyCode.LEFT)
    game.scrollingLeft = false;
  if (evt.keyCode == KeyCode.UP)
    game.scrollingUp = false;
  if (evt.keyCode == KeyCode.RIGHT)
    game.scrollingRight = false;
  if (evt.keyCode == KeyCode.DOWN)
    game.scrollingDown = false;
}

void onEnter(evt) {
  engine.mouse.active = true;
}

void onLeave(evt) {
  engine.mouse.active = false;
}

void onLeaveGUI(evt) {
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].hovered = false;
  }
}

void onClickGUI(MouseEvent evt) {
  for (int i = 0; i < game.buildings.length; i++)
    game.buildings[i].selected = false;

  for (int i = 0; i < game.ships.length; i++)
    game.ships[i].selected = false;

  engine.playSound("click");
  for (int i = 0; i < game.symbols.length; i++) {
    game.symbols[i].setActive();
  }

  if (game.activeSymbol != -1) {
    engine.canvas["main"].element.style.cursor = "none";
  }
}

void onDoubleClick(MouseEvent evt) {
  bool selectShips = false;
  // select a ship if hovered
  for (int i = 0; i < game.ships.length; i++) {
    if (game.ships[i].hovered) {
      selectShips = true;
      break;
    }
  }
  if (selectShips)for (int i = 0; i < game.ships.length; i++) {
    game.ships[i].selected = true;
  }
}

void onMouseDown(MouseEvent evt) {
  if (evt.which == 1) {
    // left mouse button
    Vector position = game.getHoveredTilePosition();

    if (engine.mouse.dragStart == null) {
      engine.mouse.dragStart = new Vector(position.x, position.y);
    }
  }
}

void onMouseUp(MouseEvent evt) {
  if (evt.which == 1) {

    Vector position = game.getHoveredTilePosition();

    // set terraforming target
    if (game.mode == "TERRAFORM") {
      game.world.terraform[position.x][position.y]["target"] = game.terraformingHeight;
      game.world.terraform[position.x][position.y]["progress"] = 0;
    }

    // control ships
    for (int i = 0; i < game.ships.length; i++) {
      if (game.ships[i].selected) {
        if (position.x - 1 == game.ships[i].home.position.x && position.y - 1 == game.ships[i].home.position.y) {
          game.ships[i].targetPosition.x = (position.x - 1) * game.tileSize;
          game.ships[i].targetPosition.y = (position.y - 1) * game.tileSize;
          game.ships[i].status = 2;
        } else {
          // take energy from base
          game.ships[i].energy = game.ships[i].home.energy;
          game.ships[i].home.energy = 0;
          game.ships[i].targetPosition.x = position.x * game.tileSize;
          game.ships[i].targetPosition.y = position.y * game.tileSize;
          game.ships[i].status = 1;
        }

      }
    }

    // select a ship if hovered
    for (int i = 0; i < game.ships.length; i++) {
      game.ships[i].selected = game.ships[i].hovered;
      if (game.ships[i].selected)
        game.mode = "SHIP_SELECTED";
    }

    // reposition building
    for (int i = 0; i < game.buildings.length; i++) {
      if (game.buildings[i].built && game.buildings[i].selected && game.buildings[i].canMove) {
        // check if it can be placed
        if (game.canBePlaced(position, game.buildings[i].size, game.buildings[i])) {
          game.buildings[i].moving = true;
          game.buildings[i].moveTargetPosition = position;
          game.buildings[i].calculateVector();
        }
      }
    }

    // select a building if hovered
    if (game.mode == "DEFAULT") {
      Building buildingSelected = null;
      for (int i = 0; i < game.buildings.length; i++) {
        game.buildings[i].selected = game.buildings[i].hovered;
        if (game.buildings[i].selected) {
          query('#selection')
          ..style.display = "block"
          ..innerHtml = "Type: " + game.buildings[i].imageID + "<br/>" + "Health/HR/MaxHealth: " + game.buildings[i].health.toString() + "/" + game.buildings[i].healthRequests.toString() + "/" + game.buildings[i].maxHealth.toString();
          buildingSelected = game.buildings[i];
        }
      }
      if (buildingSelected != null) {
        if (buildingSelected.active) {
          query('#deactivate').style.display = "block";
          query('#activate').style.display = "none";
        } else {
          query('#deactivate').style.display = "none";
          query('#activate').style.display = "block";
        }
      } else {
        query('#selection').style.display = "none";
        query('#deactivate').style.display = "none";
        query('#activate').style.display = "none";
      }
    }

    engine.mouse.dragStart = null;

    // when there is an active symbol place building
    if (game.activeSymbol != -1) {
      String type = game.symbols[game.activeSymbol].imageID.substring(0, 1).toUpperCase() + game.symbols[game.activeSymbol].imageID.substring(1);
      bool soundSuccess = false;
      for (int i = 0; i < game.ghosts.length; i++) {
        if (game.canBePlaced(game.ghosts[i], game.symbols[game.activeSymbol].size, null)) {
          soundSuccess = true;
          game.addBuilding(game.ghosts[i], game.symbols[game.activeSymbol].imageID);
        }
      }
      if (soundSuccess)engine.playSound("click"); else
        engine.playSound("failure");
    }
  } else if (evt.which == 3) {
    game.mode = "DEFAULT";

    // unselect all currently selected buildings
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].selected = false;
      query('#deactivate').style.display = "none";
      query('#activate').style.display = "none";
    }

    // unselect all currently selected ships
    for (int i = 0; i < game.ships.length; i++) {
      game.ships[i].selected = false;
    }

    query('#selection').innerHtml = "";
    query("#terraform").attributes['value'] = "Terraform Off";
    game.clearSymbols();
  }
}

void onMouseScroll(WheelEvent evt) {
  if (evt.deltaY > 0) {
  //scroll down
    game.zoomOut();
  } else {
  //scroll up
    game.zoomIn();
  }
  //prevent page fom scrolling
  evt.preventDefault();
}

num HelperRad2deg(num angle) {
  return angle * 57.29577951308232;
}

num HelperDeg2rad(num angle) {
  return angle * .017453292519943295;
}

num HelperDistance(Vector a, Vector b) {
  return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
}

// converts tile coordinates to canvas coordinates
Vector HelperTiled2screen(Vector pVector) {
  return new Vector(engine.halfWidth + (pVector.x - game.scroll.x) * game.tileSize * game.zoom, engine.halfHeight + (pVector.y - game.scroll.y) * game.tileSize * game.zoom);
}

// converts full coordinates to canvas coordinates
Vector HelperReal2screen(Vector pVector) {
  return new Vector(engine.halfWidth + (pVector.x - game.scroll.x * game.tileSize) * game.zoom, engine.halfHeight + (pVector.y - game.scroll.y * game.tileSize) * game.zoom);
}

// converts full coordinates to tile coordinates
Vector HelperReal2tiled(Vector pVector) {
  return new Vector((pVector.x / game.tileSize).floor(), (pVector.y / game.tileSize).floor());
}

HelperClone(pObject) {
  List newObject = new List();
  for (int i = 0; i < pObject.length; i++) {
    newObject.add(pObject[i]);
  }
  return newObject;
}

int HelperRandomInt(num from, num to) {
  var random = new Math.Random();
  return (random.nextInt(to - from + 1) + from);
}

void HelperShuffle(List list) {
  int len = list.length;
  int i = len;
  while (i-- > 0) {
    int p = HelperRandomInt(0, len);
    var t = list[i];
    list[i] = list[p];
    list[p] = t;
  }
}

/**
 * Main drawing function
 * For some reason this may not be a member function of "game" in order to be called by requestAnimationFrame
 */

void draw(num _) {
  game.drawGUI();

  // clear canvas
  engine.canvas["buffer"].clear();
  engine.canvas["main"].clear();

  // draw terraform numbers
  int timesX = (engine.halfWidth / game.tileSize / game.zoom).floor();
  int timesY = (engine.halfHeight / game.tileSize / game.zoom).floor();

  for (int i = -timesX; i <= timesX; i++) {
    for (int j = -timesY; j <= timesY; j++) {

      int iS = i + game.scroll.x;
      int jS = j + game.scroll.y;

      if (game.withinWorld(iS, jS)) {
        if (game.world.terraform[iS][jS]["target"] > -1) {
          engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images["numbers"], game.world.terraform[iS][jS]["target"] * 16, 0, game.tileSize, game.tileSize, engine.halfWidth + i * game.tileSize * game.zoom, engine.halfHeight + j * game.tileSize * game.zoom, game.tileSize * game.zoom, game.tileSize * game.zoom);
        }
      }
    }
  }

  // draw emitters
  for (int i = 0; i < game.emitters.length; i++) {
    game.emitters[i].draw();
  }

  // draw spore towers
  for (int i = 0; i < game.sporetowers.length; i++) {
    game.sporetowers[i].draw();
  }

  // draw node connections
  for (int i = 0; i < game.buildings.length; i++) {
    Vector centerI = game.buildings[i].getCenter();
    Vector drawCenterI = HelperReal2screen(centerI);
    for (int j = 0; j < game.buildings.length; j++) {
      if (i != j) {
        if (!game.buildings[i].moving && !game.buildings[j].moving) {
          Vector centerJ = game.buildings[j].getCenter();
          Vector drawCenterJ = HelperReal2screen(centerJ);

          num allowedDistance = 10 * game.tileSize;
          if (game.buildings[i].imageID == "relay" && game.buildings[j].imageID == "relay") {
            allowedDistance = 20 * game.tileSize;
          }

          if (Math.pow(centerJ.x - centerI.x, 2) + Math.pow(centerJ.y - centerI.y, 2) <= Math.pow(allowedDistance, 2)) {
            engine.canvas["buffer"].context.strokeStyle = '#000';
            engine.canvas["buffer"].context.lineWidth = 3;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenterI.x, drawCenterI.y);
            engine.canvas["buffer"].context.lineTo(drawCenterJ.x, drawCenterJ.y);
            engine.canvas["buffer"].context.stroke();

            engine.canvas["buffer"].context.strokeStyle = '#fff';
            if (!game.buildings[i].built || !game.buildings[j].built)engine.canvas["buffer"].context.strokeStyle = '#777';
            engine.canvas["buffer"].context.lineWidth = 2;
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(drawCenterI.x, drawCenterI.y);
            engine.canvas["buffer"].context.lineTo(drawCenterJ.x, drawCenterJ.y);
            engine.canvas["buffer"].context.stroke();
          }
        }
      }
    }
  }

  // draw movement indicators
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].drawMovementIndicators();
  }

  // draw buildings
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].draw();
  }

  // draw shells
  for (int i = 0; i < game.shells.length; i++) {
    game.shells[i].draw();
  }

  // draw smokes
  for (int i = 0; i < game.smokes.length; i++) {
    game.smokes[i].draw();
  }

  // draw explosions
  for (int i = 0; i < game.explosions.length; i++) {
    game.explosions[i].draw();
  }

  // draw spores
  for (int i = 0; i < game.spores.length; i++) {
    game.spores[i].draw();
  }

  if (engine.mouse.active) {

    // if a building is built and selected draw a green box and a line at mouse position as the reposition target
    for (int i = 0; i < game.buildings.length; i++) {
      game.buildings[i].drawRepositionInfo();
    }

    // draw attack symbol
    game.drawAttackSymbol();

    if (game.activeSymbol != -1) {
      game.drawPositionInfo();
    }

    if (game.mode == "TERRAFORM") {
      Vector positionScrolled = game.getHoveredTilePosition();
      Vector drawPosition = HelperTiled2screen(positionScrolled);
      engine.canvas["buffer"].context.drawImageScaledFromSource(engine.images["numbers"], game.terraformingHeight * game.tileSize, 0, game.tileSize, game.tileSize, drawPosition.x, drawPosition.y, game.tileSize * game.zoom, game.tileSize * game.zoom);

      engine.canvas["buffer"].context.strokeStyle = '#fff';
      engine.canvas["buffer"].context.lineWidth = 1;

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(0, drawPosition.y);
      engine.canvas["buffer"].context.lineTo(engine.width, drawPosition.y);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(0, drawPosition.y + game.tileSize * game.zoom);
      engine.canvas["buffer"].context.lineTo(engine.width, drawPosition.y + game.tileSize * game.zoom);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(drawPosition.x, 0);
      engine.canvas["buffer"].context.lineTo(drawPosition.x, engine.halfHeight * 2);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.beginPath();
      engine.canvas["buffer"].context.moveTo(drawPosition.x + game.tileSize * game.zoom, 0);
      engine.canvas["buffer"].context.lineTo(drawPosition.x + game.tileSize * game.zoom, engine.halfHeight * 2);
      engine.canvas["buffer"].context.stroke();

      engine.canvas["buffer"].context.stroke();

    }
  }

  // draw packets
  for (int i = 0; i < game.packets.length; i++) {
    game.packets[i].draw();
  }

  // draw ships
  for (int i = 0; i < game.ships.length; i++) {
    game.ships[i].draw(engine.canvas["buffer"].context);
  }

  // draw building hover/selection box
  for (int i = 0; i < game.buildings.length; i++) {
    game.buildings[i].drawBox();
  }

  engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element, 0, 0); // copy from buffer to context
  // double buffering taken from: http://www.youtube.com/watch?v=FEkBldQnNUc

  window.requestAnimationFrame(draw);
}