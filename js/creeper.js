/*!
 * Open Creeper v1.2.2
 * http://alexanderzeillinger.github.com/OpenCreeper/
 *
 * Copyright 2012, Alexander Zeillinger
 * Dual licensed under the MIT or GPL licenses.
 */

var engine = {
    FPS: 60,
    delta: 1000 / 60,
    fps_delta: null,
    fps_lastTime: null,
    fps_frames: null,
    fps_totalTime: null,
    fps_updateTime: null,
    fps_updateFrames: null,
    images: [],
    sounds: [],
    animationRequest: null,
    canvas: [],
    imageSrcs: null,
    mouse: {
        x: 0,
        y: 0,
        active: false,
        dragStart: null,
        dragEnd: null
    },
    mouseGUI: {
        x: 0,
        y: 0
    },
    width: 0,
    height: 0,
    halfWidth: 0,
    halfHeight: 0,
    /**
     * Initializes the canvases and mouse, loads sounds and images.
     */
    init: function () {
        var width = window.innerWidth;
        var height = window.innerHeight;
        engine.width = width;
        engine.height = height;
        engine.halfWidth = Math.floor(width / 2);
        engine.halfHeight = Math.floor(height / 2);

        // main
        engine.canvas["main"] = new Canvas($("<canvas width='" + width + "' height='" + height + "' style='position: absolute;z-index: 1'>"));
        document.getElementById('canvasContainer').appendChild(engine.canvas["main"].element[0]);
        engine.canvas["main"].top = engine.canvas["main"].element.offset().top;
        engine.canvas["main"].left = engine.canvas["main"].element.offset().left;

        // buffer
        engine.canvas["buffer"] = new Canvas($("<canvas width='" + width + "' height='" + height + "'>"));

        // gui
        engine.canvas["gui"] = new Canvas($("<canvas width='780' height='110'>"));
        document.getElementById('gui').appendChild(engine.canvas["gui"].element[0]);

        for (var i = 0; i < 10; i++) {
            engine.canvas["level" + i] = new Canvas($("<canvas width='" + (128 * 16 + width * 2) + "' height='" + (128 * 16 + height * 2) + "' style='position: absolute'>"));
        }

        engine.canvas["levelbuffer"] = new Canvas($("<canvas width='" + (128 * 16 + width * 2) + "' height='" + (128 * 16 + height * 2) + "' style='position: absolute'>"));
        engine.canvas["levelfinal"] = new Canvas($("<canvas width='" + width + "' height='" + height + "' style='position: absolute'>"));
        document.getElementById('canvasContainer').appendChild(engine.canvas["levelfinal"].element[0]);

        // collection
        engine.canvas["collection"] = new Canvas($("<canvas width='" + width + "' height='" + height + "' style='position: absolute'>"));
        document.getElementById('canvasContainer').appendChild(engine.canvas["collection"].element[0]);

        // creeper
        engine.canvas["creeper"] = new Canvas($("<canvas width='" + width + "' height='" + height + "' style='position: absolute'>"));
        document.getElementById('canvasContainer').appendChild(engine.canvas["creeper"].element[0]);

        // load sounds
        this.addSound("shot", "wav");
        this.addSound("click", "wav");
        this.addSound("music", "ogg");
        this.addSound("explosion", "wav");
        this.addSound("failure", "wav");
        this.addSound("energy", "wav");
        this.addSound("laser", "wav");

        // load images
        this.imageSrcs = ["numbers", "level0", "level1", "level2", "level3", "level4", "level5", "level6", "level7", "level8", "level9", "borders", "mask", "cannon", "cannongun", "base", "collector", "reactor", "storage", "terp", "packet_collection", "packet_energy", "packet_health", "relay", "emitter", "creep",
            "mortar", "shell", "beam", "spore", "bomber", "bombership", "smoke", "explosion", "targetcursor", "sporetower", "forcefield", "shield"];

        document.getElementById('terraform').onclick = function () {
            game.toggleTerraform()
        };
        document.getElementById('slower').onclick = function () {
            game.slower()
        };
        document.getElementById('faster').onclick = function () {
            game.faster()
        };
        document.getElementById('pause').onclick = function () {
            game.pause()
        };
        document.getElementById('resume').onclick = function () {
            game.resume()
        };
        document.getElementById('restart').onclick = function () {
            game.restart()
        };
        document.getElementById('deactivate').onclick = function () {
            game.deactivateBuilding()
        };
        document.getElementById('activate').onclick = function () {
            game.activateBuilding()
        };
        document.getElementById('zoomin').onclick = function () {
            game.zoomIn()
        };
        document.getElementById('zoomout').onclick = function () {
            game.zoomOut()
        };

        $('#time').stopwatch().stopwatch('start');
        var mainCanvas = engine.canvas["main"].element;
        var guiCanvas = engine.canvas["gui"].element;
        mainCanvas.on('mousemove', onMouseMove);
        mainCanvas.on('dblclick', onDoubleClick);
        mainCanvas.on('mouseup', onMouseUp).on('mousedown', onMouseDown);
        mainCanvas.on('mouseenter', onEnter).on('mouseleave', onLeave);
        mainCanvas.on('DOMMouseScroll mousewheel', onMouseScroll);

        guiCanvas.on('mousemove', onMouseMoveGUI);
        guiCanvas.on('click', onClickGUI);
        guiCanvas.on('mouseleave', onLeaveGUI);

        $(document).on('keydown', onKeyDown);
        $(document).on('keyup', onKeyUp);
        $(document).on('contextmenu', function () {
            return false;
        });
    },
    /**
     * Loads all images.
     *
     * A callback is used to make sure the game starts after all images have been loaded.
     * Otherwise some images might not be rendered at all.
     */
    loadImages: function (callback) {
        var loadedImages = 0;
        var numImages = this.imageSrcs.length - 1;

        for (var i = 0; i < this.imageSrcs.length; i++) {
            this.images[this.imageSrcs[i]] = new Image();
            this.images[this.imageSrcs[i]].onload = function () {
                if (++loadedImages >= numImages) {
                    callback();
                }
            };
            this.images[this.imageSrcs[i]].src = "images/" + this.imageSrcs[i] + ".png";
        }
    },
    addSound: function (name, type) {
        this.sounds[name] = [];
        for (var i = 0; i < 5; i++) {
            this.sounds[name][i] = new Audio("sounds/" + name + "." + type);
        }
    },
    playSound: function (name, position) {
        // adjust sound volume based on the current zoom as well as the position

        var volume = 1;
        if (position) {
            var screenCenter = new Vector(
                Math.floor(engine.halfWidth / (game.tileSize * game.zoom)) + game.scroll.x,
                Math.floor(engine.halfHeight / (game.tileSize * game.zoom)) + game.scroll.y);
            var distance = Helper.distance(screenCenter, position);
            volume = Helper.clamp(game.zoom / Math.pow(distance / 20, 2), 0, 1);
        }

        for (var i = 0; i < 5; i++) {
            if (this.sounds[name][i].ended == true || this.sounds[name][i].currentTime == 0) {
                this.sounds[name][i].volume = volume;
                this.sounds[name][i].play();
                return;
            }
        }
    },
    updateMouse: function (evt) {
        if (evt.pageX > this.canvas["main"].left && evt.pageX < this.canvas["main"].right && evt.pageY > this.canvas["main"].top && evt.pageY < this.canvas["main"].bottom) {
            this.mouse.x = evt.pageX - this.canvas["main"].left;
            this.mouse.y = evt.pageY - this.canvas["main"].top;
            var position = game.getHoveredTilePosition();

            engine.mouse.dragEnd = new Vector(position.x, position.y);

            //$("#mouse").html("Mouse: " + this.mouse.x + "/" + this.mouse.y + " - " + position.x + "/" + position.y);
        }
    },
    updateMouseGUI: function (evt) {
        if (evt.pageX > this.canvas["gui"].left && evt.pageX < this.canvas["gui"].right && evt.pageY > this.canvas["gui"].top && evt.pageY < this.canvas["gui"].bottom) {
            this.mouseGUI.x = evt.pageX - this.canvas["gui"].left;
            this.mouseGUI.y = evt.pageY - this.canvas["gui"].top;
        }
    },
    reset: function () {
        // reset FPS variables
        this.fps_lastTime = new Date().getTime();
        this.fps_frames = 0;
        this.fps_totalTime = 0;
        this.fps_updateTime = 0;
        this.fps_updateFrames = 0;
    },
    update: function () {
        // update FPS
        var now = new Date().getTime();
        this.fps_delta = now - this.fps_lastTime;
        this.fps_lastTime = now;
        this.fps_totalTime += this.fps_delta;
        this.fps_frames++;
        this.fps_updateTime += this.fps_delta;
        this.fps_updateFrames++;

        // update FPS display
        if (this.fps_updateTime > 1000) {
            $("#fps").html("FPS: " + Math.floor(1000 * this.fps_frames / this.fps_totalTime) + " average, " + Math.floor(1000 * this.fps_updateFrames / this.fps_updateTime) + " currently, " + (game.speed * this.FPS) + " desired");
            this.fps_updateTime -= 1000;
            this.fps_updateFrames = 0;
        }
    },
    /**
     * Checks if an object is visible on the screen
     *
     * @param   position
     * @param   size
     * @return  boolean
     */
    isVisible: function (position, size) {
        var r1 = {left: position.x, top: position.y, right: position.x + size.x, bottom: position.y + size.y};
        var r2 = {left: this.canvas["main"].left, top: this.canvas["main"].top, right: this.canvas["main"].right, bottom: this.canvas["main"].bottom};

        return !(r2.left > r1.right ||
            r2.right < r1.left ||
            r2.top > r1.bottom ||
            r2.bottom < r1.top);
    }
};

