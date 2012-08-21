/*!
 * Open Creeper v1.0
 * http://alexanderzeillinger.github.com/OpenCreeper/
 *
 * Copyright 2012, Alexander Zeillinger
 * Dual licensed under the MIT or GPL licenses.
 */

var engine;
engine = {
    FPS: 60,
    delta: 1000 / 60,
    fps_delta: null,
    fps_lastTime: null,
    fps_frames: null,
    fps_totalTime: null,
    fps_updateTime: null,
    fps_updateFrames: null,
    fps_drawTime: null,
    canvas: null, // at the top, contains everything but the terrain
    canvasBuffer: null,
    canvasTiles: null, // at the bottom, contains the terrain and is only drawn once for performance reasons, no buffer needed
    canvasGUI: null,
    ctx: null,
    ctxBuffer: null,
    ctxTiles: null,
    ctxGUI: null,
    canvasMinX: 0,
    canvasMaxX: 0,
    canvasMinY: 0,
    canvasMaxY: 0,
    guiCanvasMinX: 0,
    guiCanvasMaxX: 0,
    guiCanvasMinY: 0,
    guiCanvasMaxY: 0,
    images: null,
    sounds: null,
    imageSrcs: null,
    /**
     * @author Alexander Zeillinger
     *
     * Initializes the canvases and mouse, loads sounds and images.
     */
    init: function () {
        this.canvas = document.getElementById('mainCanvas');
        this.canvasBuffer = document.createElement('canvas');
        this.canvasTiles = document.getElementById('tilesCanvas');
        this.canvasGUI = document.getElementById('guiCanvas');

        this.canvasBuffer.width = this.canvas.width;
        this.canvasBuffer.height = this.canvas.height;

        this.ctx = this.canvas.getContext('2d');
        this.ctxBuffer = this.canvasBuffer.getContext('2d');
        this.ctxTiles = this.canvasTiles.getContext('2d');
        this.ctxGUI = this.canvasGUI.getContext('2d');

        this.images = new Array();
        this.sounds = new Array();

        // load sounds
        this.addSound("shot", "wav");
        this.addSound("click", "wav");
        this.addSound("music", "ogg");
        this.addSound("explosion", "wav");

        // load images
        this.imageSrcs = ["terrain", "cannon", "cannongun", "base", "collector", "reactor", "storage", "speed", "packet_ammo", "packet_health", "relay", "emitter", "creep",
            "mortar", "shell", "beam", "spore", "bomber", "bombership", "smoke", "explosion", "targetcursor", "sporetower", "forcefield", "shield"];

        this.initMouse();
        this.initMouseGUI();
    },
    /**
     * @author Alexander Zeillinger
     *
     * Loads all images.
     *
     * A callback is used to make sure the game starts after all images have been loaded.
     * Otherwise some images might not be rendered at all.
     */
    loadImages: function (callback) {
        var loadedImages = 0;
        var numImages = this.imageSrcs.length - 1;

        for(var i = 0; i < this.imageSrcs.length; i++) {
            this.images[this.imageSrcs[i]] = new Image();
            this.images[this.imageSrcs[i]].onload = function() {
                if(++loadedImages >= numImages) {
                    callback();
                }
            };
            this.images[this.imageSrcs[i]].src = "images/" + this.imageSrcs[i] + ".png";
        }
    },
    addSound: function (name, type) {
        this.sounds[name] = new Audio("sounds/" + name + "." + type);
    },
    mouse: {
        x: 0,
        y: 0,
        active: false
    },
    mouseGUI: {
        x: 0,
        y: 0
    },
    initMouse: function () {
        this.canvasMinX = $("#mainCanvas").offset().left;
        this.canvasMaxX = this.canvasMinX + this.canvas.width;
        this.canvasMinY = $("#mainCanvas").offset().top;
        this.canvasMaxY = this.canvasMinY + this.canvas.height;
    },
    initMouseGUI: function () {
        this.guiCanvasMinX = $("#guiCanvas").offset().left;
        this.guiCanvasMaxX = this.guiCanvasMinX + this.canvasGUI.width;
        this.guiCanvasMinY = $("#guiCanvas").offset().top;
        this.guiCanvasMaxY = this.guiCanvasMinY + this.canvasGUI.height;
    },
    updateMouse: function (evt) {
        if (evt.pageX > this.canvasMinX && evt.pageX < this.canvasMaxX && evt.pageY > this.canvasMinY && evt.pageY < this.canvasMaxY) {
            this.mouse.x = evt.pageX - this.canvasMinX;
            this.mouse.y = evt.pageY - this.canvasMinY;
            $("#mouse").html("Mouse: " + this.mouse.x + "/" + this.mouse.y + " - " + (Math.floor((this.mouse.x - 512) / game.tileSize) + game.scroll.x) + "/" + (Math.floor((this.mouse.y  - 384) / game.tileSize) + game.scroll.y));
        }
    },
    updateMouseGUI: function (evt) {
        if (evt.pageX > this.guiCanvasMinX && evt.pageX < this.guiCanvasMaxX && evt.pageY > this.guiCanvasMinY && evt.pageY < this.guiCanvasMaxY) {
            this.mouseGUI.x = evt.pageX - this.guiCanvasMinX;
            this.mouseGUI.y = evt.pageY - this.guiCanvasMinY;
        }
    },
    reset: function () {
        // reset FPS variables
        this.fps_lastTime = new Date().getTime();
        this.fps_frames = 0;
        this.fps_totalTime = 0;
        this.fps_updateTime = 0;
        this.fps_updateFrames = 0;
        this.fps_drawTime = 0;
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
        this.fps_drawTime += this.fps_delta;

        // update FPS display
        if (this.fps_updateTime > 1000) {
            $("#fps").html("FPS: " + Math.floor(1000 * this.fps_frames / this.fps_totalTime) + " average, " + Math.floor(1000 * this.fps_updateFrames / this.fps_updateTime) + " currently, " + (game.speed * this.FPS) + " desired");
            this.fps_updateTime = 0;
            this.fps_updateFrames = 0;
        }
    },
    canDraw: function () {
        if (this.fps_drawTime > this.delta) {
            this.fps_drawTime -= this.delta;
            return true;
        }
        else {
            return false;
        }
    }
};

