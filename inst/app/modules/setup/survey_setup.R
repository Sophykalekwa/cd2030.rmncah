surveySetupUI <- function(id, i18n) {
  ns <- NS(id)
  box(
    title = i18n$t("title_survey_setup"),
    status = 'primary',
    solidHeader = TRUE,
    width = 12,
    fluidRow(
      column(3, numericInput(ns('anc4_prop'), i18n$t("title_anc4_survey"),
                             min = 0, max = 100, value = NA, step = 1)),
      column(3, numericInput(ns('ideliv_prop'), i18n$t("title_ideliv_survey"),
                             min = 0, max = 100, value = NA, step = 1)),
      column(3, numericInput(ns('lbw_prop'), i18n$t("title_lbw_survey"),
                             min = 0, max = 100, value = NA, step = 1)),
      column(3, numericInput(ns('csection_prop'), i18n$t("title_csection_survey"),
                             min = 0, max = 100, value = NA, step = 1))
    ),
    fluidRow(
      column(3, numericInput(ns('penta3_prop'), i18n$t("title_penta3_survey"),
                             min = 0, max = 100, value = NA, step = 1)),
      column(3, numericInput(ns('measles1_prop'), i18n$t("title_measles1_survey"),
                             min = 0, max = 100, value = NA, step = 1)),
      column(3, numericInput(ns('bcg_prop'), i18n$t("title_bcg_survey"),
                             min = 0, max = 100, value = NA, step = 1))
    ),
    fluidRow(
      column(3, numericInput(ns('survey_year'), i18n$t("title_survey_year"),
                             min = 2015, max = 2030, value = NA, step = 1)),
      column(3, uiOutput(ns('survey_start_ui')))
    )
  )
}

surveySetupServer <- function(id, cache, i18n) {
  stopifnot(is.reactive(cache))

  moduleServer(
    id = id,
    module = function(input, output, session) {
      ns <- session$ns

      observe({
        req(cache())
        estimates <- cache()$survey_estimates

        if (is.na(cache()$survey_source) || cache()$survey_source == 'ratios') {
          updateNumericInput(session, 'penta3_prop', value = unname(estimates['penta3']))
        }
        updateNumericInput(session, 'measles1_prop', value = unname(estimates['measles1']))
        updateNumericInput(session, 'bcg_prop', value = unname(estimates['bcg']))
        updateNumericInput(session, 'anc4_prop', value = unname(estimates['anc4']))
        updateNumericInput(session, 'ideliv_prop', value = unname(estimates['ideliv']))
        updateNumericInput(session, 'lbw_prop', value = unname(estimates['lbw']))
        updateNumericInput(session, 'csection_prop', value = unname(estimates['csection']))
      })

      observeEvent(c(input$penta3_prop, input$measles1_prop, input$bcg_prop, input$anc4_prop,
                     input$ideliv_prop, input$lbw_prop, input$csection_prop), {
        req(cache())

        estimates <- cache()$survey_estimates
        new_estimates <- c(
          anc1 = unname(estimates['anc1']),
          penta1 = unname(estimates['penta1']),
          penta3 = as.numeric(input$penta3_prop),
          measles1 = as.numeric(input$measles1_prop),
          bcg = as.numeric(input$bcg_prop),
          anc4 = as.numeric(input$anc4_prop),
          ideliv = as.numeric(input$ideliv_prop),
          lbw = as.numeric(input$lbw_prop),
          csection = as.numeric(input$csection_prop)
        )

        cache()$set_survey_estimates(new_estimates)
        cache()$set_survey_source('setup')
      })

      observeEvent(input$survey_start_year, {
        req(cache(), input$survey_start_year)
        cache()$set_start_survey_year(as.numeric(input$survey_start_year))
      })

      observe({
        req(cache())
        survey_year <- cache()$survey_year
        updateNumericInput(session, 'survey_year', value = survey_year)
      })

      observeEvent(input$survey_year, {
        req(cache(), input$survey_year)
        cache()$set_survey_year(as.numeric(input$survey_year))
      })

      output$survey_start_ui <- renderUI({
        req(cache())
        years <- cache()$survey_years

        if (is.null(years) || length(years) == 0) return(NULL)

        selectizeInput(
          ns('survey_start_year'),
          label = i18n$t("title_survey_data_year"),
          choices = years,
          selected = cache()$start_survey_year
        )
      })
    }
  )
}
