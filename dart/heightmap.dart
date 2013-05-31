// Terrain generation using the Diamond Square algorithm, thanks to https://github.com/baxter/csterrain
// This file was ported from CoffeeScript to Dart with minor modifications from myself

//import 'dart:math' as Math;

part of creeper;

class HeightMap {
  int size, low_value, high_value, mid_value, centre_cell;
  List queue = new List();
  List map;
  
  HeightMap(this.size, this.low_value, this.high_value) {
    this.mid_value = ((this.low_value + this.high_value) / 2).floor();
    this.centre_cell = (this.size / 2).floor();
    this.reset();
  }

  reset() {
      var random = new Random();
      var x, y,
          _this = this;
      
      this.queue.clear();
      
      this.map = new List(size);
      for (int i = 0; i < size; i++) {
        this.map[i] = new List(size);
      }
           
      this.set_nw(random.nextInt(this.high_value));
      this.set_ne(random.nextInt(this.high_value));
      this.set_sw(random.nextInt(this.high_value));
      this.set_se(random.nextInt(this.high_value));
      
      return this.push(() {
          return _this.diamond_square(0, 0, _this.size - 1, _this.size - 1, _this.mid_value);
      });
  }

  get_cell(x, y) {
      return this.map[y][x];
  }

  set_cell(x, y, v) {
      return this.map[y][x] = v;
  }

  soft_set_cell(x, y, v) {
    if (this.map[y][x] == null)
      this.map[y][x] = v;
    
    return this.map[y][x];
  }

  set_nw(v) {
      return this.set_cell(0, 0, v);
  }

  set_ne(v) {
      return this.set_cell(0, this.size - 1, v);
  }

  set_sw(v) {
      return this.set_cell(this.size - 1, 0, v);
  }

  set_se(v) {
      return this.set_cell(this.size - 1, this.size - 1, v);
  }

  set_centre(v) {
      return this.set_cell(this.centre_cell, this.centre_cell, v);
  }

  List push(value) {
    this.queue.add(value);
    return this.queue;
  }

  pop() {
    return this.queue.removeAt(0);
  }

  remaining() {
      if ((this.queue != null) && this.queue.length > 0) {
          return true;
      } else {
          return false;
      }
  }

  step() {
      return this.pop()();
  }

  run() {
      while (this.remaining()) {
          this.step();
      }
      return null;
  }

  diamond_square(left, top, right, bottom, base_height) {
    var random = new Random();
    
      var centre_point_value, x_centre, y_centre,
          _this = this;
      
      x_centre = ((left + right) / 2).floor();
      y_centre = ((top + bottom) / 2).floor();
      
      centre_point_value = (((this.get_cell(left, top) + this.get_cell(right, top) + this.get_cell(left, bottom) + this.get_cell(right, bottom)) / 4) - (((random.nextDouble() - 0.5) * base_height * 2).floor())).floor();
      
      this.soft_set_cell(x_centre, y_centre, centre_point_value);
      this.soft_set_cell(x_centre, top, ((this.get_cell(left, top) + this.get_cell(right, top)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      this.soft_set_cell(x_centre, bottom, ((this.get_cell(left, bottom) + this.get_cell(right, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      this.soft_set_cell(left, y_centre, ((this.get_cell(left, top) + this.get_cell(left, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      this.soft_set_cell(right, y_centre, ((this.get_cell(right, top) + this.get_cell(right, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      
      if ((right - left) > 2) {
          base_height = (base_height * pow(2.0, -0.75)).floor();
          this.push(() {
              return _this.diamond_square(left, top, x_centre, y_centre, base_height);
          });
          this.push(() {
              return _this.diamond_square(x_centre, top, right, y_centre, base_height);
          });
          this.push(() {
              return _this.diamond_square(left, y_centre, x_centre, bottom, base_height);
          });
          return this.push(() {
              return _this.diamond_square(x_centre, y_centre, right, bottom, base_height);
          });
      }
  }

  /*tile(x, y) {
      return {
          nw: this.get_cell(x, y),
          ne: this.get_cell(x + 1, y),
          sw: this.get_cell(x, y + 1),
          se: this.get_cell(x + 1, y + 1)
      };
  }*/

  //return HeightMap;

}
