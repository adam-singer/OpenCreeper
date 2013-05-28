part of creeper;

class Helper {
  static num rad2deg(num angle) {
    return angle * 57.29577951308232;
  }
  
  static num deg2rad(num angle) {
    return angle * .017453292519943295;
  }
  
  static num distance(Vector a, Vector b) {
    return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
  }
  
  // converts tile coordinates to canvas coordinates
  static Vector tiled2screen(Vector pVector) {
    return new Vector(
        engine.halfWidth + (pVector.x - game.scroll.x) * game.tileSize * game.zoom,
        engine.halfHeight + (pVector.y - game.scroll.y) * game.tileSize * game.zoom);
  }
  
  // converts full coordinates to canvas coordinates
  static Vector real2screen(Vector pVector) {
    return new Vector(
        engine.halfWidth + (pVector.x - game.scroll.x * game.tileSize) * game.zoom,
        engine.halfHeight + (pVector.y - game.scroll.y * game.tileSize) * game.zoom);
  }
  
  // converts full coordinates to tile coordinates
  static Vector real2tiled(Vector pVector) {
    return new Vector(
        (pVector.x / game.tileSize).floor(),
        (pVector.y / game.tileSize).floor());
  }
  
  static clone(pObject) {
    List newObject = new List();
    for (int i = 0; i < pObject.length; i++) {
      newObject.add(pObject[i]);
    }
    return newObject;
  }
  
  static int randomInt(num from, num to) {
    var random = new Math.Random();
    return (random.nextInt(to - from + 1) + from);
  }
  
  static void shuffle(List list) {
    int len = list.length;
    int i = len;
    while (i-- > 0) {
      int p = HelperRandomInt(0, len);
      var t = list[i];
      list[i] = list[p];
      list[p] = t;
    }
  }
}