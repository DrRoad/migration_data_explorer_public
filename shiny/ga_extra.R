## Extra app-specific ga trackers
ga_qjump = function()
   ga_track(".hjump a", "click",
            category = c("attr", "value"),
            action = "qjump")

ga_buttons = function()
   ga_track("button", "click",
            category = call("JS", 'curtar.text().replace(/(^\\s+)|(\\s+$)/g, "")'),
            action = "button")

ga_extra = function()
   tags$script(HTML(paste(
      ga_qjump(),
      ga_buttons()
   )))
