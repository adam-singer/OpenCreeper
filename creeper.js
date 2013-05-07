/*!
 * Open Creeper v1.1.0
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
        active: false
    },
    mouseGUI: {
        x: 0,
        y: 0
    },
    /**
     * @author Alexander Zeillinger
     *
     * Initializes the canvases and mouse, loads sounds and images.
     */
    init: function () {
        // main: at the top, contains everything but the terrain
        this.canvas["main"] = new Canvas($("#mainCanvas"));

        // buffer
        engine.canvas["buffer"] = new Canvas($("<canvas width='1280' height='720'>"));

        // tiles: at the bottom, contains the terrain and is only drawn once
        engine.canvas["tiles"] = new Canvas($("#tilesCanvas"));

        // gui
        engine.canvas["gui"] = new Canvas($("#guiCanvas"));

        // load sounds
        this.addSound("shot", "wav");
        this.addSound("click", "wav");
        this.addSound("music", "ogg");
        this.addSound("explosion", "wav");

        // load images
        this.imageSrcs = ["terrain", "cannon", "cannongun", "base", "collector", "reactor", "storage", "speed", "packet_ammo", "packet_health", "relay", "emitter", "creep",
            "mortar", "shell", "beam", "spore", "bomber", "bombership", "smoke", "explosion", "targetcursor", "sporetower", "forcefield", "shield"];
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

        for (var i = 0; i < this.imageSrcs.length; i++) {
            this.images[this.imageSrcs[i]] = new Image();
            this.images[this.imageSrcs[i]].onload = function() {
                if(++loadedImages >= numImages) {
                    callback();
                }
            };
            this.images[this.imageSrcs[i]].src = "images/" + this.imageSrcs[i] + ".png";
        }
    },
    addSound: function(name, type) {
        this.sounds[name] = [];
        for (var i = 0; i < 5; i++) {
            this.sounds[name][i] = new Audio("sounds/" + name + "." + type);
        }
    },
    playSound: function(name) {
        for(var i = 0; i < 5; i++)
        {
            if(this.sounds[name][i].ended == true || this.sounds[name][i].currentTime == 0)
            {
                this.sounds[name][i].play();
                return;
            }
        }
    },
    updateMouse: function (evt) {
        if (evt.pageX > this.canvas["main"].left && evt.pageX < this.canvas["main"].right && evt.pageY > this.canvas["main"].top && evt.pageY < this.canvas["main"].bottom) {
            this.mouse.x = evt.pageX - this.canvas["main"].left;
            this.mouse.y = evt.pageY - this.canvas["main"].top;
            var position = game.getTilePositionScrolled();
            $("#mouse").html("Mouse: " + this.mouse.x + "/" + this.mouse.y + " - " + position.x + "/" + position.y);
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
    }
};