var game = {
    tileSize: 16,
    speed: 1,
    //zoom: 1,
    running: null,
    mode: null,
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
    sporeTimer: 0,
    smokeTimer: 0,
    explosionTimer: 0,
    shieldTimer: 0,
    symbols: null,
    activeSymbol: -1,
    packetSpeed: 1.5,
    shellSpeed: 1,
    sporeSpeed: 1,
    buildingSpeed: .5,
    base: null,
    shipSpeed: 1,
    emitters: null,
    sporetowers: null,
    packetQueue: null,
    init: function () {
        this.buildings = new Array();
        this.packets = new Array();
        this.shells = new Array();
        this.spores = new Array();
        this.ships = new Array();
        this.smokes = new Array();
        this.explosions = new Array();
        this.symbols = new Array();
        this.emitters = new Array();
        this.sporetowers = new Array();
        this.packetQueue = new Array();
        this.reset();
        this.setupUI();
    },
    reset: function () {
        $('#time').stopwatch().stopwatch('reset');
        $('#lose').hide();
        $('#win').hide();

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
        this.sporeTimer = 0;
        this.smokeTimer = 0;
        this.explosionTimer = 0;
        this.shieldTimer = 0;

        this.packetSpeed = 1.5;
        this.shellSpeed = 1;
        this.sporeSpeed = 1;
        this.buildingSpeed = .5;
        this.shipSpeed = 1;
        this.speed = 1;
        this.activeSymbol = -1;
        this.updateEnergyElement();
        this.updateSpeedElement();
        this.updateCollectionElement();
        this.clearSymbols();
        this.createWorld();
    },
    /**
     * @author Alexander Zeillinger
     *
     * Returns the position of the tile the mouse is hovering above.
     */
    getTilePosition: function () {
        return new Vector(Math.floor(engine.mouse.x / this.tileSize), Math.floor(engine.mouse.y / this.tileSize));
    },
    getTilePositionScrolled: function () {
        return new Vector(Math.floor((engine.mouse.x - 512) / this.tileSize) + this.scroll.x, Math.floor((engine.mouse.y  - 384) / this.tileSize) + this.scroll.y);
    },
    world: {
        tiles: null,
        size: {
            x: 64,
            y: 64
        }
    },
    alert: {
        x: 0,
        y: 0,
        message: null
    },
    scroll: {
        x: 32,
        y: 24
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
    createWorld: function () {
        this.world.tiles = new Array(this.world.size.x);
        for (var i = 0; i < this.world.size.x; i++) {
            this.world.tiles[i] = new Array(this.world.size.y);
        }

        generateTerrain();

        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                this.world.tiles[i][j] = new Tile();
                this.world.tiles[i][j].height = Math.ceil(map[i][j] * 10) - 1; // generated values are to high, this compensates it
                if (this.world.tiles[i][j].height > 9)
                    this.world.tiles[i][j].height = 9;
                if (this.world.tiles[i][j].height < 0)
                    this.world.tiles[i][j].height = 0;
            }
        }

        var building = new Building(45, 30, "base", "Base", 0);
        building.health = 40;
        building.maxHealth = 40;
        building.nodeRadius = 10;
        building.built = true;
        building.size = 9;
        this.buildings.push(building);
        game.base = building;

        this.calculateCollection();

        this.emitters.push(new Emitter(9, 9, 10));

        this.sporetowers.push(new Sporetower(4, 13));
    },
    addBuilding: function (x, y, type, name) {
        var building = new Building(x, y, type, name);
        building.health = 0;

        if (building.type == "Shield") {
            building.maxHealth = 75;
            building.size = 3;
            building.health = 0;
            building.canMove = true;
        }
        if (building.type == "Bomber") {
            building.maxHealth = 75;
            building.size = 3;
        }
        if (building.type == "Storage") {
            building.maxHealth = 8;
            building.size = 3;
        }
        if (building.type == "Reactor") {
            building.maxHealth = 50;
            building.size = 3;
        }
        if (building.type == "Collector") {
            building.maxHealth = 5;
            building.size = 2;
        }
        if (building.type == "Relay") {
            building.maxHealth = 10;
            building.size = 2;
        }
        if (building.type == "Cannon") {
            building.maxHealth = 25;
            building.maxAmmo = 40;
            building.ammo = 0;
            building.weaponRadius = 6;
            building.canMove = true;
            building.canShoot = true;
            building.size = 3;
        }
        if (building.type == "Mortar") {
            building.maxHealth = 40;
            building.maxAmmo = 20;
            building.ammo = 0;
            building.weaponRadius = 12;
            building.canMove = true;
            building.canShoot = true;
            building.size = 3;
        }
        if (building.type == "Beam") {
            building.maxHealth = 20;
            building.maxAmmo = 10;
            building.ammo = 0;
            building.weaponRadius = 12;
            building.canMove = true;
            building.canShoot = true;
            building.size = 3;
        }

        if (building.type == "Relay")
            building.nodeRadius = 20;
        else
            building.nodeRadius = 10;

        this.buildings.push(building);
    },
    removeBuilding: function (building) {
        this.explosions.push(new Explosion(building.x * game.tileSize, building.y * game.tileSize));
        if (building.type == "Base") {
            stop();
        }
        if (building.type == "Collector") {
            this.updateCollection(building, "remove");
        }
        if (building.type == "Storage") {
            this.maxEnergy -= 10;
            this.updateEnergyElement();
        }
        if (building.type == "Speed") {
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
    updateEnergyElement: function () {
        $('#energy').html("Energy: " + this.currentEnergy + "/" + this.maxEnergy);
    },
    updateSpeedElement: function () {
        $("#speed").html("Speed: " + this.speed + "x");
    },
    updateCollectionElement: function () {
        $('#collection').html("Collection: " + this.collection);
    },
    clearSymbols: function () {
        this.activeSymbol = -1;
        for (var i = 0; i < this.symbols.length; i++)
            this.symbols[i].active = false;
    },
    setupUI: function () {
        this.symbols.push(new UISymbol(0 * 81, 0, "cannon", "Q", 3, 25));
        this.symbols.push(new UISymbol(1 * 81, 0, "collector", "W", 2, 5));
        this.symbols.push(new UISymbol(2 * 81, 0, "reactor", "E", 3, 50));
        this.symbols.push(new UISymbol(3 * 81, 0, "storage", "R", 3, 8));
        this.symbols.push(new UISymbol(4 * 81, 0, "shield", "T", 3, 50));

        this.symbols.push(new UISymbol(0 * 81, 56, "relay", "A", 2, 10));
        this.symbols.push(new UISymbol(1 * 81, 56, "mortar", "S", 3, 40));
        this.symbols.push(new UISymbol(2 * 81, 56, "beam", "D", 3, 20));
        this.symbols.push(new UISymbol(3 * 81, 56, "bomber", "F", 3, 75));
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the terrain using a simple auto-tiling mechanism
     */
    drawTerrain: function () {
        engine.ctxTiles.clearRect(0, 0, engine.canvas.width, engine.canvas.height);
        engine.ctxTiles.strokeStyle = "rgba(0,0,0,0.125)";
        engine.ctxTiles.lineWidth = 1;

        for (var i = -32; i < 32; i++) {
            for (var j = -24; j < 24; j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                    if (this.world.tiles[iS][jS].enabled) {

                        var height = this.world.tiles[iS][jS].height;

                        var up = 0, down = 0, left = 0, right = 0;
                        if (jS - 1 < 0)
                            up = 1;
                        else if (this.world.tiles[iS][jS - 1].height >= height)
                            up = 1;
                        if (jS + 1 > this.world.size.y - 1)
                            down = 1;
                        else if (this.world.tiles[iS][jS + 1].height >= height)
                            down = 1;
                        if (iS - 1 < 0)
                            left = 1;
                        else if (this.world.tiles[iS - 1][jS].height >= height)
                            left = 1;
                        if (iS + 1 > this.world.size.x - 1)
                            right = 1;
                        else if (this.world.tiles[iS + 1][jS].height >= height)
                            right = 1;

                        if (height > 0)
                            engine.ctxTiles.drawImage(engine.images["terrain"], 15 * this.tileSize, (this.world.tiles[iS][jS].height - 1) * this.tileSize, this.tileSize, this.tileSize, 512 + i * this.tileSize, 384 + j * this.tileSize, this.tileSize, this.tileSize);
                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        // save index for later use
                        this.world.tiles[iS][jS].index = index;
                        engine.ctxTiles.drawImage(engine.images["terrain"], index * this.tileSize, this.world.tiles[iS][jS].height * this.tileSize, this.tileSize, this.tileSize, 512 + i * this.tileSize, 384 + j * this.tileSize, this.tileSize, this.tileSize);

                        // grid (debug)
                        //engine.ctxTiles.strokeRect(i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
                    }
                }
            }
        }
    },
    shoot: function () {
        for (var t = 0; t < this.buildings.length; t++) {
            if (this.buildings[t].canShoot && this.buildings[t].active) {
                this.buildings[t].shooting = false;
                this.buildings[t].shootTimer++;
                var center = this.buildings[t].getCenter();
                if (this.buildings[t].type == "Cannon" && this.buildings[t].ammo > 0 && this.buildings[t].shootTimer > 10) {
                    this.buildings[t].shootTimer = 0;

                    // get building x and building y
                    var x = this.buildings[t].x;
                    var y = this.buildings[t].y;

                    // find closest random target
                    for (var r = 0; r < this.buildings[t].weaponRadius + 1; r++) {
                        var targets = new Array();
                        var radius = r * this.tileSize;
                        for (var i = x - this.buildings[t].weaponRadius; i < x + this.buildings[t].weaponRadius + 2; i++) {
                            for (var j = y - this.buildings[t].weaponRadius; j < y + this.buildings[t].weaponRadius + 2; j++) {
                                // cannons can only shoot at tiles not higher than themselves
                                if (i > -1 && i < this.world.size.x && j > -1 && j < this.world.size.y && this.world.tiles[i][j].height <= this.world.tiles[x][y].height) {
                                    var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                                    if (distance <= Math.pow(radius, 2) && this.world.tiles[i][j].creep > 0) {
                                        targets.push(new Vector(i, j));
                                    }
                                }
                            }
                        }
                        if (targets.length > 0) {
                            targets.shuffle();

                            this.world.tiles[targets[0].x][targets[0].y].creep -= 10;
                            if (this.world.tiles[targets[0].x][targets[0].y].creep < 0)
                                this.world.tiles[targets[0].x][targets[0].y].creep = 0;

                            var dx = targets[0].x * this.tileSize + this.tileSize / 2 - center.x;
                            var dy = targets[0].y * this.tileSize + this.tileSize / 2 - center.y;
                            this.buildings[t].targetAngle = Math.atan2(dy, dx) + Math.PI / 2; // * 180 / Math.PI;
                            this.buildings[t].targetX = targets[0].x * this.tileSize + this.tileSize / 2;
                            this.buildings[t].targetY = targets[0].y * this.tileSize + this.tileSize / 2;
                            this.buildings[t].ammo -= 1;
                            this.buildings[t].shooting = true;
                            this.smokes.push(new Smoke(this.buildings[t].targetX, this.buildings[t].targetY));
                            break;
                        }
                    }
                }
                if (this.buildings[t].type == "Mortar" && this.buildings[t].ammo > 0 && this.buildings[t].shootTimer > 200) {
                    this.buildings[t].shootTimer = 0;

                    // get building x and building y
                    var x = this.buildings[t].x;
                    var y = this.buildings[t].y;

                    // find most creep in range
                    var target = null;
                    var highestCreep = 0;
                    for (var i = x - this.buildings[t].weaponRadius; i < x + this.buildings[t].weaponRadius + 2; i++) {
                        for (var j = y - this.buildings[t].weaponRadius; j < y + this.buildings[t].weaponRadius + 2; j++) {
                            var distance = Math.pow((i * this.tileSize + this.tileSize / 2) - center.x, 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - center.y, 2);

                            if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2) && this.world.tiles[i][j].creep > 0 && this.world.tiles[i][j].creep >= highestCreep) {
                                highestCreep = this.world.tiles[i][j].creep;
                                target = new Vector(i, j);
                            }
                        }
                    }
                    if (target) {
                        engine.sounds["shot"].play();
                        var shell = new Shell(center.x, center.y, "shell", target.x * this.tileSize + this.tileSize / 2, target.y * this.tileSize + this.tileSize / 2);
                        shell.init();
                        this.shells.push(shell);
                        this.buildings[t].ammo -= 1;
                    }
                }
                if (this.buildings[t].type == "Beam" && this.buildings[t].ammo > 0 && this.buildings[t].shootTimer > 0) {
                    this.buildings[t].shootTimer = 0;

                    // find spore in range
                    for (var i = 0; i < this.spores.length; i++) {
                        var sporeCenter = this.spores[i].getCenter();
                        var distance = Math.pow(sporeCenter.x - center.x, 2) + Math.pow(sporeCenter.y - center.y, 2);

                        if (distance <= Math.pow(this.buildings[t].weaponRadius * this.tileSize, 2)) {
                            this.buildings[t].targetX = sporeCenter.x;
                            this.buildings[t].targetY = sporeCenter.y;
                            this.buildings[t].ammo -= .1;
                            this.buildings[t].shooting = true;
                            this.spores[i].health -= 2;
                            if (this.spores[i].health <= 0) {
                                this.spores[i].remove = true;
                                engine.sounds["explosion"].play();
                                this.explosions.push(new Explosion(sporeCenter.x, sporeCenter.y));
                            }
                        }
                    }
                }
            }
        }
    },
    updateCollection: function (building, action) {
        this.collection = 0;

        var height = this.world.tiles[building.x][building.y].height;
        for (var i = building.x - 2; i < building.x + 4; i++) {
            for (var j = building.y - 2; j < building.y + 4; j++) {
                if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                    if (Math.pow((i * this.tileSize + this.tileSize / 2) - (building.x * this.tileSize + this.tileSize), 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - (building.y * this.tileSize + this.tileSize), 2) < Math.pow(this.tileSize * 3, 2)) {
                        if (this.world.tiles[i][j].height == height && this.world.tiles[i][j].enabled) {
                            if (action == "remove")
                                this.world.tiles[i][j].collection = 0;
                            else
                                this.world.tiles[i][j].collection = 1;
                        }
                    }
                }
            }
        }

        this.calculateCollection();
    },
    calculateCollection: function () {
        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                if (this.world.tiles[i][j].collection == 1)
                    this.collection += 1;
            }
        }

        // decrease collection of collectors
        this.collection = parseInt(this.collection * .1);

        for (var t = 0; t < this.buildings.length; t++) {
            if (this.buildings[t].type == "Reactor" || this.buildings[t].type == "Base") {
                this.collection += 1;
            }
        }

        this.updateCollectionElement();
    },
    updateCreeper: function () {
        this.sporeTimer++;
        // generate a new spore with random target
        if (this.sporeTimer >= (10000 / this.speed)) {
            for (var i = 0; i < this.sporetowers.length; i++)
                this.sporetowers[i].spawn();
            this.sporeTimer = 0;
        }

        this.spawnTimer++;
        if (this.spawnTimer >= (150 / this.speed)) {
            for (var i = 0; i < this.emitters.length; i++)
                this.emitters[i].spawn();
            this.spawnTimer = 0;
        }

        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                this.world.tiles[i][j].newcreep = this.world.tiles[i][j].creep;
            }
        }

        var transferRate = .25;
        var minimum = .001;

        this.creeperTimer++;
        if (this.creeperTimer > (150 / this.speed)) {
            this.creeperTimer -= (150 / this.speed);

            for (var i = 0; i < this.world.size.x; i++) {
                for (var j = 0; j < this.world.size.y; j++) {

                    if (i - 1 > -1 && i + 1 < this.world.size.x - 1 && j - 1 > -2 && j + 1 < this.world.size.y) {

                        if (this.world.tiles[i][j].enabled) {
                            var sourceAmount = this.world.tiles[i][j].creep;
                            var sourceTotal = this.world.tiles[i][j].height + this.world.tiles[i][j].creep;

                            // right cell
                            if (this.world.tiles[i + 1][j].enabled) {
                                var targetAmount = this.world.tiles[i + 1][j].creep;
                                if (sourceAmount > 0 || targetAmount > 0) {
                                    var targetTotal = this.world.tiles[i + 1][j].height + this.world.tiles[i + 1][j].creep;
                                    var rightDelta = 0;
                                    if (sourceTotal > targetTotal) {
                                        rightDelta = sourceTotal - targetTotal;
                                        if (rightDelta > sourceAmount)
                                            rightDelta = sourceAmount;
                                        var delta = rightDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep -= delta;
                                        this.world.tiles[i + 1][j].newcreep += delta;
                                    }
                                    else {
                                        rightDelta = targetTotal - sourceTotal;
                                        if (rightDelta > targetAmount)
                                            rightDelta = targetAmount;
                                        var delta = rightDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep += delta;
                                        this.world.tiles[i + 1][j].newcreep -= delta;
                                    }
                                }
                            }

                            // bottom right cell
                            if (this.world.tiles[i + 1][j + 1].enabled) {
                                var targetAmount = this.world.tiles[i + 1][j + 1].creep;
                                if (sourceAmount > 0 || targetAmount > 0) {
                                    var targetTotal = this.world.tiles[i + 1][j + 1].height + this.world.tiles[i + 1][j + 1].creep;
                                    var bottomRightDelta = 0;
                                    if (sourceTotal > targetTotal) {
                                        bottomRightDelta = sourceTotal - targetTotal;
                                        if (bottomRightDelta > sourceAmount)
                                            bottomRightDelta = sourceAmount;
                                        var delta = bottomRightDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep -= delta;
                                        this.world.tiles[i + 1][j + 1].newcreep += delta;
                                    }
                                    else {
                                        bottomRightDelta = targetTotal - sourceTotal;
                                        if (bottomRightDelta > targetAmount)
                                            bottomRightDelta = targetAmount;
                                        var delta = bottomRightDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep += delta;
                                        this.world.tiles[i + 1][j + 1].newcreep -= delta;
                                    }
                                }
                            }

                            // bottom cell
                            if (this.world.tiles[i][j + 1].enabled) {
                                var targetAmount = this.world.tiles[i][j + 1].creep;
                                if (sourceAmount > 0 || targetAmount > 0) {
                                    var targetTotal = this.world.tiles[i][j + 1].height + this.world.tiles[i][j + 1].creep;
                                    var bottomDelta = 0;
                                    if (sourceTotal > targetTotal) {
                                        bottomDelta = sourceTotal - targetTotal;
                                        if (bottomDelta > sourceAmount)
                                            bottomDelta = sourceAmount;
                                        var delta = bottomDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep -= delta;
                                        this.world.tiles[i][j + 1].newcreep += delta;
                                    }
                                    else {
                                        bottomDelta = targetTotal - sourceTotal;
                                        if (bottomDelta > targetAmount)
                                            bottomDelta = targetAmount;
                                        var delta = bottomDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep += delta;
                                        this.world.tiles[i][j + 1].newcreep -= delta;
                                    }
                                }
                            }

                            // bottom left cell
                            if (this.world.tiles[i - 1][j + 1].enabled) {
                                var targetAmount = this.world.tiles[i - 1][j + 1].creep;
                                if (sourceAmount > 0 || targetAmount > 0) {
                                    var targetTotal = this.world.tiles[i - 1][j + 1].height + this.world.tiles[i - 1][j + 1].creep;
                                    var bottomLeftDelta = 0;
                                    if (sourceTotal > targetTotal) {
                                        bottomLeftDelta = sourceTotal - targetTotal;
                                        if (bottomLeftDelta > sourceAmount)
                                            bottomLeftDelta = sourceAmount;
                                        var delta = bottomLeftDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep -= delta;
                                        this.world.tiles[i - 1][j + 1].newcreep += delta;
                                    }
                                    else {
                                        bottomLeftDelta = targetTotal - sourceTotal;
                                        if (bottomLeftDelta > targetAmount)
                                            bottomLeftDelta = targetAmount;
                                        var delta = bottomLeftDelta * .5 * transferRate;
                                        this.world.tiles[i][j].newcreep += delta;
                                        this.world.tiles[i - 1][j + 1].newcreep -= delta;
                                    }
                                }
                            }
                        }

                    }
                }
            }

            for (var i = 0; i < this.world.size.x; i++) {
                for (var j = 0; j < this.world.size.y; j++) {
                    this.world.tiles[i][j].creep = this.world.tiles[i][j].newcreep;
                    if (this.world.tiles[i][j].creep > 10)
                        this.world.tiles[i][j].creep = 10;
                    if (this.world.tiles[i][j].creep < minimum)
                        this.world.tiles[i][j].creep = 0;
                }
            }

        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Used for A*, finds all neighbouring nodes of a given node.
     */
    getNeighbours: function (node, target) {
        var neighbours = [];
        //if (node.built) {
        for (var i = 0; i < this.buildings.length; i++) {
            // the neighbour must not be moving
            if (this.buildings[i].x != node.x && this.buildings[i].y != node.y && !this.buildings[i].moving) {
                // if the node is not the target AND built it is a valid neighbour
                if (this.buildings[i] != target) {
                    if (this.buildings[i].built) {
                        centerI = this.buildings[i].getCenter();
                        centerNode = node.getCenter();
                        var dx = centerI.x - centerNode.x;
                        var dy = centerI.y - centerNode.y;
                        var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

                        var allowedDistance = 10 * this.tileSize;
                        if (node.type == "Relay" && this.buildings[i].type == "Relay") {
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
                    var dx = centerI.x - centerNode.x;
                    var dy = centerI.y - centerNode.y;
                    var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

                    var allowedDistance = 10 * this.tileSize;
                    if (node.type == "Relay" && this.buildings[i].type == "Relay") {
                        allowedDistance = 20 * this.tileSize;
                    }
                    if (distance <= allowedDistance) {
                        neighbours.push(this.buildings[i]);
                    }
                }
            }
        }
        //}
        return neighbours;
    },
    /**
     * @author Alexander Zeillinger
     *
     * Used for A*, checks if a node is already in a given route.
     */
    inRoute: function (neighbour, route) {
        var found = false;
        for (var i = 0; i < route.length; i++) {
            if (neighbour.x == route[i].x && neighbour.y == route[i].y) {
                found = true;
                break;
            }
        }
        return found;
    },
    /**
     * @author Alexander Zeillinger
     *
     * Main function of A*, finds a path to the target node.
     */
    findRoute: function (packet) {
        // A* using Branch and Bound with dynamic programming and underestimates, thanks to: http://ai-depot.com/Tutorial/PathFinding-Optimal.html

        // this holds all routes
        var routes = [];

        // create a new route and add the command node as first element
        var route = new Route();
        route.nodes.push(packet.currentTarget);
        routes.push(route);

        /*
            As long as there is any route AND
            the last node of the route is not the end node try to get to the end node

            If there is no route the packet will be removed
         */
        //$('#other').html("");
        while (routes.length > 0 && routes[0].nodes[routes[0].nodes.length - 1] != packet.target) {

            // remove the first route from the list of routes
            var oldRoute = routes.shift();

            // get the last node of the route
            var lastNode = oldRoute.nodes[oldRoute.nodes.length - 1];
            //$('#other').append("1) currently at: " + lastNode.type + ", length: " + oldRoute.nodes.length + "<br/>");

            // find all neighbours of this node
            var neighbours = this.getNeighbours(lastNode, packet.target);
            //$('#other').append("2) found neighbours: " + neighbours.length);

            var newRoutes = 0;
            // extend the old route with each neighbour creating a new route each
            for (var i = 0; i < neighbours.length; i++) {

                // if the neighbour is not already in the list..
                if (!this.inRoute(neighbours[i], oldRoute.nodes)) {

                    newRoutes++;

                    // create new route
                    var newRoute = new Route();

                    // copy current list of nodes from old route to new route
                    newRoute.nodes = oldRoute.nodes.clone();

                    // add the new node to the new route
                    newRoute.nodes.push(neighbours[i]);

                    // copy distance travelled from old route to new route
                    newRoute.distanceTravelled = oldRoute.distanceTravelled;

                    // increase distance travelled
                    var dx = newRoute.nodes[newRoute.nodes.length - 1].x * this.tileSize - newRoute.nodes[newRoute.nodes.length - 2].x * this.tileSize;
                    var dy = newRoute.nodes[newRoute.nodes.length - 1].y * this.tileSize - newRoute.nodes[newRoute.nodes.length - 2].y * this.tileSize;
                    newRoute.distanceTravelled += Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

                    // update underestimate of distance remaining
                    dx = packet.target.x * this.tileSize - newRoute.nodes[newRoute.nodes.length - 1].x * this.tileSize;
                    dy = packet.target.y * this.tileSize - newRoute.nodes[newRoute.nodes.length - 1].y * this.tileSize;
                    newRoute.distanceRemaining = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

                    // finally push the new route to the list of routes
                    routes.push(newRoute);
                }

            }

            //$('#other').append(", new routes: " + newRoutes + "<br/>");
            //$('#other').append("-- total routes: " + routes.length + "<br/><br/>");

            // find routes that end at the same node, remove those with the longer distance travelled
            var remove = [];
            for (var i = 0; i < routes.length; i++) {
                for (var j = 0; j < routes.length; j++) {
                    if (i != j) {
                        if (routes[i].nodes[routes[i].nodes.length - 1] == routes[j].nodes[routes[j].nodes.length - 1]) {
                            //$('#other').append("5) found duplicate route to " + routes[i].nodes[routes[i].nodes.length - 1].type + ", removing longer<br/>");
                            if (routes[i].distanceTravelled < routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[j]));
                                //remove.push(routes[j]);
                            }
                            else if (routes[i].distanceTravelled > routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[i]));
                                //remove.push(routes[i]);
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
            routes.sort(function(a,b){return (a.distanceTravelled + a.distanceRemaining) - (b.distanceTravelled + b.distanceRemaining)});
        }

        // if a route is left set the second element as the next node for the packet
        if (routes.length > 0)
            //packet.currentTarget = routes[0].nodes[1];
            return routes[0].nodes[1];
        else {
            if (packet.type == "Ammo")
                packet.target.ammoRequests -= 4;
            if (packet.target.ammoRequests < 0)
                packet.target.ammoRequests = 0;
            if (packet.type == "Health")
                packet.target.healthRequests--;
            if (packet.target.healthRequests < 0)
                packet.target.healthRequests = 0;
            packet.remove = true;
            return null;
        }
    },
    queuePacket: function (building, type) {
        var img;
        if (type == "Ammo")
            img = "packet_ammo";
        if (type == "Health")
            img = "packet_health";
        var center = game.base.getCenter();
        var packet = new Packet(center.x, center.y, img, type);
        packet.target = building;
        packet.currentTarget = game.base;
        if (this.findRoute(packet) != null) {
            if (packet.type == "Health")
                packet.target.healthRequests++;
            if (packet.type == "Ammo")
                packet.target.ammoRequests += 4;
            this.packetQueue.push(packet);
        }
    },
    sendPacket: function (packet) {
        packet.currentTarget = this.findRoute(packet);
        if (packet.currentTarget != null) {
            packet.calculateVector();
            this.packets.push(packet);
            this.updateEnergyElement();
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Checks if a building can be placed on the current tile.
     */
    canBePlaced: function (size, building) {
        var count = 0;

        var position = this.getTilePositionScrolled();

        var height = this.world.tiles[position.x][position.y].height;

        // 1. check for collision with another building
        for (var i = 0; i < this.buildings.length; i++) {
            if (building && building == this.buildings[i])
                continue;
            var x1 = this.buildings[i].x * this.tileSize;
            var x2 = this.buildings[i].x * this.tileSize + this.buildings[i].size * this.tileSize - 1;
            var y1 = this.buildings[i].y * this.tileSize;
            var y2 = this.buildings[i].y * this.tileSize + this.buildings[i].size * this.tileSize - 1;

            var cx1 = position.x * this.tileSize;
            var cx2 = position.x * this.tileSize + size * this.tileSize - 1;
            var cy1 = position.y * this.tileSize;
            var cy2 = position.y * this.tileSize + size * this.tileSize - 1;

            if (((cx1 >= x1 && cx1 <= x2) || (cx2 >= x1 && cx2 <= x2)) && ((cy1 >= y1 && cy1 <= y2) || (cy2 >= y1 && cy2 <= y2)))
                count++;
        }

        // 2. check if all tiles have the same height and are not corners
        for (var i = position.x; i < position.x + size; i++) {
            for (var j = position.y; j < position.y + size; j++) {
                if (i > -1 && i < this.world.size.x && j > -1 && j < this.world.size.y) {
                    if (!this.world.tiles[i][j].enabled)
                        count++;
                    if (this.world.tiles[i][j].height != height)
                        count++;
                    if (!(this.world.tiles[i][j].index == 7 || this.world.tiles[i][j].index == 11 || this.world.tiles[i][j].index == 13 || this.world.tiles[i][j].index == 14 || this.world.tiles[i][j].index == 15))
                        count++;
                }
            }
        }
        if (count > 0)
            return false;
        else
            return true;
    },
    updatePacketQueue: function() {
        for (var i = 0; i < this.packetQueue.length; i++) {
            if (this.currentEnergy > 0) {
                this.currentEnergy--;
                var packet = this.packetQueue.shift();
                this.sendPacket(packet);
            }
        }
    },
    updateBuildings: function () {
        this.shoot();

        // move
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].move();
        }

        // push away creeper (shield)
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].shield();
        }
        this.shieldTimer++;
        if (this.shieldTimer > 100) {
            this.shieldTimer = 0;
            // TODO: decrease energy
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
            if (this.buildings[i].active) {
                this.buildings[i].requestTimer++;
                // request health
                if (this.buildings[i].type != "Base") {
                    var healthAndRequestDelta = this.buildings[i].maxHealth - this.buildings[i].health - this.buildings[i].healthRequests;
                    if (healthAndRequestDelta > 0 && this.buildings[i].requestTimer > 100) {
                        this.buildings[i].requestTimer = 0;
                        this.queuePacket(this.buildings[i], "Health");
                    }
                }
                // request ammo
                if (this.buildings[i].canShoot) {
                    var ammoAndRequestDelta = this.buildings[i].maxAmmo - this.buildings[i].ammo - this.buildings[i].ammoRequests;
                    if (ammoAndRequestDelta > 0 && this.buildings[i].requestTimer > 100 && this.buildings[i].built) {
                        this.buildings[i].requestTimer = 0;
                        this.queuePacket(this.buildings[i], "Ammo");
                    }
                }
            }
        }

    },
    updateEnergy: function () {
        this.energyTimer++;
        if (this.energyTimer > (250 / this.speed)) {
            this.energyTimer -= (250 / this.speed);
            this.currentEnergy += this.collection;
            if (this.currentEnergy > this.maxEnergy)
                this.currentEnergy = this.maxEnergy;
            this.updateEnergyElement();
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
        if (this.smokeTimer > 5) {
            this.smokeTimer = 0;
            for (var i = 0; i < this.smokes.length; i++) {
                this.smokes[i].frame++;
                if (this.smokes[i].frame == 36)
                    this.smokes[i].remove = true;
                if (this.smokes[i].remove)
                    this.smokes.splice(i, 1);
            }
        }
    },
    updateExplosions: function () {
        this.explosionTimer++;
        if (this.explosionTimer > 5) {
            this.explosionTimer = 0;
            for (var i = 0; i < this.explosions.length; i++) {
                this.explosions[i].frame++;
                if (this.explosions[i].frame == 44)
                    this.explosions[i].remove = true;
                if (this.explosions[i].remove)
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
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the green collection areas of Collectors.
     */
    drawCollectionAreas: function() {
        engine.ctxBuffer.save();
        engine.ctxBuffer.globalAlpha = .5;

        for (var i = -32; i < 32; i++) {
            for (var j = -24; j < 24; j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                    if (this.world.tiles[iS][jS].collection == 1) {
                        var up = 0, down = 0, left = 0, right = 0;
                        if (jS - 1 < 0)
                            up = 0;
                        else
                            up = this.world.tiles[iS][jS - 1].collection;
                        if (jS + 1 > this.world.size.y - 1)
                            down = 0;
                        else
                            down = this.world.tiles[iS][jS + 1].collection;
                        if (iS - 1 < 0)
                            left = 0;
                        else
                            left = this.world.tiles[iS - 1][jS].collection;
                        if (iS + 1 > this.world.size.x - 1)
                            right = 0;
                        else
                            right = this.world.tiles[iS + 1][jS].collection;

                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        engine.ctxBuffer.drawImage(engine.images["terrain"], index * this.tileSize, 10 * this.tileSize, this.tileSize, this.tileSize, 512 + i * this.tileSize, 384 + j * this.tileSize, this.tileSize, this.tileSize);
                    }
                }
            }
        }
        engine.ctxBuffer.restore();
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the creep.
     */
    drawCreep: function() {
        engine.ctxBuffer.font = '9px';
        engine.ctxBuffer.lineWidth = 1;
        engine.ctxBuffer.fillStyle = '#fff';

        for (var i = -32; i < 32; i++) {
            for (var j = -24; j < 24; j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                    if (this.world.tiles[iS][jS].creep > 0) {
                        var creep = Math.ceil(this.world.tiles[iS][jS].creep);

                        var up = 0, down = 0, left = 0, right = 0;
                        if (jS - 1 < 0)
                            up = 1;
                        else if (Math.ceil(this.world.tiles[iS][jS - 1].creep) >= creep)
                            up = 1;
                        if (jS + 1 > this.world.size.y - 1)
                            down = 1;
                        else if (Math.ceil(this.world.tiles[iS][jS + 1].creep) >= creep)
                            down = 1;
                        if (iS - 1 < 0)
                            left = 1;
                        else if (Math.ceil(this.world.tiles[iS - 1][jS].creep) >= creep)
                            left = 1;
                        if (iS + 1 > this.world.size.x - 1)
                            right = 1;
                        else if (Math.ceil(this.world.tiles[iS + 1][jS].creep) >= creep)
                            right = 1;

                        //if (creep > 1) {
                        //    engine.ctxBuffer.drawImage(engine.images["creep"], 15 * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
                        //}

                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        engine.ctxBuffer.drawImage(engine.images["creep"], index * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, 512 + i * this.tileSize, 384 + j * this.tileSize, this.tileSize, this.tileSize);
                    }

                    // creep value
                    //engine.ctxBuffer.textAlign = 'left';
                    //engine.ctxBuffer.fillText(Math.floor(this.world.tiles[i][j].creep), i * this.tileSize + 2, j * this.tileSize + 10);

                    // height value
                    //engine.ctxBuffer.textAlign = 'left';
                    //engine.ctxBuffer.fillText(this.world.tiles[i][j].height, i * this.tileSize + 2, j * this.tileSize + 10);
                }
            }
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * When a building from the GUI is selected this draws some info whether it can be build on the current tile,
     * the collection preview of Collectors and connections to other buildings
     */
    drawPositionInfo: function () {
        var position = this.getTilePosition();

        engine.ctxBuffer.save();
        engine.ctxBuffer.globalAlpha = .5;

        // draw green or red box
        // make sure there isn't a building on this tile yet
        if (this.canBePlaced(this.symbols[this.activeSymbol].size)) {
            engine.ctxBuffer.strokeStyle = "#0f0";
        }
        else {
            engine.ctxBuffer.strokeStyle = "#f00";
        }

        // draw collection preview, FIXME: this is not working right yet
        /*if (type == "Collector") {
            engine.ctxBuffer.save();
            engine.ctxBuffer.globalAlpha = .25;

            for (var i = -3; i < 3; i++) {
                for (var j = -3; j < 3; j++) {

                    var iS = position.x + 1 + i;
                    var jS = position.y + 1 + j;

                    if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                        // auto-tiling
                        if (Math.pow(iS + .5 - (position.x + 1), 2) + Math.pow(jS + .5 - (position.y + 1), 2) < Math.pow(3.5, 2) && this.world.tiles[iS-1][jS-1].height == this.world.tiles[position.x][position.y].height) {
                            var up = 0, down = 0, left = 0, right = 0;

                            if (Math.pow(iS + .5 - (position.x + 1), 2) + Math.pow(jS - .5 - (position.y + 1), 2) < Math.pow(3.5, 2) && this.world.tiles[iS-1][jS-2].height == this.world.tiles[position.x][position.y].height)
                                up = 1;
                            if (Math.pow(iS + .5 - (position.x + 1), 2) + Math.pow(jS + 1.5 - (position.y + 1), 2) < Math.pow(3.5, 2) && this.world.tiles[iS-1][jS].height == this.world.tiles[position.x][position.y].height)
                                down = 1;
                            if (Math.pow(iS - .5 - (position.x + 1), 2) + Math.pow(jS + .5 - (position.y + 1), 2) < Math.pow(3.5, 2) && this.world.tiles[iS-2][jS-1].height == this.world.tiles[position.x][position.y].height)
                                left = 1;
                            if (Math.pow(iS + 1.5 - (position.x + 1), 2) + Math.pow(jS + .5 - (position.y + 1), 2) < Math.pow(3.5, 2) && this.world.tiles[iS][jS-1].height == this.world.tiles[position.x][position.y].height)
                                right = 1;

                            var index = (8 * down) + (4 * left) + (2 * up) + right;

                            engine.ctxBuffer.drawImage(engine.images["terrain"], index * this.tileSize, 10 * this.tileSize, this.tileSize, this.tileSize, iS * this.tileSize, jS * this.tileSize, this.tileSize, this.tileSize);
                        }
                    }
                }
            }
            engine.ctxBuffer.restore();
        }*/

        engine.ctxBuffer.strokeRect(position.x * game.tileSize, position.y * game.tileSize, this.tileSize * this.symbols[this.activeSymbol].size, this.tileSize * this.symbols[this.activeSymbol].size);

        engine.ctxBuffer.drawImage(engine.images[this.symbols[this.activeSymbol].imageID], position.x * this.tileSize, position.y * this.tileSize);

        if (this.symbols[this.activeSymbol].imageID == "cannon")
            engine.ctxBuffer.drawImage(engine.images["cannongun"], position.x * this.tileSize, position.y * this.tileSize);

        engine.ctxBuffer.restore();

        // draw lines to close buildings
        for (var i = 0; i < this.buildings.length; i++) {
            var center = this.buildings[i].getDrawCenter();
            var centerCursorX = (position.x * game.tileSize) + ((this.tileSize / 2) * this.symbols[this.activeSymbol].size);
            var centerCursorY = (position.y * game.tileSize) + ((this.tileSize / 2) * this.symbols[this.activeSymbol].size);
            var allowedDistance = 10 * this.tileSize;
            if (this.buildings[i].type == "Relay" && this.symbols[this.activeSymbol].imageID == "relay") {
                allowedDistance = 20 * this.tileSize;
            }
            if (Math.pow(center.x - centerCursorX, 2) + Math.pow(center.y - centerCursorY, 2) < Math.pow(allowedDistance, 2)) {
                engine.ctxBuffer.strokeStyle = '#000';
                engine.ctxBuffer.lineWidth = 2;
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(position.x * game.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size, position.y * game.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size);
                engine.ctxBuffer.stroke();

                engine.ctxBuffer.strokeStyle = '#fff';
                engine.ctxBuffer.lineWidth = 1;
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(position.x * game.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size, position.y * game.tileSize + (this.tileSize / 2) * this.symbols[this.activeSymbol].size);
                engine.ctxBuffer.stroke();
            }
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the attack symbols of ships.
     */
    drawAttackSymbol: function () {
        var shipSelected = false;
        for (var i = 0; i < this.ships.length; i++) {
            if (this.ships[i].selected)
                shipSelected = true;
        }

        if (shipSelected) {
            var position = this.getTilePosition();
            engine.ctxBuffer.drawImage(engine.images["targetcursor"], position.x * this.tileSize - this.tileSize, position.y * this.tileSize - this.tileSize);
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the GUI with symbols, height and creep meter.
     */
    drawGUI: function () {
        engine.ctxGUI.clearRect(0, 0, engine.canvasGUI.width, engine.canvasGUI.height);
        for (var i = 0; i < this.symbols.length; i++) {
            this.symbols[i].draw(engine.ctxGUI);
        }

        // draw height and creep meter
        engine.ctxGUI.fillStyle = '#fff';
        engine.ctxGUI.font = '9px';
        engine.ctxGUI.textAlign = 'right';
        engine.ctxGUI.strokeStyle = '#fff';
        engine.ctxGUI.lineWidth = 1;
        engine.ctxGUI.fillStyle = "rgba(205, 133, 63, 1)";
        engine.ctxGUI.fillRect(555, 110, 25, -this.world.tiles[Math.floor(engine.mouse.x / this.tileSize)][Math.floor(engine.mouse.y / this.tileSize)].height * 10);
        engine.ctxGUI.fillStyle = "rgba(0, 0, 255, 1)";
        engine.ctxGUI.fillRect(555, 110 - this.world.tiles[Math.floor(engine.mouse.x / this.tileSize)][Math.floor(engine.mouse.y / this.tileSize)].height * 10, 25, -this.world.tiles[Math.floor(engine.mouse.x / this.tileSize)][Math.floor(engine.mouse.y / this.tileSize)].creep / 25 * 10);
        engine.ctxGUI.fillStyle = "rgba(255, 255, 255, 1)";
        for (var i = 1; i < 11; i++) {
            engine.ctxGUI.fillText(i, 550, 120 - i * 10);
            engine.ctxGUI.beginPath();
            engine.ctxGUI.moveTo(555, 120 - i * 10);
            engine.ctxGUI.lineTo(580, 120 - i * 10);
            engine.ctxGUI.stroke();
        }
        engine.ctxGUI.textAlign = 'left';
        engine.ctxGUI.fillText(this.world.tiles[Math.floor(engine.mouse.x / this.tileSize)][Math.floor(engine.mouse.y / this.tileSize)].creep.toFixed(2), 605, 10);
    },
    /**
     * @author Alexander Zeillinger
     *
     * Main drawing function
     */
    draw: function () {
        this.drawGUI();

        // clear canvas
        engine.ctxBuffer.clearRect(0, 0, engine.canvas.width, engine.canvas.height);
        engine.ctx.clearRect(0, 0, engine.canvas.width, engine.canvas.height);

        this.drawCollectionAreas();
        this.drawCreep();

        // draw emitters
        for (var i = 0; i < this.emitters.length; i++) {
            this.emitters[i].draw();
        }

        // draw spore towers
        for (var i = 0; i < this.sporetowers.length; i++) {
            this.sporetowers[i].draw();
        }

        // draw node connections
        for (var i = 0; i < this.buildings.length; i++) {
            var centerI = this.buildings[i].getCenter();
            var centerID = new Vector(512 + centerI.x - game.scroll.x * game.tileSize, 384 + centerI.y - game.scroll.y * game.tileSize);
            for (var j = 0; j < this.buildings.length; j++) {
                if (i != j) {
                    var centerJ = this.buildings[j].getCenter();
                    var centerJD = new Vector(512 + centerJ.x - game.scroll.x * game.tileSize, 384 + centerJ.y - game.scroll.y * game.tileSize);
                    var allowedDistance = 10 * this.tileSize;
                    if (this.buildings[i].type == "Relay" && this.buildings[j].type == "Relay") {
                        allowedDistance = 20 * this.tileSize;
                    }
                    if (Math.pow(centerJD.x - centerID.x, 2) + Math.pow(centerJD.y - centerID.y, 2) < Math.pow(allowedDistance, 2)) {
                        engine.ctxBuffer.strokeStyle = '#000';
                        engine.ctxBuffer.lineWidth = 3;
                        engine.ctxBuffer.beginPath();
                        engine.ctxBuffer.moveTo(centerID.x, centerID.y);
                        engine.ctxBuffer.lineTo(centerJD.x, centerJD.y);
                        engine.ctxBuffer.stroke();

                        engine.ctxBuffer.strokeStyle = '#fff';
                        if (!this.buildings[i].built || !this.buildings[j].built)
                            engine.ctxBuffer.strokeStyle = '#aaa';
                        engine.ctxBuffer.lineWidth = 2;
                        engine.ctxBuffer.beginPath();
                        engine.ctxBuffer.moveTo(centerID.x, centerID.y);
                        engine.ctxBuffer.lineTo(centerJD.x, centerJD.y);
                        engine.ctxBuffer.stroke();
                    }
                }
            }
        }

        // draw movement indicators
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].drawMovementIndicators();
        }

        // draw buildings
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].draw();
        }

        // draw radius
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].drawRadius();
        }

        // draw shells
        for (var i = 0; i < this.shells.length; i++) {
            this.shells[i].draw();
        }

        // draw smokes
        for (var i = 0; i < this.smokes.length; i++) {
            this.smokes[i].draw();
        }

        // draw explosions
        for (var i = 0; i < this.explosions.length; i++) {
            this.explosions[i].draw();
        }

        // draw spores
        for (var i = 0; i < this.spores.length; i++) {
            this.spores[i].draw();
        }

        if (engine.mouse.active) {

            // if a building is built and selected draw a green box and a line at mouse position as the reposition target
            for (var i = 0; i < this.buildings.length; i++) {
                this.buildings[i].drawRepositionInfo();
            }

            // draw attack symbol
            this.drawAttackSymbol();

            if (this.activeSymbol != -1) {
                this.drawPositionInfo();
            }
        }

        // draw packets
        for (var i = 0; i < this.packets.length; i++) {
            this.packets[i].draw();
        }

        // draw ships
        for (var i = 0; i < this.ships.length; i++) {
            this.ships[i].draw(engine.ctxBuffer);
        }

        // draw building hover/selection box
        for (var i = 0; i < this.buildings.length; i++) {
            this.buildings[i].drawBox();
        }

        // draw ship hover/selection box
        for (var i = 0; i < this.ships.length; i++) {
            this.ships[i].drawBox();
        }

        engine.ctx.drawImage(engine.canvasBuffer, 0, 0); // copy from buffer to context
        // double buffering taken from: http://www.youtube.com/watch?v=FEkBldQnNUc
    }
};

// Objects

/**
 * @author Alexander Zeillinger
 *
 * Generic game object
 */
function GameObject(pX, pY, pImage) {
    this.x = pX;
    this.y = pY;
    this.imageID = pImage;
}

/**
 * @author Alexander Zeillinger
 *
 * Building symbols in the GUI
 */
function UISymbol(pX, pY, pImage, pKey, pSize, pPackets) {
    this.x = pX;
    this.y = pY;
    this.imageID = pImage;
    this.key = pKey;
    this.active = false;
    this.hovered = false;
    this.width = 80;
    this.height = 55;
    this.size = pSize;
    this.packets = pPackets;
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
        pContext.fillRect(this.x + 1, this.y + 1, this.width, this.height);

        pContext.drawImage(engine.images[this.imageID], this.x + 24, this.y + 20, 32, 32); // scale buildings to 32x32
        // draw cannon gun and ships
        if (this.imageID == "cannon")
            pContext.drawImage(engine.images["cannongun"], this.x + 24, this.y + 20, 32, 32);
        if (this.imageID == "bomber")
            pContext.drawImage(engine.images["bombership"], this.x + 24, this.y + 20, 32, 32);
        pContext.fillStyle = '#fff';
        pContext.font = '10px';
        pContext.textAlign = 'center';
        pContext.fillText(this.imageID.substring(0, 1).toUpperCase() + this.imageID.substring(1), this.x + (this.width / 2), this.y + 15);
        pContext.textAlign = 'left';
        pContext.fillText("(" + this.key + ")", this.x + 5, this.y + 50);
        pContext.textAlign = 'right';
        pContext.fillText(this.packets, this.x + this.width - 5, this.y + 50);
        //pContext.fillText(this.size + "x" + this.size, this.x + (this.width / 2), this.y + 60);

    };
    this.checkHovered = function () {
        this.hovered = false;
        if (engine.mouseGUI.x > this.x && engine.mouseGUI.x < this.x + this.width && engine.mouseGUI.y > this.y && engine.mouseGUI.y < this.y + this.height) {
            this.hovered = true;
        }
    };
    this.setActive = function () {
        this.active = false;
        if (engine.mouseGUI.x > this.x && engine.mouseGUI.x < this.x + this.width && engine.mouseGUI.y > this.y && engine.mouseGUI.y < this.y + this.height) {
            game.activeSymbol = Math.floor(this.x / 81) + (Math.floor(this.y / 56)) * 5;
            this.active = true;
        }
    };
}

/**
 * @author Alexander Zeillinger
 *
 * Buildings
 */
function Building(pX, pY, pImage, pType) {
    this.base = GameObject;
    this.base(pX, pY, pImage);
    this.shooting = false;
    this.selected = false;
    this.hovered = false;
    this.targetX = 0;
    this.targetY = 0;
    this.type = pType;
    this.health = 0;
    this.maxHealth = 0;
    this.ammo = 0;
    this.maxAmmo = 0;
    this.healthRequests = 0;
    this.ammoRequests = 0;
    this.requestTimer = 0;
    this.nodeRadius = 0;
    this.weaponRadius = 0;
    this.built = false;
    this.shootTimer = 0;
    this.targetAngle = 0;
    this.size = 0;
    this.active = true;
    this.moving = false;
    this.speed = new Vector(0, 0);
    this.tx = 0;
    this.ty = 0;
    this.canMove = false;
    this.canShoot = false;
    this.updateHoverState = function () {
        if (engine.mouse.x > 512 + (this.x - game.scroll.x) * game.tileSize && engine.mouse.x < 512 + (this.x - game.scroll.x) * game.tileSize + game.tileSize * this.size - 1 && engine.mouse.y > 384 + (this.y - game.scroll.y) * game.tileSize && engine.mouse.y < 384 + (this.y - game.scroll.y) * game.tileSize + game.tileSize * this.size - 1) {
            this.hovered = true;
            return true;
        }
        else {
            this.hovered = false;
            return false;
        }
    };
    this.drawBox = function () {
        if (this.hovered || this.selected) {
            engine.ctxBuffer.lineWidth = 1;
            engine.ctxBuffer.strokeStyle = "#000";
            engine.ctxBuffer.strokeRect(512 + (this.x - game.scroll.x) * game.tileSize, 384 + (this.y - game.scroll.y) * game.tileSize, game.tileSize * this.size, game.tileSize * this.size);
        }
    };
    this.move = function () {
        if (this.moving) {
            this.x += this.speed.x;
            this.y += this.speed.y;
            if (this.x * game.tileSize > this.tx * game.tileSize - 3 && this.x * game.tileSize < this.tx * game.tileSize + 3 && this.y * game.tileSize > this.ty * game.tileSize - 3 && this.y * game.tileSize < this.ty * game.tileSize + 3) {
                this.moving = false;
                this.x = this.tx;
                this.y = this.ty;
            }
        }
    };
    this.calculateVector = function () {
        if (this.tx != this.x || this.ty != this.y) {
            var dx = this.tx * game.tileSize - this.x * game.tileSize;
            var dy = this.ty * game.tileSize - this.y * game.tileSize;
            var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

            this.speed.x = (dx / distance) * game.buildingSpeed * game.speed / game.tileSize;
            this.speed.y = (dy / distance) * game.buildingSpeed * game.speed / game.tileSize;
        }
    };
    this.getCenter = function () {
        var x = this.x * game.tileSize + (game.tileSize / 2) * this.size;
        var y = this.y * game.tileSize + (game.tileSize / 2) * this.size;
        return new Vector(x, y);
    };
    this.getDrawCenter = function () {
        var center = this.getCenter();
        var x = 512 + center.x - game.scroll.x * game.tileSize;
        var y = 384 + center.y - game.scroll.y * game.tileSize;
        return new Vector(x, y);
    };
    this.takeDamage = function () {
        // buildings can only be damaged while not moving
        if (!this.moving) {

            for (var i = 0; i < this.size; i++) {
                for (var j = 0; j < this.size; j++) {
                    if (game.world.tiles[this.x + i][this.y + j].creep > 0) {
                        this.health -= 1;
                    }
                }
            }

            if (this.health < 0) {
                game.removeBuilding(this);
                engine.sounds["explosion"].play();
                game.explosions.push(new Explosion(this.x * game.tileSize, this.y * game.tileSize));
                if (this == game.base) {
                    $('#lose').toggle();
                    stop();
                }
            }
        }
    };
    this.drawRadius = function () {
        if (this.selected) {
            var center = this.getDrawCenter();

            // node radius
            engine.ctxBuffer.strokeStyle = "#000";
            engine.ctxBuffer.beginPath();
            engine.ctxBuffer.arc(center.x, center.y, this.nodeRadius * game.tileSize, 0, Math.PI * 2, true);
            engine.ctxBuffer.closePath();
            engine.ctxBuffer.stroke();

            // weapon radius
            if (this.canShoot) {
                engine.ctxBuffer.strokeStyle = "#f00";
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.arc(center.x, center.y, this.weaponRadius * game.tileSize, 0, Math.PI * 2, true);
                engine.ctxBuffer.closePath();
                engine.ctxBuffer.stroke();
            }
        }
    };
    this.drawMovementIndicators = function () {
        if (this.moving) {
            var center = this.getCenter();
            // draw box
            engine.ctxBuffer.fillStyle = "rgba(0,255,0,0.5)";
            engine.ctxBuffer.fillRect(this.tx * game.tileSize, this.ty * game.tileSize, this.size * game.tileSize, this.size * game.tileSize);
            // draw line
            engine.ctxBuffer.strokeStyle = "rgba(255,255,255,0.5)";
            engine.ctxBuffer.beginPath();
            engine.ctxBuffer.moveTo(center.x, center.y);
            engine.ctxBuffer.lineTo(this.tx * game.tileSize + (game.tileSize / 2) * this.size, this.ty * game.tileSize + (game.tileSize / 2) * this.size);
            engine.ctxBuffer.stroke();
        }
    };
    this.drawRepositionInfo = function () {
        var center = this.getCenter();
        var position = game.getTilePosition();
        // only armed buildings can move
        if (this.built && this.selected && this.canMove) {
            if (game.canBePlaced(this.size, this)) {
                // draw rectangle
                engine.ctxBuffer.strokeStyle = "rgba(0,255,0,0.5)";
                engine.ctxBuffer.strokeRect(position.x * game.tileSize, position.y * game.tileSize, game.tileSize * this.size, game.tileSize * this.size);
                // draw line
                engine.ctxBuffer.strokeStyle = "rgba(255,255,255,0.5)";
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(position.x * game.tileSize + (game.tileSize / 2) * this.size, position.y * game.tileSize + (game.tileSize / 2) * this.size);
                engine.ctxBuffer.stroke();
            }
            else {
                // draw rectangle
                engine.ctxBuffer.strokeStyle = "rgba(255,0,0,0.5)";
                engine.ctxBuffer.strokeRect(position.x * game.tileSize, position.y * game.tileSize, game.tileSize * this.size, game.tileSize * this.size);
                // draw line
                engine.ctxBuffer.strokeStyle = "rgba(255,255,255,0.5)";
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(position.x * game.tileSize + (game.tileSize / 2) * this.size, position.y * game.tileSize + (game.tileSize / 2) * this.size);
                engine.ctxBuffer.stroke();
            }
        }
    };
    this.shield = function () {
        if (this.type == "Shield" && !this.moving) {
            var center = this.getCenter();

            for (var i = this.x - 9; i < this.x + 10; i++) {
                for (var j = this.y - 9; j < this.y + 10; j++) {
                    if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - center.x, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - center.y, 2);
                        if (distance < Math.pow(game.tileSize * 10, 2)) {
                            if (game.world.tiles[i][j].creep > 0) {
                                game.world.tiles[i][j].creep -= distance / game.tileSize * .1; // the closer to the shield the more creep is removed
                                if (game.world.tiles[i][j].creep < 0) {
                                    game.world.tiles[i][j].creep = 0;
                                }
                            }
                        }
                    }
                }
            }

        }
    };
    this.draw = function () {
        // draw buildings
        var center = this.getDrawCenter();
        if (!this.built) {
            engine.ctxBuffer.save();
            engine.ctxBuffer.globalAlpha = .5;
            engine.ctxBuffer.drawImage(engine.images[this.imageID], 512 + (this.x - game.scroll.x) * game.tileSize, 384 + (this.y - game.scroll.y) * game.tileSize, engine.images[this.imageID].width, engine.images[this.imageID].height);
            if (this.type == "Cannon") {
                engine.ctxBuffer.drawImage(engine.images["cannongun"], 512 + (this.x - game.scroll.x) * game.tileSize, 384 + (this.y - game.scroll.y) * game.tileSize, engine.images[this.imageID].width, engine.images[this.imageID].height);
            }
            engine.ctxBuffer.restore();
        }
        else {
            engine.ctxBuffer.drawImage(engine.images[this.imageID], 512 + (this.x - game.scroll.x) * game.tileSize, 384 + (this.y - game.scroll.y) * game.tileSize, engine.images[this.imageID].width, engine.images[this.imageID].height);
            if (this.type == "Cannon") {
                engine.ctxBuffer.save();
                engine.ctxBuffer.translate(512 + (this.x - game.scroll.x) * game.tileSize + 24, 384 + (this.y - game.scroll.y) * game.tileSize + 24);
                engine.ctxBuffer.rotate(this.targetAngle);
                engine.ctxBuffer.drawImage(engine.images["cannongun"], -24, -24);
                engine.ctxBuffer.restore();
            }
            if (this.type == "Shield" && !this.moving) {
                engine.ctxBuffer.drawImage(engine.images["forcefield"], center.x - 168, center.y - 168);
            }
        }

        // draw ammo bar
        if (this.canShoot) {
            engine.ctxBuffer.fillStyle = '#000';
            engine.ctxBuffer.fillRect(512 + (this.x - game.scroll.x) * game.tileSize + 2, 384 + (this.y - game.scroll.y) * game.tileSize, 44, 4);
            engine.ctxBuffer.fillStyle = '#f00';
            engine.ctxBuffer.fillRect(512 + (this.x - game.scroll.x) * game.tileSize + 3, 384 + (this.y - game.scroll.y) * game.tileSize + 1, (42 / this.maxAmmo) * this.ammo, 2);
        }

        // draw health bar (only if health is below maxHealth)
        if (this.health < this.maxHealth) {
            engine.ctxBuffer.fillStyle = '#000';
            engine.ctxBuffer.fillRect(512 + (this.x - game.scroll.x) * game.tileSize + 2, 384 + (this.y - game.scroll.y) * game.tileSize + game.tileSize * this.size - 4, game.tileSize * this.size - 4, 4);
            engine.ctxBuffer.fillStyle = '#0f0';
            engine.ctxBuffer.fillRect(512 + (this.x - game.scroll.x) * game.tileSize + 3, 384 + (this.y - game.scroll.y) * game.tileSize + game.tileSize * this.size - 3, ((game.tileSize * this.size - 6) / this.maxHealth) * this.health, 2);
        }

        // draw shots
        if (this.shooting) {
            if (this.type == "Cannon") {
                engine.ctxBuffer.strokeStyle = "#f00";
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(this.targetX, this.targetY);
                engine.ctxBuffer.stroke();
            }
            if (this.type == "Beam") {
                engine.ctxBuffer.strokeStyle = '#f00';
                engine.ctxBuffer.lineWidth = 4;
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(this.targetX, this.targetY);
                engine.ctxBuffer.stroke();

                engine.ctxBuffer.strokeStyle = '#fff';
                engine.ctxBuffer.lineWidth = 2;
                engine.ctxBuffer.beginPath();
                engine.ctxBuffer.moveTo(center.x, center.y);
                engine.ctxBuffer.lineTo(this.targetX, this.targetY);
                engine.ctxBuffer.stroke();
            }
        }

        // draw inactive sign
        if (!this.active) {
            var center = this.getCenter();
            engine.ctxBuffer.strokeStyle = "#F00";
            engine.ctxBuffer.lineWidth = 2;

            engine.ctxBuffer.beginPath();
            engine.ctxBuffer.arc(center.x, center.y, (game.tileSize / 2) * this.size, 0, Math.PI * 2, true);
            engine.ctxBuffer.closePath();
            engine.ctxBuffer.stroke();

            engine.ctxBuffer.beginPath();
            engine.ctxBuffer.moveTo(this.x * game.tileSize, this.y * game.tileSize + game.tileSize * this.size);
            engine.ctxBuffer.lineTo(this.x * game.tileSize + game.tileSize * this.size, this.y);
            engine.ctxBuffer.stroke();
        }
    };
}
Building.prototype = new GameObject;
Building.prototype.constructor = Building;

/**
 * @author Alexander Zeillinger
 *
 * Packets
 */
function Packet(pX, pY, pImage, pType) {
    this.base = GameObject;
    this.base(pX, pY, pImage);
    this.speed = new Vector(0, 0);
    this.target = null;
    this.currentTarget = null;
    this.type = pType;
    this.remove = false;
    this.move = function () {
        // if the target is moving recalculate vector
        if (this.currentTarget.moving)
            this.calculateVector();
        this.x += this.speed.x * game.speed;
        this.y += this.speed.y * game.speed;
        var centerTarget = this.currentTarget.getCenter();
        if (this.x > centerTarget.x - 2 && this.x < centerTarget.x + 2 && this.y > centerTarget.y - 2 && this.y < centerTarget.y + 2) {
            // if the final node was reached deliver and remove
            if (this.currentTarget == this.target) {
                this.remove = true;
                // deliver package
                if (this.type == "Health") {
                    this.target.health += 1;
                    this.target.healthRequests--;
                    if (this.target.health >= this.target.maxHealth) {
                        this.target.health = this.target.maxHealth;
                        if (!this.target.built) {
                            this.target.built = true;
                            if (this.target.type == "Collector")
                                game.updateCollection(this.target, "add");
                            if (this.target.type == "Storage")
                                game.maxEnergy += 20;
                            if (this.target.type == "Speed")
                                game.packetSpeed *= 1.01;
                            if (this.target.type == "Bomber") {
                                var ship = new Ship(this.target.x * game.tileSize, this.target.y * game.tileSize, "bombership", "Bomber", this.target);
                                game.ships.push(ship);
                            }
                        }
                    }
                }
                if (this.type == "Ammo") {
                    this.target.ammo += 4;
                    this.target.ammoRequests -= 4;
                    if (this.target.ammo > this.target.maxAmmo)
                        this.target.ammo = this.target.maxAmmo;
                }
            }
            else {
                this.currentTarget = game.findRoute(this);
                this.calculateVector();
            }
        }
    };
    this.calculateVector = function () {
        var centerTarget = this.currentTarget.getCenter();
        var dx = centerTarget.x - this.x;
        var dy = centerTarget.y - this.y;
        var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

        this.speed.x = (dx / distance) * game.packetSpeed;
        this.speed.y = (dy / distance) * game.packetSpeed;
    };
    this.draw = function () {
        engine.ctxBuffer.drawImage(engine.images[this.imageID], 512 + this.x - game.scroll.x * game.tileSize - 8, 384 + this.y - game.scroll.y * game.tileSize - 8);
    }
}
Packet.prototype = new GameObject;
Packet.prototype.constructor = Packet;

/**
 * @author Alexander Zeillinger
 *
 * Shells (fired by Mortars)
 */
function Shell(pX, pY, pImage, pTX, pTY) {
    this.base = GameObject;
    this.base(pX, pY, pImage);
    this.speed = new Vector(0, 0);
    this.tx = pTX;
    this.ty = pTY;
    this.remove = false;
    this.rotation = 0;
    this.init = function () {
        var dx = this.tx - this.x;
        var dy = this.ty - this.y;
        var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

        this.speed.x = (dx / distance) * game.shellSpeed * game.speed;
        this.speed.y = (dy / distance) * game.shellSpeed * game.speed;
    };
    this.move = function () {
        this.rotation += 10;
        if (this.rotation > 359)
            this.rotation -= 359;
        this.x += this.speed.x;
        this.y += this.speed.y;
        if (this.x > this.tx - 2 && this.x < this.tx + 2 && this.y > this.ty - 2 && this.y < this.ty + 2) {
            // if the target is reached explode and remove
            this.remove = true;

            game.explosions.push(new Explosion(this.tx, this.ty));
            engine.sounds["explosion"].play();

            for (var i = Math.floor(this.tx / game.tileSize) - 4; i < Math.floor(this.tx / game.tileSize) + 5; i++) {
                for (var j = Math.floor(this.ty / game.tileSize) - 4; j < Math.floor(this.ty / game.tileSize) + 5; j++) {
                    if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - this.tx, 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - this.ty, 2);
                        if (distance < Math.pow(game.tileSize * 4, 2)) {
                            game.world.tiles[i][j].creep -= 10;
                            if (game.world.tiles[i][j].creep < 0) {
                                game.world.tiles[i][j].creep = 0;
                            }
                        }
                    }
                }
            }

        }
    };
    this.draw = function () {
        engine.ctxBuffer.save();
        engine.ctxBuffer.translate(512 + this.x - game.scroll.x * game.tileSize + 8, 384 + this.y - game.scroll.y * game.tileSize + 8);
        engine.ctxBuffer.rotate(this.rotation * (Math.PI / 180));
        engine.ctxBuffer.drawImage(engine.images["shell"], -8, -8);
        engine.ctxBuffer.restore();
    };
}
Shell.prototype = new GameObject;
Shell.prototype.constructor = Shell;

