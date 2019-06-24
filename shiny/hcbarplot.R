hcbarplot = local({
   ## A wrapper for drawing barplots (column charts) in highcharts.
   ## The local environment holds helper functions for the
   ##  main function found at the end.

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
      function(hc, ...){
         eItems = list(
            list(textKey = "printChart", onclick = JS('function(){this.print()}')),
            list(textKey = "downloadPNG", onclick = JS('function(){this.exportChartLocal({type:"image/png"})}')),
            list(textKey = "downloadSVG", onclick = JS('function(){this.exportChartLocal({type:"image/svg+xml"})}'))#,
            # list(textKey = "downloadCSV", onclick = JS('function(){this.downloadCSV()}'))
         )
         hc_exporting(hc, ..., enabled = FALSE,
            formAttributes = list(target = "_blank"),
            buttons = list(contextButton = list(menuItems = eItems)),
            sourceWidth =  1600, sourceHeight = 800, scale = 1)
      }
   
   hc_format_yAxis =
      ## Create appropriate format string for yAxis
      function(yformat) paste0(yformat$prefix, "{value:,f}", yformat$suffix)
   ################
   ## JavaScript ##
   ################
   ## Tooltip formatter
   hc_formatter =
      ## Create appropriate formatter function for tooltips
      function(yformat){
         symbol_unicode = "\u25CF"
         
         JS(paste0(
            'function(){',
               'var is_hover = this.series.state === "hover";',
               'var hsymbol = "<span style=" + ',
                  'JSON.stringify("color: " + this.color) + ">" + ',
                  jsonlite::toJSON(symbol_unicode), ' + "</span>";',
               'var hseries = this.series.name + ":";',
               "var hvalue = ", jsonlite::toJSON(yformat$prefix), " + ",
                  "Highcharts.numberFormat(this.y, ",
                  if(is.na(yformat$digits)) "-1" else yformat$digits, ") +",
                  jsonlite::toJSON(yformat$suffix), ";",
               'if(is_hover){hseries = "<b>" + hseries + "</b>";}',
               'if(is_hover){hvalue = "<b>" + hvalue + "</b>";} ',
               'return "<tr><td>" + hsymbol + " " + hseries + "</td>" + ',
                  '"<td>" + hvalue + "</td>";',
            '}'
         ))
      }

   ###################
   ## Main function ##
   ###################
   ## Arguments:
   ## -curdat-
   ## A matrix or dataframe with data to plot.
   ## Each column defines a series.
   ##
   ## -cats-
   ## The x categories
   ## length(cats) == nrow(curdat)
   ##
   ## -titles-
   ## List containing titles for "main", "x" and "y"
   ##  e.g. list(main = "Main Title")
   ##  e.g. list(main = "Seasonal Effect (multiplicative)", x = "Month", y = "Effect (%)")
   ##
   ## -yformat-
   ## List containing formatting specifications for y.
   ##  Contains the prefix, suffix and the digits for rounding
   ##  e.g. list(prefix = "$", suffix = "", digits = 0)
   ## If digits is NA, then no rounding is applied.
   ##
   ## -pal-
   ## Colours for the series variable.
   ##
   ## -proxy-
   ## A highchart proxy object, see "hc_proxy.R" or use NULL to ignore.
   function(curdat, cats, titles, yformat, pal, proxy = NULL){
      if(is.null(names(pal)))
         names(pal) = colnames(curdat)
      ## If we have no proxy given, we create a new highcharts object
      ## Else we can just use the proxy.
      if(is.null(proxy)){
         hc = highchart() %>%
            hc_export_settings() %>%
            hc_chart(type = "column", zoomType = "x", backgroundColor = NULL) %>%
            hc_xAxis(categories = I(cats), crosshair = TRUE, minRange = 1) %>%
            hc_yAxis(labels = list(format = hc_format_yAxis(yformat))) %>%
            hc_tooltip(shared = TRUE, useHTML = TRUE,
               headerFormat = '<span style="font-size: 10px">{point.key}</span><br/><table>',
               pointFormatter = hc_formatter(yformat),
               footerFormat = '</table>')

         if(!is.null(titles$main)) hc = hc_title_style(hc, text = titles$main)
         if(!is.null(titles$x)) hc = hc_xAxis(hc, title = list(text = titles$x))
         if(!is.null(titles$y)) hc = hc_yAxis(hc, title = list(text = titles$y))
      } else hc = proxy

      ## Add series
      for(cseries in colnames(curdat))
         hc = hc_add_series(hc, curdat[,cseries],
            color = pal[[cseries]], id = cseries, name = cseries)
      hc
   }
})
