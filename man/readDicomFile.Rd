% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/15_dicom.R
\name{readDicomFile}
\alias{readDicomFile}
\title{Read a DICOM file into a DicomMetadata object}
\usage{
readDicomFile(fileName, checkFormat = TRUE, stopTag = NULL,
  ignoreTransferSyntax = FALSE, ascii = TRUE)
}
\arguments{
\item{fileName}{The name of a DICOM file.}

\item{checkFormat}{If \code{TRUE}, the function will check for the magic
string \code{"DICM"} at byte offset 128. This string should be present,
but in reality not all files contain it.}

\item{stopTag}{An integer vector giving the group and element numbers (in
that order) of a DICOM tag, or \code{NULL}. If not \code{NULL}, the
function will stop parsing the DICOM file if the specified tag is
encountered. This can be used to speed up the process if a specific tag is
required.}

\item{ignoreTransferSyntax}{If \code{TRUE}, any transfer syntax stored in
the file will be ignored, and the code will try to deduce the transfer
syntax using heuristics. This may occasionally be necessary for awkward
DICOM files, but is not generally recommended.}

\item{ascii}{If \code{TRUE}, the function will attempt to read an embedded
Siemens ASCII header, if one exists.}
}
\value{
\code{readDicomFile} returns a \code{\linkS4class{DicomMetadata}}
  object, or \code{NULL} on failure.
}
\description{
This function reads a DICOM file into a \code{\link{DicomMetadata}} object.
Only DICOM files from magnetic resonance scanners are supported.
}
\references{
Please cite the following reference when using TractoR in your
work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
}
\seealso{
The DICOM standard, found online at
  \url{https://www.dicomstandard.org/}. (Warning: may produce headaches!)
  Also \code{\link{readDicomDirectory}} for information on how to create
  \code{\linkS4class{MriImage}} objects from DICOM files.
}
\author{
Jon Clayden
}
