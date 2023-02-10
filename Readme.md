# strandersson.se
_A domain and collection of tools and things for our family._ ([link](https://strandersson.se))

Johan Strand: [jst.dev](https://jst.dev)
____________
____________
# Meal Calculator
a tool for myself when cooking. Makes it easier to calculate macros (protein, carbs and fat) and kcal for my lunchboxes

 

## Development Process
As the nature of this is a hobby-project and a help for myself I decided to start small with the minimum that would help me and build from there. 

### Language
I chose to build this tool in a delightful little language called Elm. It is a functional language made for web-apps. It compiles to JavaScript, is fully compatible with all browsers that matters, is very fast and quite small. The functional nature and the type system near guarantee no runtime exceptions. 

### testing 
I built the module for the logic, state and encode/decode thereof first. I created tests alongside my efforts to validate my code. After beeing confident I had most basic features in place I built the _Main module_. It is is responsible for the on-page representation o the calculator and for handling input and storing and retrieving state from local storage 

## Future
### Ideas
- on-page search and retrieval of product. (maybe _livsmedelsverket_ has an API I can use)
- storing used foodstuffs on a backend somewhere. 
- user accounts to share lists between devices.
- share lists by links
- have a table of most common foodstuffs
- have adds and make money (maybe even a whole SEK)
- remake ui in elm-ui


### TODOs

#### Features
- show percentage for macros per weight
- show percentage for macros per kcal
- highlight food if kcal estimate missmatch the given value
- tooltip for kcal estimate
#### Interaction
- click outside of edit input to close
- have kcal estimate as placeholder in input, move it below when input is focused or there is a value
- focus input when edit is invoked
- close edit on enter
- next edit field on tab
- prev edit field on shift+tab
#### Clarity
- make input feedback more clear
- add units to list
- prettier "remove"
- find a layout for phone

____________
____________
