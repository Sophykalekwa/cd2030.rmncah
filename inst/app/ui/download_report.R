downloadReportUI <- function(id, i18n) {
  ns <- NS(id)

  tags$li(
    actionLink(
      inputId = ns('download'),
      label = i18n$t('btn_download_report'),
      icon = icon('download')
    ),
    class = 'dropdown'
  )
}

downloadReportServer <- function(id, cache, i18n) {
  stopifnot(is.reactive(cache))

  moduleServer(
    id = id,
    module = function(input, output, session) {
      ns <- session$ns
      rv <- reactiveValues(generating = FALSE, future = NULL, file_path = NULL)

      adminlevel_1 <- reactive({
        req(cache(), cache()$adjusted_data)
        cache()$adjusted_data %>%
          distinct(adminlevel_1) %>%
          arrange(adminlevel_1) %>%
          pull(adminlevel_1)
      })

      observeEvent(input$download, {
        req(cache())

        if (!cache()$check_coverage_params || !cache()$check_mortality_params ||
            !cache()$check_sector_params) {
          # Show an error dialog if data is not available
          showModal(
            modalDialog(
              title = i18n$t('msg_error'),
              i18n$t('error_download_report_no_data'),
              easyClose = TRUE,
              footer = modalButton(i18n$t('btn_ok'))
            )
          )
        } else {
          ns <- NS(id)
          showModal(
            modalDialog(
              title = i18n$t('title_download_options'),
              selectizeInput(
                ns('type'), i18n$t('title_report_type'),
                choices = set_names(c('synthesis_report', 'admin_level_1_one_pager'),
                                    c(i18n$t('opt_synthesis_report'), i18n$t('opt_admin_level_one_pager')))
              ),

              conditionalPanel(
                condition = sprintf("input['%s'] == 'admin_level_1_one_pager'", ns('type')),
                selectizeInput(
                  inputId = ns('adminlevel_1'),
                  label = i18n$t('opt_admin_level_1'),
                  choices = adminlevel_1()
                )
              ),

              footer = tagList(
                modalButton(i18n$t('btn_cancel')),
                reportButtonUI(ns('report'), label = i18n$t('btn_generate_report'))
              )
            )
          )
        }
      })

      report_name <- reactive({
        req(input$type)
        if (input$type == 'synthesis_report') {
          lang <- switch(
            cache()$language,
            en = '',
            fr = '_fr',
            pt = '_pt'
          )
          paste0(input$type, lang)
        } else {
          input$type
        }
      })

      admin_level <- reactive({
        req(input$type)
        if (input$type == 'synthesis_report') {
          NULL
        } else {
          input$adminlevel_1
        }
      })

      reportButtonServer('report', cache, report_name, i18n, admin_level)
    }
  )
}