var game = {
    tileSize: 16,
    speed: 1,
    zoom: 1,
    running: null,
    paused: false,
    currentEnergy: 0,
    maxEnergy: 0,
    collection: 0,
    buildings: null,
    packets: null,
    shells: null,
    spores: null,
    ships: null,
    smokes: null,
    explosions: null,
    creeperTimer: 0,
    energyTimer: 0,
    spawnTimer: 0,
    damageTimer: 0,
    smokeTimer: 0,
    explosionTimer: 0,
    shieldTimer: 0,
    symbols: null,
    activeSymbol: -1,
    packetSpeed: 1,
    shellSpeed: 1,
    sporeSpeed: 1,
    buildingSpeed: .5,
    base: null,
    shipSpeed: 1,
    emitters: null,
    sporetowers: null,
    packetQueue: null,
    terraformingHeight: 0,
    mode: null,
    ghosts: null,
    init: function () {
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
    },
    reset: function () {
        $('#time').stopwatch().stopwatch('reset');
        $('#lose').hide();
        $('#win').hide();

        this.mode = this.modes.DEFAULT;
        this.buildings.length = 0;
        this.packets.length = 0;
        this.shells.length = 0;
        this.spores.length = 0;
        this.ships.length = 0;
        this.smokes.length = 0;
        this.explosions.length = 0;
        //this.symbols.length = 0;
        this.emitters.length = 0;
        this.sporetowers.length = 0;
        this.packetQueue.length = 0;

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
    },
    world: {
        tiles: null,
        size: {
            x: 128,
            y: 128
        },
        terraform: null // separate array to store terraform information
    },
    alert: {
        x: 0,
        y: 0,
        message: null
    },
    scroll: {
        x: 40,
        y: 23
    },
    scrolling: {
        up: false,
        down: false,
        left: false,
        right: false
    },
    keyMap: {"k81": "Q",
        "k87": "W",
        "k69": "E",
        "k82": "R",
        "k84": "T",
        "k90": "Z",
        "k85": "U",
        "k73": "I",
        "k65": "A",
        "k83": "S",
        "k68": "D",
        "k70": "F",
        "k71": "G",
        "k72": "H"},
    modes: {
        DEFAULT: 0,
        BUILDING_SELECTED: 1,
        SHIP_SELECTED: 2,
        ICON_SELECTED: 3,
        TERRAFORM: 4
    },
    /**
     * Checks if the given position is within the world
     *
     * @param   {int}   x
     * @param   {int}   y
     * @return  {Boolean}   boolean
     */
    withinWorld: function (x, y) {
        return (x > -1 && x < this.world.size.x && y > -1 && y < this.world.size.y)
    },
    // Returns the position of the tile the mouse is hovering above
    getHoveredTilePosition: function () {
        return new Vector(
            Math.floor((engine.mouse.x - engine.halfWidth) / (this.tileSize * this.zoom)) + this.scroll.x,
            Math.floor((engine.mouse.y - engine.halfHeight) / (this.tileSize * this.zoom)) + this.scroll.y);
    },
    /**
     * @param {Vector} pVector The position of the tile to check
     */
    getHighestTerrain: function (pVector) {
        var height = -1;
        for (var i = 9; i > -1; i--) {
            if (this.world.tiles[pVector.x][pVector.y][i].full) {
                height = i;
                break;
            }
        }
        return height;
    },
    pause: function () {
        $('#pause').hide();
        $('#resume').show();
        $('#paused').show();
        this.paused = true;
    },
    resume: function () {
        $('#pause').show();
        $('#resume').hide();
        $('#paused').hide();
        this.paused = false;
    },
    stop: function () {
        clearInterval(this.running);
    },
    run: function () {
        this.running = setInterval(update, 1000 / this.speed / engine.FPS);
        engine.animationRequest = requestAnimationFrame(draw);
    },
    restart: function () {
        this.stop();
        this.reset();
        this.run();
    },
    toggleTerraform: function () {
        if (this.mode == this.modes.TERRAFORM) {
            this.mode = this.modes.DEFAULT;
            $("#terraform").val("Terraform Off");
        }
        else {
            this.mode = this.modes.TERRAFORM;
            $("#terraform").val("Terraform On");
        }
    },
    faster: function () {
        $('#slower').show();
        $('#faster').hide();
        if (this.speed < 2) {
            this.speed *= 2;
            this.stop();
            this.run();
            this.updateSpeedElement();
        }
    },
    slower: function () {
        $('#slower').hide();
        $('#faster').show();
        if (this.speed > 1) {
            this.speed /= 2;
            this.stop();
            this.run();
            this.updateSpeedElement();
        }
    },
    zoomIn: function () {
        if (this.zoom < 1.6) {
            this.zoom += .2;
            this.zoom = parseFloat(this.zoom.toFixed(2));
            this.copyTerrain();
            this.drawCollection();
            this.drawCreeper();
            this.updateZoomElement();
        }
    },
    zoomOut: function () {
        if (this.zoom > .4) {
            this.zoom -= .2;
            this.zoom = parseFloat(this.zoom.toFixed(2));
            this.copyTerrain();
            this.drawCollection();
            this.drawCreeper();
            this.updateZoomElement();
        }
    },
    createWorld: function () {
        this.world.tiles = new Array(this.world.size.x);
        this.world.terraform = new Array(this.world.size.x);
        for (var i = 0; i < this.world.size.x; i++) {
            this.world.tiles[i] = new Array(this.world.size.y);
            this.world.terraform[i] = new Array(this.world.size.y);
            for (var j = 0; j < this.world.size.y; j++) {
                this.world.tiles[i][j] = [];
                for (var k = 0; k < 10; k++) {
                    this.world.tiles[i][j][k] = new Tile();
                }
                this.world.terraform[i][j] = {target: -1, progress: 0};
            }
        }

        var heightmap = new HeightMap(129, 0, 90);
        heightmap.run();

        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                var height = Math.round(heightmap.map[i][j] / 10);
                if (height > 10)
                    height = 10;
                for (var k = 0; k < height; k++) {
                    this.world.tiles[i][j][k].full = true;
                }
            }
        }

        /*for (var i = 0; i < this.world.size.x; i++) {
         for (var j = 0; j < this.world.size.y; j++) {
         for (var k = 0; k < 10; k++) {

         if (this.world.tiles[i][j][k].full) {
         var up = 0, down = 0, left = 0, right = 0;
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

         for (var i = 0; i < this.world.size.x; i++) {
         for (var j = 0; j < this.world.size.y; j++) {
         var removeBelow = false;
         for (var k = 9; k > -1; k--) {
         if (removeBelow) {
         this.world.tiles[i][j][k].full = false;
         }
         else {
         var index = this.world.tiles[i][j][k].index;
         if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
         removeBelow = true;
         }
         }
         }
         }*/

        // create base
        var randomPosition = new Vector(
            Helper.randomInt(0, this.world.size.x - 9),
            Helper.randomInt(0, this.world.size.y - 9));

        this.scroll.x = randomPosition.x + 4;
        this.scroll.y = randomPosition.y + 4;

        var building = new Building(randomPosition, "base");
        building.health = 40;
        building.maxHealth = 40;
        building.built = true;
        building.size = 9;
        this.buildings.push(building);
        game.base = building;

        var height = this.getHighestTerrain(new Vector(building.position.x + 4, building.position.y + 4));
        if (height < 0)
            height = 0;
        for (var i = 0; i < 9; i++) {
            for (var j = 0; j < 9; j++) {
                for (var k = 0; k < 10; k++) {
                    this.world.tiles[building.position.x + i][building.position.y + j][k].full = (k <= height);
                }
            }
        }

        this.calculateCollection();

        // create emitter
        randomPosition = new Vector(
            Helper.randomInt(0, this.world.size.x - 3),
            Helper.randomInt(0, this.world.size.x - 3));

        var emitter = new Emitter(randomPosition, 5);
        this.emitters.push(emitter);

        height = this.getHighestTerrain(new Vector(emitter.position.x + 1, emitter.position.y + 1));
        if (height < 0)
            height = 0;
        for (var i = 0; i < 3; i++) {
            for (var j = 0; j < 3; j++) {
                for (var k = 0; k < 10; k++) {
                    this.world.tiles[emitter.position.x + i][emitter.position.y + j][k].full = (k <= height);
                }
            }
        }

        // create sporetower
        randomPosition = new Vector(
            Helper.randomInt(0, this.world.size.x - 3),
            Helper.randomInt(0, this.world.size.x - 3));

        var sporetower = new Sporetower(randomPosition);
        sporetower.reset();
        this.sporetowers.push(sporetower);

        height = this.getHighestTerrain(new Vector(sporetower.position.x + 1, sporetower.position.y + 1));
        if (height < 0)
            height = 0;
        for (var i = 0; i < 3; i++) {
            for (var j = 0; j < 3; j++) {
                for (var k = 0; k < 10; k++) {
                    this.world.tiles[sporetower.position.x + i][sporetower.position.y + j][k].full = (k <= height);
                }
            }
        }

    },
    /**
     * @param {Vector} position The position of the new building
     * @param {String} type The type of the new building
     */
    addBuilding: function (position, type) {
        var building = new Building(position, type);
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

        this.buildings.push(building);
    },
    /**
     * @param {Building} building The building to remove
     */
    removeBuilding: function (building) {

        // only explode building when it has been built
        if (building.built) {
            this.explosions.push(new Explosion(building.getCenter()));
            engine.playSound("explosion", building.position);
        }

        if (building.imageID == "base") {
            $('#lose').toggle();
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
        for (var i = 0; i < this.packets.length; i++) {
            if (this.packets[i].currentTarget == building || this.packets[i].target == building) {
                //this.packets[i].remove = true;
                this.packets.splice(i, 1);
            }
        }
        for (var i = 0; i < this.packetQueue.length; i++) {
            if (this.packetQueue[i].currentTarget == building || this.packetQueue[i].target == building) {
                this.packetQueue.splice(i, 1);
            }
        }

        var index = this.buildings.indexOf(building);
        this.buildings.splice(index, 1);
    },
    activateBuilding: function () {
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].selected)
                this.buildings[i].active = true;
        }
    },
    deactivateBuilding: function () {
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].selected)
                this.buildings[i].active = false;
        }
    },
    updateEnergyElement: function () {
        $('#energy').html("Energy: " + this.currentEnergy + "/" + this.maxEnergy);
    },
    updateSpeedElement: function () {
        $("#speed").html("Speed: " + this.speed + "x");
    },
    updateZoomElement: function () {
        $("#speed").html("Zoom: " + this.zoom + "x");
    },
    updateCollectionElement: function () {
        $('#collection').html("Collection: " + this.collection);
    },
    clearSymbols: function () {
        this.activeSymbol = -1;
        for (var i = 0; i < this.symbols.length; i++)
            this.symbols[i].active = false;
        engine.canvas["main"].element.css('cursor', 'default');
    },
    setupUI: function () {
        this.symbols.push(new UISymbol(new Vector(0, 0), "cannon", "Q", 3, 25, 8));
        this.symbols.push(new UISymbol(new Vector(81, 0), "collector", "W", 3, 5, 6));
        this.symbols.push(new UISymbol(new Vector(2 * 81, 0), "reactor", "E", 3, 50, 0));
        this.symbols.push(new UISymbol(new Vector(3 * 81, 0), "storage", "R", 3, 8, 0));
        this.symbols.push(new UISymbol(new Vector(4 * 81, 0), "shield", "T", 3, 50, 10));

        this.symbols.push(new UISymbol(new Vector(0, 56), "relay", "A", 3, 10, 8));
        this.symbols.push(new UISymbol(new Vector(81, 56), "mortar", "S", 3, 40, 12));
        this.symbols.push(new UISymbol(new Vector(2 * 81, 56), "beam", "D", 3, 20, 12));
        this.symbols.push(new UISymbol(new Vector(3 * 81, 56), "bomber", "F", 3, 75, 0));
        this.symbols.push(new UISymbol(new Vector(4 * 81, 56), "terp", "G", 3, 60, 12));
    },
    drawTerrain: function () {
        for (var i = 0; i < 10; i++) {
            engine.canvas["level" + i].clear();
        }

        // 1st pass - draw masks
        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                for (var k = 9; k > -1; k--) {

                    if (this.world.tiles[i][j][k].full) {

                        // calculate index
                        var up = 0, down = 0, left = 0, right = 0;
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
                        this.world.tiles[i][j][k].index = (8 * down) + (4 * left) + (2 * up) + right;

                        var index = this.world.tiles[i][j][k].index;

                        // skip tiles that are identical to the one above
                        if (k + 1 < 10 && index == this.world.tiles[i][j][k + 1].index)
                            continue;

                        engine.canvas["level" + k].context.drawImage(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, engine.width + i * this.tileSize, engine.height + j * this.tileSize, this.tileSize, this.tileSize);

                        // don't draw anymore under tiles that don't have transparent parts
                        if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
                            break;
                    }
                }
            }
        }

        // 2nd pass - draw textures
        for (var i = 0; i < 10; i++) {
            var pattern = engine.canvas["level" + i].context.createPattern(engine.images["level" + i], 'repeat');
            engine.canvas["level" + i].context.globalCompositeOperation = 'source-in';
            engine.canvas["level" + i].context.fillStyle = pattern;
            engine.canvas["level" + i].context.fillRect(0, 0, engine.canvas["level" + i].element[0].width, engine.canvas["level" + i].element[0].height);
            engine.canvas["level" + i].context.globalCompositeOperation = 'source-over';
        }

        // 3rd pass - draw borders
        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                for (var k = 9; k > -1; k--) {

                    if (this.world.tiles[i][j][k].full) {

                        var index = this.world.tiles[i][j][k].index;

                        if (k + 1 < 10 && index == this.world.tiles[i][j][k + 1].index)
                            continue;

                        engine.canvas["level" + k].context.drawImage(engine.images["borders"], index * (this.tileSize + 6) + 2, 2, this.tileSize + 2, this.tileSize + 2, engine.width + i * this.tileSize, engine.height + j * this.tileSize, (this.tileSize + 2), (this.tileSize + 2));

                        if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
                            break;
                    }
                }
            }
        }

        engine.canvas["levelbuffer"].clear();
        for (var k = 0; k < 10; k++) {
            engine.canvas["levelbuffer"].context.drawImage(engine.canvas["level" + k].element[0], 0, 0);
        }
        $('#loading').hide();
    },
    copyTerrain: function () {
        engine.canvas["levelfinal"].clear();
        var left = engine.width + this.scroll.x * this.tileSize - (engine.width / this.tileSize / 2) * this.tileSize * (1 / this.zoom);
        var top = engine.height + this.scroll.y * this.tileSize - (engine.height / this.tileSize / 2) * this.tileSize * (1 / this.zoom);
        var width = (engine.width / this.tileSize) * this.tileSize * (1 / this.zoom);
        var height = (engine.height / this.tileSize) * this.tileSize * (1 / this.zoom);
        engine.canvas["levelfinal"].context.drawImage(engine.canvas["levelbuffer"].element[0], left, top, width, height, 0, 0, engine.width, engine.height);
    },
    /**
     * @param {Array} tilesToRedraw An array of tiles to redraw
     */
    redrawTile: function (tilesToRedraw) {
        var tempCanvas = [];
        var tempContext = [];
        for (var t = 0; t < 10; t++) {
            tempCanvas[t] = document.createElement('canvas');
            tempCanvas[t].width = this.tileSize;
            tempCanvas[t].height = this.tileSize;
            tempContext[t] = tempCanvas[t].getContext('2d');
        }

        for (var i = 0; i < tilesToRedraw.length; i++) {

            var iS = tilesToRedraw[i].x;
            var jS = tilesToRedraw[i].y;
            var k = tilesToRedraw[i].z;

            // recalculate index
            if (this.world.tiles[iS][jS][k].full) {

                var up = 0, down = 0, left = 0, right = 0;
                if (jS - 1 < 0)
                    up = 0;
                else if (this.world.tiles[iS][jS - 1][k].full)
                    up = 1;
                if (jS + 1 > this.world.size.y - 1)
                    down = 0;
                else if (this.world.tiles[iS][jS + 1][k].full)
                    down = 1;
                if (iS - 1 < 0)
                    left = 0;
                else if (this.world.tiles[iS - 1][jS][k].full)
                    left = 1;
                if (iS + 1 > this.world.size.x - 1)
                    right = 0;
                else if (this.world.tiles[iS + 1][jS][k].full)
                    right = 1;

                // save index for later use
                this.world.tiles[iS][jS][k].index = (8 * down) + (4 * left) + (2 * up) + right;
            }
            else
                this.world.tiles[iS][jS][k].index = -1;

            // redraw mask
            for (var t = 9; t > -1; t--) {
                tempContext[t].clearRect(0, 0, this.tileSize, this.tileSize);

                if (this.world.tiles[iS][jS][t].full) {
                    var index = this.world.tiles[iS][jS][t].index;

                    // skip tiles that are identical to the one above
                    if (t + 1 < 10 && index == this.world.tiles[iS][jS][t + 1].index)
                        continue;

                    tempContext[t].drawImage(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 0, 0, this.tileSize, this.tileSize);

                    // don't draw anymore under tiles that don't have transparent parts
                    if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
                        break;
                }
            }

            // redraw pattern
            for (var t = 9; t > -1; t--) {
                /*var tCanvas = document.createElement('canvas');
                 tCanvas.width = 256;
                 tCanvas.height = 256;
                 var ctx = tCanvas.getContext('2d');

                 ctx.drawImage(engine.images["level" + t], 0, 0);
                 var pattern = tempContext[t].createPattern(tCanvas, 'repeat');*/

                if (this.world.tiles[iS][jS][t].full) {
                    var pattern = tempContext[t].createPattern(engine.images["level" + t], 'repeat');

                    tempContext[t].globalCompositeOperation = 'source-in';
                    tempContext[t].fillStyle = pattern;

                    tempContext[t].save();
                    var translation = new Vector(
                        engine.width + Math.floor(iS * this.tileSize),
                        engine.height + Math.floor(jS * this.tileSize));
                    tempContext[t].translate(-translation.x, -translation.y);

                    //tempContext[t].fill();
                    tempContext[t].fillRect(translation.x, translation.y, this.tileSize, this.tileSize);
                    tempContext[t].restore();

                    tempContext[t].globalCompositeOperation = 'source-over';
                }
            }

            // redraw borders
            for (var t = 9; t > -1; t--) {
                if (this.world.tiles[iS][jS][t].full) {
                    var index = this.world.tiles[iS][jS][t].index;

                    if (index < 0 || (t + 1 < 10 && index == this.world.tiles[iS][jS][t + 1].index))
                        continue;

                    tempContext[t].drawImage(engine.images["borders"], index * (this.tileSize + 6) + 2, 2, this.tileSize + 2, this.tileSize + 2, 0, 0, (this.tileSize + 2), (this.tileSize + 2));

                    if (index == 5 || index == 7 || index == 10 || index == 11 || index == 13 || index == 14 || index == 15)
                        break;
                }
            }

            engine.canvas["levelbuffer"].context.clearRect(engine.width + iS * this.tileSize, engine.height + jS * this.tileSize, this.tileSize, this.tileSize);
            for (var t = 0; t < 10; t++) {
                engine.canvas["levelbuffer"].context.drawImage(tempCanvas[t], 0, 0, this.tileSize, this.tileSize, engine.width + iS * this.tileSize, engine.height + jS * this.tileSize, this.tileSize, this.tileSize);
            }
        }
        this.copyTerrain();
    },
    checkOperating: function () {
        for (var t = 0; t < this.buildings.length; t++) {
            this.buildings[t].operating = false;
            if (this.buildings[t].needsEnergy && this.buildings[t].active && !this.buildings[t].moving) {

                this.buildings[t].energyTimer++;
                var center = this.buildings[t].getCenter();

                if (this.buildings[t].imageID == "terp" && this.buildings[t].energy > 0) {
                    // find lowest target
                    if (this.buildings[t].weaponTargetPosition == null) {

                        // get building x and building y
                        var x = this.buildings[t].position.x;
                        var y = this.buildings[t].position.y;

                        // find lowest tile
                        var target = null;
                        var lowestTile = 10;
                        for (var i = x - this.buildings[t].weaponRadius; i < x + this.buildings[t].weaponRadius + 2; i++) {
                            for (var j = y - this.buildings[t].weaponRadius; j < y + this.buildings[t].weaponRadius + 2; j++) {

                                if (this.withinWorld(i, j)) {
                                    var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);
                                    var tileHeight = this.getHighestTerrain(new Vector(i, j));

                                    if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.terraform[i][j].target > -1 && tileHeight <= lowestTile) {
                                        lowestTile = tileHeight;
                                        target = new Vector(i, j);
                                    }
                                }
                            }
                        }
                        if (target) {
                            this.buildings[t].weaponTargetPosition = target;
                        }
                    }
                    else {
                        if (this.buildings[t].energyTimer > 20) {
                            this.buildings[t].energyTimer = 0;
                            this.buildings[t].energy -= 1;
                        }

                        this.buildings[t].operating = true;
                        var terraformElement = this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y];
                        terraformElement.progress += 1;
                        if (terraformElement.progress == 100) {
                            terraformElement.progress = 0;

                            var height = this.getHighestTerrain(this.buildings[t].weaponTargetPosition);
                            var tilesToRedraw = [];

                            if (height < terraformElement.target) {
                                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height + 1].full = true;
                                // reset index around tile
                                for (var i = -1; i <= 1; i++) {
                                    for (var j = -1; j <= 1; j++) {
                                        tilesToRedraw.push({x: this.buildings[t].weaponTargetPosition.x + i, y: this.buildings[t].weaponTargetPosition.y + j, z: height + 1});
                                    }
                                }
                            }
                            else {
                                this.world.tiles[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y][height].full = false;
                                // reset index around tile
                                for (var i = -1; i <= 1; i++) {
                                    for (var j = -1; j <= 1; j++) {
                                        tilesToRedraw.push({x: this.buildings[t].weaponTargetPosition.x + i, y: this.buildings[t].weaponTargetPosition.y + j, z: height});
                                    }
                                }
                            }

                            this.redrawTile(tilesToRedraw);
                            this.copyTerrain();

                            height = this.getHighestTerrain(this.buildings[t].weaponTargetPosition);
                            if (height == terraformElement.target) {
                                this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y].progress = 0;
                                this.world.terraform[this.buildings[t].weaponTargetPosition.x][this.buildings[t].weaponTargetPosition.y].target = -1;
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

                    var x = this.buildings[t].position.x;
                    var y = this.buildings[t].position.y;
                    var height = this.getHighestTerrain(this.buildings[t].position);

                    // find closest random target
                    for (var r = 0; r < this.buildings[t].weaponRadius + 1; r++) {
                        var targets = [];
                        var radius = r * this.tileSize;
                        for (var i = x - this.buildings[t].weaponRadius; i < x + this.buildings[t].weaponRadius + 2; i++) {
                            for (var j = y - this.buildings[t].weaponRadius; j < y + this.buildings[t].weaponRadius + 2; j++) {

                                // cannons can only shoot at tiles not higher than themselves
                                if (this.withinWorld(i, j)) {
                                    var tileHeight = this.getHighestTerrain(new Vector(i, j));
                                    if (tileHeight <= height) {
                                        var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                                        if (distance <= Math.pow(radius, 2) && this.world.tiles[i][j][0].creep > 0) {
                                            targets.push(new Vector(i, j));
                                        }
                                    }
                                }
                            }
                        }
                        if (targets.length > 0) {
                            targets.shuffle();

                            this.world.tiles[targets[0].x][targets[0].y][0].creep -= 10;
                            if (this.world.tiles[targets[0].x][targets[0].y][0].creep < 0)
                                this.world.tiles[targets[0].x][targets[0].y][0].creep = 0;

                            var dx = targets[0].x * this.tileSize + this.tileSize / 2 - center.x;
                            var dy = targets[0].y * this.tileSize + this.tileSize / 2 - center.y;
                            this.buildings[t].targetAngle = Math.atan2(dy, dx) + Math.PI / 2;
                            this.buildings[t].weaponTargetPosition = new Vector(targets[0].x, targets[0].y);
                            this.buildings[t].energy -= 1;
                            this.buildings[t].operating = true;
                            this.smokes.push(new Smoke(new Vector(targets[0].x * this.tileSize + this.tileSize / 2, targets[0].y * this.tileSize + this.tileSize / 2)));
                            engine.playSound("laser", new Vector(x, y));
                            break;
                        }
                    }
                }

                else if (this.buildings[t].imageID == "mortar" && this.buildings[t].energy > 0 && this.buildings[t].energyTimer > 200) {
                    this.buildings[t].energyTimer = 0;

                    // get building x and building y
                    var x = this.buildings[t].position.x;
                    var y = this.buildings[t].position.y;

                    // find most creep in range
                    var target = null;
                    var highestCreep = 0;
                    for (var i = x - this.buildings[t].weaponRadius; i < x + this.buildings[t].weaponRadius + 2; i++) {
                        for (var j = y - this.buildings[t].weaponRadius; j < y + this.buildings[t].weaponRadius + 2; j++) {
                            var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                            if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.tiles[i][j][0].creep > 0 && this.world.tiles[i][j][0].creep >= highestCreep) {
                                highestCreep = this.world.tiles[i][j][0].creep;
                                target = new Vector(i, j);
                            }
                        }
                    }
                    if (target) {
                        engine.playSound("shot", new Vector(x, y));
                        var shell = new Shell(center, "shell", new Vector(target.x * this.tileSize + this.tileSize / 2, target.y * this.tileSize + this.tileSize / 2));
                        shell.init();
                        this.shells.push(shell);
                        this.buildings[t].energy -= 1;
                    }
                }

                else if (this.buildings[t].imageID == "beam" && this.buildings[t].energy > 0 && this.buildings[t].energyTimer > 0) {
                    this.buildings[t].energyTimer = 0;

                    // find spore in range
                    for (var i = 0; i < this.spores.length; i++) {
                        var sporeCenter = this.spores[i].getCenter();
                        var distance = Math.pow(sporeCenter.x - center.x, 2) + Math.pow(sporeCenter.y - center.y, 2);

                        if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2)) {
                            this.buildings[t].weaponTargetPosition = sporeCenter;
                            this.buildings[t].energy -= .1;
                            this.buildings[t].operating = true;
                            this.spores[i].health -= 2;
                            if (this.spores[i].health <= 0) {
                                this.spores[i].remove = true;
                                engine.playSound("explosion", Helper.real2tiled(this.spores[i].position));
                                this.explosions.push(new Explosion(sporeCenter));
                            }
                        }
                    }
                }
            }
        }
    },
    /**
     * @param {Building} building The building to update
     * @param {String} action Add or Remove action
     */
    updateCollection: function (building, action) {
        var height = this.getHighestTerrain(building.position);
        var centerBuilding = building.getCenter();

        for (var i = -5; i < 7; i++) {
            for (var j = -5; j < 7; j++) {

                var positionCurrent = new Vector(
                    building.position.x + i,
                    building.position.y + j);
                var positionCurrentCenter = new Vector(
                    positionCurrent.x * this.tileSize + (this.tileSize / 2),
                    positionCurrent.y * this.tileSize + (this.tileSize / 2));
                var tileHeight = this.getHighestTerrain(positionCurrent);

                if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {

                    if (action == "add") {
                        if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
                            if (tileHeight == height) {
                                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = building;
                            }
                        }
                    }
                    else if (action == "remove") {

                        if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
                            if (tileHeight == height) {
                                this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector = null;
                            }
                        }

                        for (var k = 0; k < this.buildings.length; k++) {
                            if (this.buildings[k] != building && this.buildings[k].imageID == "collector") {
                                var heightK = this.getHighestTerrain(new Vector(this.buildings[k].position.x, this.buildings[k].position.y));
                                var centerBuildingK = this.buildings[k].getCenter();
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
    },
    calculateCollection: function () {
        this.collection = 0;

        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                for (var k = 0; k < 10; k++) {
                    if (this.world.tiles[i][j][k].collector)
                        this.collection += 1;
                }
            }
        }

        // decrease collection of collectors
        this.collection = parseInt(this.collection * .1);

        for (var t = 0; t < this.buildings.length; t++) {
            if (this.buildings[t].imageID == "reactor" || this.buildings[t].imageID == "base") {
                this.collection += 1;
            }
        }

        this.updateCollectionElement();
    },
    updateCreeper: function () {
        for (var i = 0; i < this.sporetowers.length; i++)
            this.sporetowers[i].update();

        this.spawnTimer++;
        if (this.spawnTimer >= (25 / this.speed)) { // 125
            for (var i = 0; i < this.emitters.length; i++)
                this.emitters[i].spawn();
            this.spawnTimer = 0;
        }

        var minimum = .001;

        this.creeperTimer++;
        if (this.creeperTimer > (25 / this.speed)) {
            this.creeperTimer -= (25 / this.speed);

            for (var i = 0; i < this.world.size.x; i++) {
                for (var j = 0; j < this.world.size.y; j++) {
                    this.world.tiles[i][j][0].newcreep = this.world.tiles[i][j][0].creep;
                }
            }

            for (var i = 0; i < this.world.size.x; i++) {
                for (var j = 0; j < this.world.size.y; j++) {

                    var height = this.getHighestTerrain(new Vector(i, j));
                    if (i - 1 > -1 && i + 1 < this.world.size.x && j - 1 > -1 && j + 1 < this.world.size.y) {
                        //if (height >= 0) {
                        // right neighbour
                        var height2 = this.getHighestTerrain(new Vector(i + 1, j));
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

            for (var i = 0; i < this.world.size.x; i++) {
                for (var j = 0; j < this.world.size.y; j++) {
                    this.world.tiles[i][j][0].creep = this.world.tiles[i][j][0].newcreep;
                    if (this.world.tiles[i][j][0].creep > 10)
                        this.world.tiles[i][j][0].creep = 10;
                    if (this.world.tiles[i][j][0].creep < minimum)
                        this.world.tiles[i][j][0].creep = 0;
                }
            }

            this.drawCreeper();

        }
    },
    transferCreeper: function (height, height2, source, target) {
        var transferRate = .25;

        var sourceAmount = source.creep;
        var sourceTotal = height + source.creep;

        if (height2 > -1) {
            var targetAmount = target.creep;
            if (sourceAmount > 0 || targetAmount > 0) {
                var targetTotal = height2 + target.creep;
                var delta = 0;
                if (sourceTotal > targetTotal) {
                    delta = sourceTotal - targetTotal;
                    if (delta > sourceAmount)
                        delta = sourceAmount;
                    var adjustedDelta = delta * transferRate;
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
    },
    /**
     * Used for A*, finds all neighbouring nodes of a given node.
     *
     * @param {Building} node The current node
     * @param {Building} target The target node
     */
    getNeighbours: function (node, target) {
        var neighbours = [], centerI, centerNode;
        //if (node.built) {
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].position.x == node.position.x && this.buildings[i].position.y == node.position.y) {
                // console.log("is me");
            } else {
                // if the node is not the target AND built it is a valid neighbour
                // also the neighbour must not be moving
                if (!this.buildings[i].moving) { // && this.buildings[i].imageID != "base") {
                    if (this.buildings[i] != target) {
                        if (this.buildings[i].built) {
                            centerI = this.buildings[i].getCenter();
                            centerNode = node.getCenter();
                            var distance = Helper.distance(centerI, centerNode);

                            var allowedDistance = 10 * this.tileSize;
                            if (node.imageID == "relay" && this.buildings[i].imageID == "relay") {
                                allowedDistance = 20 * this.tileSize;
                            }
                            if (distance <= allowedDistance) {
                                neighbours.push(this.buildings[i]);
                            }
                        }
                    }
                    // if it is the target it is a valid neighbour
                    else {
                        centerI = this.buildings[i].getCenter();
                        centerNode = node.getCenter();
                        var distance = Helper.distance(centerI, centerNode);

                        var allowedDistance = 10 * this.tileSize;
                        if (node.imageID == "relay" && this.buildings[i].imageID == "relay") {
                            allowedDistance = 20 * this.tileSize;
                        }
                        if (distance <= allowedDistance) {
                            neighbours.push(this.buildings[i]);
                        }
                    }
                }
            }
        }
        //}
        return neighbours;
    },
    /**
     * Used for A*, checks if a node is already in a given route.
     *
     * @param {Building} neighbour The node to check
     * @param {Array} route The route to check
     */
    inRoute: function (neighbour, route) {
        var found = false;
        for (var i = 0; i < route.length; i++) {
            if (neighbour.position.x == route[i].position.x && neighbour.position.y == route[i].position.y) {
                found = true;
                break;
            }
        }
        return found;
    },
    /**
     * Main function of A*, finds a path to the target node.
     *
     * @param {Packet} packet The packet to find a path for
     */
    findRoute: function (packet) {
        // A* using Branch and Bound with dynamic programming and underestimates, thanks to: http://ai-depot.com/Tutorial/PathFinding-Optimal.html

        // this holds all routes
        var routes = [];

        // create a new route and add the current node as first element
        var route = new Route();
        route.nodes.push(packet.currentTarget);
        routes.push(route);

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
            var oldRoute = routes.shift();

            // get the last node of the route
            var lastNode = oldRoute.nodes[oldRoute.nodes.length - 1];
            //console.log("1) currently at: " + lastNode.type + ": " + lastNode.x + "/" + lastNode.y + ", route length: " + oldRoute.nodes.length);

            // find all neighbours of this node
            var neighbours = this.getNeighbours(lastNode, packet.target);
            //console.log("2) neighbours found: " + neighbours.length);

            var newRoutes = 0;
            // extend the old route with each neighbour creating a new route each
            for (var i = 0; i < neighbours.length; i++) {

                // if the neighbour is not already in the list..
                if (!this.inRoute(neighbours[i], oldRoute.nodes)) {

                    newRoutes++;

                    // create new route
                    var newRoute = new Route();

                    // copy current list of nodes from old route to new route
                    newRoute.nodes = Helper.clone(oldRoute.nodes);

                    // add the new node to the new route
                    newRoute.nodes.push(neighbours[i]);

                    // copy distance travelled from old route to new route
                    newRoute.distanceTravelled = oldRoute.distanceTravelled;

                    // increase distance travelled
                    var centerA = newRoute.nodes[newRoute.nodes.length - 1].getCenter();
                    var centerB = newRoute.nodes[newRoute.nodes.length - 2].getCenter();
                    newRoute.distanceTravelled += Helper.distance(centerA, centerB);

                    // update underestimate of distance remaining
                    var centerC = packet.target.getCenter();
                    newRoute.distanceRemaining = Helper.distance(centerC, centerA);

                    // finally push the new route to the list of routes
                    routes.push(newRoute);
                }

            }

            //console.log("3) new routes: " + newRoutes);
            //console.log("4) total routes: " + routes.length);

            // find routes that end at the same node, remove those with the longer distance travelled
            for (var i = 0; i < routes.length; i++) {
                for (var j = 0; j < routes.length; j++) {
                    if (i != j) {
                        if (routes[i].nodes[routes[i].nodes.length - 1] == routes[j].nodes[routes[j].nodes.length - 1]) {
                            //console.log("5) found duplicate route to " + routes[i].nodes[routes[i].nodes.length - 1].type + ", removing longer");
                            if (routes[i].distanceTravelled < routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[j]), 1);
                            }
                            else if (routes[i].distanceTravelled > routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[i]), 1);
                            }

                        }
                    }
                }
            }

            /*$('#other').append("-- to be removed: " + remove.length);
             for (var i = 0; i < remove.length; i++) {
             for (var j = 0; j < routes.length; j++) {
             if (remove[i].x == routes[i].x && remove[i].y == routes[i].y)
             routes.splice(j);
             }
             }
             $('#other').append(", new total routes: " + routes.length + "<br/>");*/

            // sort routes by total underestimate so that the possibly shortest route gets checked first
            routes.sort(function (a, b) {
                return (a.distanceTravelled + a.distanceRemaining) - (b.distanceTravelled + b.distanceRemaining)
            });
        }

        // if a route is left set the second element as the next node for the packet
        if (routes.length > 0) {
            // adjust speed if packet is travelling between relays
            if (routes[0].nodes[1].imageID == "relay") {
                packet.speedMultiplier = 2;
            }
            else {
                packet.speedMultiplier = 1;
            }

            packet.currentTarget = routes[0].nodes[1];
        }
        else {
            packet.currentTarget = null;
            if (packet.type == "energy") {
                packet.target.energyRequests -= 4;
                if (packet.target.energyRequests < 0)
                    packet.target.energyRequests = 0;
            }
            else if (packet.type == "health") {
                packet.target.healthRequests--;
                if (packet.target.healthRequests < 0)
                    packet.target.healthRequests = 0;
            }
            packet.remove = true;
        }
    },
    /**
     * @param {Building} building The packet target building
     * @param {String} type The type of the packet
     */
    queuePacket: function (building, type) {
        var img = "packet_" + type;
        var center = game.base.getCenter();
        var packet = new Packet(center, img, type);
        packet.target = building;
        packet.currentTarget = game.base;
        this.findRoute(packet);
        if (packet.currentTarget) {
            if (packet.type == "health")
                packet.target.healthRequests++;
            if (packet.type == "energy")
                packet.target.energyRequests += 4;
            this.packetQueue.push(packet);
        }
    },
    /**
     * Checks if a building can be placed on the current tile.
     *
     * @param {Vector} position The position to place the building
     * @param {int} size The size of the building
     * @param {Building} building The building to place
     */
    canBePlaced: function (position, size, building) {
        var collision = false;

        if (position.x > -1 && position.x < this.world.size.x - size + 1 && position.y > -1 && position.y < this.world.size.y - size + 1) {
            var height = this.getHighestTerrain(position);

            // 1. check for collision with another building
            for (var i = 0; i < this.buildings.length; i++) {
                if (building && building == this.buildings[i])
                    continue;
                var x1 = this.buildings[i].position.x * this.tileSize;
                var x2 = this.buildings[i].position.x * this.tileSize + this.buildings[i].size * this.tileSize - 1;
                var y1 = this.buildings[i].position.y * this.tileSize;
                var y2 = this.buildings[i].position.y * this.tileSize + this.buildings[i].size * this.tileSize - 1;

                var cx1 = position.x * this.tileSize;
                var cx2 = position.x * this.tileSize + size * this.tileSize - 1;
                var cy1 = position.y * this.tileSize;
                var cy2 = position.y * this.tileSize + size * this.tileSize - 1;

                if (((cx1 >= x1 && cx1 <= x2) || (cx2 >= x1 && cx2 <= x2)) && ((cy1 >= y1 && cy1 <= y2) || (cy2 >= y1 && cy2 <= y2))) {
                    collision = true;
                    break;
                }
            }

            // 2. check if all tiles have the same height and are not corners
            if (!collision) {
                for (var i = position.x; i < position.x + size; i++) {
                    for (var j = position.y; j < position.y + size; j++) {
                        if (this.withinWorld(i, j)) {
                            var tileHeight = this.getHighestTerrain(new Vector(i, j));
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
        }
        else {
            collision = true;
        }

        return (!collision);
    },
    updatePacketQueue: function () {
        for (var i = 0; i < this.packetQueue.length; i++) {
            if (this.currentEnergy > 0) {
                this.currentEnergy--;
                this.updateEnergyElement();
                var packet = this.packetQueue.shift();
                this.packets.push(packet);
            }
        }
    },
    updateBuildings: function () {
        this.checkOperating();

        // move
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].move();
        }

        // push away creeper (shield)
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].shield();
        }

        // take damage
        this.damageTimer++;
        if (this.damageTimer > 100) {
            this.damageTimer = 0;
            for (var i = 0; i < this.buildings.length; i++) {
                this.buildings[i].takeDamage();
            }
        }

        // request packets
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].active && !this.buildings[i].moving) {
                this.buildings[i].requestTimer++;
                // request health
                if (this.buildings[i].imageID != "base") {
                    var healthAndRequestDelta = this.buildings[i].maxHealth - this.buildings[i].health - this.buildings[i].healthRequests;
                    if (healthAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
                        this.buildings[i].requestTimer = 0;
                        this.queuePacket(this.buildings[i], "health");
                    }
                }
                // request energy
                if (this.buildings[i].needsEnergy && this.buildings[i].built) {
                    var energyAndRequestDelta = this.buildings[i].maxEnergy - this.buildings[i].energy - this.buildings[i].energyRequests;
                    if (energyAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
                        this.buildings[i].requestTimer = 0;
                        this.queuePacket(this.buildings[i], "energy");
                    }
                }
            }
        }

    },
    updateEnergy: function () {
        this.energyTimer++;
        if (this.energyTimer > (250 / this.speed)) {
            this.energyTimer -= (250 / this.speed);
            for (var k = 0; k < this.buildings.length; k++) {
                if (this.buildings[k].imageID == "collector" && this.buildings[k].built) {
                    var height = this.getHighestTerrain(this.buildings[k].position);
                    var centerBuilding = this.buildings[k].getCenter();

                    for (var i = -5; i < 7; i++) {
                        for (var j = -5; j < 7; j++) {
                            var positionCurrent = new Vector(
                                this.buildings[k].position.x + i,
                                this.buildings[k].position.y + j);
                            var positionCurrentCenter = new Vector(
                                positionCurrent.x * this.tileSize + (this.tileSize / 2),
                                positionCurrent.y * this.tileSize + (this.tileSize / 2));
                            var tileHeight = this.getHighestTerrain(positionCurrent);

                            if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
                                if (Math.pow(positionCurrentCenter.x - centerBuilding.x, 2) + Math.pow(positionCurrentCenter.y - centerBuilding.y, 2) < Math.pow(this.tileSize * 6, 2)) {
                                    if (tileHeight == height) {
                                        if (this.world.tiles[positionCurrent.x][positionCurrent.y][tileHeight].collector == this.buildings[k])
                                            this.buildings[k].collectedEnergy += 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].collectedEnergy >= 100) {
                this.buildings[i].collectedEnergy -= 100;
                var img = "packet_collection";
                var center = this.buildings[i].getCenter();
                var packet = new Packet(center, img, "collection");
                packet.target = game.base;
                packet.currentTarget = this.buildings[i];
                this.findRoute(packet);
                if (packet.currentTarget)
                    this.packets.push(packet);
            }
        }
    },
    updatePackets: function () {
        for (var i = 0; i < this.packets.length; i++) {
            this.packets[i].move();
            if (this.packets[i].remove)
                this.packets.splice(i, 1);
        }
    },
    updateShells: function () {
        for (var i = 0; i < this.shells.length; i++) {
            this.shells[i].move();
            if (this.shells[i].remove)
                this.shells.splice(i, 1);
        }
    },
    updateSpores: function () {
        for (var i = 0; i < this.spores.length; i++) {
            this.spores[i].move();
            if (this.spores[i].remove)
                this.spores.splice(i, 1);
        }
    },
    updateSmokes: function () {
        this.smokeTimer++;
        if (this.smokeTimer > 3) {
            this.smokeTimer = 0;
            for (var i = 0; i < this.smokes.length; i++) {
                this.smokes[i].frame++;
                if (this.smokes[i].frame == 36)
                    this.smokes.splice(i, 1);
            }
        }
    },
    updateExplosions: function () {
        this.explosionTimer++;
        if (this.explosionTimer == 1) {
            this.explosionTimer = 0;
            for (var i = 0; i < this.explosions.length; i++) {
                this.explosions[i].frame++;
                if (this.explosions[i].frame == 44)
                    this.explosions.splice(i, 1);
            }
        }
    },
    updateShips: function () {
        // move
        for (var i = 0; i < this.ships.length; i++) {
            this.ships[i].move();
        }
    },
    update: function () {
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].updateHoverState();
        }
        for (var i = 0; i < this.ships.length; i++) {
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
        if (this.scrolling.left) {
            if (this.scroll.x > 0)
                this.scroll.x -= 1;
        }

        // scroll right
        else if (this.scrolling.right) {
            if (this.scroll.x < this.world.size.x)
                this.scroll.x += 1;
        }

        // scroll up
        if (this.scrolling.up) {
            if (this.scroll.y > 0)
                this.scroll.y -= 1;
        }

        // scroll down
        else if (this.scrolling.down) {
            if (this.scroll.y < this.world.size.y)
                this.scroll.y += 1;

        }

        if (this.scrolling.left || this.scrolling.right || this.scrolling.up || this.scrolling.down) {
            this.copyTerrain();
            this.drawCollection();
            this.drawCreeper();
        }
    },
    /**
     * @param {Vector} position The position of the building
     * @param {String} type The type of the building
     * @param {int} radius The radius of the building
     * @param {int} size The size of the building
     */
    drawRangeBoxes: function (position, type, radius, size) {
        var positionCenter = new Vector(
            position.x * this.tileSize + (this.tileSize / 2) * size,
            position.y * this.tileSize + (this.tileSize / 2) * size);
        var positionHeight = this.getHighestTerrain(position);

        if (this.canBePlaced(position, size, null) && (type == "collector" || type == "cannon" || type == "mortar" || type == "shield" || type == "beam" || type == "terp")) {

            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.globalAlpha = .25;

            var radius = radius * this.tileSize;

            for (var i = -radius; i < radius; i++) {
                for (var j = -radius; j < radius; j++) {

                    var positionCurrent = new Vector(
                        position.x + i,
                        position.y + j);
                    var positionCurrentCenter = new Vector(
                        positionCurrent.x * this.tileSize + (this.tileSize / 2),
                        positionCurrent.y * this.tileSize + (this.tileSize / 2));

                    var drawPositionCurrent = Helper.tiled2screen(positionCurrent);

                    if (this.withinWorld(positionCurrent.x, positionCurrent.y)) {
                        var positionCurrentHeight = this.getHighestTerrain(positionCurrent);

                        if (Math.pow(positionCurrentCenter.x - positionCenter.x, 2) + Math.pow(positionCurrentCenter.y - positionCenter.y, 2) < Math.pow(radius, 2)) {
                            if (type == "collector") {
                                if (positionCurrentHeight == positionHeight) {
                                    engine.canvas["buffer"].context.fillStyle = "#fff";
                                }
                                else {
                                    engine.canvas["buffer"].context.fillStyle = "#f00";
                                }
                            }
                            if (type == "cannon") {
                                if (positionCurrentHeight <= positionHeight) {
                                    engine.canvas["buffer"].context.fillStyle = "#fff";
                                }
                                else {
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
    },
    /**
     * Draws the green collection areas of collectors.
     */
    drawCollection: function () {
        engine.canvas["collection"].clear();
        engine.canvas["collection"].context.save();
        engine.canvas["collection"].context.globalAlpha = .5;

        var timesX = Math.ceil(engine.halfWidth / this.tileSize / this.zoom);
        var timesY = Math.ceil(engine.halfHeight / this.tileSize / this.zoom);

        for (var i = -timesX; i <= timesX; i++) {
            for (var j = -timesY; j <= timesY; j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (this.withinWorld(iS, jS)) {

                    for (var k = 0; k < 10; k++) {
                        if (this.world.tiles[iS][jS][k].collector) {
                            var up = 0, down = 0, left = 0, right = 0;
                            if (jS - 1 < 0)
                                up = 0;
                            else
                                up = this.world.tiles[iS][jS - 1][k].collector ? 1 : 0;
                            if (jS + 1 > this.world.size.y - 1)
                                down = 0;
                            else
                                down = this.world.tiles[iS][jS + 1][k].collector ? 1 : 0;
                            if (iS - 1 < 0)
                                left = 0;
                            else
                                left = this.world.tiles[iS - 1][jS][k].collector ? 1 : 0;
                            if (iS + 1 > this.world.size.x - 1)
                                right = 0;
                            else
                                right = this.world.tiles[iS + 1][jS][k].collector ? 1 : 0;

                            var index = (8 * down) + (4 * left) + (2 * up) + right;
                            engine.canvas["collection"].context.drawImage(engine.images["mask"], index * (this.tileSize + 6) + 3, (this.tileSize + 6) + 3, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * this.zoom, engine.halfHeight + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
                        }
                    }
                }
            }
        }
        engine.canvas["collection"].context.restore();
    },
    drawCreeper: function () {
        engine.canvas["creeper"].clear();

        var timesX = Math.ceil(engine.halfWidth / this.tileSize / this.zoom);
        var timesY = Math.ceil(engine.halfHeight / this.tileSize / this.zoom);

        for (var i = -timesX; i <= timesX; i++) {
            for (var j = -timesY; j <= timesY; j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (this.withinWorld(iS, jS)) {

                    if (this.world.tiles[iS][jS][0].creep > 0) {
                        var creep = Math.ceil(this.world.tiles[iS][jS][0].creep);

                        var up = 0, down = 0, left = 0, right = 0;
                        if (jS - 1 < 0)
                            up = 0;
                        else if (Math.ceil(this.world.tiles[iS][jS - 1][0].creep) >= creep)
                            up = 1;
                        if (jS + 1 > this.world.size.y - 1)
                            down = 0;
                        else if (Math.ceil(this.world.tiles[iS][jS + 1][0].creep) >= creep)
                            down = 1;
                        if (iS - 1 < 0)
                            left = 0;
                        else if (Math.ceil(this.world.tiles[iS - 1][jS][0].creep) >= creep)
                            left = 1;
                        if (iS + 1 > this.world.size.x - 1)
                            right = 0;
                        else if (Math.ceil(this.world.tiles[iS + 1][jS][0].creep) >= creep)
                            right = 1;

                        //if (creep > 1) {
                        //    engine.canvas["buffer"].context.drawImage(engine.images["creep"], 15 * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
                        //}

                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        engine.canvas["creeper"].context.drawImage(engine.images["creep"], index * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, engine.halfWidth + i * this.tileSize * game.zoom, engine.halfHeight + j * this.tileSize * game.zoom, this.tileSize * game.zoom, this.tileSize * game.zoom);
                    }

                    // creep value
                    //engine.canvas["buffer"].context.textAlign = 'left';
                    //engine.canvas["buffer"].context.fillText(Math.floor(this.world.tiles[i][j].creep), i * this.tileSize + 2, j * this.tileSize + 10);

                    // height value
                    //engine.canvas["buffer"].context.textAlign = 'left';
                    //engine.canvas["buffer"].context.fillText(this.world.tiles[i][j].height, i * this.tileSize + 2, j * this.tileSize + 10);
                }
            }
        }
    },
    /**
     * When a building from the GUI is selected this draws some info whether it can be build on the current tile,
     * the range as white boxes and connections to other buildings
     */
    drawPositionInfo: function () {
        game.ghosts = []; // ghosts are all the placeholders to build
        if (engine.mouse.dragStart) {

            var start = engine.mouse.dragStart;
            var end = engine.mouse.dragEnd;
            var delta = new Vector(end.x - start.x, end.y - start.y);
            var distance = Helper.distance(start, end);
            var times = Math.floor(distance / 10) + 1;

            game.ghosts.push({position: start});

            for (var i = 1; i < times; i++) {
                var newX = Math.floor(start.x + (delta.x / distance) * i * 10);
                var newY = Math.floor(start.y + (delta.y / distance) * i * 10);

                if (this.withinWorld(newX, newY)) {
                    var ghost = {position: new Vector(newX, newY)};
                    game.ghosts.push(ghost);
                }
            }
            if (this.withinWorld(end.x, end.y)) {
                game.ghosts.push({position: end});
            }
        }
        else {
            if (engine.mouse.active) {
                var position = this.getHoveredTilePosition();
                if (this.withinWorld(position.x, position.y)) {
                    game.ghosts.push({position: position})
                }
            }
        }

        for (var j = 0; j < game.ghosts.length; j++) {
            var positionScrolled = new Vector(game.ghosts[j].position.x, game.ghosts[j].position.y); //this.getHoveredTilePosition();
            var drawPosition = Helper.tiled2screen(positionScrolled);
            var positionScrolledCenter = new Vector(
                positionScrolled.x * this.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size,
                positionScrolled.y * this.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size);

            this.drawRangeBoxes(positionScrolled, this.symbols[this.activeSymbol].imageID,
                this.symbols[this.activeSymbol].radius,
                this.symbols[this.activeSymbol].size);

            if (this.withinWorld(positionScrolled.x, positionScrolled.y)) {
                engine.canvas["buffer"].context.save();
                engine.canvas["buffer"].context.globalAlpha = .5;

                // draw building
                engine.canvas["buffer"].context.drawImage(engine.images[this.symbols[this.activeSymbol].imageID], drawPosition.x, drawPosition.y, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom);
                if (this.symbols[this.activeSymbol].imageID == "cannon")
                    engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], drawPosition.x, drawPosition.y, 48 * this.zoom, 48 * this.zoom);

                // draw green or red box
                // make sure there isn't a building on this tile yet
                if (this.canBePlaced(positionScrolled, this.symbols[this.activeSymbol].size, null)) {
                    engine.canvas["buffer"].context.strokeStyle = "#0f0";
                }
                else {
                    engine.canvas["buffer"].context.strokeStyle = "#f00";
                }
                engine.canvas["buffer"].context.lineWidth = 4 * this.zoom;
                engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom);

                engine.canvas["buffer"].context.restore();

                // draw lines to other buildings
                for (var i = 0; i < this.buildings.length; i++) {
                    var center = this.buildings[i].getCenter();
                    var drawCenter = Helper.real2screen(center);

                    var allowedDistance = 10 * this.tileSize;
                    if (this.buildings[i].imageID == "relay" && this.symbols[this.activeSymbol].imageID == "relay") {
                        allowedDistance = 20 * this.tileSize;
                    }

                    if (Math.pow(center.x - positionScrolledCenter.x, 2) + Math.pow(center.y - positionScrolledCenter.y, 2) <= Math.pow(allowedDistance, 2)) {
                        var lineToTarget = Helper.real2screen(positionScrolledCenter);
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
                for (var k = 0; k < game.ghosts.length; k++) {
                    if (k != j) {
                        var center = new Vector(
                            game.ghosts[k].position.x * game.tileSize + (game.tileSize / 2) * 3,
                            game.ghosts[k].position.y * game.tileSize + (game.tileSize / 2) * 3);
                        var drawCenter = Helper.real2screen(center);

                        var allowedDistance = 10 * this.tileSize;
                        if (this.symbols[this.activeSymbol].imageID == "relay") {
                            allowedDistance = 20 * this.tileSize;
                        }

                        if (Math.pow(center.x - positionScrolledCenter.x, 2) + Math.pow(center.y - positionScrolledCenter.y, 2) <= Math.pow(allowedDistance, 2)) {
                            var lineToTarget = Helper.real2screen(positionScrolledCenter);
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

    },
    /**
     * Draws the attack symbols of ships.
     */
    drawAttackSymbol: function () {
        if (this.mode == this.modes.SHIP_SELECTED) {
            var position = Helper.tiled2screen(this.getHoveredTilePosition());
            engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], position.x - this.tileSize, position.y - this.tileSize);
        }
    },
    /**
     * Draws the GUI with symbols, height and creep meter.
     */
    drawGUI: function () {
        var position = game.getHoveredTilePosition();

        engine.canvas["gui"].clear();
        for (var i = 0; i < this.symbols.length; i++) {
            this.symbols[i].draw(engine.canvas["gui"].context);
        }

        if (this.withinWorld(position.x, position.y)) {

            var total = this.world.tiles[position.x][position.y][0].creep;

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
            for (var i = 1; i < 11; i++) {
                engine.canvas["gui"].context.fillText(i.toString(), 550, 120 - i * 10);
                engine.canvas["gui"].context.beginPath();
                engine.canvas["gui"].context.moveTo(555, 120 - i * 10);
                engine.canvas["gui"].context.lineTo(580, 120 - i * 10);
                engine.canvas["gui"].context.stroke();
            }
            engine.canvas["gui"].context.textAlign = 'left';
            engine.canvas["gui"].context.fillText(total.toFixed(2), 605, 10);
        }
    }
};

// Objects

/**
 * Building symbols in the GUI
 */
function UISymbol(pPosition, pImage, pKey, pSize, pPackets, pRadius) {
    this.position = pPosition;
    this.imageID = pImage;
    this.key = pKey;
    this.active = false;
    this.hovered = false;
    this.width = 80;
    this.height = 55;
    this.size = pSize;
    this.packets = pPackets;
    this.radius = pRadius;
    this.draw = function (pContext) {
        if (this.active) {
            pContext.fillStyle = "#696";
        }
        else {
            if (this.hovered) {
                pContext.fillStyle = "#232";
            }
            else {
                pContext.fillStyle = "#454";
            }
        }
        pContext.fillRect(this.position.x + 1, this.position.y + 1, this.width, this.height);

        pContext.drawImage(engine.images[this.imageID], this.position.x + 24, this.position.y + 20, 32, 32); // scale buildings to 32x32
        // draw cannon gun and ships
        if (this.imageID == "cannon")
            pContext.drawImage(engine.images["cannongun"], this.position.x + 24, this.position.y + 20, 32, 32);
        if (this.imageID == "bomber")
            pContext.drawImage(engine.images["bombership"], this.position.x + 24, this.position.y + 20, 32, 32);
        pContext.fillStyle = '#fff';
        pContext.font = '10px';
        pContext.textAlign = 'center';
        pContext.fillText(this.imageID.substring(0, 1).toUpperCase() + this.imageID.substring(1), this.position.x + (this.width / 2), this.position.y + 15);
        pContext.textAlign = 'left';
        pContext.fillText("(" + this.key + ")", this.position.x + 5, this.position.y + 50);
        pContext.textAlign = 'right';
        pContext.fillText(this.packets, this.position.x + this.width - 5, this.position.y + 50);
    };
    this.checkHovered = function () {
        this.hovered = (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height);
    };
    this.setActive = function () {
        this.active = false;
        if (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height) {
            game.activeSymbol = Math.floor(this.position.x / 81) + (Math.floor(this.position.y / 56)) * 5;
            this.active = true;
        }
    };
}

function Building(pPosition, pImage) {
    this.position = pPosition;
    this.imageID = pImage;
    this.operating = false;
    this.selected = false;
    this.hovered = false;
    this.weaponTargetPosition = null;
    this.health = 0;
    this.maxHealth = 0;
    this.energy = 0;
    this.maxEnergy = 0;
    this.energyTimer = 0;
    this.healthRequests = 0;
    this.energyRequests = 0;
    this.requestTimer = 0;
    this.weaponRadius = 0;
    this.built = false;
    this.targetAngle = 0;
    this.size = 0;
    this.active = true;
    this.moving = false;
    this.speed = new Vector(0, 0);
    this.moveTargetPosition = new Vector(0, 0);
    this.canMove = false;
    this.needsEnergy = false;
    this.collectedEnergy = 0;
    this.ship = null;
    this.updateHoverState = function () {
        var position = Helper.tiled2screen(this.position);
        this.hovered = (engine.mouse.x > position.x &&
            engine.mouse.x < position.x + game.tileSize * this.size * game.zoom - 1 &&
            engine.mouse.y > position.y &&
            engine.mouse.y < position.y + game.tileSize * this.size * game.zoom - 1);

        return this.hovered;
    };
    this.drawBox = function () {
        if (this.hovered || this.selected) {
            var position = Helper.tiled2screen(this.position);
            engine.canvas["buffer"].context.lineWidth = 2 * game.zoom;
            engine.canvas["buffer"].context.strokeStyle = "#000";
            engine.canvas["buffer"].context.strokeRect(position.x, position.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
        }
    };
    this.move = function () {
        if (this.moving) {
            this.position.x += this.speed.x;
            this.position.y += this.speed.y;
            if (this.position.x * game.tileSize > this.moveTargetPosition.x * game.tileSize - 3 &&
                this.position.x * game.tileSize < this.moveTargetPosition.x * game.tileSize + 3 &&
                this.position.y * game.tileSize > this.moveTargetPosition.y * game.tileSize - 3 &&
                this.position.y * game.tileSize < this.moveTargetPosition.y * game.tileSize + 3) {
                this.moving = false;
                this.position.x = this.moveTargetPosition.x;
                this.position.y = this.moveTargetPosition.y;
            }
        }
    };
    this.calculateVector = function () {
        if (this.moveTargetPosition.x != this.position.x || this.moveTargetPosition.y != this.position.y) {
            var targetPosition = new Vector(this.moveTargetPosition.x * game.tileSize, this.moveTargetPosition.y * game.tileSize);
            var ownPosition = new Vector(this.position.x * game.tileSize, this.position.y * game.tileSize);
            var delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
            var distance = Helper.distance(targetPosition, ownPosition);

            this.speed.x = (delta.x / distance) * game.buildingSpeed * game.speed / game.tileSize;
            this.speed.y = (delta.y / distance) * game.buildingSpeed * game.speed / game.tileSize;
        }
    };
    this.getCenter = function () {
        return new Vector(
            this.position.x * game.tileSize + (game.tileSize / 2) * this.size,
            this.position.y * game.tileSize + (game.tileSize / 2) * this.size);
    };
    this.takeDamage = function () {
        // buildings can only be damaged while not moving
        if (!this.moving) {

            for (var i = 0; i < this.size; i++) {
                for (var j = 0; j < this.size; j++) {
                    if (game.world.tiles[this.position.x + i][this.position.y + j][0].creep > 0) {
                        this.health -= game.world.tiles[this.position.x + i][this.position.y + j][0].creep;
                    }
                }
            }

            if (this.health < 0) {
                game.removeBuilding(this);
            }
        }
    };
    this.drawMovementIndicators = function () {
        if (this.moving) {
            var center = Helper.real2screen(this.getCenter());
            var target = Helper.tiled2screen(this.moveTargetPosition);
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
    };
    this.drawRepositionInfo = function () {
        if (this.built && this.selected && this.canMove) {
            var positionScrolled = game.getHoveredTilePosition();
            var drawPosition = Helper.tiled2screen(positionScrolled);
            var positionScrolledCenter = new Vector(
                positionScrolled.x * game.tileSize + (game.tileSize / 2) * this.size,
                positionScrolled.y * game.tileSize + (game.tileSize / 2) * this.size);
            var drawPositionCenter = Helper.real2screen(positionScrolledCenter);

            var center = Helper.real2screen(this.getCenter());

            game.drawRangeBoxes(positionScrolled, this.imageID, this.weaponRadius, this.size);

            if (game.canBePlaced(positionScrolled, this.size, this))
                engine.canvas["buffer"].context.strokeStyle = "rgba(0,255,0,0.5)";
            else
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
    };
    this.shield = function () {
        if (this.built && this.imageID == "shield" && !this.moving) {
            var center = this.getCenter();

            for (var i = this.position.x - 9; i < this.position.x + 10; i++) {
                for (var j = this.position.y - 9; j < this.position.y + 10; j++) {
                    if (game.withinWorld(i, j)) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - center.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - center.y, 2);
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
    };
    this.draw = function () {
        var position = Helper.tiled2screen(this.position);
        var center = Helper.real2screen(this.getCenter());

        if (engine.isVisible(position, new Vector(engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom))) {
            if (!this.built) {
                engine.canvas["buffer"].context.save();
                engine.canvas["buffer"].context.globalAlpha = .5;
                engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
                if (this.imageID == "cannon") {
                    engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
                }
                engine.canvas["buffer"].context.restore();
            }
            else {
                engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
                if (this.imageID == "cannon") {
                    engine.canvas["buffer"].context.save();
                    engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
                    engine.canvas["buffer"].context.rotate(this.targetAngle);
                    engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
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
                var targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
                engine.canvas["buffer"].context.strokeStyle = "#f00";
                engine.canvas["buffer"].context.beginPath();
                engine.canvas["buffer"].context.moveTo(center.x, center.y);
                engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
                engine.canvas["buffer"].context.stroke();
            }
            if (this.imageID == "beam") {
                var targetPosition = Helper.real2screen(this.weaponTargetPosition);
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
                engine.canvas["buffer"].context.drawImage(engine.images["forcefield"], center.x - 168 * game.zoom, center.y - 168 * game.zoom, 336 * game.zoom, 336 * game.zoom);
            }
            if (this.imageID == "terp") {
                var targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
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

    };
}

function Packet(pPosition, pImage, pType) {
    this.position = pPosition;
    this.imageID = pImage;
    this.speed = new Vector(0, 0);
    this.target = null;
    this.currentTarget = null;
    this.type = pType;
    this.remove = false;
    this.speedMultiplier = 1;
    this.move = function () {
        this.calculateVector();

        this.position.x += this.speed.x;
        this.position.y += this.speed.y;

        var centerTarget = this.currentTarget.getCenter();
        if (this.position.x > centerTarget.x - 1 && this.position.x < centerTarget.x + 1 && this.position.y > centerTarget.y - 1 && this.position.y < centerTarget.y + 1) {
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
                            if (this.target.imageID == "storage")
                                game.maxEnergy += 20;
                            if (this.target.imageID == "speed")
                                game.packetSpeed *= 1.01;
                            if (this.target.imageID == "bomber") {
                                var ship = new Ship(new Vector(this.target.position.x * game.tileSize, this.target.position.y * game.tileSize), "bombership", "Bomber", this.target);
                                this.target.ship = ship;
                                game.ships.push(ship);
                            }
                        }
                    }
                }
                else if (this.type == "energy") {
                    this.target.energy += 4;
                    this.target.energyRequests -= 4;
                    if (this.target.energy > this.target.maxEnergy)
                        this.target.energy = this.target.maxEnergy;
                }
                else if (this.type == "collection") {
                    game.currentEnergy += 1;
                    if (game.currentEnergy > game.maxEnergy)
                        game.currentEnergy = game.maxEnergy;
                    game.updateEnergyElement();
                }
            }
            else {
                game.findRoute(this);
            }
        }
    };
    this.calculateVector = function () {
        var targetPosition = this.currentTarget.getCenter();
        var delta = new Vector(targetPosition.x - this.position.x, targetPosition.y - this.position.y);
        var distance = Helper.distance(targetPosition, this.position);

        var packetSpeed = game.packetSpeed;
        // reduce speed for collection
        if (this.type == "collection")
            packetSpeed /= 4;

        this.speed.x = (delta.x / distance) * packetSpeed * game.speed * this.speedMultiplier;
        this.speed.y = (delta.y / distance) * packetSpeed * game.speed * this.speedMultiplier;

        if (Math.abs(this.speed.x) > Math.abs(delta.x))
            this.speed.x = delta.x;
        if (Math.abs(this.speed.y) > Math.abs(delta.y))
            this.speed.y = delta.y;
    };
    this.draw = function () {
        var position = Helper.real2screen(this.position);
        if (engine.isVisible(new Vector(position.x - 8, position.y - 8), new Vector(16 * game.zoom, 16 * game.zoom))) {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x - 8 * game.zoom, position.y - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
        }
    }
}

/**
 * Shells (fired by Mortars)
 */
function Shell(pPosition, pImage, pTargetPosition) {
    this.position = pPosition;
    this.imageID = pImage;
    this.speed = new Vector(0, 0);
    this.targetPosition = pTargetPosition;
    this.remove = false;
    this.rotation = 0;
    this.trailTimer = 0;
    this.init = function () {
        var delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
        var distance = Helper.distance(this.targetPosition, this.position);

        this.speed.x = (delta.x / distance) * game.shellSpeed * game.speed;
        this.speed.y = (delta.y / distance) * game.shellSpeed * game.speed;
    };
    this.getCenter = function () {
        return new Vector(this.position.x - 8, this.position.y - 8);
    };
    this.move = function () {
        this.trailTimer++;
        if (this.trailTimer == 10) {
            this.trailTimer = 0;
            game.smokes.push(new Smoke(this.getCenter()));
        }

        this.rotation += 20;
        if (this.rotation > 359)
            this.rotation -= 359;

        this.position.x += this.speed.x;
        this.position.y += this.speed.y;

        if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
            // if the target is reached explode and remove
            this.remove = true;

            game.explosions.push(new Explosion(this.targetPosition));
            engine.playSound("explosion", Helper.real2tiled(this.targetPosition));

            for (var i = Math.floor(this.targetPosition.x / game.tileSize) - 4; i < Math.floor(this.targetPosition.x / game.tileSize) + 5; i++) {
                for (var j = Math.floor(this.targetPosition.y / game.tileSize) - 4; j < Math.floor(this.targetPosition.y / game.tileSize) + 5; j++) {
                    if (game.withinWorld(i, j)) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - this.targetPosition.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - this.targetPosition.y, 2);
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
    };
    this.draw = function () {
        var position = Helper.real2screen(this.position);

        if (engine.isVisible(position, new Vector(16 * game.zoom, 16 * game.zoom))) {
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.translate(position.x + 8 * game.zoom, position.y + 8 * game.zoom);
            engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.rotation));
            engine.canvas["buffer"].context.drawImage(engine.images["shell"], -8 * game.zoom, -8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
            engine.canvas["buffer"].context.restore();
        }
    };
}

/**
 * Spore (fired by Sporetower)
 */
function Spore(pPosition, pTargetPosition) {
    this.position = pPosition;
    this.imageID = "spore";
    this.speed = new Vector(0, 0);
    this.targetPosition = pTargetPosition;
    this.remove = false;
    this.rotation = 0;
    this.health = 100;
    this.trailTimer = 0;
    this.init = function () {
        var delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
        var distance = Helper.distance(this.targetPosition, this.position);

        this.speed.x = (delta.x / distance) * game.sporeSpeed * game.speed;
        this.speed.y = (delta.y / distance) * game.sporeSpeed * game.speed;
    };
    this.getCenter = function () {
        return new Vector(this.position.x - 16, this.position.y - 16);
    };
    this.move = function () {
        this.trailTimer++;
        if (this.trailTimer == 10) {
            this.trailTimer = 0;
            game.smokes.push(new Smoke(this.getCenter()));
        }
        this.rotation += 10;
        if (this.rotation > 359)
            this.rotation -= 359;

        this.position.x += this.speed.x;
        this.position.y += this.speed.y;

        if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
            // if the target is reached explode and remove
            this.remove = true;
            engine.playSound("explosion", Helper.real2tiled(this.targetPosition));

            for (var i = Math.floor(this.targetPosition.x / game.tileSize) - 2; i < Math.floor(this.targetPosition.x / game.tileSize) + 2; i++) {
                for (var j = Math.floor(this.targetPosition.y / game.tileSize) - 2; j < Math.floor(this.targetPosition.y / game.tileSize) + 2; j++) {
                    if (game.withinWorld(i, j)) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.targetPosition.x + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.targetPosition.y + game.tileSize), 2);
                        if (distance < Math.pow(game.tileSize, 2)) {
                            game.world.tiles[i][j][0].creep += .05;
                        }
                    }
                }
            }
        }
    };
    this.draw = function () {
        var position = Helper.real2screen(this.position);

        if (engine.isVisible(position, new Vector(32 * game.zoom, 32 * game.zoom))) {
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.translate(position.x, position.y);
            engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.rotation));
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], -16 * game.zoom, -16 * game.zoom, 32 * game.zoom, 32 * game.zoom);
            engine.canvas["buffer"].context.restore();
        }
    };
}

/**
 * Ships (Bomber)
 */
function Ship(pPosition, pImage, pType, pHome) {
    this.position = pPosition;
    this.imageID = pImage;
    this.speed = new Vector(0, 0);
    this.targetPosition = new Vector(0, 0);
    this.remove = false;
    this.angle = 0;
    this.maxEnergy = 15;
    this.energy = 0;
    this.type = pType;
    this.home = pHome;
    this.status = 0; // 0 idle, 1 attacking, 2 returning
    this.trailTimer = 0;
    this.weaponTimer = 0;
    this.getCenter = function () {
        return new Vector(this.position.x + 24, this.position.y + 24);
    };
    this.updateHoverState = function () {
        var position = Helper.real2screen(this.position);
        this.hovered = (engine.mouse.x > position.x &&
            engine.mouse.x < position.x + 47 &&
            engine.mouse.y > position.y &&
            engine.mouse.y < position.y + 47);

        return this.hovered;
    };
    this.turnToTarget = function () {
        var delta = new Vector(this.targetPosition.x - this.position.x, this.targetPosition.y - this.position.y);
        var angleToTarget = Helper.rad2deg(Math.atan2(delta.y, delta.x));

        var turnRate = 1.5;
        var absoluteDelta = Math.abs(angleToTarget - this.angle);

        if (absoluteDelta < turnRate)
            turnRate = absoluteDelta;

        if (absoluteDelta <= 180)
            if (angleToTarget < this.angle)
                this.angle -= turnRate;
            else
                this.angle += turnRate;
        else if (angleToTarget < this.angle)
            this.angle += turnRate;
        else
            this.angle -= turnRate;

        if (this.angle > 180)
            this.angle -= 360;
        if (this.angle < -180)
            this.angle += 360;
    };
    this.calculateVector = function () {
        var x = Math.cos(Helper.deg2rad(this.angle));
        var y = Math.sin(Helper.deg2rad(this.angle));

        this.speed.x = x * game.shipSpeed * game.speed;
        this.speed.y = y * game.shipSpeed * game.speed;
    };
    this.move = function () {

        if (this.status != 0) {
            this.trailTimer++;
            if (this.trailTimer == 10) {
                this.trailTimer = 0;
                game.smokes.push(new Smoke(this.getCenter()));
            }

            this.weaponTimer++;

            this.turnToTarget();
            this.calculateVector();

            this.position.x += this.speed.x;
            this.position.y += this.speed.y;

            if (this.position.x > this.targetPosition.x - 2 && this.position.x < this.targetPosition.x + 2 && this.position.y > this.targetPosition.y - 2 && this.position.y < this.targetPosition.y + 2) {
                if (this.status == 1) { // attacking
                    if (this.weaponTimer >= 10) {
                        this.weaponTimer = 0;
                        game.explosions.push(new Explosion(this.targetPosition));
                        this.energy -= 1;

                        for (var i = Math.floor(this.targetPosition.x / game.tileSize) - 3; i < Math.floor(this.targetPosition.x / game.tileSize) + 5; i++) {
                            for (var j = Math.floor(this.targetPosition.y / game.tileSize) - 3; j < Math.floor(this.targetPosition.y / game.tileSize) + 5; j++)
                                if (game.withinWorld(i, j)) {
                                    {
                                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.targetPosition.x + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.targetPosition.y + game.tileSize), 2);
                                        if (distance < Math.pow(game.tileSize * 3, 2)) {
                                            game.world.tiles[i][j][0].creep -= 5;
                                            if (game.world.tiles[i][j][0].creep < 0) {
                                                game.world.tiles[i][j][0].creep = 0;
                                            }
                                        }
                                    }
                                }
                        }

                        if (this.energy == 0) { // return to base
                            this.status = 2;
                            this.targetPosition.x = this.home.position.x * game.tileSize;
                            this.targetPosition.y = this.home.position.y * game.tileSize;
                        }
                    }
                }
                else if (this.status == 2) { // if returning set to idle
                    this.status = 0;
                    this.position.x = this.home.position.x * game.tileSize;
                    this.position.y = this.home.position.y * game.tileSize;
                    this.targetPosition.x = 0;
                    this.targetPosition.y = 0;
                    this.energy = 5;
                }
            }
        }
    };
    this.draw = function () {
        var position = Helper.real2screen(this.position);

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
                var cursorPosition = Helper.real2screen(this.targetPosition);
                engine.canvas["buffer"].context.save();
                engine.canvas["buffer"].context.globalAlpha = .5;
                engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], cursorPosition.x - game.tileSize * game.zoom, cursorPosition.y - game.tileSize * game.zoom, 48 * game.zoom, 48 * game.zoom);
                engine.canvas["buffer"].context.restore();
            }
        }

        if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
            // draw ship
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
            engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.angle + 90));
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
            engine.canvas["buffer"].context.restore();

            // draw energy bar
            engine.canvas["buffer"].context.fillStyle = '#f00';
            engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + 1, (44 * game.zoom / this.maxEnergy) * this.energy, 3);
        }
    };
}

