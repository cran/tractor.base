% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/misc.R
\name{implode}
\alias{implode}
\title{Create a character string by concatenating the elements of a vector}
\usage{
implode(strings, sep = "", finalSep = NULL, ranges = FALSE)
}
\arguments{
\item{strings}{A vector, which will be coerced to mode \code{character}.}

\item{sep}{A unit length character vector giving the separator to insert
between elements.}

\item{finalSep}{An optional unit length character vector giving the
separator to insert between the final two elements.}

\item{ranges}{Logical value. If \code{TRUE} and \code{strings} can be
interpreted as integers, collapse runs of consecutive numbers into range
notation.}
}
\value{
A character vector of length one.
}
\description{
Create a character string by concatenating the elements of a vector, using a
separator and optional final separator.
}
\examples{
implode(1:3, ", ")  # "1, 2, 3"
implode(1:3, ", ", " and ")  # "1, 2 and 3"
implode(1:2, ", ", " and ")  # "1 and 2"
implode(1:3, ", ", ranges=TRUE)  # "1-3"

}
\references{
Please cite the following reference when using TractoR in your
work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
}
\seealso{
\code{\link{paste}}
}
\author{
Jon Clayden
}
