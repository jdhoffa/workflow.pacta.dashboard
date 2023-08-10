library(shiny)
library(shinythemes)

# Define UI for app that draws a histogram ----
ui <- tagList(
  navbarPage(
    theme = shinythemes::shinytheme("flatly"),
    "PACTA Dashboard",
    tabPanel("Interactive Report - Tabular Format",
             sidebarPanel(
               fileInput("portfolio_input", "Please upload your portfolio:"),
               selectInput("scenario_input",
                           "Please select a scenario:",
                           choices = c("WEO 2023", "GECO 2023"),
                           selected = "WEO 2023"
                           ),
             ),
             mainPanel(
               tabsetPanel(
                 tabPanel("Introduction", "This panel is intentionally left blank"),
                 tabPanel("Scope", "This panel is intentionally left blank"),
                 tabPanel("PACTA", "This panel is intentionally left blank"),
                 tabPanel("Next Steps", "This panel is intentionally left blank")
               )
             )
    )
  )
)

# Define server logic required to draw a histogram ----
server <- function(input, output) {
  output$txtout <- renderText({
    paste(input$txt, input$slider, format(input$date), sep = ", ")
  })
  output$table <- renderTable({
    head(cars, 4)
  })
}

shinyApp(ui = ui, server = server)
