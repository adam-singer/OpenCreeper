part of creeper;

class UISymbol {
  Vector position;
  String imageID, key;
  num width = 80, height = 55, size, packets, radius;
  bool active = false, hovered = false;

  UISymbol(this.position, this.imageID, this.key, this.size, this.packets, this.radius);

  void checkHovered() {
    this.hovered = (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height);
  }

  void setActive() {
    this.active = false;
    if (engine.mouseGUI.x > this.position.x && engine.mouseGUI.x < this.position.x + this.width && engine.mouseGUI.y > this.position.y && engine.mouseGUI.y < this.position.y + this.height) {
      game.activeSymbol = (this.position.x / 81).floor() + ((this.position.y / 56).floor()) * 6;
      this.active = true;
    }
  }
  
  void draw() {
    CanvasRenderingContext2D context = engine.canvas["gui"].context;
    
    if (this.active) {
      context.fillStyle = "#696";
    } else {
      if (this.hovered) {
        context.fillStyle = "#232";
      } else {
        context.fillStyle = "#454";
      }
    }
    context.fillRect(this.position.x + 1, this.position.y + 1, this.width, this.height);

    context.drawImageScaled(engine.images[this.imageID], this.position.x + 24, this.position.y + 20, 32, 32); // scale buildings to 32x32
    
    // draw cannon gun and ships
    if (this.imageID == "cannon")
      context.drawImageScaled(engine.images["cannongun"], this.position.x + 24, this.position.y + 20, 32, 32);
    if (this.imageID == "bomber")
      context.drawImageScaled(engine.images["bombership"], this.position.x + 24, this.position.y + 20, 32, 32);
    
    context
      ..fillStyle = '#fff'
      ..font = '10px'
      ..textAlign = 'center'
      ..fillText(this.imageID.substring(0, 1).toUpperCase() + this.imageID.substring(1), this.position.x + (this.width / 2), this.position.y + 15)
      ..textAlign = 'left'
      ..fillText("(" + this.key.toString() + ")", this.position.x + 5, this.position.y + 50)
      ..textAlign = 'right'
      ..fillText(this.packets.toString(), this.position.x + this.width - 5, this.position.y + 50);
  }

}