var game = {
    tileSize: 16,
    speed: 1,
    zoom: 1,
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
    packetSpeed: 1,
    shellSpeed: 1,
    sporeSpeed: 1,
    buildingSpeed: .5,
    base: null,
    shipSpeed: 1,
    emitters: null,
    sporetowers: null,
    packetQueue: null,
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
            x: 120,
            y: 120
        }
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
    /**
     * @author Alexander Zeillinger
     *
     * Returns the position of the tile the mouse is hovering above.
     */
    getTilePositionScrolled: function () {
        return new Vector(
            Math.floor((engine.mouse.x - 640) / (this.tileSize * this.zoom)) + this.scroll.x,
            Math.floor((engine.mouse.y - 368) / (this.tileSize * this.zoom)) + this.scroll.y);
    },
    pause: function() {
        $('#pause').hide();
        $('#unpause').show();
        $('#paused').show();
        this.paused = true;
    },
    unpause: function() {
        $('#pause').show();
        $('#unpause').hide();
        $('#paused').hide();
        this.paused = false;
    },
    stop: function() {
        clearInterval(this.running);
    },
    run: function() {
        this.running = setInterval(update, 1000 / this.speed / engine.FPS);
        engine.animationRequest = requestAnimationFrame(draw);
    },
    restart: function() {
        this.stop();
        this.reset();
        this.run();
    },
    faster: function() {
        $('#buttonslower').show();
        $('#buttonfaster').hide();
        if (this.speed < 2) {
            this.speed *= 2;
            this.stop();
            this.run();
            this.updateSpeedElement();
        }
    },
    slower: function() {
        $('#buttonslower').hide();
        $('#buttonfaster').show();
        if (this.speed > 1) {
            this.speed /= 2;
            this.stop();
            this.run();
            this.updateSpeedElement();
        }
    },
    zoomIn: function() {
        if (this.zoom < 1) {
            this.zoom += .2;
            this.zoom = parseFloat(this.zoom.toFixed(2));
            this.drawTerrain();
            this.updateZoomElement();
        }
    },
    zoomOut: function() {
        if (this.zoom > .6) {
            this.zoom -= .2;
            this.zoom = parseFloat(this.zoom.toFixed(2));
            this.drawTerrain();
            this.updateZoomElement();
        }
    },
    createWorld: function () {
        this.world.tiles = new Array(this.world.size.x);
        for (var i = 0; i < this.world.size.x; i++) {
            this.world.tiles[i] = new Array(this.world.size.y);
        }

        var terrain = generateTerrain();

        for (var i = 0; i < this.world.size.x; i++) {
            for (var j = 0; j < this.world.size.y; j++) {
                this.world.tiles[i][j] = new Tile();
                this.world.tiles[i][j].height = Math.ceil(terrain[i][j] * 10); // generated values are to high, this compensates it
                if (this.world.tiles[i][j].height > 9)
                    this.world.tiles[i][j].height = 9;
                if (this.world.tiles[i][j].height < 0)
                    this.world.tiles[i][j].height = 0;
            }
        }

        do {
            var randomPosition = new Vector(
                Math.floor(Math.random() * (this.world.size.x - 9)),
                Math.floor(Math.random() * (this.world.size.y - 9)));
        } while (this.world.tiles[randomPosition.x][randomPosition.y].height < 5);

        this.scroll.x = randomPosition.x + 5;
        this.scroll.y = randomPosition.y + 5;

        var building = new Building(randomPosition.x, randomPosition.y, "base", "Base");
        building.health = 40;
        building.maxHealth = 40;
        building.nodeRadius = 10;
        building.built = true;
        building.size = 9;
        this.buildings.push(building);
        game.base = building;

        var height = this.world.tiles[building.x + 3][building.y + 3].height;
        for (var i = 0; i < 9; i++) {
            for (var j = 0; j < 9; j++) {
                this.world.tiles[building.x + i][building.y + j].height = height;
            }
        }

        this.calculateCollection();

        do {
            var randomPosition = new Vector(
                Math.floor(Math.random() * (this.world.size.x - 3)),
                Math.floor(Math.random() * (this.world.size.y - 3)));
        } while (this.world.tiles[randomPosition.x][randomPosition.y].height > 4);

        var emitter = new Emitter(randomPosition, 10);
        this.emitters.push(emitter);
        height = this.world.tiles[emitter.position.x][emitter.position.y].height;
        for (var i = 0; i < 3; i++) {
            for (var j = 0; j < 3; j++) {
                this.world.tiles[emitter.position.x + i][emitter.position.y + j].height = height;
            }
        }

        do {
            var randomPosition = new Vector(
                Math.floor(Math.random() * (this.world.size.x - 3)),
                Math.floor(Math.random() * (this.world.size.y - 3)));
        } while (this.world.tiles[randomPosition.x][randomPosition.y].height < 7);

        var sporetower = new Sporetower(randomPosition);
        this.sporetowers.push(sporetower);
        height = this.world.tiles[sporetower.position.x][sporetower.position.y].height;
        for (var i = 0; i < 3; i++) {
            for (var j = 0; j < 3; j++) {
                this.world.tiles[sporetower.position.x + i][sporetower.position.y + j].height = height;
            }
        }
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
            building.maxHealth = 5;
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

        // only explode building when it has been built
        if (building.built) {
            this.explosions.push(new Explosion(building.getCenter()));
            engine.playSound("explosion");
        }

        if (building.type == "Base") {
            $('#lose').toggle();
            this.stop();
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
    activateBuilding: function() {
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].selected)
                this.buildings[i].active = true;
        }
    },
    deactivateBuilding: function() {
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
        $("#mainCanvas").css('cursor', 'default');
    },
    setupUI: function () {
        this.symbols.push(new UISymbol(0 * 81, 0, "cannon", "Q", 3, 25, 6));
        this.symbols.push(new UISymbol(1 * 81, 0, "collector", "W", 2, 5, 4));
        this.symbols.push(new UISymbol(2 * 81, 0, "reactor", "E", 3, 50, 0));
        this.symbols.push(new UISymbol(3 * 81, 0, "storage", "R", 3, 8, 0));
        this.symbols.push(new UISymbol(4 * 81, 0, "shield", "T", 3, 50, 10));

        this.symbols.push(new UISymbol(0 * 81, 56, "relay", "A", 2, 10, 8));
        this.symbols.push(new UISymbol(1 * 81, 56, "mortar", "S", 3, 40, 12));
        this.symbols.push(new UISymbol(2 * 81, 56, "beam", "D", 3, 20, 12));
        this.symbols.push(new UISymbol(3 * 81, 56, "bomber", "F", 3, 75, 0));
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the terrain using a simple auto-tiling mechanism
     */
    drawTerrain: function () {
        engine.canvas["tiles"].clear();
        engine.canvas["tiles"].context.strokeStyle = "rgba(0,0,0,0.125)";
        engine.canvas["tiles"].context.lineWidth = 1;

        for (var i = Math.floor(-40 / this.zoom); i < Math.floor(40 / this.zoom); i++) {
            for (var j = Math.floor(-23 / this.zoom); j < Math.floor(22 / this.zoom); j++) {

                var iS = i + this.scroll.x;
                var jS = j + this.scroll.y;

                if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                    if (this.world.tiles[iS][jS].enabled) {

                        var height = this.world.tiles[iS][jS].height;

                        var up = 0, down = 0, left = 0, right = 0;
                        if (jS - 1 < 0)
                            up = 1;
                        else if (this.world.tiles[iS][jS - 1].height >= height && this.world.tiles[iS][jS - 1].enabled)
                            up = 1;
                        if (jS + 1 > this.world.size.y - 1)
                            down = 1;
                        else if (this.world.tiles[iS][jS + 1].height >= height && this.world.tiles[iS][jS + 1].enabled)
                            down = 1;
                        if (iS - 1 < 0)
                            left = 1;
                        else if (this.world.tiles[iS - 1][jS].height >= height && this.world.tiles[iS - 1][jS].enabled)
                            left = 1;
                        if (iS + 1 > this.world.size.x - 1)
                            right = 1;
                        else if (this.world.tiles[iS + 1][jS].height >= height && this.world.tiles[iS + 1][jS].enabled)
                            right = 1;

                        if (height > 0)
                            engine.canvas["tiles"].context.drawImage(engine.images["terrain"], 15 * (this.tileSize + 6) + 3, (this.world.tiles[iS][jS].height - 1) * (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 640 + i * this.tileSize * this.zoom, 368 + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        // save index for later use
                        this.world.tiles[iS][jS].index = index;
                        engine.canvas["tiles"].context.drawImage(engine.images["terrain"], index * (this.tileSize + 6) + 3, this.world.tiles[iS][jS].height * (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 640 + i * this.tileSize * this.zoom, 368 + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);

                        // grid (debug)
                        //engine.canvas["tiles"].context.strokeRect(i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
                    }
                    /*else {
                        engine.canvas["tiles"].context.fillStyle = "#000";
                        engine.canvas["tiles"].context.fillRect(640 + i * this.tileSize, 368 + j * this.tileSize, this.tileSize, this.tileSize);
                    }*/
                }
            }
        }
    },
    shoot: function () {
        for (var t = 0; t < this.buildings.length; t++) {
            if (this.buildings[t].canShoot && this.buildings[t].active && !this.buildings[t].moving) {
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
                        var targets = [];
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
                            this.buildings[t].targetAngle = Math.atan2(dy, dx) + Math.PI / 2;
                            this.buildings[t].weaponTargetPosition = new Vector(targets[0].x, targets[0].y);
                            this.buildings[t].ammo -= 1;
                            this.buildings[t].shooting = true;
                            this.smokes.push(new Smoke(new Vector(targets[0].x * this.tileSize + this.tileSize / 2, targets[0].y * this.tileSize + this.tileSize / 2)));
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
                        engine.playSound("shot");
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
                            this.buildings[t].weaponTargetPosition = sporeCenter;
                            this.buildings[t].ammo -= .1;
                            this.buildings[t].shooting = true;
                            this.spores[i].health -= 2;
                            if (this.spores[i].health <= 0) {
                                this.spores[i].remove = true;
                                engine.playSound("explosion");
                                this.explosions.push(new Explosion(sporeCenter));
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
        for (var i = building.x - 3; i < building.x + 5; i++) {
            for (var j = building.y - 3; j < building.y + 5; j++) {
                if (i > -1 && i < game.world.size.x && j > -1 && j < game.world.size.y) {
                    if (Math.pow((i * this.tileSize + this.tileSize / 2) - (building.x * this.tileSize + this.tileSize), 2) + Math.pow((j * this.tileSize + this.tileSize / 2) - (building.y * this.tileSize + this.tileSize), 2) < Math.pow(this.tileSize * 4, 2)) {
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
        if (this.creeperTimer > (125 / this.speed)) {
            this.creeperTimer -= (125 / this.speed);

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
        var neighbours = [], centerI, centerNode;
        //if (node.built) {
        for (var i = 0; i < this.buildings.length; i++) {
            if (this.buildings[i].x == node.x && this.buildings[i].y == node.y) {
                // console.log("is me");
            } else {
                // if the node is not the target AND built it is a valid neighbour
                // also the neighbour must not be moving
                if (!this.buildings[i].moving && this.buildings[i].type != "Base") {
                     if (this.buildings[i] != target) {
                          if (this.buildings[i].built) {
                              centerI = this.buildings[i].getCenter();
                              centerNode = node.getCenter();
                              var distance = Helper.distance(centerI, centerNode);

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
                         var distance = Helper.distance(centerI, centerNode);

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

            //console.log("3) new routes: " + newRoutes);
            //console.log("4) total routes: " + routes.length);

            // find routes that end at the same node, remove those with the longer distance travelled
            //var remove = [];
            for (var i = 0; i < routes.length; i++) {
                for (var j = 0; j < routes.length; j++) {
                    if (i != j) {
                        if (routes[i].nodes[routes[i].nodes.length - 1] == routes[j].nodes[routes[j].nodes.length - 1]) {
                            //console.log("5) found duplicate route to " + routes[i].nodes[routes[i].nodes.length - 1].type + ", removing longer");
                            if (routes[i].distanceTravelled < routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[j]), 1);
                                //remove.push(routes[j]);
                            }
                            else if (routes[i].distanceTravelled > routes[j].distanceTravelled) {
                                routes.splice(routes.indexOf(routes[i]), 1);
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
        if (routes.length > 0) {
            //packet.currentTarget = routes[0].nodes[1];

            // adjust speed if packet is travelling between relays
            if (routes[0].nodes[1].type == "Relay") {
                packet.speedMultiplier = 2;
            }
            else {
                packet.speedMultiplier = 1;
            }

            return routes[0].nodes[1];
        }
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
            this.packets.push(packet);
            this.updateEnergyElement();
        } else {
            packet.remove = true;
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Checks if a building can be placed on the current tile.
     */
    canBePlaced: function (size, building) {
        var collision = false;

        var position = this.getTilePositionScrolled();

        if (position.x > -1 && position.x < this.world.size.x - size + 1 && position.y > -1 && position.y < this.world.size.y - size + 1) {
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

                if (((cx1 >= x1 && cx1 <= x2) || (cx2 >= x1 && cx2 <= x2)) && ((cy1 >= y1 && cy1 <= y2) || (cy2 >= y1 && cy2 <= y2))) {
                    collision = true;
                    break;
                }
            }

            // 2. check if all tiles have the same height and are not corners
            if (!collision) {
                for (var i = position.x; i < position.x + size; i++) {
                    for (var j = position.y; j < position.y + size; j++) {
                        if (i > -1 && i < this.world.size.x && j > -1 && j < this.world.size.y) {
                            if (!this.world.tiles[i][j].enabled) {
                                collision = true;
                                break;
                            }
                            if (this.world.tiles[i][j].height != height) {
                                collision = true;
                                break;
                            }
                            if (!(this.world.tiles[i][j].index == 7 || this.world.tiles[i][j].index == 11 || this.world.tiles[i][j].index == 13 || this.world.tiles[i][j].index == 14 || this.world.tiles[i][j].index == 15)) {
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
            if (this.buildings[i].active && !this.buildings[i].moving) {
                this.buildings[i].requestTimer++;
                // request health
                if (this.buildings[i].type != "Base") {
                    var healthAndRequestDelta = this.buildings[i].maxHealth - this.buildings[i].health - this.buildings[i].healthRequests;
                    if (healthAndRequestDelta > 0 && this.buildings[i].requestTimer > 50) {
                        this.buildings[i].requestTimer = 0;
                        this.queuePacket(this.buildings[i], "Health");
                    }
                }
                // request ammo
                if (this.buildings[i].canShoot) {
                    var ammoAndRequestDelta = this.buildings[i].maxAmmo - this.buildings[i].ammo - this.buildings[i].ammoRequests;
                    if (ammoAndRequestDelta > 0 && this.buildings[i].requestTimer > 50 && this.buildings[i].built) {
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
            this.drawTerrain();
        }

        // scroll right
        if (this.scrolling.right) {
            if (this.scroll.x < this.world.size.x)
                this.scroll.x += 1;
            this.drawTerrain();
        }

        // scroll up
        if (this.scrolling.up) {
            if (this.scroll.y > 0)
                this.scroll.y -= 1;
            this.drawTerrain();
        }

        // scroll down
        if (this.scrolling.down) {
            if (this.scroll.y < this.world.size.y)
                this.scroll.y += 1;
            this.drawTerrain();
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the green collection areas of Collectors.
     */
    drawCollectionAreas: function() {
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.globalAlpha = .5;

        for (var i = Math.floor(-40 / this.zoom); i < Math.floor(40 / this.zoom); i++) {
            for (var j = Math.floor(-23 / this.zoom); j < Math.floor(22 / this.zoom); j++) {

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
                        engine.canvas["buffer"].context.drawImage(engine.images["terrain"], index * (this.tileSize + 6) + 3, 10 * (this.tileSize + 6) + 3, this.tileSize, this.tileSize, 640 + i * this.tileSize * this.zoom, 368 + j * this.tileSize * this.zoom, this.tileSize * this.zoom, this.tileSize * this.zoom);
                    }
                }
            }
        }
        engine.canvas["buffer"].context.restore();
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the creep.
     */
    drawCreep: function() {
        engine.canvas["buffer"].context.font = '9px';
        engine.canvas["buffer"].context.lineWidth = 1;
        engine.canvas["buffer"].context.fillStyle = '#fff';

        for (var i = Math.floor(-40 / this.zoom); i < Math.floor(40 / this.zoom); i++) {
            for (var j = Math.floor(-23 / this.zoom); j < Math.floor(22 / this.zoom); j++) {

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
                        //    engine.canvas["buffer"].context.drawImage(engine.images["creep"], 15 * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, i * this.tileSize, j * this.tileSize, this.tileSize, this.tileSize);
                        //}

                        var index = (8 * down) + (4 * left) + (2 * up) + right;
                        engine.canvas["buffer"].context.drawImage(engine.images["creep"], index * this.tileSize, (creep - 1) * this.tileSize, this.tileSize, this.tileSize, 640 + i * this.tileSize * game.zoom, 368 + j * this.tileSize * game.zoom, this.tileSize * game.zoom, this.tileSize * game.zoom);
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
     * @author Alexander Zeillinger
     *
     * When a building from the GUI is selected this draws some info whether it can be build on the current tile,
     * the collection preview of Collectors and connections to other buildings
     */
    drawPositionInfo: function () {
        var positionScrolled = this.getTilePositionScrolled();
        var drawPosition = Helper.tiled2screen(positionScrolled);

        // draw collection preview
        if (this.canBePlaced(this.symbols[this.activeSymbol].size) &&
            (this.symbols[this.activeSymbol].imageID == "collector" ||
             this.symbols[this.activeSymbol].imageID == "cannon" ||
             this.symbols[this.activeSymbol].imageID == "mortar" ||
             this.symbols[this.activeSymbol].imageID == "shield" ||
             this.symbols[this.activeSymbol].imageID == "beam") ) {
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.globalAlpha = .25;

            var radius = this.symbols[this.activeSymbol].radius;
            for (var i = -radius; i < radius; i++) {
                for (var j = -radius; j < radius; j++) {

                    var iS = positionScrolled.x + 1 + i;
                    var jS = positionScrolled.y + 1 + j;

                    var drawPositionCollection = Helper.tiled2screen(new Vector(iS, jS));

                    if (iS > -1 && iS < this.world.size.x && jS > -1 && jS < this.world.size.y) {

                        if (Math.pow(iS + .5 - (positionScrolled.x + 1), 2) + Math.pow(jS + .5 - (positionScrolled.y + 1), 2) < Math.pow(radius, 2)) {
                            if (this.symbols[this.activeSymbol].imageID == "collector") {
                                if (this.world.tiles[iS][jS].height == this.world.tiles[positionScrolled.x][positionScrolled.y].height) {
                                    engine.canvas["buffer"].context.fillStyle = "#fff";
                                }
                                else {
                                    engine.canvas["buffer"].context.fillStyle = "#f00";
                                }
                            }
                            if (this.symbols[this.activeSymbol].imageID == "cannon") {
                                if (this.world.tiles[iS][jS].height <= this.world.tiles[positionScrolled.x][positionScrolled.y].height) {
                                    engine.canvas["buffer"].context.fillStyle = "#fff";
                                }
                                else {
                                    engine.canvas["buffer"].context.fillStyle = "#f00";
                                }
                            }
                            if (this.symbols[this.activeSymbol].imageID == "mortar" ||
                                this.symbols[this.activeSymbol].imageID == "shield" ||
                                this.symbols[this.activeSymbol].imageID == "beam") {
                                engine.canvas["buffer"].context.fillStyle = "#fff";
                            }
                            engine.canvas["buffer"].context.fillRect(drawPositionCollection.x, drawPositionCollection.y, this.tileSize * this.zoom, this.tileSize * this.zoom);
                        }

                    }
                }
            }
            engine.canvas["buffer"].context.restore();
        }

        if (positionScrolled.x > -1 && positionScrolled.x < this.world.size.x && positionScrolled.y > -1 && positionScrolled.y < this.world.size.y) {
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.globalAlpha = .5;

            // draw green or red box
            // make sure there isn't a building on this tile yet
            if (this.canBePlaced(this.symbols[this.activeSymbol].size)) {
                engine.canvas["buffer"].context.strokeStyle = "#0f0";
            }
            else {
                engine.canvas["buffer"].context.strokeStyle = "#f00";
            }
            engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom, this.tileSize * this.symbols[this.activeSymbol].size * this.zoom);

            // draw building
            engine.canvas["buffer"].context.drawImage(engine.images[this.symbols[this.activeSymbol].imageID], drawPosition.x, drawPosition.y, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom, this.symbols[this.activeSymbol].size * this.tileSize * this.zoom);
            if (this.symbols[this.activeSymbol].imageID == "cannon")
                engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], drawPosition.x, drawPosition.y, 48 * this.zoom, 48 * this.zoom);

            engine.canvas["buffer"].context.restore();

            // draw lines to close buildings
            for (var i = 0; i < this.buildings.length; i++) {
                var center = this.buildings[i].getCenter();
                var drawCenter = Helper.real2screen(center);

                var centerCursorX = (positionScrolled.x * this.tileSize) + ((this.tileSize / 2) * this.symbols[this.activeSymbol].size);
                var centerCursorY = (positionScrolled.y * this.tileSize) + ((this.tileSize / 2) * this.symbols[this.activeSymbol].size);

                var allowedDistance = 10 * this.tileSize;
                if (this.buildings[i].type == "Relay" && this.symbols[this.activeSymbol].imageID == "relay") {
                    allowedDistance = 20 * this.tileSize;
                }

                if (Math.pow(center.x - centerCursorX, 2) + Math.pow(center.y - centerCursorY, 2) < Math.pow(allowedDistance, 2)) {
                    var lineToTarget = Helper.tiled2screen(positionScrolled);
                    engine.canvas["buffer"].context.strokeStyle = '#000';
                    engine.canvas["buffer"].context.lineWidth = 2;
                    engine.canvas["buffer"].context.beginPath();
                    engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
                    engine.canvas["buffer"].context.lineTo(lineToTarget.x + (this.tileSize / 2) * this.symbols[this.activeSymbol].size * this.zoom, lineToTarget.y + (this.tileSize / 2) * this.symbols[this.activeSymbol].size * this.zoom);
                    engine.canvas["buffer"].context.stroke();

                    engine.canvas["buffer"].context.strokeStyle = '#fff';
                    engine.canvas["buffer"].context.lineWidth = 1;
                    engine.canvas["buffer"].context.beginPath();
                    engine.canvas["buffer"].context.moveTo(drawCenter.x, drawCenter.y);
                    engine.canvas["buffer"].context.lineTo(lineToTarget.x + (this.tileSize / 2) * this.symbols[this.activeSymbol].size * this.zoom, lineToTarget.y + (this.tileSize / 2) * this.symbols[this.activeSymbol].size * this.zoom);
                    engine.canvas["buffer"].context.stroke();
                }
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
            var position = Helper.tiled2screen(this.getTilePositionScrolled());
            engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], position.x - this.tileSize, position.y - this.tileSize);
        }
    },
    /**
     * @author Alexander Zeillinger
     *
     * Draws the GUI with symbols, height and creep meter.
     */
    drawGUI: function () {
        var position = game.getTilePositionScrolled();

        engine.canvas["gui"].clear();
        for (var i = 0; i < this.symbols.length; i++) {
            this.symbols[i].draw(engine.canvas["gui"].context);
        }

        if (position.x > 0 && position.x < this.world.size.x && position.y > 0 && position.y < this.world.size.y) {
            // draw height and creep meter
            engine.canvas["gui"].context.fillStyle = '#fff';
            engine.canvas["gui"].context.font = '9px';
            engine.canvas["gui"].context.textAlign = 'right';
            engine.canvas["gui"].context.strokeStyle = '#fff';
            engine.canvas["gui"].context.lineWidth = 1;
            engine.canvas["gui"].context.fillStyle = "rgba(205, 133, 63, 1)";
            engine.canvas["gui"].context.fillRect(555, 110, 25, -this.world.tiles[position.x][position.y].height * 10);
            engine.canvas["gui"].context.fillStyle = "rgba(0, 0, 255, 1)";
            engine.canvas["gui"].context.fillRect(555, 110 - this.world.tiles[position.x][position.y].height * 10, 25, -this.world.tiles[position.x][position.y].creep);
            engine.canvas["gui"].context.fillStyle = "rgba(255, 255, 255, 1)";
            for (var i = 1; i < 11; i++) {
                engine.canvas["gui"].context.fillText(i.toString(), 550, 120 - i * 10);
                engine.canvas["gui"].context.beginPath();
                engine.canvas["gui"].context.moveTo(555, 120 - i * 10);
                engine.canvas["gui"].context.lineTo(580, 120 - i * 10);
                engine.canvas["gui"].context.stroke();
            }
            engine.canvas["gui"].context.textAlign = 'left';
            engine.canvas["gui"].context.fillText(this.world.tiles[position.x][position.y].creep.toFixed(2), 605, 10);
        }
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
function UISymbol(pX, pY, pImage, pKey, pSize, pPackets, pRadius) {
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
        this.hovered = (engine.mouseGUI.x > this.x && engine.mouseGUI.x < this.x + this.width && engine.mouseGUI.y > this.y && engine.mouseGUI.y < this.y + this.height);
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
    this.weaponTargetPosition = new Vector(0, 0);
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
    this.moveTargetPosition = new Vector(0, 0);
    this.canMove = false;
    this.canShoot = false;
    this.ship = null;
    this.updateHoverState = function () {
        var position = Helper.tiled2screen(new Vector(this.x, this.y));
        this.hovered = (engine.mouse.x > position.x &&
            engine.mouse.x < position.x + game.tileSize * this.size - 1 &&
            engine.mouse.y > position.y &&
            engine.mouse.y < position.y + game.tileSize * this.size - 1);

        return this.hovered;
    };
    this.drawBox = function () {
        if (this.hovered || this.selected) {
            var position = Helper.tiled2screen(new Vector(this.x, this.y));
            engine.canvas["buffer"].context.lineWidth = 1;
            engine.canvas["buffer"].context.strokeStyle = "#000";
            engine.canvas["buffer"].context.strokeRect(position.x, position.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
        }
    };
    this.move = function () {
        if (this.moving) {
            this.x += this.speed.x;
            this.y += this.speed.y;
            if (this.x * game.tileSize > this.moveTargetPosition.x * game.tileSize - 3 &&
                this.x * game.tileSize < this.moveTargetPosition.x * game.tileSize + 3 &&
                this.y * game.tileSize > this.moveTargetPosition.y * game.tileSize - 3 &&
                this.y * game.tileSize < this.moveTargetPosition.y * game.tileSize + 3) {
                this.moving = false;
                this.x = this.moveTargetPosition.x;
                this.y = this.moveTargetPosition.y;
            }
        }
    };
    this.calculateVector = function () {
        if (this.moveTargetPosition.x != this.x || this.moveTargetPosition.y != this.y) {
            var targetPosition = new Vector(this.moveTargetPosition.x * game.tileSize, this.moveTargetPosition.y * game.tileSize);
            var ownPosition = new Vector(this.x * game.tileSize, this.y * game.tileSize);
            var delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
            var distance = Helper.distance(targetPosition, ownPosition);

            this.speed.x = (delta.x / distance) * game.buildingSpeed * game.speed / game.tileSize;
            this.speed.y = (delta.y / distance) * game.buildingSpeed * game.speed / game.tileSize;
        }
    };
    this.getCenter = function () {
        return new Vector(
            this.x * game.tileSize + (game.tileSize / 2) * this.size,
            this.y * game.tileSize + (game.tileSize / 2) * this.size);
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
            }
        }
    };
    this.drawRadius = function () {
        if (this.selected) {
            var center = Helper.real2screen(this.getCenter());

            // node radius
            engine.canvas["buffer"].context.strokeStyle = "#000";
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.arc(center.x, center.y, this.nodeRadius * game.tileSize * game.zoom, 0, Math.PI * 2, true);
            engine.canvas["buffer"].context.closePath();
            engine.canvas["buffer"].context.stroke();

            // weapon radius
            if (this.canShoot) {
                engine.canvas["buffer"].context.strokeStyle = "#f00";
                engine.canvas["buffer"].context.beginPath();
                engine.canvas["buffer"].context.arc(center.x, center.y, this.weaponRadius * game.tileSize * game.zoom, 0, Math.PI * 2, true);
                engine.canvas["buffer"].context.closePath();
                engine.canvas["buffer"].context.stroke();
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
        var center = Helper.real2screen(this.getCenter());
        var positionScrolled = game.getTilePositionScrolled();
        var drawPosition = Helper.tiled2screen(positionScrolled);

        // only armed buildings can move
        if (this.built && this.selected && this.canMove) {
            if (game.canBePlaced(this.size, this))
                engine.canvas["buffer"].context.strokeStyle = "rgba(0,255,0,0.5)";
            else
                engine.canvas["buffer"].context.strokeStyle = "rgba(255,0,0,0.5)";

            // draw rectangle
            engine.canvas["buffer"].context.strokeRect(drawPosition.x, drawPosition.y, game.tileSize * this.size * game.zoom, game.tileSize * this.size * game.zoom);
            // draw line
            engine.canvas["buffer"].context.strokeStyle = "rgba(255,255,255,0.5)";
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(center.x, center.y);
            engine.canvas["buffer"].context.lineTo(drawPosition.x + (game.tileSize / 2) * this.size * game.zoom, drawPosition.y + (game.tileSize / 2) * this.size * game.zoom);
            engine.canvas["buffer"].context.stroke();
        }
    };
    this.shield = function () {
        if (this.built && this.type == "Shield" && !this.moving) {
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
        var position = Helper.tiled2screen(new Vector(this.x, this.y));
        var center = Helper.real2screen(this.getCenter());

        if (!this.built) {
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.globalAlpha = .5;
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
            if (this.type == "Cannon") {
                engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
            }
            engine.canvas["buffer"].context.restore();
        }
        else {
            engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x, position.y, engine.images[this.imageID].width * game.zoom, engine.images[this.imageID].height * game.zoom);
            if (this.type == "Cannon") {
                engine.canvas["buffer"].context.save();
                engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
                engine.canvas["buffer"].context.rotate(this.targetAngle);
                engine.canvas["buffer"].context.drawImage(engine.images["cannongun"], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
                engine.canvas["buffer"].context.restore();
            }
            if (this.type == "Shield" && !this.moving) {
                engine.canvas["buffer"].context.drawImage(engine.images["forcefield"], center.x - 168, center.y - 168);
            }
        }

        // draw ammo bar
        if (this.canShoot) {
            engine.canvas["buffer"].context.fillStyle = '#000';
            engine.canvas["buffer"].context.fillRect(position.x + 2, position.y, 44 * game.zoom, 4);
            engine.canvas["buffer"].context.fillStyle = '#f00';
            engine.canvas["buffer"].context.fillRect(position.x + 3, position.y + 1, (42 * game.zoom / this.maxAmmo) * this.ammo, 2);
        }

        // draw health bar (only if health is below maxHealth)
        if (this.health < this.maxHealth) {
            engine.canvas["buffer"].context.fillStyle = '#000';
            engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + game.tileSize * game.zoom * this.size - 4, game.tileSize * game.zoom* this.size - 4, 4);
            engine.canvas["buffer"].context.fillStyle = '#0f0';
            engine.canvas["buffer"].context.fillRect(position.x + 3, position.y + game.tileSize * game.zoom * this.size - 3, ((game.tileSize * game.zoom * this.size - 6) / this.maxHealth) * this.health, 2);
        }

        // draw shots
        if (this.shooting) {
            if (this.type == "Cannon") {
                var targetPosition = Helper.tiled2screen(this.weaponTargetPosition);
                engine.canvas["buffer"].context.strokeStyle = "#f00";
                engine.canvas["buffer"].context.beginPath();
                engine.canvas["buffer"].context.moveTo(center.x, center.y);
                engine.canvas["buffer"].context.lineTo(targetPosition.x, targetPosition.y);
                engine.canvas["buffer"].context.stroke();
            }
            if (this.type == "Beam") {
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
        }

        // draw inactive sign
        if (!this.active) {
            var center = this.getCenter();
            engine.canvas["buffer"].context.strokeStyle = "#F00";
            engine.canvas["buffer"].context.lineWidth = 2;

            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.arc(center.x, center.y, (game.tileSize / 2) * this.size, 0, Math.PI * 2, true);
            engine.canvas["buffer"].context.closePath();
            engine.canvas["buffer"].context.stroke();

            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.moveTo(this.x * game.tileSize, this.y * game.tileSize + game.tileSize * this.size);
            engine.canvas["buffer"].context.lineTo(this.x * game.tileSize + game.tileSize * this.size, this.y * game.tileSize);
            engine.canvas["buffer"].context.stroke();
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
    this.speedMultiplier = 1;
    this.move = function () {
        this.calculateVector();

        this.x += this.speed.x;
        this.y += this.speed.y;

        var centerTarget = this.currentTarget.getCenter();
        if (this.x > centerTarget.x - 1 && this.x < centerTarget.x + 1 && this.y > centerTarget.y - 1 && this.y < centerTarget.y + 1) {
            // if the final node was reached deliver and remove
            if (this.currentTarget == this.target) {
                //console.log("target node reached!");
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
                                this.target.ship = ship;
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
                if (this.currentTarget == null)
                    this.remove = true;
            }
        }
    };
    this.calculateVector = function () {
        var targetPosition = this.currentTarget.getCenter();
        var ownPosition = new Vector(this.x, this.y);
        var delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
        var distance = Helper.distance(targetPosition, ownPosition);

        this.speed.x = (delta.x / distance) * game.packetSpeed * game.speed * this.speedMultiplier;
        this.speed.y = (delta.y / distance) * game.packetSpeed * game.speed * this.speedMultiplier;

        if (Math.abs(this.speed.x) > Math.abs(delta.x))
            this.speed.x = delta.x;
        if (Math.abs(this.speed.y) > Math.abs(delta.y))
            this.speed.y = delta.y;
    };
    this.draw = function () {
        var position = Helper.real2screen(new Vector(this.x, this.y));
        engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], position.x - 8 * game.zoom, position.y - 8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
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
        var targetPosition = new Vector(this.tx, this.ty);
        var ownPosition = new Vector(this.x, this.y);
        var delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
        var distance = Helper.distance(targetPosition, ownPosition);

        this.speed.x = (delta.x / distance) * game.shellSpeed * game.speed;
        this.speed.y = (delta.y / distance) * game.shellSpeed * game.speed;
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

            game.explosions.push(new Explosion(new Vector(this.tx, this.ty)));
            engine.playSound("explosion");

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
        var position = Helper.real2screen(new Vector(this.x, this.y));
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.translate(position.x + 8 * game.zoom, position.y + 8 * game.zoom);
        engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.rotation));
        engine.canvas["buffer"].context.drawImage(engine.images["shell"], -8 * game.zoom, -8 * game.zoom, 16 * game.zoom, 16 * game.zoom);
        engine.canvas["buffer"].context.restore();
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
        var targetPosition = new Vector(this.tx, this.ty);
        var ownPosition = new Vector(this.x, this.y);
        var delta = new Vector(targetPosition.x - ownPosition.x, targetPosition.y - ownPosition.y);
        var distance = Helper.distance(targetPosition, ownPosition);

        this.speed.x = (delta.x / distance) * game.sporeSpeed * game.speed;
        this.speed.y = (delta.y / distance) * game.sporeSpeed * game.speed;
    };
    this.getCenter = function () {
        return new Vector(this.x - 16, this.y - 16);
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
        this.x += this.speed.x;
        this.y += this.speed.y;
        if (this.x > this.tx - 2 && this.x < this.tx + 2 && this.y > this.ty - 2 && this.y < this.ty + 2) {
            // if the target is reached explode and remove
            this.remove = true;
            engine.playSound("explosion");

            for (var i = Math.floor(this.tx / game.tileSize) - 2; i < Math.floor(this.tx / game.tileSize) + 2; i++) {
                for (var j = Math.floor(this.ty / game.tileSize) - 2; j < Math.floor(this.ty / game.tileSize) + 2; j++) {
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
    this.draw = function () {
        var position = Helper.real2screen(new Vector(this.x, this.y));
        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.translate(position.x, position.y);
        engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.rotation));
        engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], -16 * game.zoom, -16 * game.zoom, 32 * game.zoom, 32 * game.zoom);
        engine.canvas["buffer"].context.restore();
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
    this.maxAmmo = 5;
    this.ammo = 5;
    this.type = pType;
    this.home = pHome;
    this.status = 0; // 0 idle, 1 attacking, 2 returning
    this.trailTimer = 0;
    this.weaponTimer = 0;
    this.getCenter = function () {
        return new Vector(this.x + 24, this.y + 24);
    };
    this.updateHoverState = function () {
        var position = Helper.real2screen(new Vector(this.x, this.y));
        this.hovered = (engine.mouse.x > position.x &&
            engine.mouse.x < position.x + 47 &&
            engine.mouse.y > position.y &&
            engine.mouse.y < position.y + 47);

        return this.hovered;
    };
    this.turnToTarget = function () {
        var delta = new Vector(this.tx - this.x, this.ty - this.y);
        var angleToTarget = Helper.rad2deg(Math.atan2(delta.y, delta.x));

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

            this.x += this.speed.x;
            this.y += this.speed.y;

            if (this.x > this.tx - 2 && this.x < this.tx + 2 && this.y > this.ty - 2 && this.y < this.ty + 2) {
                if (this.status == 1) { // attacking
                    if (this.weaponTimer >= 10) {
                        this.weaponTimer = 0;
                        game.explosions.push(new Explosion(new Vector(this.tx, this.ty)));
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
        var position = Helper.real2screen(new Vector(this.x, this.y));

        if (this.hovered) {
            engine.canvas["buffer"].context.strokeStyle = "#f00";
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, Math.PI * 2, true);
            engine.canvas["buffer"].context.closePath();
            engine.canvas["buffer"].context.stroke();
        }

        if (this.status == 1 && this.selected) {
            engine.canvas["buffer"].context.strokeStyle = "#fff";
            engine.canvas["buffer"].context.beginPath();
            engine.canvas["buffer"].context.arc(position.x + 24 * game.zoom, position.y + 24 * game.zoom, 24 * game.zoom, 0, Math.PI * 2, true);
            engine.canvas["buffer"].context.closePath();
            engine.canvas["buffer"].context.stroke();

            var cursorPosition = Helper.real2screen(new Vector(this.tx, this.ty));
            engine.canvas["buffer"].context.save();
            engine.canvas["buffer"].context.globalAlpha = .5;
            engine.canvas["buffer"].context.drawImage(engine.images["targetcursor"], cursorPosition.x - game.tileSize * game.zoom, cursorPosition.y - game.tileSize * game.zoom, 48 * game.zoom, 48 * game.zoom);
            engine.canvas["buffer"].context.restore();
        }

        // draw ship

        engine.canvas["buffer"].context.save();
        engine.canvas["buffer"].context.translate(position.x + 24 * game.zoom, position.y + 24 * game.zoom);
        engine.canvas["buffer"].context.rotate(Helper.deg2rad(this.angle + 90));
        engine.canvas["buffer"].context.drawImage(engine.images[this.imageID], -24 * game.zoom, -24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
        engine.canvas["buffer"].context.restore();

        // draw ammo bar
        engine.canvas["buffer"].context.fillStyle = '#000';
        engine.canvas["buffer"].context.fillRect(position.x + 2, position.y + 2, 44 * game.zoom, 4);
        engine.canvas["buffer"].context.fillStyle = '#fff';
        engine.canvas["buffer"].context.fillRect(position.x + 3, position.y + 3, (42 * game.zoom / this.maxAmmo) * this.ammo, 2);
    };
}
Ship.prototype = new GameObject;
Ship.prototype.constructor = Ship;

/**
 * @author Alexander Zeillinger
 *
 * Emitter
 */
function Emitter(pVector, pS) {
    this.position = pVector;
    this.strength = pS;
    this.draw = function () {
        var position = Helper.tiled2screen(this.position);
        engine.canvas["buffer"].context.drawImage(engine.images["emitter"], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
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
function Sporetower(pVector) {
    this.position = pVector;
    this.health = 100;
    this.getCenter = function () {
        return new Vector(
            this.position.x * game.tileSize + 24,
            this.position.y * game.tileSize + 24);
    };
    this.draw = function () {
        var position = Helper.tiled2screen(this.position);
        engine.canvas["buffer"].context.drawImage(engine.images["sporetower"], position.x, position.y, 48 * game.zoom, 48 * game.zoom);
    };
    this.spawn = function () {
        do {
            var target = game.buildings[Math.floor(Math.random() * game.buildings.length)];
        } while (!target.built);
        var spore = new Spore(this.getCenter().x, this.getCenter().y, "spore", target.getCenter().x, target.getCenter().y);
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
function Smoke(pVector) {
    this.position = new Vector(pVector.x, pVector.y);
    this.frame = 0;
    this.draw = function () {
        var position = Helper.real2screen(this.position);
        engine.canvas["buffer"].context.drawImage(engine.images["smoke"], (this.frame % 8) * 128, Math.floor(this.frame / 8) * 128, 128, 128, position.x - 24 * game.zoom, position.y - 24 * game.zoom, 48 * game.zoom, 48 * game.zoom);
    };
}

/**
 * @author Alexander Zeillinger
 *
 * Explosion
 *
 * Created on explosion of buildings, spores and shells
 */
function Explosion(pVector) {
    this.position = new Vector(pVector.x, pVector.y);
    this.frame = 0;
    this.draw = function () {
        var position = Helper.real2screen(this.position);
        engine.canvas["buffer"].context.drawImage(engine.images["explosion"], (this.frame % 8) * 64, Math.floor(this.frame / 8) * 64, 64, 64, position.x - 32 * game.zoom, position.y - 32 * game.zoom, 64 * game.zoom, 64 * game.zoom);
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

/**
 * @author Alexander Zeillinger
 *
 * Object to handle canvas
 */
function Canvas(pElement) {
    this.element = pElement;
    this.context = pElement[0].getContext('2d');
    this.top = pElement.offset().top;
    this.left = pElement.offset().left;
    this.bottom = this.top + pElement.height();
    this.right = this.left + pElement.width();
    this.clear = function() {
        this.context.clearRect(0,0, this.element[0].width, this.element[0].height);
    }
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
        $("#mainCanvas").css('cursor', 'none');
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
            game.unpause();
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

    if(evt.keyCode == 37)
        game.scrolling.left = true;
    if(evt.keyCode == 38)
        game.scrolling.up = true;
    if(evt.keyCode == 39)
        game.scrolling.right = true;
    if(evt.keyCode == 40)
        game.scrolling.down = true;

    var position = game.getTilePositionScrolled();

    // lower terrain ("N")
    if (evt.keyCode == 78) {
        if (game.world.tiles[position.x][position.y].height > 1) {
            game.world.tiles[position.x][position.y].height -= 1;
            game.drawTerrain();
        }
    }

    // raise terrain ("M")
    if (evt.keyCode == 77) {
        if (game.world.tiles[position.x][position.y].height < 9) {
            game.world.tiles[position.x][position.y].height += 1;
            game.drawTerrain();
        }
    }

    // enable/disable terrain ("B")
    if (evt.keyCode == 66) {
        game.world.tiles[position.x][position.y].enabled = !game.world.tiles[position.x][position.y].enabled;
        game.drawTerrain();
    }

}

function onKeyUp(evt) {
    if(evt.keyCode == 37)
      game.scrolling.left = false;
    if(evt.keyCode == 38)
      game.scrolling.up = false;
    if(evt.keyCode == 39)
      game.scrolling.right = false;
    if(evt.keyCode == 40)
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
        $("#mainCanvas").css('cursor', 'none');
    }
}

function onClick(evt) {
    var position = game.getTilePositionScrolled();

    for (var i = 0; i < game.ships.length; i++) {
        if (game.ships[i].selected) {
            if (position.x - 1 == game.ships[i].home.x &&
                position.y - 1 == game.ships[i].home.y) {
                game.ships[i].tx = (position.x - 1) * game.tileSize;
                game.ships[i].ty = (position.y - 1) * game.tileSize;
                game.ships[i].status = 2;
            }
            else {
                game.ships[i].tx = position.x * game.tileSize;
                game.ships[i].ty = position.y * game.tileSize;
                game.ships[i].status = 1;
            }

        }
    }

    var shipSelected = false;
    // select a ship if hovered
    for (var i = 0; i < game.ships.length; i++) {
        game.ships[i].selected = game.ships[i].hovered;
        if (game.ships[i].selected)
            shipSelected = true;
    }

    for (var i = 0; i < game.buildings.length; i++) {
      if (game.buildings[i].built && game.buildings[i].selected && game.buildings[i].canMove) {
        // check if it can be placed
        if (game.canBePlaced(game.buildings[i].size, game.buildings[i])) {
          game.buildings[i].moving = true;
          game.buildings[i].moveTargetPosition = position;
          game.buildings[i].calculateVector();
        }
      }
    }

    // select a building if hovered
    if (!shipSelected) {
        var buildingSelected = null;
        for (var i = 0; i < game.buildings.length; i++) {
            game.buildings[i].selected = game.buildings[i].hovered;
            if (game.buildings[i].selected) {
                $('#selection').html("Type: " + game.buildings[i].type + "<br/>" +
                    "Size: " + game.buildings[i].size + "<br/>" +
                    "Range: " + game.buildings[i].nodeRadius * game.tileSize + "<br/>" +
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
            $('#deactivate').hide();
            $('#activate').hide();
        }
    }

    // when there is an active symbol place building
    if (game.activeSymbol != -1) {
        var type = game.symbols[game.activeSymbol].imageID.substring(0, 1).toUpperCase() + game.symbols[game.activeSymbol].imageID.substring(1);
        if (game.canBePlaced(game.symbols[game.activeSymbol].size)) {
            game.addBuilding(position.x, position.y, game.symbols[game.activeSymbol].imageID, type);
            engine.playSound("click");
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

function onRightClick() {
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
    game.clearSymbols();
}

function onMouseDown() {

}

function onMouseUp() {

}

function onMouseScroll(evt) {
    if(evt.originalEvent.detail > 0 || evt.originalEvent.wheelDelta < 0) {
        //scroll down
        game.zoomIn();
    } else {
        //scroll up
        game.zoomOut();
    }
    //prevent page fom scrolling
    return false;
}

/*function request() {
    var building = null;
    for (var i = 0; i < game.buildings.length; i++)
        if (game.buildings[i].selected)
            building = game.buildings[i];

    var center = game.base.getCenter();
    var packet = new Packet(center.x, center.y, "packet_health", "Health");
    packet.target = building;
    packet.currentTarget = game.base;
    //packet.currentTarget = game.findRoute(packet);
    //game.packets.push(packet);
    console.log("--> start finding initial route");
    if (game.findRoute(packet) != null) {
        game.packetQueue.push(packet);
    }
    console.log("--> end finding initial route");
}*/

/**
 * Some helper functions below
 */

var Helper = {};

Helper.rad2deg = function(angle) {
    return angle * 57.29577951308232;
};

Helper.deg2rad = function(angle) {
    return angle * .017453292519943295;
};

Helper.distance = function(a, b) {
    return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
};

// calculates canvas coordinates from tile coordinates
Helper.tiled2screen = function(pVector) {
    return new Vector(
        640 + (pVector.x - game.scroll.x) * game.tileSize * game.zoom,
        368 + (pVector.y - game.scroll.y) * game.tileSize * game.zoom);
};

// calculates canvas coordinates from real coordinates
Helper.real2screen = function(pVector) {
    return new Vector(
        640 + (pVector.x - game.scroll.x * game.tileSize) * game.zoom,
        368 + (pVector.y - game.scroll.y * game.tileSize) * game.zoom);
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

/**
 * @author Alexander Zeillinger
 *
 * Main drawing function
 * May not be a member function of "game" in order to be called by requestAnimationFrame
 */
function draw() {
    game.drawGUI();

    // clear canvas
    engine.canvas["buffer"].clear();
    engine.canvas["main"].clear();

    game.drawCollectionAreas();
    game.drawCreep();

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
                    if (game.buildings[i].type == "Relay" && game.buildings[j].type == "Relay") {
                        allowedDistance = 20 * game.tileSize;
                    }

                    if (Math.pow(centerJ.x - centerI.x, 2) + Math.pow(centerJ.y - centerI.y, 2) < Math.pow(allowedDistance, 2)) {
                        engine.canvas["buffer"].context.strokeStyle = '#000';
                        engine.canvas["buffer"].context.lineWidth = 3;
                        engine.canvas["buffer"].context.beginPath();
                        engine.canvas["buffer"].context.moveTo(drawCenterI.x, drawCenterI.y);
                        engine.canvas["buffer"].context.lineTo(drawCenterJ.x, drawCenterJ.y);
                        engine.canvas["buffer"].context.stroke();

                        engine.canvas["buffer"].context.strokeStyle = '#fff';
                        if (!game.buildings[i].built || !game.buildings[j].built)
                            engine.canvas["buffer"].context.strokeStyle = '#aaa';
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

    // draw radius
    for (var i = 0; i < game.buildings.length; i++) {
        game.buildings[i].drawRadius();
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