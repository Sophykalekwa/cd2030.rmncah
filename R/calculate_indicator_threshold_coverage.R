#' Calculate Threshold Coverage for Health Indicators
#'
#' This function calculates the percentage of districts where coverage for specific health
#' indicators falls below a 10% threshold, for each year. The function generates a binary
#' variable for each indicator, denoting whether it is below 10%, and then calculates the
#' average percentage of below-threshold coverage for each indicator.
#'
#' @param .data A data frame or tibble containing health indicator coverage data with columns
#'   named in the format `cov_<indicator>_<source>`, where `<indicator>` is one of
#'   "zerodose", "undervax", "dropout_penta13", "dropout_measles12", "dropout_penta3mcv1",
#'   or "dropout_penta1mcv1", and `<source>` is one of "dhis2", "penta1", or "anc1".
#'
#' @return A tibble with the yearly average percentage of below-threshold coverage
#'   for each indicator-source combination, where each value represents the percentage of
#'   districts with below 10% coverage for that indicator and source.
#'
#' @details
#' The function performs the following steps:
#' 1. **Generate Binary Below-Threshold Variables**: For each indicator-source combination,
#'    it generates a binary variable indicating if coverage is below 10% (1 if below 10% and
#'    0 otherwise).
#' 2. **Rename Columns**: The generated columns are renamed by removing the `cov_` prefix.
#' 3. **Summarize**: The function then calculates the mean of each below-threshold indicator
#'    across all districts, grouped by `year`, resulting in the percentage of districts
#'    below 10% for each indicator-source.
#' 4. **Round to Percentage**: The percentages are then multiplied by 100 and rounded to one decimal place.
#'    Any missing values are set to 0%.
#'
#' @examples
#' \dontrun{
#' # Assuming `data` is a data frame with required columns:
#' result <- calculate_indicator_threshold_coverage(data)
#' result
#' }
#'
#' @export
calculate_indicator_threshold_coverage <- function(.data) {
  year <- NULL

  check_cd_indicator_coverage(.data)

  # Step 1: Generate Below 10% Indicator Variables for Each Coverage Metric
  coverage_vars <- c("zerodose", "undervax", "dropout_penta13", "dropout_measles12", "dropout_penta3mcv1", "dropout_penta1mcv1")
  indicators <- c("dhis2", "penta1", "anc1")

  .data %>%
    mutate(
      across(
        all_of(c(outer(paste0("cov_", coverage_vars), indicators, paste, sep = "_"))),
        ~ if_else(!is.na(.) & . < 10, 1, 0),
        .names = "below10_{.col}"
      )
    ) %>%
    rename_with(~ gsub("cov_", "", .x), starts_with("below10_")) %>%
    summarise(
      across(starts_with("below10_"), mean, na.rm = TRUE),
      .by = year
    ) %>%
    mutate(
      across(starts_with("below10_"), ~ if_else(is.na(.x), 0, round(.x * 100, 1)))
    )
}

#' Calculate Dropout Coverage for Health Indicators Below a Threshold
#'
#' This function filters health indicator data to identify the percentage of administrative
#' regions where the coverage for a specified indicator falls below a 10% threshold for a given year.
#' If no regions meet the criteria (i.e., all values are below the threshold), a default output is returned.
#'
#' @param .data A tibble of class `cd_data`.
#' @param survey_year Integer. The year of Penta-1 survey provided
#' @param admin_level The level of analysis.
#' @param indicator Character. The specific health indicator to evaluate. Options are:
#'   - `"coverage"`:coverage indicators.
#'   - `"dropout"`: dropout indicators.
#' @param sbr Numeric. The stillbirth rate. Default is `0.02`.
#' @param nmr Numeric. Neonatal mortality rate. Default is `0.025`.
#' @param pnmr Numeric. Post-neonatal mortality rate. Default is `0.024`.
#' @param anc1survey Numeric. Survey-derived coverage rate for ANC-1 (antenatal care, first visit). Default is `0.98`.
#' @param dpt1survey Numeric. Survey-derived coverage rate for Penta-1 (DPT1 vaccination). Default is `0.97`.
#' @param survey_year Integer. The year of Penta-1 survey provided
#' @param preg_loss Numeric. Pregnancy loss rate
#' @param twin Numeric. Twin birth rate. Default is `0.015`.
#'
#' @return A tibble with the selected administrative level and coverage value for regions
#'   that do not meet the below-10% threshold for the specified indicator and year. If no regions
#'   meet the criteria, a default row is returned with "None" and 0 as values.
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' result <- calculate_threshold(data, filter_year = 2023, indicator = "zerodose", source = "dhis2")
#' result
#' }
#'
#' @export
calculate_threshold <- function(.data,
                                admin_level = c("adminlevel_1", "district"),
                                indicator = c("maternal", "vaccine"),
                                sbr = 0.02,
                                nmr = 0.025,
                                pnmr = 0.024,
                                anc1survey = 0.98,
                                dpt1survey = 0.97,
                                survey_year = 2019,
                                twin = 0.015,
                                preg_loss = 0.03) {
  check_cd_data(.data)
  indicator <- arg_match(indicator)
  admin_level <- arg_match(admin_level)
  admin_level_cols <- get_admin_columns(admin_level)

  indicators <- if (indicator == "vaccine") {
    "penta3|mealses1|bcg"
  } else {
    "anc4|instdeliveries"
  }

  threshold <- calculate_indicator_coverage(.data,
    admin_level = admin_level,
    sbr = sbr, nmr = nmr, pnmr = pnmr,
    anc1survey = anc1survey, dpt1survey = dpt1survey,
    survey_year = survey_year, twin = twin, preg_loss = preg_loss
  ) %>%
    select(year, any_of(admin_level_cols), matches(paste0("cov_(", indicators, ")"))) %>%
    mutate(across(starts_with("cov_"), ~ if_else(.x > 90, 1, 0), .names = "below10_{.col}")) %>%
    summarise(across(starts_with("below10"), ~ mean(., na.rm = TRUE)) * 100, .by = year) %>%
    pivot_longer(
      cols = starts_with("below10"),
      names_prefix = "below10_cov_",
      names_sep = "_(?=[^_]+$)",
      names_to = c("indicator", "denominator")
    )

  new_tibble(
    threshold,
    class = "cd_threshold",
    admin_level = admin_level,
    indicator = indicator
  )
}
