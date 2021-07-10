const express = require('express');
const bodyParser = require('body-parser');
const Database = require("@replit/database")

const db = new Database()

const app = express();
app.use(bodyParser.text({type: '*/*'}));
app.use(express.static('public'));

let listen = [];
const send = cmd => {
  listen.forEach(l => l(cmd));
}

let last_data = null;
const hold_time = 1000*60*10;

const msgd = () => last_data = new Date();

app.all('/msg/:msg', (req, res) => {
  msgd();
  const body = req.params.msg;
  if (!body) return res.end('uwu daddy');
  console.log('msg', body)
  db.set('msg:'+(+new Date()), body);
  send([
    {c:0},
    {s: body.slice(0,14), x: 1, y: 1},
    {s: body.slice(14), x: 1, y: 7},
    {d:1},
  ]);
  res.send();
});

app.get('/msg', (req, res) => {
  const body = req.query.msg;
  if (!body) return res.redirect('/');

  msgd();
  console.log('msg', body)
  db.set('msg:'+(+new Date()), body);

  send([
    {c:0},
    {s: body.slice(0,14), x: 1, y: 1},
    {s: body.slice(14), x: 1, y: 7},
    {d:1},
  ]);
  res.redirect('/');
});

app.post('/msg', (req, res) => {
  const body = req.body;
  if (!body) return res.redirect('/');

  msgd();
  console.log('msg', body)
  db.set('msg:'+(+new Date()), body);

  send([
    {c:0},
    {s: body.slice(0,14), x: 1, y: 1},
    {s: body.slice(14), x: 1, y: 7},
    {d:1},
  ]);
  res.redirect('/');
});

app.post('/set', (req, res) => {
  msgd();
  let bod;
	try {
		bod = JSON.parse(req.body);
	}
	catch(error) {
		console.log(error);
		res.status(400).send('Not Valid JSON!');
    return;
	}

  let bmp = [...new Array(56*14)].fill('.');
  bod.pixels
    .forEach(({x,y,state}) => {bmp[x+(y*56)] = state ? '#' : ' '});
  console.log('|'+'='.repeat(56-2)+'|');
  console.log(bmp.join('').match(/.{1,56}/g).join("\n"));
  console.log('|'+'='.repeat(56-2)+'|');
  db.set('img:'+(+new Date()), bmp.join(''));

	if(bod.pixels.length <= 0) return;
	let sendQueue = [];
	for(var i = 0; i < bod.pixels.length; i++) {
		const pix = bod.pixels[i];
		if(typeof pix.x != 'number' || typeof pix.y != 'number') res.status(400).send('TypeError: pixel location is not a number');
		if(typeof pix.state != 'boolean') res.status(400).send('TypeError: State is not a boolean');
		var state = pix.state ? 1 : 0;
		sendQueue.push({
			p: state,
			x: pix.x,
			y: pix.y,
		});
	}
	sendQueue.push({d:1});
	send(sendQueue);
	res.status(201).send('DRAWN');
});

app.all('/set/:x/:y/:on', (req, res) => {
  msgd();
  console.log(req.params)
  send([
    {
      p: (req.params.on=='0'||req.params.on=='false') ? 0 : 1,
      x: parseInt(req.params.x),
      y: parseInt(req.params.y),
    },
    {d:1},
  ]);
  res.send();
});

app.get('/stream', (req, res) => {
  console.log('incoming stream!')
  const cb = cmd => {
    cmd.forEach(c => {
      res.write(JSON.stringify(c)+'\n');
    })
  }

  listen.push(cb);

  req.on("close", () => {
    listen = listen.filter(l => l !== cb);
  });
});

const stats_width = 56;
const hist = [...new Array(stats_width)].fill(undefined);
let last_stat = null;
let stat_name = '';
let stat_interv = 0;



app.post('/statclear', (req, res) => {
  const b = JSON.parse(req.body)

  stat_name = b.name;
  stat_interv = b.interv;
  last_stat = null;
  hist.fill(undefined);
  res.end();
});

app.post('/stat', (req, res) => {
  msgd();

  if (!req.body.match(/^[0-9.]+$/)) {
    return;
  }

  const v = parseFloat(req.body)

  if (hist[hist.length-1]) {
    if (v > hist[hist.length-1].hi) {
      hist[hist.length-1].hi = v;
    }

    if (v < hist[hist.length-1].lo) {
      hist[hist.length-1].lo = v;
    }
  } else {
    hist[hist.length-1] = {hi: v, lo: v, open: v};
  }

  if (!last_stat || new Date() - last_stat > stat_interv) {
    hist.push({hi: v, lo: v, open: v});
    hist.shift();
    last_stat = new Date();
  }

  let hi = Number.MIN_SAFE_INTEGER;
  let lo = Number.MAX_SAFE_INTEGER;
  hist.filter(l => !!l).forEach(l => {
    hi = Math.max(hi, l.hi);
    lo = Math.min(lo, l.lo);
  });

  const mapl = v => {
    const disp_hi = 5;
    const disp_lo = 13;

    return Math.floor(((v - lo) / (hi - lo)) * (disp_hi - disp_lo)) + disp_lo
  }

  const cmd = [
    {c: 0}, {s: stat_name+' '+v, x:1, y:0}
  ];
  hist.forEach((l, i) => {
    if (!l) return;

    let fr, to;
    if (i == hist.length-1) {
      fr = mapl(l.open)
      to = mapl(v);
    } else {
      fr = mapl(l.hi);
      to = mapl(l.lo);
    }

    for (let y = Math.min(fr, to); y <= Math.max(fr, to); y++) {
      cmd.push({p: 1, x: i, y})
    }
  });
  cmd.push({d:1})
  send(cmd);

  res.end();
});

setInterval(() => {
  if (new Date() - last_data < hold_time) return;

  const now = new Date(new Date().toLocaleString("en-US", { timeZone: "America/Los_Angeles" }));

  const num = [
    "one",   "two",   "three", "four", "five",   "six",
    "seven", "eight", "nine",  "ten",  "eleven", "twelve",
  ];

  const angle = [
    undefined,       "five",    "ten", "quarter", "twenty", "twenty five",
    "half",   "twenty five", "twenty", "querter",    "ten", "five",
  ]

  let a;
  let b;

  if (now.getMinutes() < 5) {
    a = num[(now.getHours() - 1 + 12) % 12];
    b = "o'clock";
  } else if (now.getMinutes() < 35) {
    a = angle[Math.floor(now.getMinutes() / 5)];
    b = `past ${num[(now.getHours() - 1 + 12) % 12]}`;
  } else {
    a = angle[Math.floor(now.getMinutes() / 5)];
    b = `to ${num[now.getHours() % 12]}`;
  }
  
  send([
    {c: 0},
    {s: a, x: 2, y: 1},
    {s: b, x: 2, y: 8},
    {
      p: 1,
      x: 54 + Math.floor((now.getSeconds() % 4)/2),
      y: Math.floor(((now.getSeconds()+1) % 4)/2),
    },
    {d:1},
  ]);
}, 1000)

setInterval(() => {
  send([{}]);
}, 2000)

app.listen(3000, () => {
  console.log('suwuver stuwurted UwU');
});