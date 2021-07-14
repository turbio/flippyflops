const BLACK = '#000000';
const WHITE = '#FFFFFF';
const WIDTH = 56;
const HEIGHT = 14;
const scale = 10

class Picture {
  constructor(width, height, pixels) {
    this.width = width
    this.height = height
    this.pixels = pixels
  }

  static empty(width, height, color) {
    let pixels = new Array(width * height).fill(color)
    return new Picture(width, height, pixels)
  }
 
  pixel(x, y) {
    return this.pixels[x + y * this.width]
  }

  draw(pixels) {
    let copy = this.pixels.slice()
    for (let { x, y, color } of pixels) {
      copy[x + y * this.width] = color
    }
    return new Picture(this.width, this.height, copy)
  }
}

function elt(type, props, className, ...children) {
  let dom = document.createElement(type)
  if (props) Object.assign(dom, props)
  for (let child of children) {
    if (typeof child != 'string') dom.appendChild(child)
    else dom.appendChild(document.createTextNode(child))
  }
  if (className) dom.classList.add(className);
  return dom
}

class PictureCanvas {
  constructor(picture, pointerDown) {
    this.dom = elt('canvas', {
      onmousedown: event => this.mouse(event, pointerDown),
      ontouchstart: event => this.touch(event, pointerDown)
    })
    this.syncState(picture)
  }
  syncState(picture) {
    if (this.picture == picture) return
    drawPicture(picture, this.dom, scale, this.picture)
    this.picture = picture
  }
}

function drawPicture(picture, canvas, scale, previous) {
  if (previous == null ||
    previous.width != picture.width ||
    previous.height != picture.height) {
    canvas.width = picture.width * scale
    canvas.height = picture.height * scale
    previous = null
  }

  let cx = canvas.getContext('2d')
  for (let y = 0; y < picture.height; y++) {
    for (let x = 0; x < picture.width; x++) {
      let color = picture.pixel(x, y)
      if (previous == null || previous.pixel(x, y) != color) {
        cx.fillStyle = color
        cx.fillRect(x * scale, y * scale, scale, scale)
      }
    }
  }
}

PictureCanvas.prototype.mouse = function(downEvent, onDown) {
  if (downEvent.button != 0) return
  let pos = pointerPosition(downEvent, this.dom)
  let onMove = onDown(pos)
  if (!onMove) return
  let move = moveEvent => {
    if (moveEvent.buttons == 0) {
      this.dom.removeEventListener('mousemove', move)
    } else {
      let newPos = pointerPosition(moveEvent, this.dom)
      if (newPos.x == pos.x && newPos.y == pos.y) return
      pos = newPos
      onMove(newPos)
    }
  }
  this.dom.addEventListener('mousemove', move)
}

function pointerPosition(pos, domNode) {
  let rect = domNode.getBoundingClientRect()
  return {
    x: Math.min(Math.floor((pos.clientX - rect.left) / rect.width * WIDTH), WIDTH-1),
    y: Math.min(Math.floor((pos.clientY - rect.top) / rect.height * HEIGHT), HEIGHT-1)
  }
}

PictureCanvas.prototype.touch = function(startEvent, onDown) {
  let pos = pointerPosition(startEvent.touches[0], this.dom)
  let onMove = onDown(pos)
  startEvent.preventDefault()
  if (!onMove) return
  let move = moveEvent => {
    let newPos = pointerPosition(moveEvent.touches[0],
      this.dom)
    if (newPos.x == pos.x && newPos.y == pos.y) return
    pos = newPos
    onMove(newPos)
  }
  let end = () => {
    this.dom.removeEventListener('touchmove', move)
    this.dom.removeEventListener('touchend', end)
  }
  this.dom.addEventListener('touchmove', move)
  this.dom.addEventListener('touchend', end)
}

class PixelEditor {
  constructor(state, config) {
    let { controls, dispatch } = config
    this.state = state

    this.canvas = new PictureCanvas(state.picture, pos => {
      let onMove = draw(pos, this.state, dispatch)
      if (onMove) return pos => onMove(pos, this.state)
    })
    this.controls = controls.map(
      Control => new Control(state, config))
    this.dom = elt(
      'div',
      { tabIndex: 0, onkeydown: event => this.keyDown(event, config) }, '',
      elt('div', {}, 'canvc', this.canvas.dom),
      ...this.controls.reduce((a, c) => a.concat(' ', c.dom), []))
  }

