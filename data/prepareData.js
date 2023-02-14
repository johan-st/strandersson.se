// load file
const fs = require('fs');
const path = require('path');

const filename = 'LivsmedelsDB.csv'

const data = fs.readFileSync(path.join(__dirname, filename), 'utf8');


// split into lines
let lines = []
if (data.indexOf('\r\n') > -1) {
    lines = data.split('\r\n')
} else {
    lines = data.split('\n')
}

// split into columns
let columns = []
for (let i = 0; i < lines.length; i++) {
    columns[i] = lines[i].split(';')
}

// remove first three line
columns.shift()
columns.shift()
columns.shift()

// parse into json
let livsmedel = []
for (let i = 0; i < columns.length; i++) {
    let obj = {}
    obj['namn'] = columns[i][0]
    obj['id'] = columns[i][1]
    obj['energi'] = columns[i][3]
    obj['protein'] = columns[i][6]
    obj['fat'] = columns[i][5]
    obj['carbohydrate'] = columns[i][7]
    livsmedel.push(obj)
}

const json = { version: 1, livsmedel: livsmedel }
// save json
fs.writeFileSync(path.join(__dirname, 'LivsmedelsDB.json'), JSON.stringify(json, null, 2), 'utf8')