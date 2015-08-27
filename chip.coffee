$ = document.querySelector.bind(document)
canvas = $('#chip_canvas')
ctx = canvas.getContext("2d")

DATA_W = 250
DATA_H = 250

DATA_LENGTH = DATA_W*DATA_H

data = new Uint8ClampedArray(DATA_LENGTH)
newdata = new Uint8ClampedArray(DATA_LENGTH)

drawdata = new Uint8ClampedArray(DATA_LENGTH*4) #RGBA

setup = ->
  for i in [0...data.length]
    data[i] = Math.random() * 255
  for i in [0...drawdata.length]
    drawdata[i] = if i % 4 is 3 then 255 #Alpha channel

setup()

ctx.scale(canvas.width/DATA_W, canvas.height/DATA_H)
ctx.globalCompositeOperation = "copy"
ctx.imageSmoothingEnabled = false

draw = ->
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for i in [0..drawdata.length] by 4
    drawdata[i] = drawdata[i+1] = drawdata[i+2] = data[i>>2]
  imageData = new ImageData(drawdata, DATA_W, DATA_H)
  ctx.putImageData(imageData, 0, 0)
  ctx.drawImage(ctx.canvas, 0, 0)

rel = (n, x, y) ->
  i = n + x + y * DATA_W
  b = n % (DATA_W) + x
  return 0 if b > (DATA_W) or b < 0 or i >= DATA_LENGTH or i < 0 # prevent overflows
  data[i]

window.rel = rel

# CHIP
SPAWN = 2.0
LIVE = 2.0
DIE = 3.0

SPAWN_POWER = 0.5
DIE_STARVE = 1/1.1
DIE_CROWD = 1/1.1

step = ->
  for i in [0...data.length] by 1
    neighbours = [
      rel i, -1, -1 #top left
      rel i,  0, -1 #top
      rel i, +1, -1 #top right

      rel i, -1,  0 #left
      rel i, +1,  0 #right

      rel i, -1, +1 #bottom left
      rel i,  0, +1 #bottom
      rel i, +1, +1 #bottom right
    ]
    alive = 0
    sum = 0
    for n in neighbours
      alive++ if n >= 127
      sum += n
    avg = sum / neighbours.length

    if sum < LIVE*255
      newdata[i] = data[i] * DIE_STARVE
    else if sum > DIE*255
      newdata[i] = data[i] * DIE_CROWD
    else if sum >= SPAWN*255
      newdata[i] = data[i]*(1-SPAWN_POWER) + 255*SPAWN_POWER
    else
      newdata[i] = data[i]

  [data, newdata] = [newdata, data]

started = false
raf = ->
  started = true
  step()
  draw()
  requestAnimationFrame raf
raf()
canvas.addEventListener 'click', -> if started then setup() else raf()
