// Terrain generation using the Diamond Square algorithm, thanks to https://github.com/baxter/csterrain
// This file was converted from CoffeeScript to JavaScript using js2coffee.org with minor modifications from myself

this.HeightMap = (function() {

    function HeightMap(size, low_value, high_value) {
        this.size = size;
        this.low_value = low_value != null ? low_value : 0;
        this.high_value = high_value != null ? high_value : 255;
        this.mid_value = Math.floor((this.low_value + this.high_value) / 2);
        this.centre_cell = Math.floor(this.size / 2);
        this.reset();
    }

    HeightMap.prototype.reset = function() {
        var x, y,
            _this = this;
        while (this.remaining()) {
            this.pop();
        }
        this.map = (function() {
            var _i, _ref, _results;
            _results = [];
            for (x = _i = 1, _ref = this.size; 1 <= _ref ? _i <= _ref : _i >= _ref; x = 1 <= _ref ? ++_i : --_i) {
                _results.push((function() {
                    var _j, _ref1, _results1;
                    _results1 = [];
                    for (y = _j = 1, _ref1 = this.size; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = 1 <= _ref1 ? ++_j : --_j) {
                        _results1.push(null);
                    }
                    return _results1;
                }).call(this));
            }
            return _results;
        }).call(this);
        this.set_nw(Math.floor(Math.random() * this.high_value));
        this.set_ne(Math.floor(Math.random() * this.high_value));
        this.set_sw(Math.floor(Math.random() * this.high_value));
        this.set_se(Math.floor(Math.random() * this.high_value));
        return this.push(function() {
            return _this.diamond_square(0, 0, _this.size - 1, _this.size - 1, _this.mid_value);
        });
    };

    HeightMap.prototype.get_cell = function(x, y) {
        return this.map[y][x];
    };

    HeightMap.prototype.set_cell = function(x, y, v) {
        return this.map[y][x] = v;
    };

    HeightMap.prototype.soft_set_cell = function(x, y, v) {
        var _base;
        return (_base = this.map[y])[x] || (_base[x] = v);
    };

    HeightMap.prototype.set_nw = function(v) {
        return this.set_cell(0, 0, v);
    };

    HeightMap.prototype.set_ne = function(v) {
        return this.set_cell(0, this.size - 1, v);
    };

    HeightMap.prototype.set_sw = function(v) {
        return this.set_cell(this.size - 1, 0, v);
    };

    HeightMap.prototype.set_se = function(v) {
        return this.set_cell(this.size - 1, this.size - 1, v);
    };

    HeightMap.prototype.set_centre = function(v) {
        return this.set_cell(this.centre_cell, this.centre_cell, v);
    };

    HeightMap.prototype.push = function(value) {
        if (this.queue) {
            this.queue.push(value);
        } else {
            this.queue = [value];
        }
        return this.queue;
    };

    HeightMap.prototype.pop = function() {
        if (this.queue != null) {
            return this.queue.shift();
        }
    };

    HeightMap.prototype.remaining = function() {
        if ((this.queue != null) && this.queue.length > 0) {
            return true;
        } else {
            return false;
        }
    };

    HeightMap.prototype.step = function() {
        return this.pop()();
    };

    HeightMap.prototype.run = function() {
        while (this.remaining()) {
            this.step();
        }
        return null;
    };

    HeightMap.prototype.diamond_square = function(left, top, right, bottom, base_height) {
        var centre_point_value, x_centre, y_centre,
            _this = this;
        x_centre = Math.floor((left + right) / 2);
        y_centre = Math.floor((top + bottom) / 2);
        centre_point_value = Math.floor(((this.get_cell(left, top) + this.get_cell(right, top) + this.get_cell(left, bottom) + this.get_cell(right, bottom)) / 4) - (Math.floor((Math.random() - 0.5) * base_height * 2)));
        this.soft_set_cell(x_centre, y_centre, centre_point_value);
        this.soft_set_cell(x_centre, top, Math.floor((this.get_cell(left, top) + this.get_cell(right, top)) / 2 + ((Math.random() - 0.5) * base_height)));
        this.soft_set_cell(x_centre, bottom, Math.floor((this.get_cell(left, bottom) + this.get_cell(right, bottom)) / 2 + ((Math.random() - 0.5) * base_height)));
        this.soft_set_cell(left, y_centre, Math.floor((this.get_cell(left, top) + this.get_cell(left, bottom)) / 2 + ((Math.random() - 0.5) * base_height)));
        this.soft_set_cell(right, y_centre, Math.floor((this.get_cell(right, top) + this.get_cell(right, bottom)) / 2 + ((Math.random() - 0.5) * base_height)));
        if ((right - left) > 2) {
            base_height = Math.floor(base_height * Math.pow(2.0, -0.75));
            this.push(function() {
                return _this.diamond_square(left, top, x_centre, y_centre, base_height);
            });
            this.push(function() {
                return _this.diamond_square(x_centre, top, right, y_centre, base_height);
            });
            this.push(function() {
                return _this.diamond_square(left, y_centre, x_centre, bottom, base_height);
            });
            return this.push(function() {
                return _this.diamond_square(x_centre, y_centre, right, bottom, base_height);
            });
        }
    };

    HeightMap.prototype.tile = function(x, y) {
        return {
            nw: this.get_cell(x, y),
            ne: this.get_cell(x + 1, y),
            sw: this.get_cell(x, y + 1),
            se: this.get_cell(x + 1, y + 1)
        };
    };

    return HeightMap;

})();
