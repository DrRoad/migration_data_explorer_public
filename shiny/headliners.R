make_headliners = local({
   ## The purpose of this function is to automatically generate short
   ##  text summaries ("headlines") for the given dataset.
   ## This local environment contains a number of supporting functions,
   ##  with the main function located at the end.
   ##
   ## Arguments:
   ## -dset-
   ## The dataset to generate headlines for.
   ## The date variable must be named "Date",
   ##  it doesn't have to be a Date object, but needs to
   ##  have correct ordering information (so a factor
   ##  with levels in correct date-order will also work).
   ## The numeric variable must be named "Value".
   ## -dvars-
   ## The variables of interest, as a character vector.
   ## Can be of length 1 or 2.
   ## -ddates-
   ## A named vector of dates for which to generate the headlines.
   ## If NULL (default), appropriate dates are automatically computed.
   ##  NOTE: The function that does this (`make_ddates`) has not been
   ##   updated when the rest of the code was last updated, so should
   ##   not be used without changes (and improvements).
   ## -cur_units-
   ##
   ## Output:
   ## A "div" tag containing the headlines.
   ##
   ## An example of the generated headline:
   ## Past Year (2015-09-30)
   ## The greatest growth in the past year came from
   ##  Persons Employed in Labour Force - Aged 65 Years and Over
   ##  which grew by 14.9%, from 136.5 to 156.9 (Number-Thousands).
   ## This is followed by Total Labour Force - Aged 65 Years and Over
   ##  which grew by 13.8%, from 138.9 to 158 (Number-Thousands).
   ## Conversely the greatest decrease in the past year came from
   ##  Persons Unemployed in Labour Force - Aged 65 Years and Over
   ##  which decreased by 54.2%, from 2.4 to 1.1 (Number-Thousands).
   ## This is followed by Not in Labour Force - Aged 45-54 Years
   ##  which decreased by 19.2%, from 93.1 to 75.2 (Number-Thousands).
   ##
   ## The general process for generating headlines is as follows:
   ## 1) Find appropriate dates of interest, e.g.
   ##    Latest, Past Quarter, Past Year, Past 5 Years, ...
   ##    The function `make_ddates` is used to do this.
   ##    -- NOTE: Skipped if ddates is provided --
   ## 2) Compute change from the past periods to the latest period.
   ##    The function `make_dchange` is used to do this.
   ## 3) For each period, get the largest/smallest value/change
   ##     (value for latest, change for all past periods),
   ##     along with some "runners-up" (second largest/smallest, etc.).
   ##    The function `make_interest` is used to do this.
   ## 4) Generate the HTML output for each period.
   ##    A large number of functions are used to generate the HTML output.
   ## 5) Collect and return inside a single div.
   ## ----------------------------------------------------------------

   ## Define the significance cutoff values as a proportion
   ##  of the smaller value.
   ## That is, when comparing two values, if the larger value
   ##  is less than 4% greater than the smaller value, the
   ##  difference is considered "close". If the larger value
   ##  is more than 100% greater than the smaller value, the
   ##  difference is considered "distant".
   sig_cutoff = list(close = 0.04, distant = 1)

   make_ddates =
      ## Find dates of interest.
      ## Procedure:
      ## 1) Create "ddates", a sorted vector of all unique
      ##     time periods in the data.
      ## 2) If (length(ddates) <= 2), get all dates.
      ## 3) Else, compute "ddatediff", the mean diff of ddates.
      ##    That is, this is the average number of days between
      ##     the time periods of the data.
      ##    Use this to choose one of 5 categories:
      ##  i)   Sparse    - dates are more than a year apart, use all data.
      ##  ii)  Yearly    - dates are about 1 year apart.
      ##  iii) Quarterly - dates are about 1 quarter (3 months) apart.
      ##  iv)  Monthly   - dates are about 1 month apart.
      ##  v)   Fail-safe - no data should trigger this,
      ##         but if it does assume daily data and use all dates.
      ##
      ## For the Yearly/Quarterly/Monthly data, the procedure to choose
      ##  dates is as follows:
      ## 1) Get latest and oldest time periods, but for quarterly/monthly,
      ##     choose oldest date that's a whole-year difference, e.g.
      ##     if the dates go from 31-03-2000 to 30-04-2015, the oldest
      ##     date chosen would be 30-04-2000.
      ## 2) Choose as much as possible from past: Month, Quarter,
      ##     1, 5, 10, 20, 30, 40, 50 years.
      ##    That is, if the data is quarterly and only goes back 25 years,
      ##    the dates chosen would be: Latest, Past Quarter, Past Year,
      ##     Past 5 Years, Past 10 Years, Past 20 Years, Past 25 Years.
      function(curDates){
         ddates = sort(unique(curDates))
         if(length(ddates) <= 2){
            ## Get all
            ddate_index = seq_along(ddates)
            names(ddate_index) = c("Latest", "Past")[ddate_index]
         } else{
            ddatediff = mean(diff(ddates))
            other_years = c(1, 5, 10, 20, 30, 40, 50)
            if(ddatediff >= 365 * 1.5){
               ## Sparse
               ddate_index = seq_along(ddates)
               diff_years = cumsum(diff(as.numeric(format(ddates, "%Y"))))
               names(ddate_index) = c("Latest", paste("Past", diff_years, "Years"))[ddate_index]
            } else if(ddatediff >= 364){
               ## Yearly
               max_years = length(ddates) - 1
               other_years = other_years[other_years < max_years]
               ddate_index = c(0, c(other_years, max_years)) + 1
               names(ddate_index) = c("Latest", paste("Past", c("Year", paste(c(other_years[-1], max_years), "Years"))))
            } else if(ddatediff >= 86){
               ## Quarterly
               max_years = (length(ddates) - 1) %/% 4
               other_years = other_years[other_years < max_years]
               ddate_index = c(0, 1, c(other_years, max_years) * 4) + 1
               names(ddate_index) = c("Latest", paste("Past", c("Quarter", "Year", paste(c(other_years[-1], max_years), "Years"))))
            } else if(ddatediff >= 26){
               ## Monthly
               max_years = (length(ddates) - 1) %/% 12
               if(max_years > 0){
                  other_years = other_years[other_years < max_years]
                  ddate_index = c(0, 1, 3, c(other_years, max_years) * 12) + 1
                  names(ddate_index) = c("Latest", paste("Past", c("Month", "Quarter", "Year", paste(c(other_years[-1], max_years), "Years"))))
               } else{
                  ddate_index = c(0, 1, 3) + 1
                  names(ddate_index) = c("Latest", paste("Past", c("Month", "Quarter")))
               }
            } else{
               ## Fail-safe, assumes days is smallest time-difference
               ## At the point of writing, no data triggers this
               warning("Fail-safe triggered in headliners.R 'find dates of interest'.\n",
                  "If everything still performs as desired, this warning can be ignored.")
               ddate_index = seq_along(ddates)
               names(ddate_index) = c("Latest", paste("Past", cumsum(diff(ddates)), "Days"))[ddate_index]
            }
         }
         ddate_get = rev(ddates)[ddate_index]
         names(ddate_get) = names(ddate_index)
         ddate_get
      }

   make_dchange =
      ## Compute change to latest period.
      function(dset, dvars, ddate_get){
         dfilter = filter(dset, Date %in% ddate_get)
         dgroup = group_by_(dfilter, dvars[1])
         if(length(dvars) > 1) dgroup = group_by_(dgroup, dvars[2], add = TRUE)
         dchange = dgroup %>%
            arrange(desc(Date)) %>%
            mutate(LastValue = Value[1], Change = Value[1] - Value) %>%
            group_by(Date) %>%
            mutate(LastProp = LastValue/sum(LastValue), Prop = Value/sum(Value)) %>%
            ungroup()
         dchange
      }

   make_interest =
      ## Get interesting max/min values/changes.
      ## The latest period uses value, all past periods use change.
      ## Compute the "MagDiff", or magnitude of differences, measuring
      ##  marginal percentage differences in the value/change, which
      ##  is used to check if the values/changes are similar or
      ##  distant.
      ## The process is to:
      ##  1) Always grab the largest/smallest values/changes.
      ##  2) Always grab the second largest/smallest values/changes
      ##      (assuming they exist).
      ##  3) Grab up to half of the remaining values/changes, so long
      ##      as the MagDiff from the second largest/smallest is small
      ##      enough. This is to provide some context (e.g. whether
      ##      there are many similar values near second place, or if
      ##      perhaps second place is quite unique).
      function(dchange, ddate_get){
         outlist = list()
         for(i in 1:length(ddate_get)){
            curdate = ddate_get[i]
            curname = names(ddate_get)[i]
            c_interest = if(curname == "Latest") "Value" else "Change"

            dinterest = dchange %>%
               filter(Date == curdate) %>%
               mutate_(C_INTEREST = c_interest)
            ## Zero values are filtered out so only meaningful Change remains
            if(c_interest == "Change") dinterest = filter(dinterest, C_INTEREST != 0)


            dsort = dinterest %>%
               arrange(C_INTEREST) %>%
               mutate(MagDiff = abs(c(0, C_INTEREST[-1]/C_INTEREST[-n()] - 1))) %>%
               mutate(MagDiff = ifelse(is.nan(MagDiff), 0, MagDiff)) %>%
               select(-C_INTEREST)

            dn = nrow(dsort)
            outlist[[curname]] = if(dn >= 6){
               ## If differences between non-firsts are close, grab
               ##  them all up to half of the dataset.
               dnhalf = 1:floor(dn/2 - 1)
               max_insig = cumsum((slice(dsort, dn - dnhalf))$MagDiff) <= sig_cutoff$close
               min_insig = cumsum((slice(dsort, dnhalf[-1] + 1))$MagDiff) <= sig_cutoff$close

               max_n = if(all(max_insig)) length(max_insig) else min(which(!max_insig))
               min_n = if(all(min_insig)) length(min_insig) else min(which(!min_insig))

               list(
                  max = slice(dsort, dn:(dn - max_n)),
                  min = slice(dsort, 1:(1 + min_n))
               )
            } else if(dn >= 4){
               list(
                  max = slice(dsort, dn:(dn - 1)),
                  min = slice(dsort, 1:2)
               )
            } else if(dn >= 2){
               list(
                  max = slice(dsort, dn),
                  min = slice(dsort, 1)
               )
            } else{
               list(
                  max = dsort
               )
            }
         }
         outlist
      }

   ## Functions to generate output text/html.
   ## The main function of this section is `makehtml` with the others
   ##  being supporting functions.
   ## The output is mostly raw HTML, which is wrapped inside `HTML`,
   ##  `p` and `div` for final layout.
   ## Raw HTML is used for finer control in spacing.
   ##
   ## Key Words:
   ## -dinterest-
   ## The output of `make_interest`, a named list, each element (and
   ##  name) corresponds to a date of interest, and contains a named
   ##  list with 2 elements, "max" and "min" which each contain a
   ##  data.frame of the largest/smallest values/changes.
   ##
   ## -curdat-
   ## A subset of "dinterest" for a specific date, e.g. curdat =
   ##  dinterest[[1]]
   ##
   ## -curpart-
   ## A subset of "curdat" for either max or min, e.g. curpart =
   ##  curdat$max

   phtml = function(...) p(HTML(paste0(...)))
   formatnum = function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
   ## Wrap "x" inside a span with class "xclass"
   spanclass =
      function(x, xclass) paste0(
         '<span class=',
         encodeString(paste(c("headliner-str", xclass), collapse = " "), quote = '"'),
         '>', x, '</span>'
      )

   ## Functions/variables for choosing the right words for the
   ##  situation (e.g. "growth" or "decrease"?)
   pmswitch = function(curpart, n, pos, neg)
      ifelse(curpart$Change[n] >= 0, pos, neg)
   typeswitch = function(curtype, a, b)
      if(curtype == "max") a else b
   pmadj = c("greatest", "smallest")
   sigswitch = function(curpart, n, curtype){
      curMagDiff = curpart$MagDiff[n + as.numeric(curtype == "min")]
      if(is.nan(curMagDiff))
         NULL
      else if(curMagDiff >= sig_cutoff$distant)
         " distantly"
      else if(curMagDiff <= sig_cutoff$close)
         " closely"
      else
         NULL
   }

   ## make a function for the current "dvars" (a vector of variable
   ## names) that produces styled text of the current dvar values.
   make_dvarstr = function(dvars) function(curpart, n){
      if(length(dvars) == 1) spanclass(curpart[[dvars[1]]][n], "headliner-dvar1")
      else paste0(spanclass(curpart[[dvars[1]]][n], "headliner-dvar1"), " (",
                  spanclass(curpart[[dvars[2]]][n], "headliner-dvar2"), ")")
   }
   ## make a function for the current "cur_units" that produces styled
   ## and formatted text of the current value.
   make_makevalue = function(cur_units) function(curpart, n){
      propvalue = round(curpart$Prop[n] * 100, 1)
      paste0(
         " with ",
         spanclass(formatnum(curpart$Value[n]), "headliner-value"),
         " (", propvalue, "% of Total)",
         cur_units
      )
   }
   ## make a function for the current "cur_units" that produces styled
   ##  and formatted text of the change, and the from/to values this
   ##  change is computed from.
   make_makechange = function(cur_units) function(curpart, n){
      propvalue = round(curpart$Prop[n] * 100, 1)
      lastpropvalue = round(curpart$LastProp[n] * 100, 1)
      changevalue = curpart$Change[n]
      changeperc = round(curpart$Change[n]/curpart$Value[n] * 100, 1)
      changepn = ifelse(changevalue >= 0, "pos", "neg")
      changeclass = paste0("headliner-change-", changepn)
      
      paste0(
         " which ",
         spanclass(pmswitch(curpart, n, "grew", "shrunk"), changeclass),
         " by ",
         spanclass(formatnum(abs(changevalue)), changeclass), ", ",
         pmswitch(curpart, n, "an increase", "a decrease"),
         " of ",
         spanclass(paste0(formatnum(abs(changeperc)), "%"), changeclass),
         " from ",
         spanclass(formatnum(curpart$Value[n]), "headliner-change-from"),
         " (", propvalue, "% of Total)",
         " to ",
         spanclass(formatnum(curpart$LastValue[n]), "headliner-change-to"),
         " (", lastpropvalue, "% of Total)",
         cur_units
      )
   }

   makefollow =
      ## Generate the "followed by" part of the HTML output and append
      ##  it to "curp".
      ## If there is only 1 "followed by" value, this is appended as a
      ##  paragraph.
      ## If there are more, at most 9 following values are appended as
      ##  an HTML unordered list, followed by how many similar values
      ##  were cut (if any).
      function(curp, curpart, curtype, makef, dvarstr){
         np = nrow(curpart)
         if(np == 2){
            tagList(curp, phtml(
               "This is followed",
               sigswitch(curpart, 1, curtype),
               " by ", dvarstr(curpart, -1), makef(curpart, -1), "."
            ))
         } else{
            if(np > 10){
               nextra = np - 10
               nseq = 2:10
            } else{
               nextra = 0
               nseq = -1
            }
            nli = paste0(
               "<li>",
               dvarstr(curpart, nseq), makef(curpart, nseq),
               ".</li>", collapse = "\n"
            )
            if(nextra > 0) nli = paste0(nli, "\n",
               "<li>and ", nextra, " more similar values.</li>")
            tagList(
               curp,
               p(paste0(
                  "This is followed",
                  sigswitch(curpart, 1, curtype),
                  " by:"
               )),
               HTML(paste0("<ul>", nli, "</ul>"))
            )
         }
      }
   makehtml =
      ## Generate the headline text for curdat.
      ## The latest period uses Value, while all others use Change.
      function(curdat, curperiod, dvarstr, makevalue, makechange){
         curhtml = list()
         for(curtype in c("max", "min")){
            curpart = curdat[[curtype]]
            if(is.null(curpart)){
               curhtml[[curtype]] = NULL
            } else if(curperiod == "Latest"){
               curp = phtml(
                  dvarstr(curpart, 1),
                  " has the ",
                  typeswitch(curtype, "largest", "smallest"),
                  " value for the latest period",
                  makevalue(curpart, 1), "."
               )
               if(nrow(curpart) > 1)
                  curp = makefollow(curp, curpart, curtype, makevalue, dvarstr)
               curhtml[[curtype]] = curp
            } else{
               curadj = typeswitch(curtype, pmadj, rev(pmadj))
               curp = phtml(
                  typeswitch(curtype, "The ", "Conversely the "),
                  pmswitch(curpart, 1, paste(curadj[1], "growth"), paste(curadj[2], "decrease")),
                  " from the period ",
                  tolower(curperiod),
                  " came from ",
                  dvarstr(curpart, 1),
                  makechange(curpart, 1), "."
               )
               if(nrow(curpart) > 1)
                  curp = makefollow(curp, curpart, curtype, makechange, dvarstr)
               curhtml[[curtype]] = curp
            }
         }
         div(
            h5(paste0(curperiod, " (", curdat$max$Date[1], ")")),
            do.call(tagList, curhtml)
         )
      }

   ## Main function
   function(dset, dvars, ddates = NULL, cur_units = NULL){
      ## Find dates of interest
      if(is.null(ddates)) ddates = make_ddates(dset$Date)

      ## Compute change to latest period
      dchange = make_dchange(dset, dvars, ddates)

      ## Get interesting max/min values/changes
      dinterest = make_interest(dchange, ddates)

      ## Create html-generator functions for the current dataset
      dvarstr = make_dvarstr(dvars)
      if(!is.null(cur_units)) cur_units = paste0(" (", cur_units, ")")
      makevalue = make_makevalue(cur_units)
      makechange = make_makechange(cur_units)
      ## Loop through and generate the headlines.
      outhtml = list()
      for(curperiod in names(dinterest))
         outhtml[[curperiod]] = dinterest[[curperiod]] %>%
            makehtml(curperiod, dvarstr, makevalue, makechange)

      ## Return as a div
      names(outhtml) = NULL
      do.call(div, c(outhtml, list(class = "headliner-con")))
   }
})
