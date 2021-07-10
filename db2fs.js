const fs = require('fs');
const Database = require("@replit/database")
const db = new Database()

db.list().then(async ks => {
  console.log(ks.length);
  let i = 0;
  for (let k of ks) {
    i++;
    console.log(i/ks.length, k)
    const v = await db.get(k);
    fs.appendFileSync(
      'hist',
      JSON.stringify({k,v})+'\n'
    )
    await db.delete(k);
  }
});
