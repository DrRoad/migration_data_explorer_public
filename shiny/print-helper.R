PrintHelper = local({
   ## An experimental tool to generate print-ready A4-type pages with
   ##  arbitrary selection and layout of outputs and narrative text.
   ## This is the R component of the tool, there are also
   ##  JavaScript and CSS components.
   
   baseid = "PrintHelper"
   makeid = function(x) paste(baseid, x, sep = "_")
   wrapid = function(x) paste(x, baseid, "Wrapper", sep = "_")
   tabname = "Print Helper"
   id_div = makeid("div")
   id_selmode = makeid("chk-selmode")
   id_moveresize = makeid("chk-moveresize")
   id_printmode = makeid("chk-printmode")
   id_textarea = makeid("btn-textarea")
   id_uiout = makeid("ui-out")
   
   index_id = 0
   gen_unique_id = function(){
      index_id <<- index_id + 1
      paste(baseid, "R", index_id, sep = "_")
   }
   
   enc = function(x) encodeString(x, quote = '"')
   args_init = paste(enc(c(tabname, id_div, id_selmode, id_moveresize, id_printmode, id_textarea)), collapse = ",")
   store = new.env()
   
   phOutput =
      ## Wrapper for html-widget output containers
      function(outputFunction, outputId, ...){
         store[[outputId]] = list()
         store[[outputId]]$outputFunction = outputFunction
         store[[outputId]]$outputDots = list(...)
         
         div(class = "ph-output",
            conditionalPanel(
               condition = paste0('input[[', enc(id_selmode), ']] == true'),
               actionButton(wrapid(outputId), "Create Print Copy")
            ),
            do.call(outputFunction, c(list(outputId = outputId), list(...)))
         )
      }
   
   phRender =
      ## Companion wrapper to phOutput for rendering
      function(output, outputId, renderFunction){
         store[[outputId]]$renderFunction = renderFunction
         
         renderFunction(output, outputId, TRUE)
      }
   
   phCopyServer =
      ## Companion function to phOutput/phRender
      ## This is what creates the print-copy
      function(input, output, session, outputId)
         observe(if(input[[(wrapid(outputId))]] > 0){
            outputFunction = store[[outputId]]$outputFunction
            outputDots = store[[outputId]]$outputDots
            renderFunction = store[[outputId]]$renderFunction
            cur_id = gen_unique_id()
            con_id = paste0(cur_id, "-con")
            
            outputDots$width = "100%"
            outputDots$height = "100%"
            
            ## Generate a copy output container
            ui_con = do.call(outputFunction, c(list(outputId = cur_id), outputDots))
            
            ## Render to uiout
            output[[id_uiout]] = renderUI(ui_con)
            
            ## Create ph-con in proxy-page
            phSend(session, msg = list(type = "create-con", id = con_id))
            
            ## Move over from uiout to ph-con
            phSend(session, msg = list(type = "move", cur_id = cur_id, con_id = con_id))
            
            ## Render
            renderFunction(output, cur_id, FALSE)
         })
      
   phSend =
      ## Convenience wrapper for sending custom messages to js
      function(session, msg)
         session$onFlushed(function() session$sendCustomMessage("print-helper", msg), once = TRUE)
   
   ui = div(id = id_div,
      div(class = "print-helper-inputs",
         checkboxInput(id_selmode, "Select Mode", FALSE),
         checkboxInput(id_moveresize, "Move/Resize Mode", FALSE),
         checkboxInput(id_printmode, "Print Mode", FALSE),
         actionButton(id_textarea, "Create Text Area", icon("font"))
      ),
      div(class = "print-helper paperA4 paperLandscape"),
      div(class = "print-helper-texteditor"),
      div(class = "print-helper-hidden",
         uiOutput(id_uiout),
         ## jQueryUI
         # tags$script(HTML(paste("\n",
            # "/* Handle jQuery plugin naming conflict between jQuery UI and Bootstrap */",
            # "var _tooltip = jQuery.fn.tooltip;",
            # "var _button = jQuery.fn.button;"))),
         # tags$script(src = "jquery-ui-1.12.1.min.js"),
         # tags$link(rel = "stylesheet", href = "jquery-ui-1.12.1.min.css"),
         # tags$script(HTML(paste("\n",
            # "/* Handle jQuery plugin naming conflict between jQuery UI and Bootstrap */",
            # "$.widget.bridge('uibutton', $.ui.button);",
            # "$.widget.bridge('uitooltip', $.ui.tooltip);",
            # "jQuery.fn.tooltip = _tooltip;",
            # "jQuery.fn.button = _button;"))),
         ## summernote
         tags$script(src = "summernote-0.8.9.js"),
         tags$link(rel = "stylesheet", href = "summernote-0.8.9.css"),
         ## Print Helper
         includeCSS("print-helper.css"),
         includeScript("print-helper.js"),
         tags$script(paste0("$(function(){PrintHelper.init(", args_init, ");});"))
      )
   )
   
   tab = tabPanel("Print Helper", ui)

   server = function(input, output, session){
      ##
   }
   
   PaperSizeCSS =
      ## Generates CSS rules for various paper sizes
      ## Only required when updating the CSS
      ## Dimensions defined (width, height) in mm
      function(){
         margins = c(10, 15)
         
         ## A Series
         ## Start with A0, then compute down to A5
         ## https://en.wikipedia.org/wiki/ISO_216#A_series
         ## "Successive paper sizes in the series (A1, A2, A3, etc.)
         ##  are defined by halving the length of the preceding paper
         ##  size and rounding down, so that the long side of A(n+1)
         ##  is the same length as the short side of An."
         A_list = list(c(841, 1189))
         for(i in 1:5){
            A_list[[i + 1]] = sort(trunc(range(A_list[[i]]) * c(1, 0.5)))
         }
         
         make_css = function(mat, name){
            mat = mat - margins
            out = list()
            for(j in 1:ncol(mat)){
               cur_dim = as.list(paste0(mat[,j], "mm"))
               names(cur_dim) = c("width", "height")
               out[[j]] = paste0(
                  ".print-helper",
                  ".paperA", j - 1,
                  ".paper", name,
                  "{", do.call(htmltools::css, cur_dim),
                  "}\n"
               )
            }
            cat(do.call(paste0, out))
         }
         
         ## Portrait
         make_css(do.call(cbind, A_list), "Portrait")
         
         ## Landscape
         make_css(do.call(cbind, A_list)[2:1,], "Landscape")
      }
   
   environment()
})
phOutput = PrintHelper$phOutput
phRender = PrintHelper$phRender
phCopyServer = PrintHelper$phCopyServer
