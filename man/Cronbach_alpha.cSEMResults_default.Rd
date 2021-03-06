% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/000_new.R
\name{Cronbach_alpha.cSEMResults_default}
\alias{Cronbach_alpha.cSEMResults_default}
\title{Cronbach_alpha}
\usage{
Cronbach_alpha(
 .object              = args_default()$.object,
 .only_common_factors = args_default()$.only_common_factors
)
}
\arguments{
\item{.object}{An R object of class \code{cSEM<class>} with corresponding method.}

\item{.only_common_factors}{Logical. Should only common factors be included?
Defaults to \code{FALSE}.}
}
\description{
Computes Cronbach's alpha \insertCite{Cronbach1951}{cSEM} based on the correlation matrix
}
\examples{
\dontrun{
# still to implement
}

}
\references{
\insertAllCited{}
}
\seealso{
\link{csem}, \link{cSEMResults}
}
