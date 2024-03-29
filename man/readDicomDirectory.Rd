% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dicom_dir.R
\name{readDicomDirectory}
\alias{readDicomDirectory}
\title{Read a directory of DICOM files}
\usage{
readDicomDirectory(dicomDir, method = c("internal", "divest"),
  readDiffusionParams = FALSE, untileMosaics = TRUE, ...)
}
\arguments{
\item{dicomDir}{Character vector of length one giving the name of a
directory containing DICOM files.}

\item{method}{Character string specifying whether to use the internal DICOM
reading code or use the \code{divest} package.}

\item{readDiffusionParams}{Logical value. Should diffusion MRI parameters
(b-values and gradient directions) be retrieved from the files if
possible?}

\item{untileMosaics}{Logical value. Should Siemens mosaic images be
converted into 3D volumes? This may occasionally be performed in error,
which can be prevented by setting this value to \code{FALSE}.}

\item{...}{Additional arguments to \code{readDicom}, if the \code{divest}
method is used.}
}
\value{
A list containing elements
  \describe{
    \item{image}{An \code{\linkS4class{MriImage}} object.}
    \item{bValues}{Diffusion b-values, if requested. Will be \code{NA} if
      the information could not be found in files.}
    \item{bVectors}{Diffusion gradient vectors, if requested. Will be
      \code{NA} if the information could not be found in the files.}
  }
}
\description{
This function scans a directory for files in DICOM format, and converts them
to a single Analyze/NIfTI-format image of the appropriate dimensionality.
}
\references{
Please cite the following reference when using TractoR in your
work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
}
\seealso{
\code{\linkS4class{DicomMetadata}}, \code{\linkS4class{MriImage}},
\code{\link{sortDicomDirectories}}.
}
\author{
Jon Clayden
}
