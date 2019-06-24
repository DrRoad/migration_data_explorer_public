source("headliners.R")

shinyServer(function(input, output, session){
   BetterCSVs$server(input, output, session)
})