function Emitter(pPosition, pStrength) {
    this.position = pPosition;
    this.strength = pStrength;
    this.imageID = "emitter";
    this.draw = function () {
        var position = Helper.tiled2screen(this.position);
        if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
        }
    };
    this.spawn = function () {
        game.world.tiles[this.position.x + 1][this.position.y + 1][0].creep += this.strength;
    };
}

/**
 * Sporetower
 */
function Sporetower(pPosition) {
    this.position = pPosition;
    this.imageID = "sporetower";
    this.health = 100;
    this.sporeTimer = 0;
    this.reset = function () {
        this.sporeTimer = Helper.randomInt(7500, 12500);
    };
    this.getCenter = function () {
        return new Vector(
            this.position.x * game.tileSize + 24,
            this.position.y * game.tileSize + 24);
    };
    this.draw = function () {
        var position = Helper.tiled2screen(this.position);
        if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
        }
    };
    this.update = function () {
        this.sporeTimer -= 1;
        if (this.sporeTimer <= 0) {
            this.reset();
            this.spawn();
        }
    };
    this.spawn = function () {
        do {
            var target = game.buildings[Helper.randomInt(0, game.buildings.length)];
        } while (!target.built);
        var spore = new Spore(this.getCenter(), target.getCenter());
        spore.init();
        game.spores.push(spore);
    };
}

