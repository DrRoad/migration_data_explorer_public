source("mbie-styles.R")
source("ga_Rfuncs.R")
source("ga_extra.R")

shinyUI(
   dashboardPage("Migration Data Explorer", thead = tagList(
      tags$head(
         datePickerHead,
         hc_fix,
         ## jQueryUI
         tags$script(src = "jquery-ui-1.12.1.min.js"),
         tags$link(rel = "stylesheet", href = "jquery-ui-1.12.1.min.css"),
         ## Add Highcharts accessibility module
         tags$script(src = "hc-5.0.6-accessibility.js"),
         ## Highcharter proxy methods
         includeScript("hc_proxy.js"),
         ## Google Analytics
         includeScript("ga_tracker.js"),
         ga_common(),
         ga_extra(),
         ## Other
         tags$script(src = "release_notes_apply.js"),
         tags$script(src = "defs_apply.js"),
         HelperFuncsJS,
         includeCSS("mbie-styles.css"),
         includeCSS("ui-helpers.css"),
         includeCSS("id-styles.css")
      )
   ),
   header = mbie_header(),
   tabPanel("Introduction",
      frontp
   ),
   tabPwDesc("Data Explorer",
      BetterCSVs$ui
   ),
   tabPanel("Help",
      helpp
   ),#PrintHelper$tab,
   tabPanel("Contact Us",
      mbie_contact(feedback_div)
   ),
   footer = mbie_footer(mbiekun_ui)
))
