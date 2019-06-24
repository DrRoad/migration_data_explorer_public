ga_track =
   ## Arguments:
   ##  selector - the CSS selector used to identify the elements to track
   ##  events - passed to jQuery .on(), see http://api.jquery.com/on/
   ##           One or more space-separated event types and optional namespaces,
   ##            such as "click" or "keydown.myPlugin"
   ##  category, action - passed to the Google Analytics function.
   ##  label - passed to the Google Analytics function.
   ##          If NULL (default), nothing is passed.
   ##  value - passed to the Google Analytics function.
   ##          If NULL (default), nothing is passed.
   ##          Must be a non-negative number (integer?), thus of limited value...
   ##  condition - a condition that must be true for the event to be tracked by ga
   ##              If NULL (default), no condition
   ##
   ## Arguments passed to the Google Analytics function can have the following form:
   ##  NULL - nothing is passed, note though that category and action must have values
   ##  a call - contents passed directly, e.g. call("JS", "Date.now()") --> "Date.now()"
   ##  vector of length 1 - passed as encoded string
   ##                       e.g "hello" --> "\"hello\""
   ##  vector of length 2 - specifies a value to grab from the event target,
   ##                       e.g. c("attr", "id") to get the id.
   ##  vector of length 3 - specifies a value to grab, as per length 2, but then
   ##                       appends the third element as raw JavaScript.
   ##                       This can be used to parse the value to some other result.
   ##                       e.g. c("prop", "checked", '?"checked":"unchecked"')
   ##                       --> if(prop("checked") == true)
   ##                              return "checked"
   ##                           else
   ##                              return "unchecked"
   ##  list of arguments - each vector in the list will be parsed as above
   ##                      then concatenated into a single character string.
   function(selector, events, category = NULL, action = NULL, label = NULL, value = NULL, condition = NULL){
      enc = function(x) if(!is.na(x)) encodeString(x, quote = '"') else ""
      ga_parse =
         ## Parses arguments to be passed to ga()
         function(x){
            if(is.null(x)){
               "null"
            } else if(is.call(x)){
               x[[2]]
            } else if(is.list(x)){
               xs = list()
               for(i in seq(length = length(x)))
                  xs[[i]] = ga_parse(x[[i]])
               paste0("[",
                  do.call(paste, c(xs, list(sep = ","))),
               "].join(;)")
            } else if(length(x) == 3){
               paste0("curtar.", x[1], "(", enc(x[2]), ")", x[3])
            } else if(length(x) == 2){
               paste0("curtar.", x[1], "(", enc(x[2]), ")")
            } else if(length(x) == 1){
               enc(x)
            } else{
               stop(paste0("Invalid argument for ", as.character(substitute(x))))
            }
         }
      
      ## Check category and action are not NULL
      if(is.null(category) || is.null(action))
         stop("category and action must have values provided (not NULL)")
      
      ## Formulate call to Google Analytics
      gacall = paste0(
         "ga('send', 'event', ",
             ga_parse(category), ", ",
             ga_parse(action), ", ",
             ga_parse(label), ", ",
             ga_parse(value), ");"
      )
      if(!is.null(condition)) gacall = paste0(
         "if(", ga_parse(condition), "){",
         gacall,
         "}"
      )
      jsfunc = paste0(
         "var curtar = $(e.currentTarget); ",
         gacall
      )
      
      ## Return the event binding
      paste0("$(document).on(",
               enc(events), ", ",
               enc(selector), ", ",
               "function(e){",
               jsfunc,
               "});")
   }

ga_engage_set =
   ## Bind a function to record the time when the event occured for selector
   ## Arguments selector and events are the same as for ga_track
   function(selector, events){
      enc = function(x) if(!is.na(x)) encodeString(x, quote = '"') else ""
      paste0("$(document).on(",
               enc(events), ", ",
               enc(selector), ", ",
               "function(e){",
               "ga_engage[", enc(selector), "] = Date.now();",
               "});")
   }
ga_engage_get =
   ## A JavaScript expression that will compute
   ##  time (in seconds) since engagement.
   function(selector){
      enc = function(x) if(!is.na(x)) encodeString(x, quote = '"') else ""
      call("JS", paste0("Math.round((Date.now() - ga_engage[", enc(selector), "])/1000)"))
   }
ga_engage_cond =
   ## A JavaScript expression that will evaluate to a true or false
   ##  based on the supplied condition
   ## cond is checked against the engagement time,
   ## e.g. ">1" --> true if engagement time (in seconds) > 1
   function(selector, cond){
      enc = function(x) if(!is.na(x)) encodeString(x, quote = '"') else ""
      ga_get = ga_engage_get(selector)[[2]]
      call("JS", paste0(ga_get, cond))
   }
ga_engage =
   ## Wrapper to call ga_engage_set, ga_track and ga_engage_get
   ##  for the most common case of engagement
   ## Only fires for engagement longer than 1 second (rounded from milliseconds).
   function(selector, category = NULL, action = NULL, label = NULL) paste(
      ## Begin tracking engagement when mouse enters
      ga_engage_set(selector, "mouseenter"),
      ## Store time engaged as value when mouse leaves
      ga_track(selector, "mouseleave",
               category = category,
               action = action,
               label = label,
               value = ga_engage_get(selector),
               condition = ga_engage_cond(selector, ">1"))
   )

ga_selectInput = function()
   ga_track("select", "change",
            category = c("attr", "id"),
            action = "select",
            label = c("val", NA))
ga_radioButtons = function()
   ga_track("div.radio input", "change",
            category = c("attr", "name"),
            action = "radio",
            label = c("attr", "value"))
ga_checkboxComboInput = function() paste(
   ## Check All
   ga_track("div.checkboxcombo div.checkboxcombo-all input", "change",
            category = c("attr", "id"),
            action = c("prop", "checked", '?"checked":"unchecked"')),
   ## Options
   ga_track("div.checkboxcombo div.shiny-options-group input", "change",
            category = c("attr", "name"),
            action = c("prop", "checked", '?"checked":"unchecked"'),
            label = c("attr", "value"))
)
ga_downloadButton = function()
   ga_track("a.shiny-download-link,a.download-link", "click",
            category = c("attr", "id"),
            action = "download")
ga_tabPanel = function()
   ga_track('a[data-toggle="tab"]', "click",
            category = c("attr", "data-value"),
            action = "tabchange")
ga_dygraph = function()
   ga_engage("div.dygraphs",
             category = c("attr", "id"),
             action = "engagement",
             label = "dygraphs")
ga_highchart = function()
   ga_engage("div.highchart",
      category = c("attr", "id"),
      action = "engagement",
      label = "highchart")
ga_dataTable = function()
   ga_engage("div.shiny-datatable-output",
            category = c("attr", "id"),
            action = "engagement",
            label = "dataTable")

ga_common = function()
   tags$script(HTML(paste(
      "ga_engage = {};",
      ga_selectInput(),
      ga_radioButtons(),
      ga_checkboxComboInput(),
      ga_downloadButton(),
      ga_tabPanel(),
      ga_dygraph(),
      ga_highchart(),
      ga_dataTable()
   )))

## Create a fake `ga` function to test data collection
ga_test = function() tags$script("galog = []; ga = function(){galog.push(arguments);};")