function Smoke(pPosition) {
    this.position = new Vector(pPosition.x, pPosition.y);
    this.frame = 0;
    this.imageID = "smoke";
    this.draw = function () {
        var position = Helper.real2screen(this.position);
        if (engine.isVisible(position, new Vector(48 * game.zoom, 48 * game.zoom))) {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], (this.frame % 8) * 128, Math.floor(this.frame / 8) * 128, 128, 128, position.x - 24 * game.zoom, position.y - 24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
        }
    };
}

function Explosion(pPosition) {
    this.position = new Vector(pPosition.x, pPosition.y);
    this.frame = 0;
    this.imageID = "explosion";
    this.draw = function () {
        var position = Helper.real2screen(this.position);
        if (engine.isVisible(position, new Vector(64 * game.zoom, 64 * game.zoom))) {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], (this.frame % 8) * 64, Math.floor(this.frame / 8) * 64, 64, 64, position.x - 32 * game.zoom, position.y - 32 * game.zoom, 64 * game.zoom, 64 * game.zoom);
        }
    };
}

function Tile() {
    this.index = -1;
    this.full = false;
    this.creep = 0;
    this.newcreep = 0;
    this.collector = null;
}

function Vector(pX, pY) {
    this.x = pX;
    this.y = pY;
}

/**
 * Route object used in A*
 */
