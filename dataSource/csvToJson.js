// load file
const fs = require('fs');
const path = require('path');

const filename = 'livsmedelsDB.csv'

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

// remove last line if empty
if (columns[columns.length - 1].length === 1 && columns[columns.length - 1][0] === '') {
    columns.pop()
}

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
// create folders if they doesn't exist
if (!fs.existsSync(path.join(__dirname, '../static'))) {
    fs.mkdirSync(path.join(__dirname, '../static'));
    // if (!fs.existsSync(path.join(__dirname, '../static/data'))) {
    // fs.mkdirSync(path.join(__dirname, '../static/data'));
    // }
}
// save json
fs.writeFileSync(path.join(__dirname, '../static/livsmedelsDB.json'), JSON.stringify(json, null, 2), 'utf8')
// fs.writeFileSync(path.join(__dirname, '../static/data/livsmedelsDB.json'), JSON.stringify(json, null, 2), 'utf8')