library(dplyr)
library(shiny)
library(shinythemes)
library(markdown)

add_inv_and_port_names_if_needed <- function(data, portfolio_name, investor_name) {
  if (!inherits(data, "data.frame")) {
    return(data)
  }

  if (!"portfolio_name" %in% names(data)) {
    data <- dplyr::mutate(data, portfolio_name = .env$portfolio_name, .before = everything())
  }

  if (!"investor_name" %in% names(data)) {
    data <- dplyr::mutate(data, investor_name = .env$investor_name, .before = everything())
  }

  data
}

args <- commandArgs(trailingOnly = TRUE)
portfolio_name_ref_all <- if (length(args) != 0) {
  args[1]
} else {
  "1234"
}

templates_path <- "/Users/jdhoffa/github/templates.transition.monitor/general_en_template/"
working_dir_path <- "/Users/jdhoffa/github/workflow.transition.monitor/working_dir"
output_dir <- file.path(working_dir_path, "50_Outputs", portfolio_name_ref_all)
fs::dir_create("./app/www")
fs::dir_copy(fs::path(output_dir, "report/data"), "./app/www")
fs::dir_copy(fs::path(output_dir, "report/js"), "./app/www")
fs::file_copy(fs::path(output_dir, "report/2dii_gitbook_style.css"), "./app/www")

parameter_file <- yaml::read_yaml(
  file.path(
    working_dir_path,
    "10_Parameter_File",
    paste0(portfolio_name_ref_all, "_PortfolioParameters.yml")
  )
)

audit_file <- readRDS(
  file.path(working_dir_path, "30_Processed_Inputs", portfolio_name_ref_all, "audit_file.rds")
)

audit_file <- add_inv_and_port_names_if_needed(
  audit_file,
  investor_name = parameter_file$default$parameters$investor_name,
  portfolio_name = parameter_file$default$parameters$portfolio_name
  )


portfolio_parameters <- pacta.portfolio.report:::calculate_report_content_variables(
  audit_file = audit_file,
  investor_name = parameter_file$default$parameters$investor_name,
  portfolio_name = parameter_file$default$parameters$portfolio_name,
  currency_exchange_value = 1.0
)

display_currency <- "USD"

# Define UI for app that draws a histogram ----
ui <- tagList(
  uiOutput("data_includes"),
  uiOutput("js_includes"),
  navbarPage(
    # theme = shinythemes::shinytheme("flatly"),
    "PACTA Dashboard",
    tabPanel(
      "Interactive Report - Tabular Format",
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
          tabPanel("Introduction", uiOutput("introductionRMarkdown")),
          tabPanel("Scope", uiOutput("scopeRMarkdown")),
          tabPanel("Results", uiOutput("pactaRMarkdown")),
          tabPanel("Next Steps", uiOutput("nextStepsRMarkdown"))
        )
      )
    )
  )
)

# Define server logic required to draw a histogram ----
server <- function(input, output) {

  data_path <- fs::path(output_dir, "report/data")
  js_path <- fs::path(output_dir, "report/js")

  data_files <- list.files(data_path, pattern = "\\.js$", full.names = TRUE, recursive = TRUE)
  js_files <- list.files(js_path, pattern = "\\.js$", full.names = TRUE, recursive = TRUE)
  js_files <- js_files[!grepl("initialize", js_files)]


  output$data_includes <- renderUI({
    lapply(data_files, function(data_file) {
      includeScript(data_file)
    })
  })

  output$js_includes <- renderUI({
    lapply(js_files, function(js_file) {
      includeScript(js_file)
    })
  })

  output$initialize_charts <- renderUI({
    includeScript(fs::path(js_path, "initialize_charts.js"))
  })

  output$introductionRMarkdown <- renderUI({
    introductionOutput <- rmarkdown::render(
      file.path(templates_path, "rmd/01_introduction.Rmd"),
      output_format = "html_document",
      output_dir = "./app/www"
    )

    includeHTML(introductionOutput)
  })

  output$scopeRMarkdown <- renderUI({
    scopeOutput <- rmarkdown::render(
      file.path(templates_path, "rmd/02-scope.Rmd"),
      output_format = "html_document",
      output_dir = "./app/www"
    )

    includeHTML(scopeOutput)
  })


  output$pactaRMarkdown <- renderUI({
    pactaOutput <- rmarkdown::render(
      file.path(templates_path, "rmd/03-pacta.Rmd"),
      output_format = "html_document",
      output_dir = "./app/www"
    )

    optbar_html <- readLines(pacta.portfolio.report:::inst_path("optbar.html"))

    pactaOutputHtml <- readLines(pactaOutput)

    pactaOutputHtml <- c(
      pactaOutputHtml,
      sapply(
        list.files(fs::path(output_dir, "report/data")),
        function(data_file) {
          paste0("<script src='data/", data_file, "'></script>")
        },
        USE.NAMES = FALSE
      ),
      "<script src='js/d3.v4.min.js'></script>",
      "<script src='js/initialize_charts.js'></script>",
      optbar_html
    )

    writeLines(unlist(pactaOutputHtml), pactaOutput)

    includeHTML(pactaOutput)
  })

  output$nextStepsRMarkdown <- renderUI({
    nextStepsOutput <- rmarkdown::render(
      file.path(templates_path, "rmd/08-next_steps.Rmd"),
      output_format = "html_document",
      output_dir = "./app/www"
    )

    includeHTML(nextStepsOutput)
  })
}


shinyApp(ui = ui, server = server)