function Route() {
    this.distanceTravelled = 0;
    this.distanceRemaining = 0;
    this.nodes = [];
}

/**
 * Object to store canvas information
 */
function Canvas(pElement) {
    this.element = pElement;
    this.context = pElement[0].getContext('2d');
    this.top = pElement.offset().top;
    this.left = pElement.offset().left;
    this.bottom = this.top + this.element[0].height;
    this.right = this.left + this.element[0].width;
    this.context.webkitImageSmoothingEnabled = false;
    this.clear = function () {
        this.context.clearRect(0, 0, this.element[0].width, this.element[0].height);
    }
}

// Functions

// Entry Point
$(function () {
    main();
});

function main() {
    engine.init();
    engine.loadImages(function () {
        game.init();
        game.drawTerrain();
        game.copyTerrain();

        //engine.sounds["music"].loop = true;
        //engine.sounds["music"].play();

        game.stop();
        game.run();
    });
}

function update() {
    engine.update();
    game.update();
}

function onMouseMove(evt) {
    engine.updateMouse(evt);
}

function onMouseMoveGUI(evt) {
    engine.updateMouseGUI(evt);

    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].checkHovered();
    }
}

function onKeyDown(evt) {
    // select instruction with keypress
    var key = game.keyMap["k" + evt.keyCode];
    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].active = false;
        if (game.symbols[i].key == key) {
            game.activeSymbol = i;
            game.symbols[i].active = true;
        }
    }

    if (game.activeSymbol != -1) {
        engine.canvas["main"].element.css('cursor', 'none');
    }

    // delete building
    if (evt.keyCode == 46) {
        for (var i = 0; i < game.buildings.length; i++) {
            if (game.buildings[i].selected) {
                if (game.buildings[i].imageID != "base")
                    game.removeBuilding(game.buildings[i]);
            }
        }
    }

    // pause/resume
    if (evt.keyCode == 80) {
        if (game.paused)
            game.resume();
        else
            game.pause();
    }

    // ESC - deselect all
    if (evt.keyCode == 27) {
        game.activeSymbol = -1;
        for (var i = 0; i < game.symbols.length; i++) {
            game.symbols[i].active = false;
        }
        for (var i = 0; i < game.buildings.length; i++) {
            game.buildings[i].selected = false;
        }
    }

    if (evt.keyCode == 37)
        game.scrolling.left = true;
    if (evt.keyCode == 38)
        game.scrolling.up = true;
    if (evt.keyCode == 39)
        game.scrolling.right = true;
    if (evt.keyCode == 40)
        game.scrolling.down = true;

    var position = game.getHoveredTilePosition();

    // lower terrain ("N")
    if (evt.keyCode == 78) {
        var height = game.getHighestTerrain(position);
        if (height > -1) {
            game.world.tiles[position.x][position.y][height].full = false;
            var tilesToRedraw = [];
            // reset index around tile
            for (var i = -1; i <= 1; i++) {
                for (var j = -1; j <= 1; j++) {
                    tilesToRedraw.push({x: position.x + i, y: position.y + j, z: height});
                }
            }
            game.redrawTile(tilesToRedraw);
            game.copyTerrain();
        }
    }

    // raise terrain ("M")
    if (evt.keyCode == 77) {
        var height = game.getHighestTerrain(position);
        if (height < 9) {
            game.world.tiles[position.x][position.y][height + 1].full = true;
            var tilesToRedraw = [];
            // reset index around tile
            for (var i = -1; i <= 1; i++) {
                for (var j = -1; j <= 1; j++) {
                    tilesToRedraw.push({x: position.x + i, y: position.y + j, z: height + 1});
                }
            }
            game.redrawTile(tilesToRedraw);
            game.copyTerrain();
        }
    }

    // clear terrain ("B")
    if (evt.keyCode == 66) {
        var tilesToRedraw = [];
        for (var k = 0; k < 10; k++) {
            game.world.tiles[position.x][position.y][k].full = false;
            // reset index around tile
            for (var i = -1; i <= 1; i++) {
                for (var j = -1; j <= 1; j++) {
                    tilesToRedraw.push({x: position.x + i, y: position.y + j, z: k});
                }
            }
        }
        game.redrawTile(tilesToRedraw);
        game.copyTerrain();
    }

    // select height for terraforming
    if (game.mode == game.modes.TERRAFORM) {

        // remove terraform number
        if (evt.keyCode == 46) {
            game.world.terraform[position.x][position.y].target = -1;
            game.world.terraform[position.x][position.y].progress = 0;
        }

        // set terraform value
        if (evt.keyCode >= 48 && evt.keyCode <= 57) {
            game.terraformingHeight = parseInt(evt.keyCode) - 49;
            if (game.terraformingHeight == -1)
                game.terraformingHeight = 9;
        }

    }

}