/**
 * @author Alexander Zeillinger
 *
 * Spore (fired by Sporetower)
 */
function Spore(pX, pY, pImage, pTX, pTY) {
    this.base = GameObject;
    this.base(pX, pY, pImage);
    this.speed = new Vector(0, 0);
    this.tx = pTX;
    this.ty = pTY;
    this.remove = false;
    this.rotation = 0;
    this.health = 100;
    this.trailTimer = 0;
    this.init = function () {
        var dx = this.tx - this.x;
        var dy = this.ty - this.y;
        var distance = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

        this.speed.x = (dx / distance) * game.sporeSpeed * game.speed;
        this.speed.y = (dy / distance) * game.sporeSpeed * game.speed;
    };
    this.move = function () {
        this.trailTimer++;
        if (this.trailTimer == 10) {
            this.trailTimer = 0;
            game.smokes.push(new Smoke(this.x, this.y));
        }
        this.rotation += 10;
        if (this.rotation > 359)
            this.rotation -= 359;
        this.x += this.speed.x;
        this.y += this.speed.y;
        if (this.x > this.tx - 2 && this.x < this.tx + 2 && this.y > this.ty - 2 && this.y < this.ty + 2) {
            // if the target is reached explode and remove
            this.remove = true;
            engine.sounds["explosion"].play();

            for (var i = Math.floor(this.tx / game.tileSize) - 1; i < Math.floor(this.tx / game.tileSize) + 3; i++) {
                for (var j = Math.floor(this.ty / game.tileSize) - 1; j < Math.floor(this.ty / game.tileSize) + 3; j++) {
                    if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                        var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.tx + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.ty + game.tileSize), 2);
                        if (distance < Math.pow(game.tileSize, 2)) {
                            game.world.tiles[i][j].creep += .05;
                            if (game.world.tiles[i][j].creep > 1) {
                                game.world.tiles[i][j].creep = 1;
                            }
                        }
                    }
                }
            }
        }
    };
    this.getCenter = function () {
        var x = this.x + 16;
        var y = this.y + 16;
        return new Vector(x, y);
    };
    this.draw = function () {
        engine.ctxBuffer.save();
        engine.ctxBuffer.translate(512 + this.x - game.scroll.x * game.tileSize + 16, 384 + this.y - game.scroll.y * game.tileSize + 16);
        engine.ctxBuffer.rotate(this.rotation * (Math.PI / 180));
        engine.ctxBuffer.drawImage(engine.images["spore"], -16, -16);
        engine.ctxBuffer.restore();
    };
}
Spore.prototype = new GameObject;
Spore.prototype.constructor = Spore;

