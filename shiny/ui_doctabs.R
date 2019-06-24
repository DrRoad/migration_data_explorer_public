tablink = function(tabName, linkText = tabName){
   linkjs = JS(paste0(
      "HelperFuncs.tab(", encodeString(tabName, quote = '"'), ");"
   ))
   tags$a(linkText, href = "#", onclick = linkjs)
}

addHelpIcon = function(){
   HTML(paste0("$(function(){",
      'var divbrand = $("div.mbie-brand");',
      'if(divbrand.length > 0){',
         '$("<div>", {class: "helpmark-con"})',
            '.append($("<i>", {class: "glyphicon glyphicon-question-sign"}))',
            '.on("click", function(){HelperFuncs.tab("Help");})',
            '.appendTo(divbrand);',
      '}',
   "});"))
}

url_report = paste0("https://www.mbie.govt.nz/immigration-and-tourism/immigration/",
   "migration-research-and-evaluation/migration-trends-report/")
img_report = "migration-trends-1617.png"

## Feedback div used in Contact Us page.
feedback_div = div(
   h4("Questions, Concerns, Feedback"),
   tags$table(
      tags$tr(tags$td("Data Explorer Help, Migration Evidence and Insights")),
      tags$tr(tags$td(a(href = "mailto:data_explorer_help@mbie.govt.nz", "data_explorer_help@mbie.govt.nz"))),
      tags$tr(tags$td("15 Stout Street, Wellington 6011")),
      tags$tr(tags$td("PO Box 1473, Wellington 6140"))
   )
)

## Release schedule
release_div = div(
   h6("Release Schedule"),
   p("The data will generally be updated on the second Monday of each month."),
   p("This is to ensure all the datasets the Data Explorer draws on are up-to-date with the previous month's data.")
)

## Seasonal adjustment text
## inputSeas - condensed explanation added to ui panel when seasonal adjustment is enabled
## helpSeas  - full explanation used in Help tab
inputSeas = tagList(
   p(
      "Seasonal adjustment is computed automatically, as such they may",
      "not be the most appropriate adjustment for the data.",
      "It is also not available for sub-series with very",
      "small counts or where there is less than 2 years of data."
   ),
   p(
      "Where there are a large number of sub-series selected, seasonal",
      "adjustment will only be provided for the largest sub-series.",
      "Use filters to narrow down the data if seasonal adjustment is",
      "required for a specific sub-series."
   )
)
helpSeas = tagList(
   p(
      "Seasonal decomposition is computed automatically using the",
      tags$code("stl"), "algorithm in R, for every sub-series individually."
   ),
   p(
      "The decomposition is applied on the log-transformed data, as the",
      "seasonal effects are generally multiplicative. We also assume a fixed",
      "seasonal effect across the entire time-period.",
      "Note that filters can be used to narrow down the time-period to a",
      "specific window if required."
   ),
   p(
      "The trend provided is the loess smoothed trend after removal of the computed",
      "seasonal effects, and thus excludes both seasonal effects and any computed errors."
   ),
   p("Seasonal decomposition may not be carried out in the following cases:"),
   tags$ul(
      tags$li(
         "There are a large number of sub-series, in which case the smaller",
         "sub-series are skipped for performance reasons."
      ),
      tags$li("There are missing values or 0 counts in the data."),
      tags$li("There is not enough data (less than 2 years).")
   )
)

## input Tooltips
## These are used within the ui section in "helper_funcs.R"
##  but are defined here for easier editing.
inputTips = list(
   "dname" = "Start by selecting the dataset to explore.",
   "datekind" = "Some datasets may have different cuts of time available, e.g. by Financial Year.",
   "dvars" = "Add variables here to get a breakdown of the data by those variables, e.g. add [Gender] to get a breakdown by Gender.",
   "cond" = "Use filters to narrow down the data to a specific selection, e.g. add [Gender] CONTAINS [Male] to only see male migrants.",
   "condvar" = "Choose the variable to filter.",
   "condtype" = "Choose the type of filter.",
   "condval" = "Choose values to apply the filter to."
)

