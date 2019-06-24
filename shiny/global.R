library(shiny)
library(data.table)
library(rlang)
library(dplyr)
library(tidyr)
library(zoo)
library(highcharter)
source("print-helper.R")
source("random_rounding.R")
source("compute_other.R")
source("hclinebasic.R")
# source("hcdotchart.R")
source("hcbarplot.R")
source("ui-helpers.R")
source("ui_doctabs.R")
source("hc_proxy.R")

load("all_csv_names.rda")
names(all_csv_names) = gsub("_(.)", " \\U\\1", all_csv_names, perl = TRUE)

### ---- ---- ----
## Interim code for adding highcharts accessibility module.
## This should be obsolete once the highcharter package is updated
##  to include the accessibility module natively.
## When removing this code, need to also remove:
## 1) The js file: www/hc-5.0.6-accessibility.js
## 2) The ui.R call to the js file: tags$script(src = "hc-5.0.6-accessibility.js")
hc_accessibility <- with(environment(highchart), {
   function(hc, ...){
      .hc_opt(hc, "accessibility", ...)
   }
})
local({
   doptions = options("highcharter.chart")$highcharter.chart
   
   ## Add required accessibility options
   doptions$accessibility = list(
      enabled = TRUE,
      keyboardNavigation = list(
         enabled = TRUE,
         skipNullPoints = TRUE
      )
   )
   
   ## Add a callback to adjust the title added by accessibility
   ##  which results in an annoying tooltip.
   doptions$chart = list(events = list(load = JS(paste("function(){",
      "var csvg = $(this.container).find('svg');",
      "var ctitle = csvg.children('title');",
      "csvg.children('desc').attr('id', ctitle.attr('id')).text(ctitle.text());",
      "ctitle.remove();}"))))
   
   options(highcharter.chart = doptions)
})
### ---- ---- ----
hc_fix = tags$script(HTML("
    /* Fix for plotBand labels not showing
       Adapted from: https://github.com/highcharts/highcharts/issues/8477
       Along with code from latest version:
       https://github.com/highcharts/highcharts/blob/master/js/parts/PlotLineOrBand.js */
    Highcharts.wrap(Highcharts.Axis.prototype, 'getPlotBandPath', function(proceed, from, to) {
        var path = proceed.apply(this, Array.prototype.slice.call(arguments, 1));
        var pone = this.getPlotLinePath(to, null, null, true),
            ptwo = this.getPlotLinePath(from, null, null, true);
        if (path) {
            path.flat = pone.toString() === ptwo.toString();
        }
        return path;
    });
"))

## mbiekun (guided tour) ui code
if(!exists("mbiekun_enable")) mbiekun_enable = TRUE
if(mbiekun_enable){
   box_lost = a(class = "box-link", href = "#",
      div(class = "box box-help",
         p(class = "intro", "Feeling lost?"),
         p("If you're not sure where to start, click this box to start a quick tour of the key features.")
      )
   )
   box_lost_JS = tags$script(HTML(
      '$(function(){$(".box-help").on("click.lost", function(){',
      'mbiekun_tour_begin("quick_pop"); return false;',
      '});});'
   ))

   mbiekun_ui = tagList(
      tags$script(src = "mbiekun.js"),
      tags$link(rel = "stylesheet", href = "mbiekun.css"),
      tags$script(src = "mbiekun_defs.js"),
      box_lost_JS
   )

   helpp = tagAppendChild(helpp, tagList(
      h3("Guided Tours"),
      p("This data explorer features an integrated guided tour, which can provide you with hints on how to get the most out of the data explorer."),
      p(a("Start the tour by clicking here.", href = "#",
         onclick = JS("mbiekun_tour_begin();")))
   ))
   frontp = tagAppendChild(frontp, box_lost)
} else{
   mbiekun_ui = NULL
   box_lost = NULL
}

source("helper_funcs.R")
