# NOTE!

source: Livsmedelsverkets livsmedelsdatabas version 2022-05-24

The food data is fetched after load from a json file. This data is from _livsmedelsverket_. To update or rebuild data, fetch the data from [www7.slv.se/SokNaringsinnehall](https://www7.slv.se/SokNaringsinnehall). At the bottom of the page there is a link to download the data as an excel file. Save it as csv, name it `LivsmedelsDB.csv` and place it in the `dataSource` folder. Now run csvToJson.js (probably like this. `node ./dataSource/csvToJson.js`) to convert the csv to json. This will create the static folder and place the json file in it. Filename is `livsmedelsDB.csv`