/**
 * @author Alexander Zeillinger
 *
 * Ships (Bomber)
 */
function Ship(pX, pY, pImage, pType, pHome) {
    this.base = GameObject;
    this.base(pX, pY, pImage);
    this.speed = new Vector(0, 0);
    this.tx = 0;
    this.ty = 0;
    this.remove = false;
    this.angle = 0;
    this.ammo = 5;
    this.type = pType;
    this.home = pHome;
    this.status = 0; // 0 idle, 1 attacking, 2 returning
    this.trailTimer = 0;
    this.weaponTimer = 0;
    this.updateHoverState = function () {
        if (engine.mouse.x > this.x && engine.mouse.x < this.x + 47 && engine.mouse.y > this.y && engine.mouse.y < this.y + 47) {
            this.hovered = true;
            return true;
        }
        else {
            this.hovered = false;
            return false;
        }
    };
    this.drawBox = function () {
        if (this.hovered || this.selected) {
            engine.ctxBuffer.lineWidth = 1;
            engine.ctxBuffer.strokeStyle = "#f00";
            engine.ctxBuffer.strokeRect(this.x, this.y, 47, 47);
        }
    };
    this.turnToTarget = function () {
        var dx = this.tx - this.x;
        var dy = this.ty - this.y;
        var angleToTarget = Math.atan2(dy, dx) * 180 / Math.PI;

        var turnRate = 1;
        var absoluteDelta = Math.abs(angleToTarget - this.angle);

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

        if (this.angle > 180)
            this.angle -= 360;
        if (this.angle < -180)
            this.angle += 360;
    };
    this.calculateVector = function () {
        var x = Math.cos(this.angle * Math.PI / 180);
        var y = Math.sin(this.angle * Math.PI / 180);

        this.speed.x = x * game.shipSpeed;
        this.speed.y = y * game.shipSpeed;
    };
    this.move = function () {

        if (this.status != 0) {
            this.trailTimer++;
            if (this.trailTimer == 10) {
                this.trailTimer = 0;
                game.smokes.push(new Smoke(this.x + 24, this.y + 24));
            }

            this.weaponTimer++;

            this.turnToTarget();
            this.calculateVector();

            this.x += this.speed.x;
            this.y += this.speed.y;

            if (this.x > this.tx - 2 && this.x < this.tx + 2 && this.y > this.ty - 2 && this.y < this.ty + 2) {
                if (this.status == 1) { // attacking
                    if (this.weaponTimer >= 10) {
                        this.weaponTimer = 0;
                        game.explosions.push(new Explosion(this.tx, this.ty));
                        this.ammo -= 1;

                        for (var i = Math.floor(this.tx / game.tileSize) - 3; i < Math.floor(this.tx / game.tileSize) + 5; i++) {
                            for (var j = Math.floor(this.ty / game.tileSize) - 3; j < Math.floor(this.ty / game.tileSize) + 5; j++) {
                                if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                                    var distance = Math.pow((i * game.tileSize + game.tileSize / 2) - (this.tx + game.tileSize), 2) + Math.pow((j * game.tileSize + game.tileSize / 2) - (this.ty + game.tileSize), 2);
                                    if (distance < Math.pow(game.tileSize * 3, 2)) {
                                        game.world.tiles[i][j].creep -= 10;
                                        if (game.world.tiles[i][j].creep < 0) {
                                            game.world.tiles[i][j].creep = 0;
                                        }
                                    }
                                }
                            }
                        }

                        if (this.ammo == 0) { // return
                            this.status = 2;
                            this.tx = this.home.x * game.tileSize;
                            this.ty = this.home.y * game.tileSize;
                        }
                    }
                }
                else if (this.status == 2) { // if returning set to idle
                    this.status = 0;
                    this.x = this.home.x * game.tileSize;
                    this.y = this.home.y * game.tileSize;
                    this.tx = 0;
                    this.ty = 0;
                    this.ammo = 5;
                }
            }
        }
    };
    this.draw = function () {
        if (this.status == 1 && this.selected) {
            engine.ctxBuffer.save();
            engine.ctxBuffer.globalAlpha = .5;
            engine.ctxBuffer.drawImage(engine.images["targetcursor"], 512 + this.tx - game.scroll.x * game.tileSize - game.tileSize, 384 + this.ty - game.scroll.y * game.tileSize - game.tileSize);
            engine.ctxBuffer.restore();
        }

        engine.ctxBuffer.save();
        engine.ctxBuffer.translate(512 + this.x - game.scroll.x * game.tileSize + 24, 384 + this.y - game.scroll.y * game.tileSize + 24);
        engine.ctxBuffer.rotate((this.angle + 90) * (Math.PI / 180));
        engine.ctxBuffer.drawImage(engine.images[this.imageID], -24, -24);
        engine.ctxBuffer.restore();
    };
}
Ship.prototype = new GameObject;
Ship.prototype.constructor = Ship;

