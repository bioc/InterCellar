% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fct_multi_cond.R
\name{getSignif_table}
\alias{getSignif_table}
\title{Wrapper for other functions to get significant table of func terms}
\usage{
getSignif_table(
  data_cond1,
  data_cond2,
  data_cond3,
  lab_c1,
  lab_c2,
  lab_c3,
  annot_cond1,
  annot_cond2,
  annot_cond3
)
}
\arguments{
\item{data_cond1}{filt.data() corresponding to chosen condition 1}

\item{data_cond2}{filt.data() corresponding to chosen condition 2}

\item{data_cond3}{filt.data() corresponding to chosen condition 3}

\item{lab_c1}{data label for condition 1}

\item{lab_c2}{data label for condition 2}

\item{lab_c3}{data label for condition 3}

\item{annot_cond1}{binary matrix int-pair by functions for cond1}

\item{annot_cond2}{binary matrix int-pair by functions for cond2}

\item{annot_cond3}{binary matrix int-pair by functions for cond3}
}
\value{
list containing pvalue_df and unique_intpairs df
}
\description{
Wrapper for other functions to get significant table of func terms
}
