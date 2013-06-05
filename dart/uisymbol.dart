part of creeper;

class UISymbol {
  Vector position;
  String imageID;
  int width = 80, height = 55, size, packets, radius, keyCode;
  bool active = false, hovered = false;

  UISymbol(this.position, this.imageID, this.keyCode, this.size, this.packets, this.radius);

  void checkHovered() {
    hovered = (engine.mouseGUI.x > position.x &&
                    engine.mouseGUI.x < position.x + width &&
                    engine.mouseGUI.y > position.y &&
                    engine.mouseGUI.y < position.y + height);
  }

  void setActive() {
    if (hovered) {
      game.activeSymbol = (position.x / 81).floor() + ((position.y / 56).floor()) * 6;
      active = true;
    } else {
      active = false;
    }
  }
  
  void draw() {
    CanvasRenderingContext2D context = engine.canvas["gui"].context;
    
    if (active) {
      context.fillStyle = "#696";
    } else {
      if (hovered) {
        context.fillStyle = "#232";
      } else {
        context.fillStyle = "#454";
      }
    }
    context.fillRect(position.x + 1, position.y + 1, width, height);

    context.drawImageScaled(engine.images[imageID], position.x + 24, position.y + 20, 32, 32); // scale buildings to 32x32
    
    // draw cannon gun and ships
    if (imageID == "cannon")
      context.drawImageScaled(engine.images["cannongun"], position.x + 24, position.y + 20, 32, 32);
    if (imageID == "bomber")
      context.drawImageScaled(engine.images["bombership"], position.x + 24, position.y + 20, 32, 32);
    
    context
      ..fillStyle = '#fff'
      ..font = '10px'
      ..textAlign = 'center'
      ..fillText(imageID.substring(0, 1).toUpperCase() + imageID.substring(1), position.x + (width / 2), position.y + 15)
      ..textAlign = 'left'
      ..fillText("(${new String.fromCharCode(keyCode)})", position.x + 5, position.y + 50)
      ..textAlign = 'right'
      ..fillText(packets.toString(), position.x + width - 5, position.y + 50);
  }

}