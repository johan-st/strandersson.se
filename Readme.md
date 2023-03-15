# strandersson.se

_A domain and collection of tools and things for our family._ ([link](https://strandersson.se))

I have decided to take inspiration from [this structure](https://github.com/madasebrof/elm-taco-donut) and use it as a step-off point for this project.

Johan Strand: [jst.dev](https://jst.dev)

# App

This is an Elm app. I am trying out a new structure for this project. I have decided to use [this structure](https://github.com/madasebrof/elm-taco-donut). It is quite a departure from the usual Elm app. I am hoping to learn something new and get a better understanding of how to structure Elm apps.

---

---

# Home

a placeholder with some links. Maybe..

---

# Meal Calculator

a tool for myself when cooking. Makes it easier to calculate macros (protein, carbs and fat) and kcal for my lunchboxes

## NOTE!

The food data for the search is fetched after load. Technically it is a json-file on the server. This data is originally from _livsmedelsverket_. To update or rebuild data, fetch the data from [www7.slv.se/SokNaringsinnehall](https://www7.slv.se/SokNaringsinnehall). At the bottom of the page there is a link to download the data as an excel file. Save it as csv, name it `LivsmedelsDB.csv` and place it in the `dataSource` folder. Now run csvToJson.js (probably like this. `node ./dataSource/csvToJson.js`) to convert the csv to json. This will create the static folder and place the json file in it. Filename is `LivsmedelsDB.csv`


## Development Process

As the nature of this is a hobby-project and a help for myself I decided to start small with the minimum that would help me and build from there.

### Language

I chose to build this tool in a delightful little language called Elm. It is a functional language made for web-apps. It compiles to JavaScript, is fully compatible with all browsers that matters, is very fast and quite small. The functional nature and the type system near guarantee no runtime exceptions.

### testing

I built the module for the logic, state and encode/decode thereof first. I created tests alongside my efforts to validate my code. After beeing confident I had most basic features in place I built the _Main module_. It was responsible for the on-page representation of the calculator and for handling input and storing and retrieving state from local storage

## Features
- App is installable as a pwa
- 

## Future

### Ideas

- storing used foodstuffs on a backend somewhere.
- user accounts to share lists between devices.
- share lists by links
- have adds and make money (maybe even a whole SEK)
- remake ui in elm-ui
- build time and commit hash insted of current buildTag
- 

### TODOs

#### Bugs/Reliability
- have rollback option for broken service worker
- update manifest on main branch with all icons

#### Refactoring
- remove :not() from css
- set max-width on #main instead of child components

#### Features

- highlight food if kcal estimate missmatch the given value
- tooltip for kcal estimate
- Save and restore several meals
- toggle light/dark mode
- have feature-flags be dynamic (currently a file)
- allow simple math in number input boxes (+-/*)
- scale all ingredients together, upscale meal/recepie
- have options page:
  - dark/light mode (today it's dependent och client)

#### Interaction/UI

- have kcal estimate as placeholder in input, move it below when input is focused or there is a value
- click outside of edit input to close
- have search work of name field
- hide manual add when search is active
- focus input when edit is invoked
- close edit on enter
- next edit field on tab
- prev edit field on shift+tab
- make input feedback more clear
- check contrast in colors (e.g. text and text-muted)
- add units to list
- search and manual as part of foods list (e.g. last entry in list is search and manual)

#### Other
- add icon for ios (apple-touch-icon). [link](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html)
- create new icons

---
