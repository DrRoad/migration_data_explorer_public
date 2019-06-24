mbie_header =
   ## Adds a basic MBIE header.
   function() div(
      id = "mbie-header",
      div(class = "mbie-topbar"),
      div(class = "mbie-brand",
         tags$a(class = "mbie-brand", href = "http://www.mbie.govt.nz/",
                title = "Ministry of Business, Innovation & Employment home page.",
                tags$img(src = "mbie-logo.png",
                         alt = "Ministry of Business, Innovation & Employment"))
      )
   )

mbie_footer =
   ## Adds an MBIE footer.
   function(extraTags = NULL){
      ## By default the footer links to MBIE website pages
      ## But if the custom shiny-specific pages (found in this file)
      ##  are added via tabs, this script finds them and automatically
      ##  updates the links to those tabs instead.
      script_smartlink = tags$script(HTML(
         '$(function(){
            $(".footer-lower a[key]").each(function(){
               var cur_id = $(this).attr("key");
               var cur_tab = $("#" + cur_id).parent(".tab-pane").attr("data-value");
               if(cur_tab !== undefined){
                  var cur_nav = $(".navbar a[data-value=" + JSON.stringify(cur_tab) + "]")[0];
                  $(this)
                     .attr("href", "#")
                     .removeAttr("target")
                     .on("click", function(){cur_nav.click();});
               }
            })
         });'
      ))
      
      ## Out HTML
      div(
         id = "mbie-footer", class = "mbie-footer",
         div(class = "mbie-footer-container mbie-text-block",
            div(tags$a(href = "https://www.govt.nz/", target = "_blank",
               title = "Govt.nz | NZ Government",
               div(id = "nzGov",
                  tags$img(src = "nz-gov-logo.png",
                           alt = "New Zealand Government")
               )
            )),
            tags$hr(),
            div(class = "footer-lower footer-lower-first-item",
               tags$a("Disclaimer", target = "_blank",
                  href = "https://www.mbie.govt.nz/disclaimer/")
            ),
            div(class = "footer-lower",
               tags$a("Copyright", key = "mbie_copyright", target = "_blank",
                  href = "https://www.mbie.govt.nz/copyright/")
            ),
            div(class = "footer-lower",
               tags$a("Privacy Policy", key = "mbie_privacy", target = "_blank",
                  href = "https://www.mbie.govt.nz/privacy/")
            ),
            div(class = "footer-lower",
               tags$a("Contact us", key = "mbie_contact", target = "_blank",
                  href = "https://www.mbie.govt.nz/about/contact-us/")
            ),
            div(class = "footer-lower footer-lower-last-item",
               div(id = "Copyright", HTML("&copy;"),
                  "Ministry of Business Innovation & Employment"
               )
            )
         ),
         script_smartlink,
         extraTags
      )
   }

mbie_contact =
   ## Page with Contact information
   ## Modified from http://www.mbie.govt.nz/about/our-people/contact-us
   function(contactDiv) div(id = "mbie_contact", class = "mbie-text-block",
      h1("Contact Us"),
      p(class = "intro",
         "This page contains contact details for this specific website's content only. For more general MBIE contact information, please refer to the",
         tags$a("MBIE Contact Us", target = "_blank",
            href = "https://www.mbie.govt.nz/about/contact-us/"),
         "page."
      ),
      contactDiv
   )
