part of creeper;

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
      engine.canvas["level$i"] = new Canvas(new CanvasElement(), 128 * 16, 128 * 16);
    }

    engine.canvas["levelbuffer"] = new Canvas(new CanvasElement(), 128 * 16, 128 * 16);
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

    window..onResize.listen((event) => onResize(event));
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
      num distance = Helper.distance(screenCenter, position);
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
    
    //query("#mouse").innerHtml = ("Mouse: " + this.mouseGUI.x.toString() + "/" + this.mouseGUI.y.toString());
    
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
      //query("#fps").innerHtml = "FPS: " + (1000 * this.fps_frames / this.fps_totalTime).floor().toString() + " average, " + (1000 * this.fps_updateFrames / this.fps_updateTime).floor().toString() + " currently, " + (game.speed * this.FPS).toString() + " desired";
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