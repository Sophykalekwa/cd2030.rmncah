% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.health_system.R
\name{plot.cd_health_system_comparison}
\alias{plot.cd_health_system_comparison}
\title{Compare District vs Admin 1 Health Metrics}
\usage{
\method{plot}{cd_health_system_comparison}(
  x,
  indicator = c("cov_instdeliveries_hstaff", "ratio_opd_u5_hstaff", "ratio_ipd_u5_hos",
    "ratio_ipd_u5_bed"),
  denominator = NULL
)
}
\arguments{
\item{x}{A data frame from \code{calculate_health_system_comparison()}.}

\item{indicator}{One of ratio_* or cov_instdeliveries_* (requires \code{denominator}).}

\item{denominator}{Optional for cov_ indicators. Must be one of 'dhis2', 'anc1', 'penta1'.}
}
\value{
A ggplot object.
}
\description{
Generates scatterplots with linear fit and identity line comparing district to admin 1 metrics or coverage vs density.
}