## tabdesc
## Descriptions for each tab
tabdesc = list(
   "Data Explorer" = div(class = "tabDesc",
      p(class = "intro",
         "Here you will find the migration datasets available in this data explorer."
      ),
      p(
         "This includes the Population (Number of migrants in New Zealand), the Visa Flows (How migrants move in and out of Visa Categories and New Zealand) and other Immigration New Zealand Statistics (Visa Applications and more)."
      ),
      div(class = "intro-divider"),
      p("To explore any of these datasets:"),
      tags$ol(
         tags$li("Select the dataset of interest"),
         tags$li("Choose the time period breakdown (Financial Year, Calendar Year or Monthly data). Some breakdowns may be unavailable for some datasets"),
         tags$li("Select up to 4 variables of interest, e.g. select [Nationality] to get the data broken down by nationality"),
         tags$li("Filters can be used to narrow down the data, e.g. for the Population dataset, add a filter for [Visa_Type] [CONTAINS] [Work] for just the migrants on a temporary work visa")
      ),
      p(
         "The chart and table displays a preview of the most interesting figures. Unless the data selected is narrow in scope, not all values will be displayed. To add additional data to the chart, use the [Add more series] button above the chart. The full data is also available via the [Download Data as CSV] button."
      ),
      p(
         "You can save your query for re-use or to share, using the [Save/Load Query] button."
      ),
      p(
         span(class = "bold", "Note:"),
         "All numbers provided are subject to random rounding to base 3 by applying",
         "the same rule used by Stats NZ for Census data."
      )
   )
)

## qjump
## Quick-jump functionality added below heading on the front-page
## Requires JavaScript to work, the function that does this is
##  "hef.qjump", defined in "helper_funcs.js" 
qjump_defs = list(
   list(
      value = "pop",
      "Migrant Population (Number of migrants in New Zealand)",
      `data-query` = '{"dname":"pop","datekind":"m","dvars":["Visa_Type"],"conds":null}'
   ),
   list(
      value = "flow",
      "Visa Flows (How migrants move in and out of Visa Categories and New Zealand)",
      `data-query` = '{"dname":"flow","datekind":"m","dvars":["Visa_Flows"],"conds":null}'
   ),
   list(
      value = "essential_skills",
      "Approved Essential Skills Applicants by Occupation and Region",
      `data-query` = '{"dname":"W3_work_occupations","datekind":"fy","dvars":["Standard Major Group","Region"],"conds":[{"vname":"Application Criteria","vtype":"CONTAINS","vvals":["Approved In Principle","Essential Skills","Essential Skills - Skill Level 1"]},{"vname":"Decision Type","vtype":"CONTAINS","vvals":["Approved"]}]}'
   )
)
qjump_li = tagList(
   do.call(tags$ul, lapply(qjump_defs, function(x)
      do.call(function(...) tags$li(tags$a(href = "#", ...)), x)
   ))
)

frontp = div(class = "frontp",
   div(class = "front-banner",
      div(class = "imgcon"),
      div(class = "hcon", h1("Migration Data Explorer")),
      div(class = "hjump", div(class = "hcon",
         h4("Quick Select..."),
         qjump_li
      ))
   ),
   h4("Welcome to the Migration Data Explorer!"),
   p(
      "If you encounter any issues, please", tablink("Contact Us"), "so we can address the problem."
   ),
   h6("Getting started"),
   p(
      "Select an item from the Quick Select list above. This will direct you to",
      "the Data Explorer tab and pre-populate some inputs for you.",
      "If you have used the Data Explorer previously, your previous session will also be available",
      "in this list, so you can jump right back to what you were looking at last time."
   ),
   release_div,
   div(id = "m_release_notes_recent"),
   div(class = "intro-divider"),
   p(class = "intro", "The Migration Data Explorer enables you to easily access migration data to address the overarching research themes and enduring questions that relate to migration in New Zealand."),
   p("The data explorer is:"),
   tags$ul(
      tags$li("A single interface for migration statistics which provides access  to migration data."),
      tags$li("A new conceptual framework for analysing migration trends based on determining migration's impact on the population and labour supply, which moves away from existing administrative metrics such as visa approval numbers.")
   ),
   p(
      span(class = "bold", "Note:"),
      "All numbers provided are subject to random rounding to base 3 by applying",
      "the same rule used by Stats NZ for Census data."
   ),
   a(class = "box-link", target = "_blank", href = url_report,
      div(class = "box box-more",
         img(class = "img-report", src = img_report),
         p(class = "intro", "Migration Trends 2016/17"),
         p("This annual report is the 17th in a series that examines trends in temporary and permanent migration to and from New Zealand. The report updates trends to 2016/17 and compares recent immigration patterns with patterns identified in previous years.")
      )
   ),
   div(class = "box box-timeout",
      p(span(class = "bold", "PLEASE NOTE:"),
             "This app may time-out if left idle too long, which will cause the screen to grey-out.",
             "To use the app again, refresh the page. This will reset all previously-selected input options.")
   ),
   tags$br()
)