/**
 * @author Alexander Zeillinger
 *
 * Emitter
 */
function Emitter(pX, pY, pS) {
    this.position = new Vector(pX, pY);
    this.strength = pS;
    this.draw = function () {
        engine.ctxBuffer.drawImage(engine.images["emitter"], 512 + (this.position.x - game.scroll.x) * game.tileSize, 384 + (this.position.y - game.scroll.y) * game.tileSize, 48, 48);
    };
    this.spawn = function () {
        game.world.tiles[this.position.x + 1][this.position.y + 1].creep = this.strength;
    };
}

/**
 * @author Alexander Zeillinger
 *
 * Sporetower
 */
function Sporetower(pX, pY) {
    this.position = new Vector(pX, pY);
    this.health = 100;
    this.draw = function () {
        engine.ctxBuffer.drawImage(engine.images["sporetower"], 512 + (this.position.x - game.scroll.x) * game.tileSize, 384 + (this.position.y - game.scroll.y) * game.tileSize, 48, 48);
    };
    this.spawn = function () {
        var target = game.buildings[Math.floor(Math.random() * game.buildings.length)];
        var spore = new Spore(this.position.x * game.tileSize, this.position.y * game.tileSize, "spore", target.x * game.tileSize, target.y * game.tileSize);
        spore.init();
        game.spores.push(spore);
    };
}

