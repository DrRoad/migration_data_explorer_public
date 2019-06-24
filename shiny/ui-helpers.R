selectInputF =
   ## A wrapper for selectInput with selectize = FALSE
   function(inputId, label, choices, selected = NULL)
      shiny:::selectInput(inputId, label, choices, selected, selectize = FALSE)

tableCombo =
   ## Combination input of a table and download button for table
   function(inputId) tagList(
      downloadButton(paste0(inputId, "Down"), "Download Data as CSV"),
      tags$div(tags$form(class = "well",
         dataTableOutput(inputId)
      ))
   )
tableComboDown =
   ## Handle download of Data Table
   function(curtab, filename){
      ## Tidy filename, not strictly necessary on Windows systems
      filename = gsub(" ", "_", filename, fixed = TRUE)
      filename = gsub(",", "", filename, fixed = TRUE)
      downloadHandler(
         filename = paste0(filename, ".csv"),
         content = function(file) write.csv(curtab, file, row.names = FALSE),
         contentType = "text/csv"
      )
   }

dashboardPage =
   ## Modified `navbarPage` from shiny
   ## Trimmed down to a more narrow purpose
   ##  and enables use of tags$head with `thead`
   ## Originally created for use with the Tourism Dashboard
   function(title, ..., id = "dashboard", thead = NULL, header = NULL, footer = NULL, windowTitle = title){
      pageTitle = title
      navbarClass = "navbar navbar-default"
      tabs = list(...)
      tabset = shiny:::buildTabset(tabs, "nav navbar-nav", NULL, id)
      containerDiv = div(class = "container", div(class = "navbar-header", 
         span(class = "navbar-brand", pageTitle)), tabset$navList)
      contentDiv = div(class = "container-fluid", tabset$content)
      if(!is.null(header))
         header = tags$header(header, role = "banner")
      if(!is.null(footer))
         footer = tags$footer(footer, role = "contentinfo")
      bootstrapPage(title = windowTitle, thead,
                    header,
                    tags$nav(class = navbarClass, role = "navigation", containerDiv),
                    tag("main", list(role = "main", contentDiv)),
                    footer)
   }

tabTitle =
   ## Creates an appropriately styled title
   ## Styles are defined in the css
   function(x)
      h3(class = "tabTitle", x)
tabDesc =
   ## Creates an appropriately styled description
   ## Styles are defined in the css
   ## If NA, returns NULL
   function(x)
      if(!is.null(x)){
         if(any(class(x) == "character"))
            tags$p(class = "tabDesc", x)
         else
            x
      } else NULL
tabPwT =
   ## tabPanel with Title (using tabTitle)
   ## Also searches for a match in `tabdesc`
   ##  (a named vector of descriptions)
   ## If one is found, adds the description below the title
   function(title, ...){
      tabPanel(title,
         div(class = "tabTitlePanel",
            tabTitle(title),
            tabDesc(tabdesc[title][[1]]),
            div(class = "tabTitlePanel-end")
         ),
         ...
      )
   }
tabPwDesc =
   ## tabPanel with Desc only
   function(title, ...){
      tabPanel(title,
         div(class = "tabTitlePanel",
            tabDesc(tabdesc[title][[1]]),
            div(class = "tabTitlePanel-end")
         ),
         ...
      )
   }
