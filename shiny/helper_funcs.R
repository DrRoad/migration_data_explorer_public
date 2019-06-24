brac = function(x) paste0("(", x, ")")
enc = function(x) encodeString(x, quote = '"')
grepcheck =
   ## Wrapper for using grep to check existence
   function(pattern, x, ...) length(grep(pattern, x, ...)) > 0
sum_by =
   ## A wrapper for an efficient grouped-sum using "data.table"
   ## Groups the dataset "dset" by "dgroups" and computes the
   ##  sum of columns "dy".
   function(dset, dy, dgroups){
      if(!is.data.table(dset)) dset = data.table(dset)
      dset[, lapply(.SD, sum), keyby = dgroups, .SDcols = dy]
   }
sum_by_dplyr =
   ## Equivalent to `sum_by` but implemented in "dplyr"
   ## This is slightly faster for 1-2 groups,
   ##  about the same for 3-4 groups,
   ##  and substantially slower for 5+ groups.
   ## The main purpose of this function is to help people
   ##  who know "dplyr" but not "data.table", so they
   ##  can understand what the function does.
   function(dset, dy, dgroups){
      dset %>%
         group_by_at(dgroups) %>%
         summarise_at(dy, sum) %>%
         ungroup()
   }
summarise_by =
   ## A more generalised version of `sum_by`, allowing for
   ##  any summarising function, not just `sum`.
   ## For some reason this becomes considerably slower than
   ##  `sum_by` as the number of groups increases.
   function(dset, dy, dgroups, yf = sum){
      if(!is.data.table(dset)) dset = data.table(dset)
      dset[, lapply(.SD, yf), by = dgroups, .SDcols = dy]
   }
summarise_by_dplyr =
   ## Equivalent to `summarise_by` but implemented in "dplyr"
   ## This is considerably slower, and is mainly here to
   ##  aid understanding.
   function(dset, dy, dgroups, yf = sum){
      dset %>%
         group_by_at(dgroups) %>%
         summarise_at(dy, yf) %>%
         ungroup()
   }
backname =
   ## Wrapper for reversing name-vector to vector-name.
   function(x) structure(names(x), .Names = x)
mbie.cols2 =
   ## mbie.cols that supports more than 7 colours
   function(x = 1:7){
      MBIE.cols = structure(
         c("#006272", "#97D700", "#00B5E2", "#753BBD", "#DF1995", "#FF6900", "#FBE122"),
         .Names = c("Teal", "Green", "Blue", "Purple", "Pink", "Orange", "Yellow")
      )
      if (x[1] == "Duo1")
         x <- 1:2
      if (x[1] == "Trio1")
         x <- 1:3
      if (x[1] == "Duo2")
         x <- 2:3
      if (x[1] == "Trio2")
         x <- 3:5
      if (x[1] == "Duo3")
         x <- 4:5
      if (x[1] == "Trio3")
         x <- c(4, 6:7)
      if (x[1] == "Duo4")
         x <- 6:7
      if (x[1] == "Duo5")
         x <- c(4, 7)
      if(max(x) <= 7 || mode(x) == "character")
         as.vector(MBIE.cols[x])
      else
         colorRampPalette(MBIE.cols)(max(x))[x]
   }
mbie.cols.scale =
   ## Scales an mbie colour towards a target colour
   ## Usually black (for greater contrast against white)
   ##      or white (for a faded look)
   function(x, mag = 0.8, target = "white")
      do.call(rgb, as.list(colorRamp(c(mbie.cols2(x), target))(mag)/255))

htable = local({
   ## Function for a minimalist conversion of an R character matrix to
   ##    an HTML table. The output table should be styled via CSS.
   ## Cells will span column-wise into empty cells (cells with value NA),
   ##    e.g. c("A", NA, NA) -> <td colspan=3>A</td>
   ## Values are NOT escaped,
   ##    If required escape prior to calling via `htmltools::htmlEscape`
   ##
   ## Arguments:
   ## -mat-
   ## The only required argument. A character matrix to be converted.
   ##
   ## -rhead-
   ## The rows to be set as the "header" using <thead>,
   ##    while the rest go into a <tbody>.
   ## If NULL, everything goes directly under the <table>.
   ## Recommended for accessibility reasons.
   ##
   ## -caption-
   ## Text to be placed inside a <caption>.
   ## Recommended for accessibility reasons.
   ##
   ## -tclass-
   ## Any classes to be set to the output <table>.
   ## No parsing is done, so for multiple classes need
   ##    to provide as a space-delimited list.
   ##    e.g. "class1 class2"
   
   ## Various supporting functions
   mcell = function(x, tagName)
      paste0("<", tagName, ">", x, "</", tagName, ">")
   mcspan = function(x, spans, tagName)
      paste0("<", tagName, " colspan=", spans, ">", x, "</", tagName, ">")
   mrow = function(x, tagName = "td"){
      rcontent = if(any(is.na(x)))
         mcspan(x[!is.na(x)], diff(c(which(!is.na(x)) - 1, length(x))), tagName)
      else
         mcell(x, tagName)
      paste0("<tr>", paste(rcontent, collapse = ""), "</tr>")
   }

   ## Main function
   function(mat, rhead = NULL, caption = NULL, tclass = NULL){
      if(!is.null(rhead)){
         content = paste(sep = "\n",
            "<thead>",
            paste(apply(mat[rhead,,drop=FALSE], 1, mrow, "th"), collapse = "\n"),
            "</thead>",
            "<tbody>",
            paste(apply(mat[-rhead,,drop=FALSE], 1, mrow), collapse = "\n"),
            "</tbody>"
         )
      } else{
         content = paste(apply(mat, 1, mrow), collapse = "\n")
      }
      
      if(!is.null(caption))
         caption = paste(sep = "\n",
            "<caption>",
            caption,
            "</caption>"
         )
      
      ttag = if(is.null(tclass)) "<table>"
         else paste0("<table class=", encodeString(tclass, quote = '"'), ">")

      paste(sep = "\n",
         ttag,
         caption,
         content,
         "</table>"
      )
   }
})

highchartOutputWithDownload =
   ## Wrapper for creating a highchartOutput with
   ##  attached buttons for PNG and Print options.
   ## Has a JS component called `hc_download` in "helper_funcs.js".
   ## Arguments:
   ## -outputId-
   ## id to use for the highchart output.
   ##
   ## -width- and -height-
   ## Passed to `highchartOutput`
   ##
   ## -extraInputs-
   ## Additional inputs to put in menu bar with the download buttons.
   ## If "extraInputs" is supplied, the download buttons are floated to
   ##  the right, while the extra inputs take over the regular space on the left.
   function(outputId, width = "100%", height = "400px", extraInputs = NULL){
      inputBar = div(
         actionButton(paste0(outputId, "-png"), "Download Chart as PNG",
            icon = icon("image"), class = "hc-pngbtn"),
         actionButton(paste0(outputId, "-print"), "Print Chart",
            icon = icon("print"), class = "hc-printbtn")
      )
      if(!is.null(extraInputs)){
         inputBar$children = lapply(inputBar$children, function(x)
            tagAppendAttributes(x, class = "float-right"))
         inputBar = inputBar %>%
            tagAppendAttributes(class = "float-con") %>%
            tagAppendChildren(extraInputs)
      }
      div(class = "hc-outputgroup",
         inputBar,
         highchartOutput(outputId, width = width, height = height)
      )
   }

