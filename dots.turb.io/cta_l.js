const fetch = require('node-fetch');

const key = '62da63e92c1d438a8fd8d3532391908f';

const stations = [
  'Logan Square (Blue Line)',

  'California (Blue Line)',
  'Western (Blue Line - O\'Hare Branch)',
  'Damen (Blue Line)',
  'Division (Blue Line)',
  'Chicago (Blue Line)',

  'Grand (Blue Line)',
];
const station_info = [];

const damen = 40590;

function haversine(coords1, coords2, isMiles) {
  function toRad(x) {
    return x * Math.PI / 180;
  }

  var lon1 = +coords1.lng || coords1.Lng;
  var lat1 = +coords1.lat || coords1.Lat;

  var lon2 = +coords2.lng || coords2.Lng;
  var lat2 = +coords2.lat || coords2.Lat;

  var R = 6371; // earths radius km

  var x1 = lat2 - lat1;
  var dLat = toRad(x1);
  var x2 = lon2 - lon1;
  var dLon = toRad(x2)
  var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c;

  if(isMiles) d /= 1.60934;

  return d;
}

const sleep = t => new Promise((resolve, reject) => {
  setTimeout(() => { resolve(); }, t);
});

const req = async () => {
  const res = await fetch("https://www.transitchicago.com/traintracker/PredictionMap/tmTrains.aspx?line=B&MaxPredictions=1", {
    "headers": {
      "accept": "application/json, text/javascript, */*; q=0.01",
      "accept-language": "en-US,en;q=0.9",
      "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"Linux\"",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "x-requested-with": "XMLHttpRequest"
    },
    "referrer": "https://www.transitchicago.com/traintrackermap/",
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": null,
    "method": "GET",
    "mode": "cors",
    "credentials": "include"
  });

  const resj = await res.json();

  //assert(resj.status === "OK");
  //assert(resj.dataObject.length === 1);

  const { Line: line, Markers: markers } = resj.dataObject[0];
  //assert(line === 'B');

  return markers
}

const c_to_px = (x, y, s) => {
	return trans(x, y, to_cmd(font[s[0]] ?? font['undefined']));
}

const max_x = buf => Math.max(...buf.map(p => p.x));
const min_x = buf => Math.min(...buf.map(p => p.x));

const s_to_px = (x, y, s) => {
	const buf = [];

	s.split('').forEach((c, i) => {
		const kern = font[s[i-1] + c] ?? 2;

		const cx = Math.max(max_x(buf) + kern, x);
		buf.push(...c_to_px(cx, y, c));
	});

	return buf;
}

const r_align = buf => {
	const d = max_x(buf) - min_x(buf);
	return buf.map(p => ({...p, x: p.x - d}));
}

const inv = buf => buf.map(p => ({...p, p: 0x1 ^ p.p}));

const leading_ws = s => {
	for (let i = 0; i < s.length; i++) {
		if (s[i] !== ' ' && s[i] !== '\t') {
			return i;
		}
	}

	return s.length;
};

const to_cmd = s => {
	const rows = s.split('\n');
	if (rows[0].trim() === '') {
		rows.shift();
	}
	if (rows[rows.length-1].trim() === '') {
		rows.pop();
	}

	const trim_l = Math.min(...rows.map(leading_ws));

	return rows
		.map(row => row.slice(trim_l))
		.map((row, i) => {
			return row
				.split('')
				.map((c, j) => {
					if (c === '.') {
						return {x: j, y: i, p: 0};
					}
					if (c === '#') {
						return {x: j, y: i, p: 1};
					}
				})
				.filter(c => c);
		})
		.flat();
};

const trans = (dx, dy, buf) => buf.map(p => ({...p, x: p.x + dx, y: p.y + dy}));