function onKeyUp(evt) {
    if (evt.keyCode == 37)
        game.scrolling.left = false;
    if (evt.keyCode == 38)
        game.scrolling.up = false;
    if (evt.keyCode == 39)
        game.scrolling.right = false;
    if (evt.keyCode == 40)
        game.scrolling.down = false;
}

function onEnter(evt) {
    engine.mouse.active = true;
}

function onLeave(evt) {
    engine.mouse.active = false;
}

function onLeaveGUI(evt) {
    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].hovered = false;
    }
}

function onClickGUI(evt) {
    for (var i = 0; i < game.buildings.length; i++)
        game.buildings[i].selected = false;

    for (var i = 0; i < game.ships.length; i++)
        game.ships[i].selected = false;

    engine.playSound("click");
    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].setActive();
    }

    if (game.activeSymbol != -1) {
        engine.canvas["main"].element.css('cursor', 'none');
    }
}

function onDoubleClick(evt) {
    var selectShips = false;
    // select a ship if hovered
    for (var i = 0; i < game.ships.length; i++) {
        if (game.ships[i].hovered) {
            selectShips = true;
            break;
        }
    }
    if (selectShips)
        for (var i = 0; i < game.ships.length; i++) {
            game.ships[i].selected = true;
        }
}

function onMouseDown(evt) {
    if (evt.which == 1) { // left mouse button
        var position = game.getHoveredTilePosition();

        if (!engine.mouse.dragStart) {
            engine.mouse.dragStart = new Vector(position.x, position.y);
        }
    }
}