/**
 * @author Alexander Zeillinger
 *
 * Smoke
 *
 * Smoke is created by weapon fire of Cannons, or exhaust trail of ships and spores.
 */
function Smoke(pX, pY) {
    this.x = pX;
    this.y = pY;
    this.remove = false;
    this.frame = 0;
    this.draw = function () {
        engine.ctxBuffer.drawImage(engine.images["smoke"], (this.frame % 8) * 128, Math.floor(this.frame / 8) * 128, 128, 128, 512 + this.x - game.scroll.x * game.tileSize - 24, 384 + this.y - game.scroll.y * game.tileSize - 24, 48, 48);
    };
}

/**
 * @author Alexander Zeillinger
 *
 * Explosion
 *
 * Created on explosion of buildings, spores and shells
 */
function Explosion(pX, pY) {
    this.x = pX;
    this.y = pY;
    this.remove = false;
    this.frame = 0;
    this.draw = function () {
        engine.ctxBuffer.drawImage(engine.images["explosion"], (this.frame % 8) * 64, Math.floor(this.frame / 8) * 64, 64, 64, 512 + this.x - game.scroll.x * game.tileSize - 32, 384 + this.y - game.scroll.y * game.tileSize - 32, 64, 64);
    };
}

/**
 * @author Alexander Zeillinger
 *
 * A tile of the world
 */
