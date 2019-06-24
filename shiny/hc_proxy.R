## Barebones Highcharts proxy methods.
## Based roughly on the leaflet model, see ?leaflet::leafletProxy
## A "fake" highchart object is created using `hc_proxy`,
##  which holds proxy information along with series data.
## This "fake" can be passed to `hc_add_series` to store the series data.
## Use `hc_proxy_update` to update existing series with this data.
## Use `hc_proxy_add` to add new series.
## Use `hc_proxy_remove` to remove series with id given in the argument.
## Use `hc_proxy_remove_all` to remove all series.
## For convenience, the proxy is created with "redraw = TRUE" by default.
## This means whenever a message is sent, the highchart object is redrawn afterwards.
## For performance reasons, you may choose to set "redraw = FALSE",
##  which means the highchart object is not redrawn unless a message is
##  specifically sent via `hc_proxy_redraw`.

hc_proxy =
   ## Create a dummy highcharts object for storing series data
   ##  along with proxy information.
   function(hcid, session = shiny::getDefaultReactiveDomain(), deferUntilFlush = TRUE, redraw = TRUE){
      if(is.null(session))
         stop("hc_proxy must be called from the server function of a Shiny app")

      structure(
         list(
            id = hcid,
            session = session,
            x = list(hc_opts = list(series = NULL)),
            deferUntilFlush = deferUntilFlush,
            redraw = redraw
         ),
         class = c("highchart", "hc_proxy")
      )
   }

hc_proxy_send =
   ## Used by the other functions to send the custom message.
   function(hc_proxy, msg){
      sess = hc_proxy$session
      msg$id = hc_proxy$id
      msg$redraw = hc_proxy$redraw
      if(hc_proxy$deferUntilFlush)
         sess$onFlushed(function() sess$sendCustomMessage("hc-proxy", msg), once = TRUE)
      else
         sess$sendCustomMessage("hc-proxy", msg)
      hc_proxy
   }

hc_proxy_update =
   ## Update existing series with the series data in the proxy.
   ## It finds the correct series to update via id.
   ## If a matching series is not found, it updates sequentially,
   ##  which is unreliable!!!
   ## `hc_proxy_update` should only be used where all the series
   ##  data in the proxy has id that matches to existing series.
   ## Use `hc_proxy_add` to add new series.
   ## See http://api.highcharts.com/highcharts/Chart.update
   function(hc_proxy){
      msg = list(type = "update", data = hc_proxy$x$hc_opts$series)
      hc_proxy_send(hc_proxy, msg)
   }

hc_proxy_add =
   ## Add series data in proxy to the highchart.
   ## It does not check if any series with the same id already exists,
   ##  which can result in duplication.
   ## Use `hc_proxy_update` to update existing series, and only
   ##  use `hc_proxy_add` to add NEW series.
   function(hc_proxy){
      msg = list(type = "add", data = hc_proxy$x$hc_opts$series)
      hc_proxy_send(hc_proxy, msg)
   }

hc_proxy_remove =
   ## Remove series with given names.
   ## Any series data in the proxy is ignored.
   function(hc_proxy, series_names){
      msg = list(type = "remove", data = I(series_names))
      hc_proxy_send(hc_proxy, msg)
   }

hc_proxy_remove_all =
   ## Remove all series.
   ## Any series data in the proxy is ignored.
   function(hc_proxy){
      msg = list(type = "remove_all")
      hc_proxy_send(hc_proxy, msg)
   }

hc_proxy_hide_all =
   ## Hide all series.
   ## Any series data in the proxy is ignored.
   function(hc_proxy){
      msg = list(type = "hide_all")
      hc_proxy_send(hc_proxy, msg)
   }

hc_proxy_redraw =
   ## Trigger a redraw.
   function(hc_proxy){
      msg = list(type = "redraw")
      hc_proxy_send(hc_proxy, msg)
   }
