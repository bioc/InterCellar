#' The application User-Interface
#' 
#' @param request Internal parameter for `{shiny}`. 
#'     DO NOT REMOVE.
#' @importFrom shinydashboard dashboardPage dashboardHeader dropdownMenu 
#' notificationItem dashboardSidebar sidebarMenu menuItem menuSubItem 
#' dashboardBody tabItems tabItem
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # List the first level UI elements here 
    dashboardPage(skin = "black",
                  dashboardHeader(title = span(img(src = "www/logoShiny.png", width = "40px"), "InterCellar"),
                                  dropdownMenu(type="tasks",
                                               icon=icon("info"),
                                               badgeStatus=NULL,
                                               headerText="Check out",
                                               notificationItem(
                                                 text="InterCellar",
                                                 icon=icon("github"), 
                                                 status="primary",
                                                 href="https://github.com/martaint/InterCellar"
                                               ),
                                               notificationItem(
                                                 text="InterCellar-reproducibility",
                                                 icon=icon("github"), 
                                                 status="primary",
                                                 href="https://github.com/martaint/InterCellar-reproducibility"
                                               ),
                                               notificationItem(
                                                 text="Bioconductor package",
                                                 icon=icon("cube"), 
                                                 status="primary",
                                                 href="https://bioconductor.org/packages/InterCellar/"
                                               )
                                  )
                                  ),
                  dashboardSidebar(sidebarMenu(id = "sidebarmenu",
                                               menuItem("About", tabName = "about", icon = icon("rocket")),
                                               menuItem("1. Data",
                                                        menuSubItem("Upload", tabName = "upload", icon = icon("file-import")),
                                                        menuSubItem("Table View", tabName = "data_table", icon = icon("table")),
                                                        icon = icon("database")),
                                               menuItem("2. Universes", icon = icon("meteor"),
                                                        menuSubItem("Cluster-verse", tabName = "cluster-verse",
                                                                    icon = icon("project-diagram")),
                                                        menuSubItem("Gene-verse", tabName = "gene-verse", icon = icon("dna")),
                                                        menuSubItem("Function-verse", tabName = "function-verse", icon = icon("comments"))),
                                               
                                               menuItem("3. Data-Driven Analysis", tabName = "analyze", icon = icon("user-astronaut"),
                                                        menuSubItem("Int-Pair Modules", tabName = "ipModules",
                                                                    icon = icon("search")),
                                                        menuSubItem("Multiple Conditions", tabName = "multiConditions",
                                                                    icon = icon("compress-arrows-alt"))),
                                               uiOutput("select_db")
                                               #uiOutput("debug")
                  )),
                  dashboardBody(
                    tabItems(
                      tabItem(tabName = "about",
                              mod_about_ui("about_ui_1")
                      ),
                      tabItem(tabName = "upload",
                              mod_upload_ui("upload_ui_1")
                      ),
                      tabItem(tabName = "data_table",
                              mod_table_view_ui("table_view_ui_1")
                      ),
                      tabItem(tabName = "cluster-verse",
                              mod_cluster_verse_ui("cluster_verse_ui_1")
                      ),
                      tabItem(tabName = "gene-verse",
                              mod_gene_verse_ui("gene_verse_ui_1")
                      ),
                      tabItem(tabName = "function-verse",
                              mod_function_verse_ui("function_verse_ui_1")
                      ),
                      tabItem(tabName = "ipModules",
                              mod_int_pair_modules_ui("int_pair_modules_ui_1")
                      ),
                      tabItem(tabName = "multiConditions",
                              mod_multi_cond_ui("multi_cond_ui_1")
                      )
                    )
                  )
    )
  )#
}#

#' Add external Resources to the Application
#' 
#' This function is internally used to add external 
#' resources inside the Shiny application. 
#' 
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @importFrom shinyalert useShinyalert
#' @importFrom shinyFeedback useShinyFeedback
#' @noRd
golem_add_external_resources <- function(){
  
  add_resource_path(
    'www', app_sys('app/www')
  )
  add_resource_path(
    'extdata', app_sys('app/extdata')
  )
 
  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys('app/www'),
      app_title = 'InterCellar'
    ),
    # Add here other external resources
    
    shinyalert::useShinyalert(),
    shinyFeedback::useShinyFeedback()
  )
}