function Tile() {
    this.index = 0;
    this.height = 0;
    this.creep = 0;
    this.newcreep = 0;
    this.collection = 0;
    this.enabled = true;
}

function Vector(pX, pY) {
    this.x = pX;
    this.y = pY;
}

/**
 * @author Alexander Zeillinger
 *
 * Route object used in A*
 */
function Route() {
    this.distanceTravelled = 0;
    this.distanceRemaining = 0;
    this.nodes = [];
}

// Functions

// Entry Point
function init() {
    engine.init();
    engine.loadImages(function() {
        game.init();
        game.drawTerrain();

        //engine.sounds["music"].loop = true;
        //engine.sounds["music"].play();

        stop();
        run();
    });
}

function stop() {
    clearInterval(game.running);
}

function run() {
    game.running = setInterval(gameloop, 1000 / game.speed / engine.FPS);
}

function faster() {
    if (game.speed < 2) {
        game.speed *= 2;
        stop();
        run();
        game.updateSpeedElement();
    }
}

function slower() {
    if (game.speed > 1) {
        game.speed /= 2;
        stop();
        run();
        game.updateSpeedElement();
    }
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

function keyDown(evt) {
    // select instruction with keypress
    var key = game.keyMap["k" + evt.keyCode];
    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].active = false;
        if (game.symbols[i].key == key) {
            game.activeSymbol = i;
            game.symbols[i].active = true;
        }
    }

    // delete building
    if (evt.keyCode == 46) {
        for (var i = 0; i < game.buildings.length; i++) {
            if (game.buildings[i].selected) {
                if (game.buildings[i].type != "Base")
                    game.removeBuilding(game.buildings[i]);
            }
        }
    }

    // pause/unpause
    if (evt.keyCode == 80) {
        if (game.paused)
            unpauseGame();
        else
            pauseGame();
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

    // scroll left
    if (evt.keyCode == 37) {
        if (game.scroll.x > 0)
            game.scroll.x -= 1;
        game.drawTerrain();
    }

    // scroll right
    if (evt.keyCode == 39) {
        if (game.scroll.x < game.world.size.x)
            game.scroll.x += 1;
        game.drawTerrain();
    }

    // scroll up
    if (evt.keyCode == 38) {
        if (game.scroll.y > 0)
            game.scroll.y -= 1;
        game.drawTerrain();
    }

    // scroll down
    if (evt.keyCode == 40) {
        if (game.scroll.y < game.world.size.y)
            game.scroll.y += 1;
        game.drawTerrain();
    }

    // lower terrain
    if (evt.keyCode == 78) {
        if (game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].height > 1) {
            game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].height -= 1;
            game.drawTerrain();
        }
    }

    // raise terrain
    if (evt.keyCode == 77) {
        if (game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].height < 9) {
            game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].height += 1;
            game.drawTerrain();
        }
    }

    // enable/disable terrain
    if (evt.keyCode == 66) {
        if (game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].enabled)
            game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].enabled = false;
        else
            game.world.tiles[Math.floor(engine.mouse.x / game.tileSize)][Math.floor(engine.mouse.y / game.tileSize)].enabled = true;
        game.drawTerrain();
    }

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

    engine.sounds["click"].play();
    for (var i = 0; i < game.symbols.length; i++) {
        game.symbols[i].setActive();
    }
}

