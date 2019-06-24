hclinebasic = local({
   ## A wrapper for drawing basic line graphs in highcharts.
   ## The local environment holds helper functions for the
   ##  main function found at the end.
   
   hc_format =
      ## Generate appropriate format list specifying:
      ## -prefix
      ## -suffix
      ## -dp (for rounding, -1 = no rounding)
      function(vartype){
         out = list()
         out$prefix = switch(vartype,
            money = "$",
            ""
         )
         out$suffix = switch(vartype,
            percent = "%",
            ""
         )
         out$dp = switch(vartype,
            index = 3,
            money = 0,
            "number-round" = 0,
            -1
         )
         
         out
      }
   hc_format_yAxis =
      ## Create appropriate format string for yAxis
      function(yformat) paste0(yformat$prefix, "{value:,f}", yformat$suffix)
   hc_formatter =
      ## Create appropriate formatter function for tooltips
      function(yformat, symbol, shared){
         symbol_unicode = switch(symbol,
            circle = "\u25CF",
            diamond = "\u25C6",
            "\u25A0"
         )
         
         JS(paste0(
            'function(){',
               'var is_hover = this.series.state === "hover";',
               'var hsymbol = "<span style=" + ',
                  'JSON.stringify("color: " + this.color) + ">" + ',
                  jsonlite::toJSON(symbol_unicode), ' + "</span>";',
               'var hseries = this.series.name + ":";',
               "var hvalue = ", jsonlite::toJSON(yformat$prefix), " + ",
                  "Highcharts.numberFormat(this.y, ",
                  if(is.na(yformat$dp)) "-1" else yformat$dp, ") +",
                  jsonlite::toJSON(yformat$suffix), ";",
               'var hvalue_extra = "";',
               'if(this.percentage !== undefined){',
                  'hvalue_extra = " (" + hvalue + ")";',
                  'hvalue = Highcharts.numberFormat(this.percentage, 1) + "%";',
               '}',
               if(shared) paste0(
                  'if(is_hover){hseries = "<b>" + hseries + "</b>";}',
                  'if(is_hover){hvalue = "<b>" + hvalue + "</b>";}'
               ) else 'hvalue = "<b>" + hvalue + "</b>";',
               'return "<tr><td>" + hsymbol + " " + hseries + "</td>" + ',
                  '"<td>" + hvalue + hvalue_extra + "</td>";',
            '}'
         ))
      }
   
   hc_asline =
      ## Convenience wrapper to hc_add_series for lines.
      ## Adds a thicker hover state.
      ## Sets "connectNulls" to TRUE by default.
      function(hc, values, Datevec, ..., id = NULL, seriesStyle = "Normal",
               marker = list(enabled = FALSE, symbol = "circle"),
               connectNulls = TRUE){
         if(is.null(id)) id = list(...)$name
         
         ## Apply style
         lineWidth = switch(seriesStyle,
            Minor = 1,
            Normal = 3,
            Major = 4,
            Context = 1
         )
         lineWidthPlus = switch(seriesStyle,
            Minor = 4,
            Normal = 3,
            Major = 2,
            Context = 5
         )
         dashStyle = switch(seriesStyle,
            Minor = "Dash",
            Normal = "Solid",
            Major = "Solid",
            Context = "ShortDash"
         )
         zIndex = switch(seriesStyle,
            Minor = NULL,
            Normal = NULL,
            Major = 1,
            Context = NULL
         )
         
         ## If marker is set to "auto"
         ## Display marker if the data is short,
         ##  or has short-runs of non-NA values
         if(marker$enabled == "auto"){
            vrle = rle(!is.na(values))
            marker$enabled = length(values) < 26 ||
               min(vrle$lengths[vrle$values]) < 3
         }
         
         if(!is.null(Datevec)){
            ## time-series line
            timestamps = datetime_to_timestamp(Datevec)
            values = list_parse2(data.frame(timestamps, values))
         }
         hc_add_series(hc, data = values, marker = marker,
            connectNulls = connectNulls, id = id,
            lineWidth = lineWidth, dashStyle = dashStyle, zIndex = zIndex,
            states = list(hover = list(lineWidthPlus = lineWidthPlus)), ...)
      }
   
   hc_title_style =
      ## Wrapper for `hc_title` to apply consistent styles
      function(...){
         mbie_h6 = list(
            "color" = "#000000",
            "fontSize" = "14.3px",
            "font-family" = '"Fira Sans",Helvetica,Arial,sans-serif',
            "font-weight" = "bold"
         )
         hc_title(..., style = mbie_h6)
      }
   hc_subtitle_style =
      ## Wrapper for `hc_subtitle` to apply consistent styles
      function(...){
         mbie_body = list(
            "color" = "#000000",
            "fontSize" = "14px",
            "font-family" = '"Fira Sans",Helvetica,Arial,sans-serif',
            "font-weight" = "lighter"
         )
         hc_subtitle(..., style = mbie_body)
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
   
   ###################
   ## Main function ##
   ###################
   ## Arguments:
   ## -out_data-
   ## A spread data.frame with the data to plot.
   ## One column should always be the column of dates, named "XVAR".
   ## The remaining columns are all numeric series to be plotted.
   ##   Each column becomes its own series.
   ##
   ## -vartype-
   ## The type of variable the series are, which defines how they are formatted.
   ## See helper function `hc_format` above.
   ##
   ## -curtitle-
   ## An optional title over the top of the graph.
   ##
   ## -pal-
   ## The colour palette to use.
   ## Can be a named vector, to assign specific colours to specific series.
   ##
   ## -seriesStyles-
   ## Defines a style to use for series.
   ## Valid values are: "Minor" "Normal" "Major" "Context"
   ## Can be a named vector, to assign specific styles to specific series.
   ##
   ## -subtitle-
   ## An optional subtitle below the title.
   ##
   ## -showmarker-
   ## Whether a marker should be displayed for each data point.
   ## Useful if the data is sparse.
   ## By default ("auto") a rudimentary check for sparse data
   ##  is conducted per series, to decide.
   ##
   ## -shared_tooltip-
   ## Whether to use shared tooltip or not.
   ## If NULL (Default), sets to TRUE if number of series <= 6.
   ##
   ## -proxy-
   ## A highchart proxy object, see "hc_proxy.R" or use NULL to ignore.
   function(out_data, vartype, curtitle = "", pal, seriesStyles = "Normal",
            subtitle = "", showmarker = "auto", shared_tooltip = NULL,
            proxy = NULL){
      numdf = as.matrix(out_data[which(names(out_data) != "XVAR")])
      if(is.null(names(pal)))
         names(pal) = colnames(numdf)
      if(length(seriesStyles) != ncol(numdf)){
         seriesStyles = rep(seriesStyles, length = ncol(numdf))
         names(seriesStyles) = NULL
      }
      if(is.null(names(seriesStyles)))
         names(seriesStyles) = colnames(numdf)
      isDate = class(out_data$XVAR) == "Date"
      Datevec = if(isDate) out_data$XVAR else NULL
      
      ## If we have no proxy given, we create a new highcharts object
      ## Else we can just use the proxy.
      if(is.null(proxy)){
         if(is.null(shared_tooltip))
            shared_tooltip = ncol(numdf) <= 6 && ncol(numdf) > 1
         yformat = hc_format(vartype)
         
         cur_format = hc_formatter(yformat, symbol = "diamond", shared = shared_tooltip)
         
         hc = highchart() %>%
            hc_export_settings() %>%
            hc_chart(type = "line", zoomType = "x", backgroundColor = NULL) %>%
            hc_legend(maxHeight = 100) %>%
            hc_title_style(text = curtitle) %>%
            hc_subtitle_style(text = subtitle) %>%
            hc_yAxis(labels = list(format = hc_format_yAxis(yformat))) %>%
            hc_tooltip(shared = shared_tooltip, useHTML = TRUE,
               headerFormat = '<span style="font-size: 10px">{point.key}</span><br/><table>',
               pointFormatter = cur_format,
               footerFormat = '</table>')
         
         ## Set x axis based on whether it's date or not
         if(isDate){
            hc = hc_xAxis(hc, type = "datetime") %>%
               hc_tooltip(xDateFormat = "%Y-%m-%d")
         } else{
            hc = hc_xAxis(hc, categories = I(out_data$XVAR), tickmarkPlacement = "on")
            ## If any categories are partial, note with a plotBand
            n_incomplete = grep("PARTIAL", out_data$XVAR)
            part_bands = lapply(n_incomplete, function(x) list(from = x - 1.5, to = x - 0.5, color = "#EAEAEA"))
            hc = hc_xAxis(hc, plotBands = part_bands)
         }
      } else hc = proxy
      
      ## Plot each series
      for(curvar in colnames(numdf)){
         hc = hc_asline(hc, name = curvar,
            values = as.vector(numdf[,curvar]), Datevec = Datevec,
            color = pal[[curvar]], animation = FALSE, connectNulls = FALSE,
            marker = list(enabled = showmarker, symbol = "diamond"),
            seriesStyle = seriesStyles[[curvar]])
      }
      hc
   }
})
