// Terrain generation using the Diamond Square algorithm, thanks to https://github.com/baxter/csterrain
// This file was ported from CoffeeScript to Dart with minor modifications from myself

//import 'dart:math' as Math;

part of creeper;

class HeightMap {
  int seed, size, low_value, high_value, mid_value, centre_cell;
  List queue = new List();
  List map;
  
  HeightMap(this.seed, this.size, this.low_value, this.high_value) {
    mid_value = ((low_value + high_value) / 2).floor();
    centre_cell = (size / 2).floor();
    reset();
  }

  reset() {
      var random = new Random(seed);
      var x, y,
          _this = this;
      
      queue.clear();
      
      map = new List(size);
      for (int i = 0; i < size; i++) {
        map[i] = new List(size);
      }
           
      set_nw(random.nextInt(high_value));
      set_ne(random.nextInt(high_value));
      set_sw(random.nextInt(high_value));
      set_se(random.nextInt(high_value));
      
      return push(() {
          return diamond_square(0, 0, size - 1, size - 1, mid_value, seed);
      });
  }

  get_cell(x, y) {
      return map[y][x];
  }

  set_cell(x, y, v) {
      return map[y][x] = v;
  }

  soft_set_cell(x, y, v) {
    if (map[y][x] == null)
      map[y][x] = v;
    
    return map[y][x];
  }

  set_nw(v) {
      return set_cell(0, 0, v);
  }

  set_ne(v) {
      return set_cell(0, size - 1, v);
  }

  set_sw(v) {
      return set_cell(size - 1, 0, v);
  }

  set_se(v) {
      return set_cell(size - 1, size - 1, v);
  }

  set_centre(v) {
      return set_cell(centre_cell, centre_cell, v);
  }

  List push(value) {
    queue.add(value);
    return queue;
  }

  pop() {
    return queue.removeAt(0);
  }

  remaining() {
      if ((queue != null) && queue.length > 0) {
          return true;
      } else {
          return false;
      }
  }

  step() {
      return pop()();
  }

  run() {
      while (remaining()) {
          step();
      }
      return null;
  }

  diamond_square(left, top, right, bottom, base_height, seed) {
    var random = new Random(seed);
    
      var centre_point_value, x_centre, y_centre,
          _this = this;
      
      x_centre = ((left + right) / 2).floor();
      y_centre = ((top + bottom) / 2).floor();
      
      centre_point_value = (((get_cell(left, top) + get_cell(right, top) + get_cell(left, bottom) + get_cell(right, bottom)) / 4) - (((random.nextDouble() - 0.5) * base_height * 2).floor())).floor();
      
      soft_set_cell(x_centre, y_centre, centre_point_value);
      soft_set_cell(x_centre, top, ((get_cell(left, top) + get_cell(right, top)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      soft_set_cell(x_centre, bottom, ((get_cell(left, bottom) + get_cell(right, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      soft_set_cell(left, y_centre, ((get_cell(left, top) + get_cell(left, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      soft_set_cell(right, y_centre, ((get_cell(right, top) + get_cell(right, bottom)) / 2 + ((random.nextDouble() - 0.5) * base_height)).floor());
      
      if ((right - left) > 2) {
          base_height = (base_height * pow(2.0, -0.75)).floor();
          push(() {
              return diamond_square(left, top, x_centre, y_centre, base_height, random.nextInt(10000));
          });
          push(() {
              return diamond_square(x_centre, top, right, y_centre, base_height, random.nextInt(10000));
          });
          push(() {
              return diamond_square(left, y_centre, x_centre, bottom, base_height, random.nextInt(10000));
          });
          return push(() {
              return diamond_square(x_centre, y_centre, right, bottom, base_height, random.nextInt(10000));
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