function onClick(evt) {
    var shipSelected = false;
    // select a ship if hovered
    for (var i = 0; i < game.ships.length; i++) {
        game.ships[i].selected = game.ships[i].hovered;
        if (game.ships[i].selected)
            shipSelected = true;
    }

    // select a building if hovered
    if (!shipSelected) {
        for (var i = 0; i < game.buildings.length; i++) {
            game.buildings[i].selected = game.buildings[i].hovered;
            if (game.buildings[i].selected)
                $('#selection').html("Type: " + game.buildings[i].type + "<br/>" +
                    "Size: " + game.buildings[i].size + "<br/>" +
                    "Range: " + game.buildings[i].nodeRadius * game.tileSize + "<br/>" +
                    "Health/HR/MaxHealth: " + game.buildings[i].health + "/" + game.buildings[i].healthRequests + "/" + game.buildings[i].maxHealth);
        }
    }

    // when there is an active symbol place building
    if (game.activeSymbol != -1) {
        var type = game.symbols[game.activeSymbol].imageID.substring(0, 1).toUpperCase() + game.symbols[game.activeSymbol].imageID.substring(1);
        var position = game.getTilePositionScrolled();
        if (game.canBePlaced(game.symbols[game.activeSymbol].size)) {
            game.addBuilding(position.x, position.y, game.symbols[game.activeSymbol].imageID, type, -1);
            engine.sounds["click"].play();
        }
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

function rightClick() {
    // unselect all currently selected buildings
    for (var i = 0; i < game.buildings.length; i++) {
        game.buildings[i].selected = false;
    }

    // unselect all currently selected ships
    for (var i = 0; i < game.ships.length; i++) {
        game.ships[i].selected = false;
    }

    $('#selection').html("");
    game.clearSymbols();
}

function onMouseDown() {

}

function onMouseUp() {
    var position = game.getTilePosition();

    for (var i = 0; i < game.buildings.length; i++) {
        if (game.buildings[i].built && game.buildings[i].selected && game.buildings[i].canMove) {
            // check if it can be placed
            if (game.canBePlaced(game.buildings[i].size, game.buildings[i])) {
                game.buildings[i].moving = true;
                game.buildings[i].tx = position.x;
                game.buildings[i].ty = position.y;
                game.buildings[i].calculateVector();
                //game.buildings[i].selected = false;
            }
        }
    }

    for (var i = 0; i < game.ships.length; i++) {
        if (game.ships[i].selected) {
            game.ships[i].status = 1;
            game.ships[i].tx = position.x * game.tileSize;
            game.ships[i].ty = position.y * game.tileSize;
        }
    }
}

function deactivateBuilding() {
    for (var i = 0; i < game.buildings.length; i++) {
        if (game.buildings[i].selected)
            game.buildings[i].active = false;
    }
}

function activateBuilding() {
    for (var i = 0; i < game.buildings.length; i++) {
        if (game.buildings[i].selected)
            game.buildings[i].active = true;
    }
}

function pauseGame() {
    game.paused = true;
}

function unpauseGame() {
    game.paused = false;
}

/*function zoomIn() {
    if (game.zoom < 1) {
        game.zoom *= 2;
        game.drawTerrain();
    }
}

function zoomOut() {
    if (game.zoom > .5) {
        game.zoom /= 2;
        game.drawTerrain();
    }
}*/

function restart() {
    stop();
    game.reset();
    run();
}

function gameloop() {
    engine.update();
    game.update();

    if (engine.canDraw()) {
        game.draw();
    }
}

/*function request() {
    var building = game.buildings[7];
    var center = game.base.getCenter();
    var packet = new Packet(center.x, center.y, "packet_health", "Health");
    packet.target = building;
    packet.currentTarget = game.base;
    packet.currentTarget = game.findRoute(packet);
    packet.calculateVector();
    game.packets.push(packet);
}*/

/**
 * Some helper functions below
 */

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

// Thanks to http://my.opera.com/GreyWyvern/blog/show.dml/1725165
Object.prototype.clone = function() {
    var newObj = (this instanceof Array) ? [] : {};
    for (var i in this) {
        if (i == 'clone') continue;
        if (this[i] && typeof this[i] == "object") {
            newObj[i] = this[i].clone();
        } else newObj[i] = this[i]
    } return newObj;
};
 