flows_numbers = list(
   "out_to_work" = 15000,
   "work_to_out" = 12000,
   "work_to_work" = 9000,
   "work_to_res" = 1600
) %>% lapply(function(x) format(x, trim = TRUE, big.mark = ",", scientific = FALSE))
helpp = div(class = "frontp",
   div(id = "m_release_notes"),
   release_div,
   h3("Population"),
   p("This is a measure of the number of migrants in New Zealand, with breakdowns by visa type and demographic characteristics, at specific points in time."),
   p(
      "The population count is taken on the last day of each month.",
      "All migrants who are in New Zealand with a valid visa on each population count date",
      "are counted as part of the population."
   ),
   p(
      "The residence count is only for recent residents. Those people who have been",
      "on a residence visa for more than 5 years are treated in the same way as citizens",
      "and are no longer counted."
   ),
   h3("Visa Flows"),
   p("This is a measure of migrant movements in and out of Visa Categories and New Zealand, with breakdowns by visa type and demographic characteristics."),
   p(
      "The visa flow is computed by comparing between two consecutive population count dates.",
      "All migrants in the population at either or both of the two population count dates are compared.",
      "Any who have changed status are measured as a flow.",
      "This flow is then recorded on the latter of the two dates."
   ),
   p(
      "Each flow has two key variables:",
      span(class = "defword", "Outflow_from"), "and",
      span(class = "defword", "Inflow_to")
   ),
   tags$ul(
      tags$li(span(class = "defword", "Outflow_from"), "indicates where the migrant came from. For migrants already in New Zealand this is the Visa Type that the migrant held on the earlier of the two dates. Otherwise it is assumed they came from outside New Zealand"),
      tags$li(span(class = "defword", "Inflow_to"), "indicates where the migrant went to. For migrants remaining in New Zealand this is the Visa Type that the migrant held on the latter of the two dates. Otherwise it is assumed they have left New Zealand, unless we have information that they have passed away.")
   ),
   p("e.g. For the date 28 February 2018, we have Visa Flows of..."),
   tags$ol(
      tags$li(paste(
         "About", flows_numbers$out_to_work, "[OUTSIDE NZ to Work].",
         "This indicates about", flows_numbers$out_to_work, "migrants who were not present",
         "on 31 January 2018 are now present on a Work visa on 28 February 2018."
      )),
      tags$li(paste(
         "About", flows_numbers$work_to_out, "[Work to OUTSIDE NZ].",
         "This indicates about", flows_numbers$work_to_out, "migrants who were not present",
         "on 31 January 2018 on a Work visa are no longer present on 28 February 2018."
      )),
      tags$li(paste(
         "About", flows_numbers$work_to_work, "[Work to Work].",
         "This indicates about", flows_numbers$work_to_work, "migrants who were present",
         "on 31 January 2018 on a Work visa are now on a new Work visa on 28 February 2018.",
         "This includes visa renewals (as this requires a new visa application and approval),",
         "and thus the new Work visa may be the same type as the previous visa."
      )),
      tags$li(paste(
         "About", flows_numbers$work_to_res, "[Work to Recent Resident].",
         "This indicates about", flows_numbers$work_to_res, "migrants who were present",
         "on 31 January 2018 on a Work visa are now on a Resident visa on 28 February 2018.",
         "That is, these migrants transitioned from a Work visa to a Resident visa.",
         "This does not capture all Work to Residence transitions, as only those who are",
         "present on, and transition between, two consecutive population count dates, are captured."
      ))
   ),
   h3("Seasonal Adjustments"),
   helpSeas,
   h3("Immigration New Zealand Statistics"),
   p(
      "Some of the data provided in the Data Explorer tab were formerly available via the",
      a("Immigration New Zealand Statistics page", target = "_blank",
         title = "Statistics, Immigration New Zealand", rel = "noopener noreferrer",
         href = "https://www.immigration.govt.nz/about-us/research-and-statistics/statistics"),
      "as CSV downloads."
   ),
   p(
      "Those CSV files were taken down over concerns that it contained information",
      "that potentially breached individuals' privacy. To address those concerns,",
      "all numbers provided are subject to random rounding to base 3 by applying",
      "the same rule used by Stats NZ for Census data."
   ),
   p(
      "More information about this procedure can be found on the",
      a("Stats NZ website", target = "_blank",
        title = "Link to Stats NZ website, opens in a new window.", rel = "noopener noreferrer",
        href = "http://archive.stats.govt.nz/about_us/legisln-policies-protocols/confidentiality-of-info-supplied-to-snz/safeguarding-confidentiality.aspx#census"),
      "under the heading 'Census tables'."
   ),
   tags$script(addHelpIcon())
)