popPanel =
   ## Allows the user to "pop-out" an input panel, dragging it
   ##  around so they can keep it with them.
   ## Has a JS component called `popinput` in "helper_funcs.js".
   function(...){
      div(class = "pop-input-con", role = "region", `aria-label` = "Input group",
         tags$button(type = "button",
            class = "pop-input-btn pop-input-out",
            title = "Pop-out Input Panel",
            tags$i(class = "glyphicon glyphicon-new-window")
         ),
         div(class = "pop-input", ...)
      )
   }

HelperFuncsJS = tagList(
   includeScript("helper_funcs.js"),
   tags$script(HTML('$(function(){HelperFuncs.init();});'))
)

## Adds datePicker Dependency and sets some default options
datePickerHead = tagList(
   shiny:::datePickerDependency,
   tags$script(HTML(paste(sep = "\n",
      "$.fn.bsDatepicker.defaults.minViewMode = 1;",
      "$.fn.bsDatepicker.defaults.format = 'MM yyyy';",
      "$.fn.bsDatepicker.defaults.autoclose = true;"
   )))
)

###########################
## Main tab environments ##
###########################
## Each tab has a local environment that is used to declare
##  shared variables and functions, that are then used to
##  create the ui object and the server function (called from server.R)
## This effectively creates small virtual shiny apps, which
##  are then added to tabs of the shiny app.
## Each local environment begins by defining the "baseid"
##  and the function "makeid", which are used to create an
##  informal namespace.
BetterCSVs = local({
   ## Originally born out of experiments to improve how Immigration
   ##  New Zealand csv data is published.
   ## Now it is used as a generic Data Explorer feature.
   ## This tab has been designed around handling a (potentially)
   ##    large number of large-ish datasets (100,000+ rows).
   ## This presents a number of challenges:
   ## 1) Initial load times.
   ##    The load time of each large dataset isn't overly long
   ##       individually, but collectively become non-trivial.
   ##    To avoid the delays associated with loading multiple such
   ##       datasets at once, they are loaded on-demand.
   ##    Refer to "Load data on-demand" section for more details.
   ## 2) Run-time performance
   ##    Processing large datasets on-the-fly can be time-consuming.
   ##    Care should be taken to keep processing times down.
   ##    When adding, modifying or removing code, consider carefully
   ##       why it's there, if that's the best place for it, and how
   ##       it's doing what it's doing and whether that's the best way.
   ##    If, after all that, the processing time is still seen to be overly
   ##       long, sections of code should be timed to see what areas are
   ##       causing the biggest delays, and these sections optimised.
   ##    If further performance gains are required, performance-oriented
   ##       R packages like Rcpp might be an option.

   baseid = "BetterCSVs"
   makeid = function(x) paste(baseid, x, sep = "_")
   
   str_nodata = "NO DATA SELECTED"
   str_datevar = "Date"
   extra_dnames = c(str_nodata, "pop", "flow")
   names(extra_dnames) = c(str_nodata, "Population", "Visa Flows")
   all_dnames = c(extra_dnames, all_csv_names)
   all_vnames = str_nodata
   
   ## Date options
   ## date_kinds is used for the input
   ## date_cnames are the column names in the actual data
   date_kinds = c(
      "Financial Year" = "fy",
      "Calendar Year" = "cy",
      "Monthly" = "m"
   )
   date_cnames = c(
      "fy" = "Financial Year",
      "cy" = "Calendar Year",
      "m" = "Date"
   )
   ## Set column name where actual Date vectors are kept
   ## Used when we need to do actual date comparisons
   datereal_cname = date_cnames[["m"]]
   
   cond_types = c("CONTAINS", "DOES NOT CONTAIN")
   cond_types_date = c("EQUALS", "AFTER", "BEFORE")
   
   ## Maximum variables allowed
   vars_max = 4
   ## Ideal values for preview table
   n_tab_row = 50
   n_tab_min_cats = 2
   ## Maximum series (at a time) in preview time-series
   n_max_ts = 5
   ## Seasonal adjustment
   n_max_seas = 25
   
   condPanel =
      ## Convenience wrapper to conditionalPanel
      function(jsCond, ...){
         conditionalPanel(paste(jsCond, collapse = " "), ...)
      }
   js_input = function(id) paste0("input[", enc(makeid(id)), "]")
   js_eqto = function(id, x) paste0(js_input(id), "==", enc(x))
   js_neqto = function(id, x) paste0(js_input(id), "!=", enc(x))
   
   ## datasets for which seasonal adjustment is valid
   seas_allowed = c(
      list(pop = "any"),
      list(flow = "any"),
      list(any = "m")
   )
   seas_allowed_R = function(seas, dname, datekind){
      if(!is.null(seas) && !is.null(dname) && !is.null(datekind)){
         seas &&
         ((datekind %in% seas_allowed$any) ||
          (datekind %in% seas_allowed[[dname]]) ||
          ("any" %in% seas_allowed[[dname]]))
      } else FALSE
   }
   seas_allowed_JS = tags$script(HTML(paste0(
      "var seas_allowed = function(){",
         "var defs=", jsonlite::toJSON(seas_allowed), ";",
         "return function(dname, datekind){",
            "if(defs.any.indexOf(datekind) > -1){",
            "  return true;",
            "}",
            "if(defs[[dname]] !== undefined){",
               "if(defs[[dname]].indexOf(datekind) > -1 ||",
                  "defs[[dname]][0] === 'any'){",
                  "return true;",
               "} else{return false;}",
            "} else{return false;}",
         "};",
      "}();"
   )))
   seas_cond = paste0("seas_allowed(", js_input("dname"), ",", js_input("datekind"), ")")
   
   hcfunction_null = function(output, id, initRender)
      output[[id]] = renderHighchart(highchart())
   
   ########################################
   ## Load data on-demand
   ########################################
   ## For performance reasons, we only want to load the datasets as
   ##    needed, because they are both large and numerous.
   ## This is achieved as follows:
   ## 1) Define a storage area, "dstore", which is an environment defined
   ##       at the tab environment level.
   ## 2) When a user selects a dataset, a check is made against "dstore"
   ##       to see if it already exists.
   ## 3) If it does not exist, the dataset is loaded into "dstore".
   ## 4) Once loaded, a JS message is sent with metadata to the client browser.
   ##    These are:
   ##    "dname" - the dataset name
   ##    "vnames" - variable names
   ##    "vdates" - additional date-like variables (e.g. Financial Year)
   ##                these are treated like regular variables for conditions
   ##    "vvals" - the levels of each variable (including date-like variables)
   ##    "presel" - an index (starting at 0) of variables to pre-select,
   ##                this is currently fixed at 0 (i.e. the first variable) but
   ##                could be adjusted as required.
   ##    This metadata is used by the JS component to drive the client ui
   ##       without having to constantly talk to the server.
   ##
   ## When deployed to shinyapps, a complication arises.
   ## The shinyapps infrastructure allows for multiple server "sessions"
   ##    of shiny to run off the same initial load.
   ## What this means is that multiple "sessions" can access the same
   ##    "dstore" (which resides in the tab environment, and thus
   ##    can be shared across "sessions").
   ## This results in further performance gains, as we don't have to
   ##    load data that has already been loaded by another "session".
   ## However, while the R server will have access to the shared data,
   ##    from a load by another session, each individual client browser
   ##    needs to be sent its own JS metadata to drive the client ui.
   ## Thus another environment, "dstore_sess", is defined within the server
   ##    function, to give a session-specific listing of loaded datasets.
   ## During step (2), when a user selects a dataset, a check is also made
   ##    against "dstore_sess" to see if the client for this session is
   ##    loading a new dataset or not. If it is new, the JS metadata is
   ##    prepared as normal (though the loading of the actual dataset into
   ##    "dstore" may be skipped if it already exists in "dstore").
   dstore = new.env()
   dstore_server = function(input, output, session){
      dstore_sess = new.env()
      observe({
         dname = input[[makeid("dname")]]
         ## Check if a real dataset and not already loaded for current session
         if(dname != str_nodata && all(names(dstore_sess) != dname)){
            ## Check if already in "dstore", if not, load
            if(all(names(dstore) != dname)){
               cat("Loading", dname, "\n")
               print(try(system.time(load(paste0(dname, ".rda"), dstore)), TRUE))
            }
            ## Update "dstore_sess"
            dstore_sess[[dname]] = TRUE
            
            ## Check to ensure data exists (it might not if load failed for some reason)
            if(!is.null(dstore[[dname]])){
               ## Prepare and send metadata
               cat("Sending message for", dname, "\n")
               
               ## Find the variable names, split into categories
               vnames_all = names(dstore[[dname]])
               vnames_count = "Count"
               vnames_dates = vnames_all[vnames_all %in% date_cnames]
               vnames = vnames_all[!vnames_all %in% c(vnames_count, vnames_dates)]
               
               ## Variable values
               ## Date variables are included here so they can be used
               ##  for applying conditions
               vnames_w_dates = c(vnames, vnames_dates)
               vvals = lapply(vnames_w_dates, function(x){
                  curvar = dstore[[dname]][[x]]
                  if(is.factor(curvar)) I(levels(curvar)) else I(sort(unique(curvar)))
               })
               names(vvals) = vnames_w_dates
               
               ## Certain variables have priority in being an initial selection
               presel_vars = c("Decision Type")
               if(any(vnames %in% presel_vars)){
                  ## Set presel to the position of the first matching presel_vars
                  presel = which(vnames == presel_vars[presel_vars %in% vnames][1]) - 1
               } else{
                  ## If no match, default is first variable
                  presel = I(0)
               }
               
               ## Send message
               msg = list(dname = dname,
                  vnames = I(vnames), vdates = I(vnames_dates),
                  vvals = I(vvals), presel = presel
               )
               session$onFlushed(
                  once = TRUE,
                  function() session$sendCustomMessage("dstore", msg)
               )
            }
         }
      })
   }
   
   ########################################
   ## Handle conditions
   ########################################
   ## See also: `cond` in "helper_funcs.js"
   ##
   ## The JavaScript component handles updates to the
   ##    conditions ui, and the collection of values.
   ## It then sends these values as a JSON stringified message
   ##    to the Shiny server. The message is stringified to
   ##    protect the data structure from processing by Shiny's
   ##    own methods.
   ## If "conds" is NULL, that means no message has been received
   ##    yet from the JS component.
   ## Otherwise, we must deparse the stringified message.
   ## After the deparse, the value may still be NULL if there are
   ##    no valid conditions.
   ## Otherwise, the deparsed "conds" is an unnamed list:
   ##    each element of this list is a condition,
   ##    each condition is itself a named list containing:
   ##       "vname" - Variable name
   ##       "vtype" - Condition type magic-word
   ##       "vvals" - Vector of values
   ##    e.g.
   ##       list(vname = "Country", vtype = "CONTAINS", vvals = c("China", "Japan"))
   ##
   ## The "vtype" and "vname" are then further parsed into a "vpredicate",
   ##    to convert magic words (e.g. "CONTAINS") to a predicate expression
   ##    understood by dplyr (e.g. `all_vars(. %in% cur_cond$vvals)`).
   ##
   ## Finally, an "isDate" logical is added to the "conds", which is TRUE
   ##    if it is a date condition. Date conditions are evaluated first,
   ##    so that a check for any partial years (that arise from applying
   ##    date conditions) can be done first, before the remaining conditions
   ##    are applied.
   cond_parse = function(conds){
      if(!is.null(conds)){
         conds = jsonlite::fromJSON(conds, simplifyVector = TRUE, simplifyDataFrame = FALSE)
         ## Need another is.null check as the deparsed result might be NULL
         if(!is.null(conds)){
            for(i in 1:length(conds)){
               cur_cond = conds[[i]]
               
               ## For Date conditions, need to:
               ##  1) set name to the actual date column
               ##  2) convert value to a real date
               if(cur_cond$vname == str_datevar){
                  cur_cond$vname = datereal_cname
                  cur_cond$vvals = as.Date(as.yearmon(cur_cond$vvals), 1)
               }
               ## Check if the condition applies to any of the
               ##  date-related columns (not just Date, but also the Year columns)
               cur_cond$isDate = any(cur_cond$vname == date_cnames)
               
               cur_cond$vpredicate = with(cur_cond, switch(vtype,
                  "EQUALS" =,
                  "CONTAINS" = all_vars(. %in% vvals),
                  "DOES NOT CONTAIN" = all_vars(!. %in% vvals),
                  "AFTER" = all_vars(. >= vvals),
                  "BEFORE" = all_vars(. <= vvals),
                  all_vars(TRUE)
               ))
               
               conds[[i]] = cur_cond
            }
         }
      }
      conds
   }
   ## Apply the conditions on the given dataset
   cond_eval = function(curdat, conds, isDate){
      if(!is.null(conds)){
         for(i in 1:length(conds)){
            cur_cond = conds[[i]]
            if(cur_cond$isDate == isDate)
               curdat = filter_at(curdat, cur_cond$vname, cur_cond$vpredicate)
         }
      }
      curdat
   }
   
   ########################################
   ## Check for partial years
   ########################################
   ## Check for, and note (by adjusting label) any partial years.
   ##    e.g. "2017 Partial (Jan-Jul)"
   ## Procedure:
   ## 1) Group by the current year type
   ## 2) Create summaries of:
   ##    - nMonths: Number of unique months found for the year
   ##    - fmtRange: A formatted character string giving the month range
   ##       e.g. "Jan-Jul" or "Mar-Nov" or "Mar" (if single month)
   ## 3) For any years with nMonths < 12, adjust the year label
   ##       e.g. "2017 Partial (Jan-Jul)"
   check_partial_years = function(curdat, datekind){
      if(any(datekind == c("cy", "fy"))){
         date_cname = date_cnames[[datekind]]
         d_datecheck = curdat %>%
            group_by_at(date_cname) %>%
            summarise_at(datereal_cname, funs(
               nMonths = length(unique(.)),
               fmtRange = paste(format(unique(range(.)), "%b"), collapse = "-")
            )) %>%
            filter(nMonths < 12) %>%
            as.data.frame()
         if(nrow(d_datecheck) > 0){
            if(!is.factor(curdat[[date_cname]]))
               curdat[[date_cname]] = factor(curdat[[date_cname]])
            d_levels = levels(curdat[[date_cname]])
            for(i in 1:nrow(d_datecheck)){
               d_which = d_levels == d_datecheck[i, date_cname]
               d_levels[d_which] = paste(
                  d_datecheck[i, date_cname], "PARTIAL",
                  brac(d_datecheck[i, "fmtRange"])
               )
            }
            levels(curdat[[date_cname]]) = d_levels
         }
      }
      curdat
   }
   
   ########################################
   ## Create combined variable
   ########################################
   ## Many procedures can only handle a single variable at a time,
   ##    e.g. time-series can only plot 1 variable vs time
   ## To handle multiple variables at the same time, the variables
   ##    are combined into a single concatenated variable,
   ##    e.g. "Male" and "China" are combined to "Male & China".
   ## If no variables are selected, a "fake" combined variable
   ##    is created with the value "Total".
   ## The combined variable is then ranked by size.
   ## The returned value is a factor of the combined variable,
   ##    with the levels ordered by size-rank.
   create_combi = function(dat, dvars){
      if(length(dvars) == 0){
         ## NO variables selected -> COMBI = "Total"
         combi = factor(rep("Total", length = nrow(dat)))
      } else{
         ## Combine all selected variables into a single variable
         combi = factor(do.call(paste, c(dat[dvars], list(sep = " & "))))
         
         ## Rank by the combined variable
         rankvars = dat %>%
            mutate(COMBI = combi) %>%
            sum_by("Count", "COMBI") %>%
            arrange(desc(Count)) %>%
            `[[`("COMBI")
         
         combi = factor(combi, levels = rankvars)
      }
      combi
   }
   
   ########################################
   ## Seasonal adjustments
   ########################################
   ## Apply seasonal decomposition on every sub-series, up to
   ##    a maximum of n_max_seas series (can take a long time
   ##    to run it for every sub-series without limit).
   ## The algorithm used is `stl`.
   ## The seasonal decomposition is applied on the log(data) (as
   ##    effects appear to be multiplicative), assuming a fixed
   ##    seasonal effect (not necessarily correct but simpler to
   ##    interpret).
   ## The trend from the decomposition is returned, along with
   ##    the (multiplicative) seasonal effects.
   seasadj_make = function(combidat, allDates, date_cname){
      dfDates = data.frame(Date = allDates)
      seasout = list()
      seaseff = list()
      
      ## COMBI in combidat should already be sorted by size
      ## so can grab the first n_max_seas to get the biggest sub-series.
      if(length(levels(combidat$COMBI)) > n_max_seas){
         combidat = combidat %>%
            filter(COMBI %in% levels(COMBI)[1:n_max_seas]) %>%
            mutate(COMBI = factor(COMBI))
      }
      for(curcombi in levels(combidat$COMBI)){
         ## left_join to a data.frame with every date, to check
         ##    for any missing date periods in our current sub-series.
         ## Trim NAs on either side, as we're only worried about missing values
         ##    in the middle of the series.
         dat_tsprep = left_join(dfDates,
            filter(combidat, COMBI == curcombi),
            by = c("Date" = date_cname)) %>%
            na.trim()
         ## Only proceed with the seasonal decomposition if:
         ## 1) There are no NA values - `stl` can't handle them,
         ##    but more importantly, an NA means 0 in our data.
         ##    Not much sense to do seasonal decomposition on tiny values.
         ##    If this is extended to other data, could use `na.approx`
         ##    to interpolate (true) missing values.
         ## 2) If there is enough data - `stl` requires a minimum of
         ##    period-length * 2 + 1
         if(all(!is.na(dat_tsprep$Count)) && all(dat_tsprep$Count > 0) && nrow(dat_tsprep) > 12 * 2){
            ## Coerce start-date to the required format for `ts`
            dstart = as.numeric(strsplit(format(min(dat_tsprep[[date_cname]]),
               "%Y-%m"), "-")[[1]])
            dat_ts = ts(dat_tsprep$Count, start = dstart, frequency = 12)
            dat_stl = stl(log(dat_ts), "periodic")
            ind_months = sapply(1:12, function(x) which(cycle(dat_stl$time.series) == x)[1])
            dat_seas = dat_stl$time.series[ind_months,"seasonal"]
            dat_trend = exp(dat_stl$time.series[,"trend"] + median(dat_seas))
            seas_effect = (exp(dat_seas - median(dat_seas)) - 1) * 100
            
            dat_tsprep$Count = as.numeric(dat_trend)
            seasout[[curcombi]] = dat_tsprep
            seaseff[[curcombi]] = seas_effect
         }
      }
      
      if(length(seasout) > 0)
         list(dat = do.call(bind_rows, seasout), effect = do.call(cbind, seaseff))
      else
         NULL
   }
   
   ########################################
   ## Create preview table
   ########################################
   ## While the full data is available for download, we want
   ##    to limit how many rows we show at once on the page itself.
   ## If the full data has too many rows, only the
   ##    "n_max" rows with the largest Count are shown.
   divvy_allocate =
      function(divvy, cur_len){
         divvy$allocate = divvy$todivvy^(1/divvy$ncats) %>%
            ceiling() %>%
            max(n_tab_min_cats) %>%
            min(cur_len)
         divvy$todivvy = ceiling(divvy$todivvy/divvy$allocate)
         divvy$ncats = divvy$ncats - 1
         divvy
      }
   make_preview_dat =
      function(dat_table, date_cname, dvars){
         if(!is.null(dvars)){
            out = mutate_at(dat_table, dvars, factor)
            len_vars = sapply(dat_table[dvars], function(x) length(levels(x)))
         } else{
            out = dat_table
            len_vars = 0
         }
         len_date = length(unique(dat_table[[date_cname]]))
         divvy = list(ncats = sum(len_date > 1) + sum(len_vars > 1),
                      todivvy = n_tab_row)
         
         ## Divvy to Date
         divvy = divvy_allocate(divvy, len_date)
         dates_tokeep = out[[date_cname]] %>%
            unique() %>%
            sort(decreasing = TRUE) %>%
            `[`(seq_len(divvy$allocate))
         out = filter_at(out, date_cname, all_vars(. %in% dates_tokeep))
         
         ## Divvy to remaining vars
         for(i in seq_along(dvars)){
            curvar = dvars[i]
            cur_levels = levels(out[[curvar]])
            divvy = divvy_allocate(divvy, length(cur_levels))
            ## Simple divvy
            ## Search for the largest categories
            ## Fails for hierarchical variables (gets too few)
            cur_tokeep = out %>%
               group_by_at(dvars[i]) %>%
               summarise(Count = sum(Count)) %>%
               arrange(desc(Count)) %>%
               slice(seq_len(divvy$allocate)) %>%
               `[[`(curvar) %>%
               unique()
            out = filter_at(out, curvar, all_vars(. %in% cur_tokeep))
            
            ## Complex divvy
            ## Search for the largest category within each parent group
            ## Can fail for non-hierarchical variables (gets too many)
            ## Always slower
            if(FALSE){
               cur_tokeep = out %>%
                  group_by_at(c(date_cname, dvars[1:i])) %>%
                  summarise(Count = sum(Count)) %>%
                  arrange(desc(Count)) %>%
                  slice(seq_len(divvy$allocate)) %>%
                  `[[`(curvar) %>%
                  unique()
               out = filter_at(out, curvar, all_vars(. %in% cur_tokeep))
            }
         }
         
         arrange_at(out, c(date_cname, "Count", dvars), desc)
      }
   
   make_preview_table =
      function(dat_table, date_cname, dvars, curtitle, subtitle){
         if(nrow(dat_table) > 0){
            dat_preview = make_preview_dat(dat_table, date_cname, dvars)
            t_rows = format(nrow(dat_table), big.mark = ",")
            tab_class = "mbie_preview"
            title_html = as.character(span(class = "mbie_preview_key", curtitle))
            if(nchar(subtitle) > 0) subtitle = paste0(" ", subtitle)
            subtitle_html = as.character(span(class = "mbie_preview_subkey", subtitle))
            nnum = sum(sapply(dat_preview, is.numeric))
            if(nnum > 1)
               tab_class = paste(tab_class, paste0("mbie_preview_nnum", nnum))
            
            ## If too many rows, get sub-selection only
            if(nrow(dat_preview) < nrow(dat_table)){
               caption = paste0(
                  "Displaying a preview table with ", nrow(dat_preview),
                  " rows for ", title_html, subtitle_html, ".",
                  " The full data with ", t_rows,
                  " rows is available in the CSV download."
               )
               rem_rows = format(nrow(dat_table) - nrow(dat_preview), big.mark = ",")
               text_more_rows = c(
                  paste(
                     "...and", rem_rows, "rows not displayed",
                     "(full data available in the CSV download)"
                  ),
                  rep(NA, ncol(dat_preview) - 1)
               )
            } else{
               caption = paste0(
                  "Display all ", t_rows, " rows for ",
                  title_html, subtitle_html, ".",
                  " The same data is also available in the",
                  " CSV download."
               )
            }
            dat_preview = dat_preview %>%
               mutate_if(is.numeric, funs(format(., big.mark = ","))) %>%
               mutate_all(as.character)
            dat_preview = rbind(colnames(dat_preview), dat_preview)
            if(nrow(dat_preview) < nrow(dat_table))
               dat_preview = rbind(dat_preview, text_more_rows)
            out = HTML(htable(dat_preview, 1, caption, tab_class))
         } else out = HTML("No Data Found.")
         out
      }
   
   ########################################
   ## Create preview time-series
   ########################################
   ## As with the preview table, we limit how many series
   ##    we display at a given time, to not overwhelm the user.
   ## Data is prepared by `make_ts_dat` and stored in "preview_env",
   ##    an environment declared in the server function.
   ## It is assumed that the data passed to `make_ts_dat` is ranked by
   ##    size (by `create_combi`).
   ## The "preview_env" is then used to draw the ts (`create_ts`) and
   ##    to update it with more series (`add_more_ts`).
   ## Those two functions retrieve data from "preview_env" via
   ##    `prep_ts_args`, which retrieves the correct slice of data
   ##    and merges in seasonally adjusted data (if available).
   make_ts_dat =
      ## Minor tidying of input data for passing to `hclinebasic`
      ## Also sets up the initial index to plot
      function(combidat, date_cname, dvars, seasadj){
         dat_ts = combidat %>%
            rename_(XVAR = as.name(date_cname)) %>%
            select(XVAR, COMBI, Count)
         index_ts = 1:min(n_max_ts, length(levels(dat_ts$COMBI)))
         
         if(!is.null(seasadj)){
            seasadj$dat = seasadj$dat %>%
               rename_(XVAR = as.name(date_cname)) %>%
               select(XVAR, COMBI, Count)
         }
         
         list(dat = dat_ts, seasadj = seasadj, index = index_ts)
      }
   rename_forseas = function(x) paste(x, brac("Trend"))
   prep_ts_args =
      ## Retrieve the correct slice of data (per "index_ts")
      ##    joining seasonally adjusted data (if available).
      ## Also sets up the necessary arguments for drawing the
      ##    time-series chart correctly (e.g. colour, series styles).
      function(preview_env, index_ts){
         cur_combi = levels(preview_env$ts$dat$COMBI)[index_ts]
         curdat = preview_env$ts$dat %>%
            filter(COMBI %in% cur_combi)
         pal = preview_env$pal[index_ts]
         names(pal) = cur_combi
         seriesStyles = "Normal"
         
         ## Add matching seasonal adjustments, if they exist
         if(!is.null(preview_env$ts$seasadj)){
            seasdat = preview_env$ts$seasadj$dat %>%
               filter(COMBI %in% cur_combi)
            if(nrow(seasdat) > 0){
               levels(seasdat$COMBI) = rename_forseas(levels(seasdat$COMBI))
               ## Set up levels for combined COMBI, with correct ordering
               new_levels = as.vector(rbind(
                  rename_forseas(levels(curdat$COMBI)),
                  levels(curdat$COMBI)
               ))
               ## Join and re-factor, to get rid of non-existent levels
               ## (some series might have no seasonal-adjusted variants)
               curdat = bind_rows(
                  mutate(curdat, COMBI = factor(COMBI, levels = new_levels)),
                  mutate(seasdat, COMBI = factor(COMBI, levels = new_levels))
               ) %>% mutate(COMBI = factor(COMBI))
               
               ## Extend pal to accommodate the seas-adj series
               pal = c(pal, structure(pal, .Names = rename_forseas(names(pal))))
               
               ## Set-up correct series styles
               seriesStyles = rep("Context", length = length(levels(curdat$COMBI)))
               names(seriesStyles) = levels(curdat$COMBI)
               seriesStyles[grepl("(Trend)", names(seriesStyles), fixed = TRUE)] = "Normal"
            }
         }
         
         list(out_data = spread(curdat, COMBI, Count),
              pal = pal, seriesStyles = seriesStyles,
              showmarker = "auto", vartype = "number")
      }
   create_ts =
      ## Used for the initial set-up of the time-series
      function(preview_env, curtitle, subtitle){
         index_ts = preview_env$ts$index
         
         ts_args = prep_ts_args(preview_env, index_ts)
         ts_args$curtitle = curtitle
         ts_args$subtitle = subtitle
         
         hc = do.call(hclinebasic, ts_args)
         
         ## Return render function
         function(output, id, initRender) output[[id]] = renderHighchart(hc)
      }
   create_seasbar =
      ## Used for the initial set-up of the seasonal effects barplot
      function(preview_env){
         if(!is.null(preview_env$ts$seasadj)){
            index_ts = preview_env$ts$index
            index_seas = index_ts[index_ts %in% seq_len(ncol(preview_env$ts$seasadj$effect))]
            curdat = preview_env$ts$seasadj$effect[,index_seas,drop=FALSE]
            pal = preview_env$pal[index_seas]
            
            hc = hcbarplot(curdat, month.abb, pal = pal,
               titles = list(main = "Average Seasonal Effect",
                             y = "% Change from Trend"),
               yformat = list(prefix = "", suffix = "%", digits = 1))
         } else hc = highchart()
         
         ## Return render function
         function(output, id, initRender) output[[id]] = renderHighchart(hc)
      }
   add_more_ts =
      ## Used for proxy-adds of additional series to ts
      function(preview_env, proxy){
         combi_levels = levels(preview_env$ts$dat$COMBI)
         new_index_start = max(preview_env$ts$index) + 1
         if(length(combi_levels) < new_index_start){
            ## No more data to add
            ## Do nothing
            return(FALSE)
         } else{
            ## Compute what new series to add
            ## Generally want to add "n_max_ts" more series, but
            ##    there might not be that much data left.
            new_index = new_index_start %>%
               seq(min(new_index_start + n_max_ts - 1, length(combi_levels)))
            ts_args = prep_ts_args(preview_env, new_index)
            ts_args$proxy = proxy
            
            ## Use proxy methods to:
            ## 1) Hide all existing series (this is to limit how many
            ##       series are drawn at the same time. The user can
            ##       toggle them back on if desired).
            ## 2) Add the new series.
            ## 3) Trigger a redraw to refresh the chart.
            do.call(hclinebasic, ts_args) %>%
               hc_proxy_hide_all() %>%
               hc_proxy_add() %>%
               hc_proxy_redraw()
            
            ## Update preview_env index with newly added series
            ## As preview_env is an environment, don't need to pass back
            preview_env$ts$index = new_index
            return(TRUE)
         }
      }
   add_more_seasbar =
      ## Used for proxy-adds of additional series to seasonal effects barplot
      function(preview_env, proxy){
         if(!is.null(preview_env$ts$seasadj)){
            index_ts = preview_env$ts$index
            seff = preview_env$ts$seasadj$effect
            index_ts = index_ts[index_ts <= ncol(seff)]
            if(length(index_ts) > 0){
               curdat = seff[,index_ts,drop=FALSE]
               pal = preview_env$pal[index_ts]
               
               hcbarplot(proxy = proxy, curdat, pal = pal) %>%
                  hc_proxy_hide_all() %>%
                  hc_proxy_add() %>%
                  hc_proxy_redraw()
            }
         }
      }
   
   ########################################
   ## ui & server functions
   ########################################
   uiSeas = tagList(
      seas_allowed_JS,
      condPanel(seas_cond,
         checkboxInput(makeid("seas"), "Add seasonally adjusted trend") %>%
            tagAppendAttributes(`aria-describedby` = makeid("seasonal_caveats")),
         condPanel(js_input("seas"),
            div(id = makeid("seasonal_caveats"), `aria-hidden` = "true",
               class = "alert alert-caveats alert-dismissible", role = "alert",
               tags$button(type = "button", class = "close", `data-dismiss` = "alert",
                  span(HTML("&times;"))
               ),
               inputSeas
            )
         )
      )
   )
   uiTop = tagList(
      div(class = "float-inputs", role = "form",
         `aria-label` = "Extra controls",
         div(class = "float-right float-con",
            div(class = "float downlink-con",
               downloadButton(makeid("csv-down"), "Download Data as CSV")
            ),
            div(id = makeid("querybtn-con"), class = "float")
         )
      )
   )
   uiSide = div(class = "well inwell", role = "form",
      `aria-label` = "Input controls for choosing the table data",
      div(class = "panel panel-skinny inpanel",
         div(class = "panel-heading",
            "Dataset", title = inputTips$dname,
            span(class = "badge float-right", "?")
         ),
         div(class = "panel-body insel-con",
            tags$button(type = "button", class = "btn insel",
               "Initialising"
            )
         ),
         div(class = "list-group inlist",
            radioButtons(makeid("dname"), "Dataset", all_dnames) %>%
               tagAppendAttributes(class = "list-group-item")
         )
      ),
      uiSeas,
      div(class = "panel panel-skinny inpanel",
         div(class = "panel-heading",
            "Time Period", title = inputTips$datekind,
            span(class = "badge float-right", "?")
         ),
         div(class = "panel-body insel-con",
            tags$button(type = "button", class = "btn insel",
               "Initialising"
            ),
            div(class = "shiny-input-container", uiOutput(makeid("datekind-msg")))
         ),
         div(class = "list-group inlist",
            radioButtons(makeid("datekind"), "Time Period", date_kinds) %>%
               tagAppendAttributes(class = "list-group-item")
         )
      ),
      div(class = "panel panel-skinny inpanel",
         div(class = "panel-heading",
            paste0("Variables (max ", vars_max, ")"), title = inputTips$dvars,
            span(class = "badge float-right", "?")
         ),
         div(class = "panel-body insel-con insel-multi",
            id = makeid("dvars"), `data-max-items` = vars_max,
            tags$button(type = "button", class = "btn insel",
               value = str_nodata, str_nodata
            )
         ),
         div(class = "list-group inlist inlist-multi",
            tags$button(type = "button", class = "list-group-item list-group-item-selected",
               span(class = "glyphicon glyphicon-check"),
               value = str_nodata, str_nodata
            )
         )
      ),
      div(class = "panel panel-skinny inpanel",
         div(class = "panel-heading",
            "Filters", title = inputTips$cond,
            span(class = "badge float-right", "?")
         ),
         div(id = makeid("cond-add"), class = "filsel-con",
            tags$button(type = "button", class = "btn insel",
               icon("filter"), "Add a new filter"
            )
         )
      )
   )
   uiSideFil = div(class = "well filwell", role = "form",
      `aria-label` = "Input controls for filter specification",
      div(class = "panel panel-skinny inpanel filpanel",
         div(class = "panel-heading",
            "Variable to Filter", title = inputTips$condvar,
            span(class = "badge float-right", "?")
         ),
         div(class = "panel-body insel-con",
            tags$button(type = "button", class = "btn insel filsel",
               str_nodata
            )
         ),
         div(class = "list-group inlist",
            radioButtons(makeid("cond-var"), "Variables", str_nodata) %>%
               tagAppendAttributes(class = "list-group-item")
         )
      ),
      div(class = "panel panel-skinny inpanel filpanel",
         div(class = "panel-heading",
            "Type of Filter", title = inputTips$condtype,
            span(class = "badge float-right", "?")
         ),
         div(class = "list-group inlist noinsel",
             `data-inlist` = "never-toggle",
            radioButtons(makeid("cond-type"), "Type", cond_types) %>%
               tagAppendAttributes(class = "list-group-item")
         )
      ),
      div(class = "panel panel-skinny panel-scroll inpanel filpanel",
         div(class = "panel-heading",
            "Filter Criteria", title = inputTips$condval,
            span(class = "badge float-right", "?")
         ),
         div(class = "panel-body insel-con",
            id = makeid("cond-vals"),
            tags$button(type = "button", class = "btn insel insel-multi filsel",
               value = str_nodata, str_nodata
            )
         ),
         div(class = "list-group inlist inlist-multi",
             `data-inlist` = "never-toggle",
            tags$button(type = "button", class = "list-group-item list-group-item-selected",
               span(class = "glyphicon glyphicon-check"),
               value = str_nodata, str_nodata
            )
         )
      ),
      div(class = "float-con",
         tags$button(type = "button", class = "btn btn-default btn-ok", "OK"),
         tags$button(type = "button", class = "btn btn-default btn-cancel", "Cancel"),
         tags$button(type = "button", class = "btn btn-danger btn-delete float-right", "Delete")
      )
   )
   uiExtra_hc = tagList(
      #actionButton(makeid("ts-type"), "Toggle Type", title = "Toggle between a simple line chart or a stacked line chart of proportions."),
      actionButton(makeid("ts-more"), "Add more series", title = "Add more series to chart")
   )
   uiMain = div(role = "region", id = makeid("outputs"),
      `aria-label` = "Outputs for data specified by the inputs",
      tabsetPanel(
         tabPanel("Chart",
            div(class = "preview-charts", `aria-live` = "polite", phOutput(
               highchartOutputWithDownload, makeid("hc-ts"), height = "700px",
               extraInputs = uiExtra_hc
            )),
            condPanel(c(js_input("seas"), "&", seas_cond),
               phOutput(highchartOutputWithDownload, makeid("hc-seaseff"), height = "100%")
            )
         ),
         tabPanel("Table",
            div(class = "preview-table", `aria-live` = "polite",
               uiOutput(makeid("preview-table"))
            )
         )
      )
   )
   uiBottom = div(
      div(class = "hidden",
         tags$form(class = "well",
            h4("Customise Titles"),
            checkboxInput(makeid("auto-title"), "Use automatically generated titles", TRUE),
            textInput(makeid("title"), "Title", ""),
            textInput(makeid("subtitle"), "Subtitle", "")
         )
      ),
      div(style = "height: 200px;"),
      box_lost
   )
   
   ui = div(id = makeid("con"),
      div(class = "top-panel", uiTop),
      div(class = "panel-row",
         div(class = "side-panel", uiSide, uiSideFil),
         div(class = "main-panel", uiMain)
      ),
      div(class = "bottom-panel", uiBottom)
   )
   
   server = function(input, output, session){
      ## Load data on-demand
      dstore_server(input, output, session)
      
      ## Default initial "csv"
      output[[makeid("csv-down")]] = tableComboDown(data.frame(str_nodata), str_nodata)
      
      ## Create environment where prepared preview data is stored
      ## These are then retrieved as required to show additional rows/series
      preview_env = new.env()
      ## Generate the colour sequence here
      ## Golden angle is used to get a long sequence of distinct colours
      # preview_env$pal = hcl(seq(from = 0, length = 196, by = 180*(3-sqrt(5))), 95, 75)
      preview_env$pal = hsv(seq(from = 0.618, length = 500, by = 180*(3-sqrt(5))/360) %% 1, 0.6, 0.9)
      
      ## Throttle input values
      ## Any changes to input values updates the list of values
      ##  held in the reactive value "ilist_rv".
      ## Any changes to "ilist_rv" triggers a throttled update to
      ##  "ilist_throttle", which is then used as the input to
      ##  the expensive output procedures.
      ilist_rv = reactiveVal()
      ilist_throttle = debounce(reactive(ilist_rv()), 400)
      observe({
         ilist_rv(list(
            dname = input[[makeid("dname")]],
            datekind = input[[makeid("datekind")]],
            dvars = input[[makeid("dvars")]],
            conds = input[[makeid("conds")]],
            seas = input[[makeid("seas")]]
         ))
      })
      
      ## Prepare data and generate previews
      observe({
         ilist = ilist_throttle()
         dname = ilist$dname
         datekind = ilist$datekind
         dvars = ilist$dvars
         conds = ilist$conds
         seas = ilist$seas
         if(is.null(dname)) dname = str_nodata
         seas = seas_allowed_R(seas, dname, datekind)
         
         ## If more than vars_max variables selected, reduce to vars_max.
         ## This is only possible if the user intentionally "hacks" the DOM
         ##  to disable the limit (which is not difficult).
         if(length(dvars) > vars_max) dvars = dvars[1:vars_max]
         
         ## Various checks to ensure we have the data loaded,
         ##  and the inputs have valid values for the data.
         dset = dstore[[dname]]
         can_continue = !is.null(dset)
         if(can_continue)
            can_continue = all(dvars %in% names(dset))
         ## Check if datekind is valid,
         ## If invalid, find and set to the first valid datekind
         if(can_continue && !any(date_cnames[[datekind]] == names(dset))){
            datekind_msg = paste(backname(date_kinds)[datekind], "is not valid for the current dataset.")
            date_cname = names(dset)[names(dset) %in% date_cnames][1]
            datekind = names(date_cnames)[date_cnames == date_cname]
            datekind_msg = paste(datekind_msg, backname(date_kinds)[datekind], "will be used instead.")
         } else{
            datekind_msg = ""
         }
         output[[makeid("datekind-msg")]] = renderUI(datekind_msg)
         
         if(can_continue){
            curseed = specify_seed(environment())
            curdat = NULL
            date_cname = date_cnames[[datekind]]
            dgroups = c(date_cname, dvars)
            allDates = sort(unique(dset[[date_cname]]))
            
            ## Handle conditions (if any)
            conds = cond_parse(conds)
            
            stime = proc.time()
            gtime = function() round((proc.time() - stime)[[3]], 2)
            cat(paste0("  ", gtime(), " - PROCESS query: "))
            cat(jsonlite::toJSON(list(dname = dname, dgroups = dgroups, conds = !is.null(conds))), "\n")
            if(!is.null(dstore[[paste0("_precomp_", dname)]]) && is.null(conds)){
               ## cat(paste0("  ", gtime(), " - CHECK for pre-computed dsets...\n"))
               pre_queries = lapply(dstore[[paste0("_precomp_", dname)]], function(x) x$query)
               match_queries = sapply(pre_queries, function(x){
                  ## Check dgroups
                  match_dgroups = all(x$dgroups %in% dgroups) && all(dgroups %in% x$dgroups)
                  
                  ## Check conds
                  ## (at the moment, can't handle conds)
                  match_conds = is.null(conds)
                  
                  match_dgroups && match_conds
               })
               ## cat(paste0("  ", gtime(), " - CHECK complete!"))
               if(any(match_queries)){
                  curdat = dstore[[paste0("_precomp_", dname)]][[which(match_queries)[1]]]$dset
                  ## cat(" MATCH found\n")
               } else{
                  ## cat(" NO match found\n")
               }
            }
            
            ## Process data
            ## Procedure:
            ## 1) Evaluate any date conditions immediately.
            ##    This is so we can carry out a check for any partial years
            ##       that arise from applying date filters.
            ## 2) Check for partial years and label,
            ##    e.g. "2017 Partial (Jan-Jul)"
            ## 3) Evaluate any remaining (non-date) conditions.
            ## 4) Aggregate data to selected variables,
            ##       specified by "dgroups".
            if(is.null(curdat)){
               ## cat(paste0("  ", gtime(), " - COMPUTE selected dset...\n"))
               curdat = dset %>%
                  cond_eval(conds, isDate = TRUE) %>%
                  check_partial_years(datekind) %>%
                  cond_eval(conds, isDate = FALSE) %>%
                  sum_by("Count", dgroups) %>%
                  as.data.frame()
               cat(paste0("  ", gtime(), " - COMPUTE complete!\n"))
            }
            
            ## Create COMBI
            combi = create_combi(curdat, dvars)
            combidat = mutate(curdat, COMBI = combi)
            
            ## Add seasonal adjustments
            seasadj = NULL
            if(seas)
               seasadj = seasadj_make(combidat, allDates, date_cname)
            
            ## Apply rounding
            curdat = mutate(curdat, Count = do_round(Count, curseed))
            combidat = mutate(combidat, Count = do_round(Count, curseed))
            if(!is.null(seasadj$dat))
               seasadj$dat = mutate(seasadj$dat, Count = do_round(Count, curseed))
            
            ## Join seasonal adjusted figures to curdat as trend
            if(!is.null(seasadj$dat))
               curdat = seasadj$dat %>%
                  select(-COMBI) %>%
                  rename(Trend = Count) %>%
                  right_join(curdat, by = dgroups)
            
            ## Title
            autitle = isolate(input[[makeid("auto-title")]])
            if(autitle){
               curtitle = backname(all_dnames)[[dname]]
               if(!is.null(dvars))
                  curtitle = paste0(curtitle, " by ", paste(dvars, collapse = " and "))
               subtitle = ""
               if(!is.null(conds)){
                  subtitle = sapply(conds, function(x) paste0("[",
                     paste(x$vname, x$vtype, paste(x$vvals, collapse = ", ")),
                  "]")) %>% paste(collapse = " AND ") %>% paste("WHERE", .)
               }
               updateTextInput(session, makeid("title"), value = curtitle)
               updateTextInput(session, makeid("subtitle"), value = subtitle)
            } else{
               curtitle = isolate(input[[makeid("title")]])
               subtitle = isolate(input[[makeid("subtitle")]])
            }
            
            ## Preview Table
            preview_table = make_preview_table(curdat, date_cname, dvars, curtitle, subtitle)
            output[[makeid("preview-table")]] = renderUI(preview_table)
            
            ## Put up full data for download
            output[[makeid("csv-down")]] = tableComboDown(curdat, curtitle)
            
            ## Preview Time-Series
            ## Process data and save to preview_env, this way the
            ##    processed data can be used to add more series when needed.
            preview_env$ts = make_ts_dat(combidat, date_cname, dvars, seasadj)
            ## Establish the ts
            ## Currently print-helper is not fully supported, as the proxy
            ##    method adds are not saved
            hcfunction = create_ts(preview_env, curtitle, subtitle)
            
            ## Seasonal effect graph
            hcfunction_seas = create_seasbar(preview_env)
         } else{
            preview_env$ts = NULL
            hcfunction = hcfunction_null
            hcfunction_seas = hcfunction_null
            autitle = isolate(input[[makeid("auto-title")]])
            if(autitle){
               updateTextInput(session, makeid("title"), value = "")
               updateTextInput(session, makeid("subtitle"), value = "")
            }
         }
         phRender(output, makeid("hc-ts"), hcfunction)
         phRender(output, makeid("hc-seaseff"), hcfunction_seas)
      })
      
      ## Plot more series when "Add more" button is pressed.
      ## Uses pre-generated data in preview_env and hc_proxy
      ##    for a fast and efficient update.
      observeEvent(input[[makeid("ts-more")]], {
         if(!is.null(preview_env$ts)){
            ## Establish a proxy, with redraw FALSE to prevent multiple redraws
            proxy = hc_proxy(makeid("hc-ts"), redraw = FALSE)
            ## Do the update
            proxy_added = add_more_ts(preview_env, proxy)
            ## If additional series were added
            ## Run the proxy update for seasonal effects bar
            if(proxy_added){
               proxy_seas = hc_proxy(makeid("hc-seaseff"), redraw = FALSE)
               add_more_seasbar(preview_env, proxy_seas)
            } else{
               ## Otherwise provide notification that nothing happened
               showNotification("No more series to add", type = "message")
            }
         }
      })
      
      phCopyServer(input, output, session, makeid("hc-ts"))
      phCopyServer(input, output, session, makeid("hc-seaseff"))
   }
   
   environment()
})
