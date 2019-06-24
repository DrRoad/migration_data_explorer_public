hcdotchart = local({
   ## A wrapper for drawing dotcharts in highcharts.
   ## The local environment holds helper functions for the
   ##  main function found at the end.

   dconv =
      ## Wrapper for converting a matrix or data.frame
      ##  into the format required by highcharts.
      ## If "rm_names" is TRUE, names are also removed
      ##  (so result will be converted to a JS array,
      ##   and order will matter).
      ## Else the names are kept
      ##  (so result will be converted to a named JS object,
      ##   and names will matter).
      function(x, rm_names = TRUE){
         if(rm_names) colnames(x) = NULL
         out = list()
         for(i in 1:nrow(x))
            out[[i]] = as.list(x[i,])
         out
      }
   afix =
      ## Attach (pre/suf)fix, and set rounding digits
      ##  for use in highcharts tooltip.
      ## "xformat" is passed directly from main function.
      function(x, xformat){
         rounding = function(digits)
            if(is.na(digits)) "" else paste0(":,.", digits, "f")
         paste0(xformat$prefix, "{", x, rounding(xformat$digits), "}", xformat$suffix)
      }
   hc_title_style =
      ## Wrapper for `hc_title` to apply consistent styles
      function(...){
         mainstyle = list(
            "font-family" = "Fira Sans",
            "font-size" = "12px",
            "font-weight" = "bold"
         )
         hc_title(..., useHTML = TRUE, style = mainstyle)
      }
   hc_export_settings =
      ## Wrapper for applying consistent export settings
      function(hc, height, ...){
         eItems = list(
            list(textKey = "printChart", onclick = JS('function(){this.print()}')),
            list(textKey = "downloadPNG", onclick = JS('function(){this.exportChartLocal({type:"image/png"})}')),
            list(textKey = "downloadSVG", onclick = JS('function(){this.exportChartLocal({type:"image/svg+xml"})}'))#,
            # list(textKey = "downloadCSV", onclick = JS('function(){this.downloadCSV()}'))
         )
         hc_exporting(hc, ..., enabled = FALSE,
            formAttributes = list(target = "_blank"),
            buttons = list(contextButton = list(menuItems = eItems)),
            sourceWidth =  1600, sourceHeight = height, scale = 1)
      }

   ycount =
      ## Sums the number of rows in the first "i"
      ##  elements of the list of datasets, "dat_split".
      ## Adds 1 to each nrow, for the group-title area.
      function(dat_split, i)
         sum(sapply(dat_split[1:i], function(x) nrow(x) + 1))
   makeyBands =
      ## Create the y Bands, which will provide an alternating
      ##  background for the groups.
      ## 2 bands are defined, one for the whole area
      ##  and the second with a higher zIndex
      ##  for placing the label above the gridlines.
      function(dat_split){
         yBands = list()
         BandCols = c("#F6F6F6", "#FFFFFF")
         for(gindex in 1:length(dat_split)){
            curgroup = names(dat_split)[gindex]
            from = if(gindex > 1) ycount(dat_split, gindex - 1) else 0
            to = ycount(dat_split, gindex)
            curcol = BandCols[gindex %% 2 + 1]
            curstyle = list(
               "font-family" = "Fira Sans",
               "font-size" = "11px",
               "font-weight" = "bold",
               "background-color" = curcol
            )
            curlabel = list(
               text = curgroup, style = curstyle,
               align = "left", verticalAlign = "middle"
            )

            yBands[[gindex]] = list(
               from = from - 0.5, to = to - 0.5, color = curcol
            )
            yBands[[length(dat_split) + gindex]] = list(
               from = from - 0.5, to = from + 0.5, color = curcol,
               label = curlabel, zIndex = 1
            )
         }
         yBands
      }
   makedat_nogroup =
      ## Used to create the series data for the selected
      ##  "curcomp" when there is no grouping variable.
      function(dat_spread, curcomp){
         curvals = dat_spread[[curcomp]]
         cury = 1:length(curvals) - 1
         cbind(cury, curvals)
      }
   makedat_group =
      ## Used to create the series data for the selected
      ##  "curcomp" when there is a grouping variable.
      function(dat_split, curcomp){
         dat_comp = list()
         for(gindex in 1:length(dat_split)){
            dat_group = dat_split[[gindex]]
            yadj = if(gindex > 1) ycount(dat_split, gindex - 1) else 0
            curvals = dat_group[[curcomp]]
            if(!is.null(curvals)){
               cury = 1:length(curvals) + yadj
               dat_comp[[gindex]] = cbind(cury, curvals)
            }
         }
         do.call(rbind, dat_comp)
      }
   makedat_diffbar =
      ## Used to create the series data for creating the diffbars.
      function(dat, isgroup, complevels, cols){
         datfunc = if(isgroup) makedat_group else makedat_nogroup
         dat_merge = merge(by = "cury", all = TRUE,
            datfunc(dat, complevels[1]),
            datfunc(dat, complevels[2])
         )
         diffcols = rep(cols[1], length = nrow(dat_merge))
         diffcols[dat_merge[,3] > dat_merge[,2]] = cols[2]
         cbind(dat_merge, diffcols)
      }

   ################
   ## JavaScript ##
   ################
   ## Tooltip formatter
   format_dots = function(yname, xformat) JS(paste0(
      "function(){",
      "  var yname = ", jsonlite::toJSON(yname), ";",
      "  var cat = yname[this.x];",
      "  var val = ", jsonlite::toJSON(xformat$prefix), " + ",
         "Highcharts.numberFormat(this.y, ",
         if(is.na(xformat$digits)) "-1" else xformat$digits, ") +",
         jsonlite::toJSON(xformat$suffix), ";",
      "  return cat + ': <b>' + val + '</b><br/>';",
      "}"
   ))
   format_diff = function(yname, xformat) JS(paste0(
      "function(){",
      "  var yname = ", jsonlite::toJSON(yname), ";",
      "  var cat = yname[this.x];",
      "  var diff = this.high - this.low;",
      "  var val = ", jsonlite::toJSON(xformat$prefix), " + ",
         "Highcharts.numberFormat(Math.abs(diff), ",
         if(is.na(xformat$digits)) "0" else xformat$digits, ") +",
         jsonlite::toJSON(xformat$suffix), ";",
      "  var dstr = (diff >= 0) ? '+' : '-';",
      "  var dperc = Math.round(Math.abs(this.high/this.low - 1) * 1000)/10;",
      "  var pval = '(' + dstr + dperc + '%)';",
      "  return cat + ': <b>' + val + '</b> ' + pval + '<br/>';",
      "}"
   ))
   ## When one of the dot series are hidden, also hide diffbar
   showhideJS = JS('function(){
      this.setVisible();
      var vis = this.chart.series.every(function(x){
         if(x.name != "diffbars"){
            return x.visible
         } else{
            return true
         }
      });
      var diffbars = this.chart.get("diffbars");
      if(vis){
         diffbars.show();
      } else{
         diffbars.hide();
      }

      return false;
   }')

   ###################
   ## Main function ##
   ###################
   ## Arguments:
   ## -curdat-
   ## A dataframe with the data to plot.
   ## Should have 3 variables for x, y, comp,
   ##  with an optional fourth for group.
   ##   x is the numeric variable.
   ##   y is the categorical variable.
   ##   comp is the comparison variable
   ##    if comp has 2 unique elements, a comparison dotchart will be drawn.
   ##    else a regular dotchart is drawn.
   ##  group is the grouping variable
   ##
   ## -plist-
   ## A list naming the variables: x, y, comp (and optionally group).
   ##  e.g. plist = list(x = "Value", y = "FirmSize", comp = "Sector")
   ##  e.g. plist = list(x = "Value", y = "FirmSize", comp = "Sector", group = "Country")
   ##
   ## -titles-
   ## List containing titles for "main" and "x"
   ##  e.g. list(main = "Main Title")
   ##  e.g. list(main = "GDP", x = "USD (millions)")
   ##
   ## -xformat-
   ## List containing formatting specifications for x.
   ##  Contains the prefix, suffix and the digits for rounding
   ##  e.g. list(prefix = "$", suffix = "", digits = 0)
   ## If digits is NA, then no rounding is applied.
   ##
   ## -cols-
   ## Colours for the comparison variables.
   ##
   ## -ordering-
   ## If TRUE, the dotchart is ordered by size.
   ##
   ## -visible-
   ## If NULL, all series will be visible.
   ## Otherwise a character vector of the names of series that should
   ##  be visible from the start. The remainder will start invisible
   ##  but visibility can be toggled via the legend.
   function(curdat, plist, titles, xformat, cols, ordering = FALSE, visible = NULL){
      ## Coerce to factor if needed
      if(!is.factor(curdat[[plist$y]])) curdat[[plist$y]] = factor(curdat[[plist$y]])
      if(!is.factor(curdat[[plist$comp]])) curdat[[plist$comp]] = factor(curdat[[plist$comp]])

      isgroup = !is.null(plist$group)
      complevels = levels(curdat[[plist$comp]])
      iscomp = length(complevels) == 2

      ## Check if comp levels contain variables not in data
      ## If so, remove these, but preserve order of levels
      compunique = as.character(unique(curdat[[plist$comp]]))
      if(length(compunique) < length(complevels)){
         warning("Levels of ", plist$comp, " contain variables not included in data.")
         complevels = complevels[complevels %in% compunique]
      }

      ## If groups, split the data by groups, then spread
      ##  Else just create a dat_spread.
      ## Also create an appropriate "yvec", used for the y categories.
      ## Without groups, this is just the y values in the data.
      ## With groups, space is left for the group headings, between
      ##  each group's y values.
      ## Corresponding to the "yvec" is "yname", which is the same
      ##  as "yvec" when without groups, but includes the group
      ##  label if there are groups. "yname" is used in the tooltips.
      if(isgroup){
         dat_split = curdat %>%
            split(curdat[[plist$group]], drop = TRUE) %>%
            lapply(function(x) spread_(x, plist$comp, plist$x))

         if(ordering){
            dat_split = lapply(dat_split, function(x){
               curlevels = complevels[complevels %in% names(x)]
               if(!is.null(visible)) curlevels = curlevels[curlevels %in% visible]
               rorder = order(apply(select(x, one_of(curlevels)), 1, mean), decreasing = TRUE)
               x[rorder,]
            })
         }

         yvec = dat_split %>%
            lapply(function(x) c("", as.character(x[[plist$y]]))) %>%
            unlist(use.names = FALSE)

         ynamel = list()
         for(i in 1:length(dat_split)){
            cur_names = c("", as.character(dat_split[[i]][[plist$y]]))
            ynamel[[i]] = paste(cur_names, brac(names(dat_split)[i]))
         }
         yname = unlist(ynamel, use.names = FALSE)
      } else{
         dat_spread = spread_(curdat, plist$comp, plist$x)

         if(ordering){
            curlevels = complevels
            if(!is.null(visible)) curlevels = curlevels[curlevels %in% visible]
            rorder = order(apply(select(dat_spread, one_of(complevels)), 1, mean), decreasing = TRUE)
            dat_spread = dat_spread[rorder,]
         }

         yvec = as.character(dat_spread[[plist$y]])
         yname = yvec
      }

      ## Note that because the chart is inverted, xAxis applies to y and vice versa
      hheight = 200 + 20 * length(yvec) + length(complevels) %/% 5 * 20
      chart_typedesc = "A dotchart, similar to a bar plot but better."
      hc = highchart() %>%
         hc_export_settings(hheight) %>%
         hc_chart(inverted = TRUE, zoomType = "y", backgroundColor = NULL,
                  height = hheight, typeDescription = chart_typedesc) %>%
         hc_xAxis(categories = I(yvec), tickmarkPlacement = "on",
                  min = 0, gridLineWidth = 1) %>%
         hc_colors(cols) %>%
         hc_tooltip(pointFormatter = format_dots(yname, xformat), useHTML = TRUE)

      if(!is.null(titles$main)) hc = hc_title_style(hc, text = titles$main)
      if(!is.null(titles$x)) hc = hc_yAxis(hc, title = list(text = titles$x))

      ## Show groups via plotBands
      if(isgroup)
         hc = hc_xAxis(hc, plotBands = makeyBands(dat_split))

      ## Diffbar for comparisons
      if(iscomp){
         dat_diff = makedat_diffbar(if(isgroup) dat_split else dat_spread,
                                    isgroup, complevels, cols)
         cur_visible = if(is.null(visible)) TRUE else length(visible) == 2
         hc = hc %>%
            hc_plotOptions(series = list(events = list(legendItemClick = showhideJS))) %>%
            hc_add_series(type = "columnrange", data = dconv(dat_diff[,1:3]),
                          id = "diffbars", name = "diffbars", pointWidth = 4,
                          colorByPoint = TRUE, colors = I(dat_diff$diffcols),
                          showInLegend = FALSE, animation = FALSE, visible = cur_visible,
                          tooltip = list(pointFormatter = format_diff(yname, xformat),
                          headerFormat = '<span style="font-size: 10px">Difference</span><br/>'))
      } else{
         ## Add a fake columnrange series, required due to bug in highcharts
         ## https://github.com/highcharts/highcharts/issues/6885
         ## Don't ask why this fixes it
         hc = hc %>% hc_add_series(type = "columnrange", showInLegend = FALSE)
      }

      ## Add series
      for(curcomp in complevels){
         dat_series = if(isgroup) makedat_group(dat_split, curcomp)
            else makedat_nogroup(dat_spread, curcomp)
         cur_visible = if(is.null(visible)) TRUE else any(curcomp == visible)
         hc = hc_add_series(hc, type = "scatter",
            marker = list(radius = 6, symbol = "circle"),
            data = dconv(dat_series), name = curcomp,
            animation = FALSE, visible = cur_visible)
      }
      hc
   }
})