  keyDown(event, config) {
    if (event.key == 'z' && (event.ctrlKey || event.metaKey)) {
      event.preventDefault()
      config.dispatch({ undo: true })
    }
  }

  syncState(state) {
    this.state = state
    this.canvas.syncState(state.picture)
    for (let ctrl of this.controls) ctrl.syncState(state)
  }
}

function drawLine(from, to, color) {
  let points = []
  if (Math.abs(from.x - to.x) > Math.abs(from.y - to.y)) {
    if (from.x > to.x) [from, to] = [to, from]
    let slope = (to.y - from.y) / (to.x - from.x)
    for (let { x, y } = from; x <= to.x; x++) {
      points.push({ x, y: Math.round(y), color })
      y += slope
    }
  } else {
    if (from.y > to.y) [from, to] = [to, from]
    let slope = (to.x - from.x) / (to.y - from.y)
    for (let { x, y } = from; y <= to.y; y++) {
      points.push({ x: Math.round(x), y, color })
      x += slope
    }
  }
  return points
}

function draw(pos, state, dispatch) {
  if (state.picture.pixel(pos.x, pos.y) == '#FFFFFF') {
    dispatch({ color: state.color = '#000000' })
  } else {
    dispatch({ color: state.color = '#FFFFFF' })
  }

  function connect(newPos, state) {
    let line = drawLine(pos, newPos, state.color)
    pos = newPos
    dispatch({ picture: state.picture.draw(line) })
  }
  connect(pos, state)

  return connect
}

class SendButton {
  constructor(state) {
    this.picture = state.picture
    this.dom = elt('button', {
      'class': 'sendbutton',
      onclick: () => this.save()
    }, 'sendbutton', 'Send')
  }

  save() {
    this.dom.classList.add('sending');
    postPx(picToPx(this.picture)).then(() =>{
        this.dom.classList.remove('sending');
        document.getElementById('thnx2').style.display = 'block';
      })
  }

  syncState(state) { this.picture = state.picture }
}

class ClearButton {
  constructor(state, { dispatch }) {
    this.picture = state.picture
    this.dom = elt('button', {
      onclick: () => this.fill(dispatch)
    }, 'clearbutton', 'Clear')
  }

  fill(dispatch) {
    const allBlack = this.picture.pixels.every(e => e === '#000000')

    const drawn = []
    for (let x = 0; x < 56; x++) {
      for (let y = 0; y < 14; y++) {
        drawn.push({ x, y, color: allBlack ? '#FFFFFF' : '#000000' });
      }
    }
    dispatch({ picture: this.picture.draw(drawn) })
  }
  syncState(state) { this.picture = state.picture }
}

function historyUpdateState(state, action) {
  if (action.undo) {
    if (state.done.length == 0) return state
    return Object.assign({}, state, {
      picture: state.done[0],
      done: state.done.slice(1),
      doneAt: 0
    })
  } else if (action.picture && state.doneAt < Date.now() - 1000) {
    return Object.assign({}, state, action, {
      done: [state.picture, ...state.done],
      doneAt: Date.now()
    })
  } else {
    return Object.assign({}, state, action)
  }
}

class UndoButton {
  constructor(state, { dispatch }) {
    this.dom = elt('button', {
      onclick: () => dispatch({ undo: true }),
      disabled: state.done.length == 0
    }, 'undobutton', 'Undo')
  }
  syncState(state) {
    this.dom.disabled = state.done.length == 0
  }
}

function startPixelEditor() {
    let state = {
      color: WHITE,
      picture: Picture.empty(56, 14, BLACK),
      done: [],
      doneAt: 0
    };

    controls = [ClearButton, UndoButton, SendButton];

  const app = new PixelEditor(state, {
    controls,
    dispatch(action) {
      state = historyUpdateState(state, action)
      app.syncState(state)
    }
  })

  return app.dom
}

document.querySelector('#editor')
  .appendChild(startPixelEditor())

const picToPx = (picture) => {
  let pixels = [];
  for (let i = 0; i < 56; i++) {
    for (let j = 0; j < 14; j++) {
      pixels.push({
        x: i,
        y: j,
        state: picture.pixel(i, j) == '#FFFFFF',
      })
    }
  }
  return pixels;
}

const postPx = pixels =>  fetch('https://dots.turb.io/set', {
    method: 'POST',
    mode: "no-cors",
    body: JSON.stringify({
      pixels: pixels,
    }),
  });