function onMouseUp(evt) {
    if (evt.which == 1) {

        var position = game.getHoveredTilePosition();

        // set terraforming target
        if (game.mode == game.modes.TERRAFORM) {
            game.world.terraform[position.x][position.y].target = game.terraformingHeight;
            game.world.terraform[position.x][position.y].progress = 0;
        }

        // control ships
        for (var i = 0; i < game.ships.length; i++) {
            if (game.ships[i].selected) {
                if (position.x - 1 == game.ships[i].home.x &&
                    position.y - 1 == game.ships[i].home.y) {
                    game.ships[i].tx = (position.x - 1) * game.tileSize;
                    game.ships[i].ty = (position.y - 1) * game.tileSize;
                    game.ships[i].status = 2;
                }
                else {
                    // take energy from base
                    game.ships[i].energy = game.ships[i].home.energy;
                    game.ships[i].home.energy = 0;
                    game.ships[i].tx = position.x * game.tileSize;
                    game.ships[i].ty = position.y * game.tileSize;
                    game.ships[i].status = 1;
                }

            }
        }

        // select a ship if hovered
        for (var i = 0; i < game.ships.length; i++) {
            game.ships[i].selected = game.ships[i].hovered;
            if (game.ships[i].selected)
                game.mode = game.modes.SHIP_SELECTED;
        }

        // reposition building
        for (var i = 0; i < game.buildings.length; i++) {
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
        if (game.mode == game.modes.DEFAULT) {
            var buildingSelected = null;
            for (var i = 0; i < game.buildings.length; i++) {
                game.buildings[i].selected = game.buildings[i].hovered;
                if (game.buildings[i].selected) {
                    $('#selection').show().html("Type: " + game.buildings[i].imageID + "<br/>" +
                        "Health/HR/MaxHealth: " + game.buildings[i].health + "/" + game.buildings[i].healthRequests + "/" + game.buildings[i].maxHealth);
                    buildingSelected = game.buildings[i];
                }
            }
            if (buildingSelected) {
                if (buildingSelected.active) {
                    $('#deactivate').show();
                    $('#activate').hide();
                } else {
                    $('#deactivate').hide();
                    $('#activate').show();
                }
            } else {
                $('#selection').hide();
                $('#deactivate').hide();
                $('#activate').hide();
            }
        }

        engine.mouse.dragStart = null;

        // when there is an active symbol place building
        if (game.activeSymbol != -1) {
            var type = game.symbols[game.activeSymbol].imageID.substring(0, 1).toUpperCase() + game.symbols[game.activeSymbol].imageID.substring(1);
            var soundSuccess = false;
            for (var i = 0; i < game.ghosts.length; i++) {
                if (game.canBePlaced(game.ghosts[i].position, game.symbols[game.activeSymbol].size, null)) {
                    soundSuccess = true;
                    game.addBuilding(game.ghosts[i].position, game.symbols[game.activeSymbol].imageID);
                }
            }
            if (soundSuccess)
                engine.playSound("click");
            else
                engine.playSound("failure");
        }
    }
    else if (evt.which == 3) {
        game.mode = game.modes.DEFAULT;

        // unselect all currently selected buildings
        for (var i = 0; i < game.buildings.length; i++) {
            game.buildings[i].selected = false;
            $('#deactivate').hide();
            $('#activate').hide();
        }

        // unselect all currently selected ships
        for (var i = 0; i < game.ships.length; i++) {
            game.ships[i].selected = false;
        }

        $('#selection').html("");
        $("#terraform").val("Terraform Off");
        game.clearSymbols();
    }
}

function onMouseScroll(evt) {
    if (evt.originalEvent.detail > 0 || evt.originalEvent.wheelDelta < 0) {
        //scroll down
        game.zoomOut();
    } else {
        //scroll up
        game.zoomIn();
    }
    //prevent page fom scrolling
    return false;
}

/**
 * Some helper functions below
 */

var Helper = {};

Helper.rad2deg = function (angle) {
    return angle * 57.29577951308232;
};

Helper.deg2rad = function (angle) {
    return angle * .017453292519943295;
};

Helper.distance = function (a, b) {
    return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
};

// converts tile coordinates to canvas coordinates
Helper.tiled2screen = function (pVector) {
    return new Vector(
        engine.halfWidth + (pVector.x - game.scroll.x) * game.tileSize * game.zoom,
        engine.halfHeight + (pVector.y - game.scroll.y) * game.tileSize * game.zoom);
};

// converts full coordinates to canvas coordinates
Helper.real2screen = function (pVector) {
    return new Vector(
        engine.halfWidth + (pVector.x - game.scroll.x * game.tileSize) * game.zoom,
        engine.halfHeight + (pVector.y - game.scroll.y * game.tileSize) * game.zoom);
};

// converts full coordinates to tile coordinates
Helper.real2tiled = function (pVector) {
    return new Vector(
        Math.floor(pVector.x / game.tileSize),
        Math.floor(pVector.y / game.tileSize));
};

Helper.clone = function (pObject) {
    var newObject = [];
    for (var attr in pObject) {
        newObject[attr] = pObject[attr];
    }
    return newObject;
};

Helper.randomInt = function (from, to) {
    return Math.floor(Math.random() * (to - from + 1) + from);
};

Helper.clamp = function (number, min, max) {
    return number < min ? min : (number > max ? max : number);
};

// Thanks to http://www.hardcode.nl/subcategory_1/article_317-array-shuffle-function
Array.prototype.shuffle = function () {
    var len = this.length;
    var i = len;
    while (i--) {
        var p = parseInt(Math.random() * len);
        var t = this[i];
        this[i] = this[p];
        this[p] = t;
    }
};

/**
 * Main drawing function
 * For some reason this may not be a member function of "game" in order to be called by requestAnimationFrame
 */
function draw() {
    game.drawGUI();

    // clear canvas
    engine.canvas["buffer"].clear();
    engine.canvas["main"].clear();

    // draw terraform numbers
    var timesX = Math.floor(engine.halfWidth / game.tileSize / game.zoom);
    var timesY = Math.floor(engine.halfHeight / game.tileSize / game.zoom);

    for (var i = -timesX; i <= timesX; i++) {
        for (var j = -timesY; j <= timesY; j++) {

            var iS = i + game.scroll.x;
            var jS = j + game.scroll.y;

            if (game.withinWorld(iS, jS)) {
                if (game.world.terraform[iS][jS].target > -1) {
                    engine.canvas["buffer"].context.drawImage(engine.images["numbers"], game.world.terraform[iS][jS].target * 16, 0, game.tileSize, game.tileSize, engine.halfWidth + i * game.tileSize * game.zoom, engine.halfHeight + j * game.tileSize * game.zoom, game.tileSize * game.zoom, game.tileSize * game.zoom);
                }
            }
        }
    }

    // draw emitters
    for (var i = 0; i < game.emitters.length; i++) {
        game.emitters[i].draw();
    }

    // draw spore towers
    for (var i = 0; i < game.sporetowers.length; i++) {
        game.sporetowers[i].draw();
    }

    // draw node connections
    for (var i = 0; i < game.buildings.length; i++) {
        var centerI = game.buildings[i].getCenter();
        var drawCenterI = Helper.real2screen(centerI);
        for (var j = 0; j < game.buildings.length; j++) {
            if (i != j) {
                if (!game.buildings[i].moving && !game.buildings[j].moving) {
                    var centerJ = game.buildings[j].getCenter();
                    var drawCenterJ = Helper.real2screen(centerJ);

                    var allowedDistance = 10 * game.tileSize;
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
                        if (!game.buildings[i].built || !game.buildings[j].built)
                            engine.canvas["buffer"].context.strokeStyle = '#777';
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
    for (var i = 0; i < game.buildings.length; i++) {
        game.buildings[i].drawMovementIndicators();
    }

    // draw buildings
    for (var i = 0; i < game.buildings.length; i++) {
        game.buildings[i].draw();
    }

    // draw shells
    for (var i = 0; i < game.shells.length; i++) {
        game.shells[i].draw();
    }

    // draw smokes
    for (var i = 0; i < game.smokes.length; i++) {
        game.smokes[i].draw();
    }

    // draw explosions
    for (var i = 0; i < game.explosions.length; i++) {
        game.explosions[i].draw();
    }

    // draw spores
    for (var i = 0; i < game.spores.length; i++) {
        game.spores[i].draw();
    }

    if (engine.mouse.active) {

        // if a building is built and selected draw a green box and a line at mouse position as the reposition target
        for (var i = 0; i < game.buildings.length; i++) {
            game.buildings[i].drawRepositionInfo();
        }

        // draw attack symbol
        game.drawAttackSymbol();

        if (game.activeSymbol != -1) {
            game.drawPositionInfo();
        }

        if (game.mode == game.modes.TERRAFORM) {
            var positionScrolled = game.getHoveredTilePosition();
            var drawPosition = Helper.tiled2screen(positionScrolled);
            engine.canvas["buffer"].context.drawImage(engine.images["numbers"], game.terraformingHeight * game.tileSize, 0, game.tileSize, game.tileSize, drawPosition.x, drawPosition.y, game.tileSize * game.zoom, game.tileSize * game.zoom);

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
    for (var i = 0; i < game.packets.length; i++) {
        game.packets[i].draw();
    }

    // draw ships
    for (var i = 0; i < game.ships.length; i++) {
        game.ships[i].draw(engine.canvas["buffer"].context);
    }

    // draw building hover/selection box
    for (var i = 0; i < game.buildings.length; i++) {
        game.buildings[i].drawBox();
    }

    engine.canvas["main"].context.drawImage(engine.canvas["buffer"].element[0], 0, 0); // copy from buffer to context
    // double buffering taken from: http://www.youtube.com/watch?v=FEkBldQnNUc

    requestAnimationFrame(draw);
}