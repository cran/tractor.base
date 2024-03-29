% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/10_mri_image.R
\name{asMriImage}
\alias{asMriImage}
\alias{extractMriImage}
\alias{trimMriImage}
\alias{reorderMriImage}
\title{Creating MriImage objects from data}
\usage{
asMriImage(data, templateImage = nilObject(), imageDims = NA,
  voxelDims = NA, voxelDimUnits = NA, origin = NA, tags = NA,
  reordered = NA)

extractMriImage(image, dim, loc)

trimMriImage(image, clearance = 4, indices = NULL)

reorderMriImage(image)
}
\arguments{
\item{data}{An array of pixel/voxel data.}

\item{templateImage}{An optional \code{MriImage} object, to be used as a
metadata template.}

\item{imageDims, voxelDims, voxelDimUnits, origin, tags, reordered}{Metadata for
the new image object. These values override any from the metadata object
or data array. See \code{\linkS4class{MriImage}} class documentation for
details.}

\item{image}{An \code{MriImage} object.}

\item{dim, loc}{The dimension and location along that dimension for which
data should be extracted.}

\item{clearance}{The number of voxels' clearance left around a trimmed
image.}

\item{indices}{A list of indices to keep along each dimension. Determined
from the specified \code{clearance} if \code{NULL}.}
}
\value{
An \code{MriImage} object.
}
\description{
Functions for creating MriImage objects from data, including other images.
All of these functions use data from arrays or \code{MriImage} objects to
create a new \code{MriImage} object. \code{asMriImage} is the basic fucntion
for creating an object from its constituents: an array of voxel values and
some metadata (and/or a template image).
}
\details{
\code{extractMriImage} reduces the dimensionality of the source image by
one, by extracting a single ``slice'' of data along one dimension.
\code{trimMriImage} trims empty space from the edges of an image, reducing
the dimensions of the image and thus avoiding the storage of lots of zeroes.
\code{reorderMriImage} reorders the image data (and corresponding metadata)
to the LAS convention, an operation which is usually performed when an
image is read from file.
}
\references{
Please cite the following reference when using TractoR in your
work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
}
\seealso{
\code{\linkS4class{MriImage}}
}
\author{
Jon Clayden
}