(async () => {
  const cta_sys_info_req = await fetch(`https://data.cityofchicago.org/resource/8pix-ypme.json`);
  const cta_sys_info = await cta_sys_info_req.json();

  stations.forEach(station => {
	const stop = cta_sys_info.find(stop => stop.station_descriptive_name === station);

	station_info.push({
	  geo: {lng: stop.location.longitude, lat: stop.location.latitude},
	  station_name: stop.station_name,
	  station_id: +stop.map_id
	});
  });

  const buf = [
	{c: 0},
  ];

	const train_diag = [
	...trans(0, 11, to_cmd(`
		........................................................
		########################################################
		........................................................
	`))
	]


  //buf.push({x: 56/2-1, y: 11, p: 1})
  //buf.push({x: 56/2+1, y: 11, p: 1})
  //buf.push({x: 56/2-1, y: 13, p: 1})
  //buf.push({x: 56/2+1, y: 13, p: 1})

  //buf.push({x: 56/2, y: 11, p: 1})
  //buf.push({x: 56/2, y: 12, p: 0})
  //buf.push({x: 56/2, y: 13, p: 1})

  const stas = stations.length - 2;
  for (let i = 0; i < stas; i++) {
	const x = 55/(stas-1) * i;

	if (i === Math.floor(stas / 2)) {
		train_diag.push(...trans(x-(4/2), 10, to_cmd(`
			....
			.##.
			#..#
			.##.
		`)))
	} else {
		train_diag.push(...trans(x, 11, to_cmd(`
			 .
			 .
			 .
		`)))
	}
  }

	let odd = false;

  while(true) {
	await sleep(5000);

	odd = !odd;
	const trainpx = [];

	let markers;

	try {
		markers = await req();
	} catch (e) {
		console.error('failed to fetch markers:', e);
		continue;
	}

	console.log('looped', markers.length, 'trains');
	markers.forEach(m => {
	  const next_st_i = station_info.findIndex(s => +s.station_id === m.Predictions[0][0])

	  if (next_st_i !== -1 && next_st_i !== 0 && next_st_i !== stations.length - 1) {
		//console.log('between', stations[next_st_i-1], stations[next_st_i+1]);

		let origin;

		if (haversine(m.Position, station_info[next_st_i-1].geo) < haversine(m.Position, station_info[next_st_i+1].geo)) {
		origin = next_st_i-1;
		} else {
		origin = next_st_i+1;
		}

		const total = haversine(station_info[next_st_i].geo, station_info[origin].geo);
		const rem = haversine(m.Position, station_info[next_st_i].geo);

		//console.log('total distance:', total);
		//console.log('remai distance:', rem);


		//console.log(stations[origin], '->', stations[next_st_i], Math.floor((1 - (rem / total)) * 100) + '%');
		//console.log(m);

		const y = origin < next_st_i ? 13 : 11;
		let x;
		if (origin < next_st_i) {
		  x = 55/(stations.length - 3) * (origin-1+(1 - rem/total));
		} else {
		  x = 55/(stations.length - 3) * (origin-1-(1 - rem/total));
		}

		trainpx.push({x: Math.floor(x), y, p: 1})
	  }
	  //console.log(m.Predictions[0], '->', m.Predictions[1], '->', m.Predictions[2]);
	})

	let etas;

	try {
		const sta_res = await fetch(`https://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?mapid=${damen}&key=${key}&outputType=JSON`);
		const sta_json = await sta_res.json();

		etas = sta_json.ctatt.eta.map(eta => ({
			name: eta.destNm,
			in_m: Math.round((new Date(eta.arrT) - new Date()) / 1000 / 60),
		}));
	} catch (e) {
		console.error('failed to fetch etas:', e);
		continue;
	}

	  //console.log(etas);

	const next_north = etas.filter(eta => eta.name === 'O\'Hare');
	const next_south = etas.filter(eta => eta.name === 'UIC-Halsted' || eta.name === 'Forest Park');

	const arrivals = [ ];

	arrivals.push(...s_to_px(1, 0, "O'hare"));
	arrivals.push(...r_align(s_to_px(55, 0, next_north.slice(0, 3).map(eta => eta.in_m).join(' ') + 'm')));

	arrivals.push(...s_to_px(1, 5, next_south[0].name === 'UIC-Halsted' ? 'UIC' : 'F.Park'));
	arrivals.push(...r_align(s_to_px(55, 5, next_south.slice(0, 3).map(eta => eta.in_m).join(' ') + 'm')));


	fetch(
	  "https://dots.turb.io/cmd",
	  {
	"body": JSON.stringify(
	  buf
		.concat(train_diag)
		.concat(trainpx)
		.concat(arrivals)
		.concat([{d: 1}])
	),
	"method": "POST",
	  },
	);
  }
})()

const font = {
	'?': `
	##.
	..#
	.#.
	...
	.#.
	`,

	'·': `
	.
	.
	#
	.
	`,
	' ': '.',
	',': `
	.
	.
	.
	.
	#
	#
	`,
	'F': `
	###
	#  
	##	
	#	
	`,
	'P': `
	##
	# #
	##	
	#	
	`,
	'k': `
	# 
	# #
	##	
	# # 
	`,
	'.': `
	.
	.
	.
	#
	`,
	'O': `
	.
	###
	# #
	###
	`,
	'\'': `
	#
	#
	`,
	'h': `
	#
	#  
	###
	# #
	`,
	'a': `
	.
	 ##    
	# #    
	 ###	 
	`,
	'r': `
	.
	 #	  
	#
	#
	`,
	'e': `
	.
	###		   
	###			
	#		 
	 ##
	`,
	'U': `
	# #
	# #
	# #
	###
	`,
	'I': `
	###
	 # 
	 # 
	###
	`,
	'C': `
	###
	# 
	# 
	###
	`,
	'1': `
   ##
	#
	#
	#
	#
	`,
	'2': `
	##
	  #
	##
	#
	###
	`,
	'3': `
	##
	  #
	##
	  #
	##
	`,
	'4': `
	 ##
	# #
	###
	  #
	  #
	`,
	'5': `
	###
	#
	##
	  #
	##
	`,
	'6': `
	 ##
	#
	##
	# #
	 ##
	`,
	'7': `
	###
	  #
	 #
	 #
	 #
	`,
	'8': `
	###
	# #
	 #
	# #
	###
	`,
	'9': `
	###
	# #
	 ##
	  #
	##
	`,
	'0': `
	 # 
	# #
	# #
	# #
	 #
	`,
	'm': `
	.
	.
	## #
	# # #
	# # #
	`,
	'F.': 1,
	'·1': 1,
	'undefined': `
	.
	###
	###
	###
	###
	`,

	'·1': 2,
	'1': `
	.
	.#
	##
	.#
	.#
	`,
	'2': `
	.
	##.
	..#
	.#
	###
	`,
	'3': `
	.
	###
	.#.
	..#
	##.
	`,
	'4': `
	.
	.##
	#.#
	###
	..#
	`,
	'5': `
	.
	###
	##.
	..#
	##.
	`,
	'6': `
	.
	.##
	##.
	#.#
	.#.
	`,
	'7': `
	.
	###
	..#
	.#.
	.#.
	`,
	'8': `
	.
	.##
	#.#
	.#.#
	.##
	`,
	'9': `
	.
	.#.
	#.#
	.##
	##.
	`,
	'0': `
	.
	.#.
	#.#
	#.#
	.#.
	`,
};
