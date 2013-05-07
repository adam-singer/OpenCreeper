var size = 150;

function generateTerrain() {
  var noiseArr = [];

  for(var i = 0; i <= 5; i++) {
    noiseArr[i] = [];

    for(var j = 0; j <= 5; j++) {
      var height = Math.random();

      if(i == 0 || j == 0 || i == 5 || j == 5)
        height = 1;

      noiseArr[i][j] = height;
    }
  }

  return(flatten(interpolate(noiseArr)));
}

function interpolate(points) {
  var noiseArr = [];
  var x = 0;
  var y = 0;

  for(var i = 0; i < size; i++) {
    if(i != 0 && i % 30 == 0)
      x++;

    noiseArr[i] = [];
    for(var j = 0; j < size; j++) {

      if(j != 0 && j % 30 == 0)
        y++;

      var mu_x = (i % 30) / 30;
      var mu_2 = (1 - Math.cos(mu_x * Math.PI)) / 2;

      var int_x1 = points[x][y] * (1 - mu_2) + points[x + 1][y] * mu_2;
      var int_x2 = points[x][y + 1] * (1 - mu_2) + points[x + 1][y + 1] * mu_2;

      var mu_y = (j % 30) / 30;
      var mu_2 = (1 - Math.cos(mu_y * Math.PI)) / 2;

      noiseArr[i][j] = int_x1 * (1 - mu_2) + int_x2 * mu_2;
    }
    y = 0;
  }
  return(noiseArr);
}

function flatten(points) {
  var noiseArr = [];
  for(var i = 0; i < points.length; i++) {
    noiseArr[i] = [];
    for(var j = 0; j < points[i].length; j++) {
      if(points[i][j] < 0.1)
        noiseArr[i][j] = 0;
      else if(points[i][j] < 0.2)
        noiseArr[i][j] = 0.1;
      else if(points[i][j] < 0.3)
        noiseArr[i][j] = 0.2;
      else if(points[i][j] < 0.4)
        noiseArr[i][j] = 0.3;
      else if(points[i][j] < 0.5)
        noiseArr[i][j] = 0.4;
      else if(points[i][j] < 0.6)
        noiseArr[i][j] = 0.5;
      else if(points[i][j] < 0.7)
        noiseArr[i][j] = 0.6;
      else if(points[i][j] < 0.8)
        noiseArr[i][j] = 0.7;
      else if(points[i][j] < 0.9)
        noiseArr[i][j] = 0.8;
      else
        noiseArr[i][j] = 1;
    }
  }

  return(noiseArr);
}