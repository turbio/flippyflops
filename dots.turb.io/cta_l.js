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

  //const sta_res = await fetch(`https://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?mapid=${damen}&key=${key}&outputType=JSON`);
  //const sta_json = await sta_res.json();

  //sta_json.ctatt.eta.forEach(eta => {
    //console.log(eta);
    //station_geos.forEach(sta => console.log(haversine(sta, eta, true)));
  //})

  //return;


  const px = [];

  for (let i = 0; i < 56; i++) {
    px.push({x: i, y: 12, state: true})
    px.push({x: i, y: 11, state: true})
  }

  //px.push({x: 56/2-1, y: 11, state: true})
  //px.push({x: 56/2+1, y: 11, state: true})
  //px.push({x: 56/2-1, y: 13, state: true})
  //px.push({x: 56/2+1, y: 13, state: true})

  //px.push({x: 56/2, y: 11, state: true})
  //px.push({x: 56/2, y: 12, state: false})
  //px.push({x: 56/2, y: 13, state: true})

  const stas = stations.length - 2;
  for (let i = 0; i < stas; i++) {
    const x = 55/(stas-1) * i;
    px.push({x: x+0, y: 10, state: true})

    if (i === Math.floor(stas / 2)) {
      px.push({x: x-1, y: 10, state: true})
      px.push({x: x+1, y: 10, state: true})

      px.push({x: x-1, y: 12, state: false})
      px.push({x: x-1, y: 11, state: false})


      px.push({x: x+1, y: 12, state: false})
      px.push({x: x+1, y: 11, state: false})

      px.push({x: x-1, y: 13, state: true})
      px.push({x: x+1, y: 13, state: true})
    }

    px.push({x: x, y: 12, state: false})
    px.push({x: x, y: 11, state: false})

    px.push({x: x+0, y: 13, state: true})
  }

   await fetch("https://dots.turb.io/msg?msg=o'hare");

  let odd = false;

  while(true) {
    odd = !odd;
    const trainpx = [];

    markers = await req();
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


	console.log(stations[origin], '->', stations[next_st_i], Math.floor((1 - (rem / total)) * 100) + '%');
	console.log(m);

	const y = origin < next_st_i ? 12 : 11;
	let x;
	if (origin < next_st_i) {
	  x = 55/(stations.length - 3) * (origin-1+(1 - rem/total));
	} else {
	  x = 55/(stations.length - 3) * (origin-1-(1 - rem/total));
	}

	trainpx.push({x: Math.floor(x), y, state: false})
      }
      //console.log(m.Predictions[0], '->', m.Predictions[1], '->', m.Predictions[2]);
    })

    //console.log(trainpx);

    fetch("https://dots.turb.io/set", { "body": JSON.stringify({pixels: px.concat(trainpx)}), "method": "POST" });

    await sleep(5000);
  }
})()
