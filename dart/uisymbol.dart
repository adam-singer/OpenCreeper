part of creeper;

class UISymbol {
  Vector position;
  String imageID, key;
  num width = 80, height = 55, size, packets, radius;
  bool active = false, hovered = false;

  UISymbol(this.position, this.imageID, this.key, this.size, this.packets, this.radius);

  void draw(pContext) {
    if (this.active) {
      pContext.fillStyle = "#696";
    } else {
      if (this.hovered) {
        pContext.fillStyle = "#232";
      } else {
        pContext.fillStyle = "#454";
      }
    }
    pContext.fillRect(this.position.x + 1, this.position.y + 1, this.width, this.height);

    pContext.drawImageScaled(engine.images[this.imageID], this.position.x + 24, this.position.y + 20, 32, 32); // scale buildings to 32x32
    
    // draw cannon gun and ships
    if (this.imageID == "cannon")
      pContext.drawImageScaled(engine.images["cannongun"], this.position.x + 24, this.position.y + 20, 32, 32);
    if (this.imageID == "bomber")
      pContext.drawImageScaled(engine.images["bombership"], this.position.x + 24, this.position.y + 20, 32, 32);
    
    pContext.fillStyle = '#fff';
    pContext.font = '10px';
    pContext.textAlign = 'center';
    pContext.fillText(this.imageID.substring(0, 1).toUpperCase() + this.imageID.substring(1), this.position.x + (this.width / 2), this.position.y + 15);
    pContext.textAlign = 'left';
    pContext.fillText("(" + this.key.toString() + ")", this.position.x + 5, this.position.y + 50);
    pContext.textAlign = 'right';
    pContext.fillText(this.packets.toString(), this.position.x + this.width - 5, this.position.y + 50);
  }

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
}