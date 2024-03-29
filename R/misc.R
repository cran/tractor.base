#' Create a character string by concatenating the elements of a vector
#' 
#' Create a character string by concatenating the elements of a vector, using a
#' separator and optional final separator.
#' 
#' @param strings A vector, which will be coerced to mode \code{character}.
#' @param sep A unit length character vector giving the separator to insert
#'   between elements.
#' @param finalSep An optional unit length character vector giving the
#'   separator to insert between the final two elements.
#' @param ranges Logical value. If \code{TRUE} and \code{strings} can be
#'   interpreted as integers, collapse runs of consecutive numbers into range
#'   notation.
#' @return A character vector of length one.
#' @author Jon Clayden
#' @seealso \code{\link{paste}}
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @examples
#' implode(1:3, ", ")  # "1, 2, 3"
#' implode(1:3, ", ", " and ")  # "1, 2 and 3"
#' implode(1:2, ", ", " and ")  # "1 and 2"
#' implode(1:3, ", ", ranges=TRUE)  # "1-3"
#' 
#' @export
implode <- function (strings, sep = "", finalSep = NULL, ranges = FALSE)
{
    # Transform runs of integers into ranges
    # This is surprisingly tricky to get right!
    if (ranges && is.integer(strings) && length(strings) > 1)
    {
        # Perform run-length encoding on the differences between elements
        gapRunLengths <- rle(diff(strings))
        
        # Mark all elements not taken and find ranges (>1 consecutive unit difference)
        taken <- rep(FALSE, length(strings))
        withinRange <- gapRunLengths$values == 1 & gapRunLengths$lengths > 1
        
        # Convert range groups into strings, marking elements as taken to avoid double-counting
        rangeStrings <- lapply(which(withinRange), function(i) {
            # NB: Sum of a length-zero vector is zero
            start <- sum(gapRunLengths$lengths[seq_len(i-1)]) + 1
            end <- start + gapRunLengths$lengths[i]
            taken[start:end] <<- TRUE
            return (paste(strings[start], strings[end], sep="-"))
        })
        
        # Convert remaining elements into strings
        nonRangeStrings <- lapply(which(!withinRange), function(i) {
            start <- sum(gapRunLengths$lengths[seq_len(i-1)]) + 1
            end <- start + gapRunLengths$lengths[i]
            toKeep <- setdiff(start:end, which(taken))
            taken[toKeep] <<- TRUE
            return (as.character(strings)[toKeep])
        })
        
        # Arrange list of strings in the right order, and convert back to character vector
        strings <- vector("list", length(withinRange))
        strings[withinRange] <- rangeStrings
        strings[!withinRange] <- nonRangeStrings
        strings <- unlist(strings)
    }
    else
        strings <- as.character(strings)
    
    if (length(strings) == 1)
        return (strings[1])
    else if (length(strings) > 1)
    {
        result <- strings[1]
        for (i in 2:length(strings))
        {
            if (i == length(strings) && !is.null(finalSep))
                result <- paste(result, strings[i], sep=finalSep)
            else
                result <- paste(result, strings[i], sep=sep)
        }
        return (result)
    }
    else
        return ("")
}

#' Number agreement with a vector
#' 
#' This function chooses the singular or plural form of a word based on the
#' length of an associated vector, or an integer.
#' 
#' @param singular The singular form of the word.
#' @param x A vector of any mode, whose length is used to choose the correct
#'   word form, unless \code{n} is specified.
#' @param n An integer which is used to choose the correct word form (singular
#'   if n = 1, plural otherwise). Take priority over \code{x} if not
#'   \code{NULL}.
#' @param plural The plural form of the word. If \code{NULL}, an 's' is simply
#'   appended to the singular form.
#' @return Either \code{singular} or \code{plural}, as appropriate.
#' 
#' @author Jon Clayden
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
pluralise <- function (singular, x = NULL, n = NULL, plural = NULL)
{
    if (is.null(x) && is.null(n))
        report(OL$Error, "Either \"x\" or \"n\" must be given")
    else if (is.null(n))
        n <- length(x)
    
    if (is.null(plural))
        plural <- paste0(singular, "s")
    
    return (ifelse(n==1L, singular, plural))
}

#' Combine similar strings into one
#' 
#' Merge a vector of strings with a common prefix and/or suffix into one string
#' with the unique parts in braces, comma-separated.
#' 
#' @param strings A vector, which will be coerced to mode \code{character}.
#' @return A single merged string, with the common prefix and suffix as
#'   attributes.
#' 
#' @author Jon Clayden
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @examples
#' embrace(c("image.hdr", "image.img"))
#' 
#' @export
embrace <- function (strings)
{
    strings <- as.character(strings)
    
    if (length(strings) < 1)
        return (structure("", prefix="", suffix=""))
    else if (length(strings) < 2)
        return (structure(strings, prefix="", suffix=""))
    
    codepoints <- lapply(enc2utf8(strings), utf8ToInt)
    lengths <- sapply(codepoints, length)
    sharedLength <- min(lengths)
    if (sharedLength == 0)
        return (structure(paste0("{",implode(strings,","),"}"), prefix="", suffix=""))
    else
    {
        forwardCodepoints <- sapply(codepoints, function(x) x[seq_len(sharedLength)], simplify="array")
        forwardMatches <- apply(forwardCodepoints, 1, allEqual)
        prefixLength <- ifelse(all(forwardMatches), sharedLength, which(!forwardMatches)[1] - 1L)
        
        reverseCodepoints <- sapply(codepoints, function(x) rev(x)[seq_len(sharedLength)], simplify="array")
        reverseMatches <- apply(reverseCodepoints, 1, allEqual)
        suffixLength <- ifelse(all(reverseMatches), sharedLength, which(!reverseMatches)[1] - 1L)
        
        prefix <- intToUtf8(codepoints[[1]][seq_len(prefixLength)])
        suffix <- intToUtf8(rev(rev(codepoints[[1]])[seq_len(suffixLength)]))
        uniqueParts <- sapply(seq_along(codepoints), function(i) {
            indices <- setdiff(seq_len(lengths[i]), c(seq_len(prefixLength), seq_len(suffixLength)+lengths[i]-suffixLength))
            intToUtf8(codepoints[[i]][indices])
        })
        return (structure(es("#{prefix}{#{implode(uniqueParts,',')}}#{suffix}"), prefix=prefix, suffix=suffix))
    }
}

#' Pretty print labelled information
#' 
#' This is a simple function to print a series of labels and associated data
#' values, or key-value pairs.
#' 
#' @param labels A character vector of labels.
#' @param values A character vector of values. Must have the same length as
#'   \code{labels}.
#' @param outputLevel The output level to print the output to. See
#'   \code{setOutputLevel}, in the reportr package.
#' @param leftJustify Logical value: if \code{TRUE} the labels will be left
#'   justified; otherwise they will be right justified.
#' @return This function is called for its side effect.
#' @author Jon Clayden
#' @seealso \code{\link{setOutputLevel}} for the reportr output level system.
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
printLabelledValues <- function (labels, values, outputLevel = OL$Info, leftJustify = FALSE)
{
    if (length(labels) != length(values))
        report(OL$Error, "Labels and values should be of the same length")
    
    labelLengths <- nchar(labels)
    maxLabelLength <- max(labelLengths)
    nValues <- length(values)
    
    for (i in seq_len(nValues))
    {
        if (leftJustify)
            report(outputLevel, "  ", labels[i], implode(rep(" ",maxLabelLength-labelLengths[i]),sep=""), " : ", values[i], prefixFormat="")
        else
            report(outputLevel, implode(rep(" ",maxLabelLength-labelLengths[i]),sep=""), labels[i], " : ", values[i], prefixFormat="")
    }
    
    invisible(NULL)
}

#' Concatenate and deduplicate vectors
#' 
#' This function returns its arguments, after concatenating them using \code{c}
#' and then removing elements with duplicate names. The first element with each
#' name will remain, possibly with subsequent elements' content appended to it.
#' Unnamed elements are retained.
#' 
#' @param ... One or more vectors of any mode, usually named.
#' @param merge If \code{FALSE}, the default, duplicate elements will simply
#'   be discarded. If \code{TRUE}, additional elements with the same name will
#'   be appended to the retained one. This does not apply to unnamed elements.
#'   If this kind of deduplication actually happens, the return value will be a
#'   list, regardless of the source type.
#' @return The concatenated and deduplicated vector.
#' @author Jon Clayden
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
deduplicate <- function (..., merge = FALSE)
{
    x <- c(...)
    n <- names(x)
    if (!is.null(n))
    {
        isDup <- (n != "" & duplicated(n))
        if (merge && any(isDup))
        {
            x <- as.list(x)
            # For each duplicated name, replace the first matching element with a concatenated vector
            for (dup in unique(n[isDup]))
                x[[dup]] <- do.call("c", c(x[names(x) == dup], list(use.names=FALSE)))
        }
        x <- x[!isDup]
    }
    return (x)
}

#' Extract one or more elements from a list
#' 
#' Given a list-like first argument, this function extracts one or more of its
#' elements. Numeric and character indexing are allowed.
#' 
#' @param list A list-like object, with a \code{[[} indexing method.
#' @param index A vector of integers or strings, or \code{NULL}.
#' @return If \code{index} is \code{NULL}, the whole list is returned.
#'   Otherwise, if \code{index} has length one, the corresponding element is
#'   extracted and returned. Otherwise a list containing the requested subset
#'   is returned.
#' 
#' @note This function is not type-safe, in the sense that its return type
#'   depends on its arguments. It should therefore be used with care.
#' @author Jon Clayden
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
indexList <- function (list, index = NULL)
{
    if (is.null(index))
        return (list)
    else if (length(index) == 1)
        return (list[[index]])
    else
        return (list[index])
}

#' Functions for file name and path manipulation
#' 
#' Functions for expanding file paths, finding relative paths and ensuring that
#' a file name has the required suffix.
#' 
#' The \code{resolvePath} function passes its arguments elementwise through any
#' matching path handler, and returns the resolved paths. Nonmatching elements
#' are returned as-is. \code{registerPathHandler} registers a new path handler
#' for special syntaxes, and is for advanced use only. \code{relativePath}
#' returns the specified \code{path}, expressed relative to
#' \code{referencePath}. \code{matchPaths} resolves a vector of paths against a
#' vector of reference paths. \code{expandFileName} returns the full path to
#' the specified file name, collapsing \code{".."} elements if appropriate.
#' \code{ensureFileSuffix} returns the specified file names with the requested
#' suffixes appended (if they are not already).
#' 
#' @param path,referencePath Character vectors whose elements represent file
#'   paths (which may or may not currently exist).
#' @param \dots Additional arguments to custom path handlers.
#' @param regex A Ruby-style regular expression.
#' @param handler A function taking and returning a string.
#' @param fileName A character vector of file names.
#' @param base If \code{fileName} is a relative path, this option gives the
#'   base directory which the path is relative to. If \code{fileName} is an
#'   absolute path, this argument is ignored.
#' @param suffix A character vector of file suffixes, which will be recycled if
#'   shorter than \code{fileName}.
#' @param strip A character vector of suffixes to remove before appending
#'   \code{suffix}. The intended suffix does not need to be given here, as the
#'   function will not append it if the specified file name already has the
#'   correct suffix.
#' @return A character vector.
#' 
#' @author Jon Clayden
#' @seealso \code{\link{normalizePath}} does most of the work for
#' \code{expandFileName}.
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @aliases paths
#' @rdname paths
#' @export
resolvePath <- function (path, ...)
{
    sapply(path, function(p) {
        for (i in seq_along(.Workspace$pathHandlers))
        {
            if (p %~% names(.Workspace$pathHandlers)[i])
            {
                result <- .Workspace$pathHandlers[[i]](p, ...)
                if (!is.null(result))
                {
                    report(OL$Debug, "Resolving #{p} to #{result}")
                    return (result)
                }
            }
        }
        return (p)
    })
}

#' @rdname paths
#' @export
relativePath <- function (path, referencePath)
{
    mainPieces <- ore.split(ore.escape(.Platform$file.sep), expandFileName(path))
    mainPieces <- mainPieces[mainPieces != "."]
    refPieces <- ore.split(ore.escape(.Platform$file.sep), expandFileName(referencePath))
    refPieces <- refPieces[refPieces != "."]
    refIsDir <- isTRUE(file.info(referencePath)$isdir)
    
    shorterLength <- min(length(mainPieces), length(refPieces))
    firstDifferentPiece <- min(which(mainPieces[1:shorterLength] != refPieces[1:shorterLength])[1], shorterLength+1, na.rm=TRUE)
    newPieces <- rep("..", max(0, length(refPieces)-firstDifferentPiece+as.integer(refIsDir)))
    if (length(mainPieces >= firstDifferentPiece))
        newPieces <- c(newPieces, mainPieces[firstDifferentPiece:length(mainPieces)])
    
    return (implode(newPieces, sep=.Platform$file.sep))
}

#' @rdname paths
#' @export
matchPaths <- function (path, referencePath)
{
    expandedPath <- expandFileName(path)
    expandedReferencePath <- expandFileName(referencePath)
    indices <- match(expandedPath, expandedReferencePath)
    result <- structure(referencePath[indices], indices=indices)
    return (result)
}

#' @rdname paths
#' @export
registerPathHandler <- function (regex, handler)
{
    if (!is.character(regex) || length(regex) != 1)
        report(OL$Error, "Regular expression should be specified as a character string")
    
    handler <- match.fun(handler)
    .Workspace$pathHandlers[[regex]] <- handler
    
    invisible(NULL)
}

#' @rdname paths
#' @export
expandFileName <- function (fileName, base = getwd())
{
    # Absolute paths are assumed to start with an optional drive letter and colon (for Windows), and then a slash or backslash
    # This covers C:\dir\file, \dir\file, \\server\dir\file, //server/dir/file and /dir/file, but not URLs
    # Cf. https://docs.microsoft.com/en-gb/windows/win32/fileio/naming-a-file#fully-qualified-vs-relative-paths
    fileName <- ifelse(fileName %~% "^([A-Za-z]:)?[/\\\\]|^~", fileName, file.path(base,fileName))
    return (normalizePath(fileName, .Platform$file.sep, FALSE))
}

#' @rdname paths
#' @export
ensureFileSuffix <- function (fileName, suffix, strip = NULL)
{
    if (is.null(strip))
        strip <- suffix %||% "\\w+"
    else
        strip <- c(strip, suffix)
    
    stripPattern <- paste("\\.(", implode(strip,sep="|"), ")$", sep="")
    fileStem <- sub(stripPattern, "", fileName, ignore.case=TRUE, perl=TRUE)
    
    if (is.null(suffix))
        return (fileStem)
    else if (length(suffix) == 0)
        return (character(0))
    else
    {
        fileName <- paste(fileStem, suffix, sep=".")
        return (fileName)
    }
}

#' @rdname execute
#' @export
locateExecutable <- function (fileName, errorIfMissing = TRUE)
{
    pathDirs <- unlist(strsplit(Sys.getenv("PATH"), .Platform$path.sep, fixed=TRUE))
    possibleLocations <- file.path(pathDirs, fileName)
    if (grepl(.Platform$file.sep, fileName, fixed=TRUE))
        possibleLocations <- fileName
    filesExist <- file.exists(possibleLocations)
    
    if (sum(filesExist) == 0)
    {
        if (errorIfMissing)
            report(OL$Error, "Required executable \"", fileName, "\" is not available on the system path")
        else
            return (NULL)
    }
    else
    {
        realLocations <- possibleLocations[filesExist]
        return (realLocations[1])
    }
}

#' Find or run an external executable file
#' 
#' The \code{execute} function is a wrapper around the \code{\link{system2}}
#' function in base, which additionally echoes the command being run (including
#' the full path to the executable) if the reportr output level is
#' \code{Debug}. \code{locateExecutable} simply returns the path to an
#' executable file on the system \code{PATH}.
#' 
#' @param executable,fileName Name of the executable to run.
#' @param params A character vector giving the parameters to pass to the
#'   executable, if any. Elements will be separated by a space.
#' @param errorOnFail,errorIfMissing Logical value: should an error be produced
#'   if the executable can't be found?
#' @param silent Logical value: should the executable be run without any
#'   output?
#' @param \dots Additional arguments to \code{\link{system}}.
#' @return For \code{execute}, the return value of the underlying call to
#'   \code{\link{system2}}. For \code{locateExecutable}, the location of the
#'   requested executable, or \code{NULL} if it could not be found.
#' 
#' @note These functions are designed for Unix systems and may not work on
#'   Windows.
#' @author Jon Clayden
#' @seealso \code{\link{system2}}
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
execute <- function (executable, params = NULL, errorOnFail = TRUE, silent = FALSE, ...)
{
    execLoc <- locateExecutable(executable, errorOnFail)
    if (!is.null(execLoc))
    {
        report(OL$Debug, "#{execLoc} #{implode(params,sep=' ')}")
        if (silent && getOutputLevel() > OL$Debug)
            system2(execLoc, as.character(params), stdout=FALSE, stderr=FALSE, ...)
        else
            system2(execLoc, as.character(params), ...)
    }
}

#' Promote a vector to a single-column or single-row matrix
#' 
#' The \code{promote} function promotes a vector argument to a single-column or
#' single-row matrix. Matrix arguments are returned unmodified.
#' 
#' @param x A vector or matrix.
#' @param byrow Logical value: if \code{TRUE}, a vector will be promoted to a
#'   single-row matrix; otherwise a single-column matrix will result.
#' @return A matrix version of the \code{x} argument.
#' @author Jon Clayden
#' @seealso \code{\link{matrix}}
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
promote <- function (x, byrow = FALSE)
{
    if (is.matrix(x))
        return (x)
    else if (byrow)
        return (matrix(x, nrow=1))
    else
        return (matrix(x, ncol=1))
}

#' Test two numeric vectors for equivalence
#' 
#' This function is a wrapper for \code{isTRUE(all.equal(x,y,\dots{}))}, but
#' with the additional capability of doing sign-insensitive comparison.
#' 
#' @param x The first numeric vector.
#' @param y The second numeric vector.
#' @param signMatters Logical value: if FALSE then equivalence in absolute
#'   value is sufficient.
#' @param \dots Additional arguments to \code{\link{all.equal}}, notably
#'   \code{tolerance}.
#' @return \code{TRUE} if all elements of \code{x} match all elements of
#'   \code{y} to within tolerance, ignoring signs if required. \code{FALSE}
#'   otherwise.
#' @author Jon Clayden
#' @seealso \code{\link{all.equal}}
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @examples
#' 
#' equivalent(c(-1,1), c(1,1))  # FALSE
#' equivalent(c(-1,1), c(1,1), signMatters=FALSE)  # TRUE
#' equivalent(1:2, 2:3, tolerance=2)  # TRUE
#' 
#' @export
equivalent <- function (x, y, signMatters = TRUE, ...)
{
    if (signMatters)
        return (isTRUE(all.equal(x, y, ...)))
    else
        return (isTRUE(all.equal(abs(x), abs(y), ...)))
}

#' Test whether all elements of a vector are equal
#' 
#' This function tests whether all elements of the specified vector are equal
#' to each other, i.e., whether the vector contains only a single unique value.
#' For lists, equality is determined using \code{\link{equivalent}}.
#' 
#' @param x A vector of any mode, including a list.
#' @param ignoreMissing If \code{TRUE}, missing elements will be ignored.
#'   Otherwise the presence of missing values will result in a return value of
#'   \code{FALSE}.
#' @param \dots Additional arguments to \code{all.equal}, via
#'   \code{\link{equivalent}}.
#' @return \code{TRUE} if all elements test equivalent; \code{FALSE}
#'   otherwise.
#' @author Jon Clayden
#' @seealso \code{\link{equivalent}} for elementwise equivalence of two
#'   vectors.
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @examples
#' 
#' allEqual(c(1,1,1))  # TRUE
#' allEqual(c(1,1,NA))  # FALSE
#' allEqual(c(1,1,NA), ignoreMissing=TRUE)  # TRUE
#' 
#' @export
allEqual <- function (x, ignoreMissing = FALSE, ...)
{
    if (ignoreMissing)
        x <- x[!is.na(x)]
    return (isTRUE(all(sapply(x, equivalent, x[[1]], ...))))
}

stripNul <- function (x, method = c("truncate","drop"))
{
    method <- match.arg(method)
    nul <- which(x == 0L)
    if (length(nul) == 0)
        return (x)
    else if (method == "truncate")
        return (x[seq_len(nul[1]-1)])
    else
        return (x[-nul])
}

#' Obtain thread-safe temporary file names
#' 
#' This function is a wrapper around \code{\link{tempfile}}, which creates
#' temporary file names whose path contains the process ID of the calling
#' process. This avoids clashes between threads created by functions such as
#' \code{mclapply} (in the ``parallel'' package), which can easily occur with
#' the standard \code{\link{tempfile}} function.
#' 
#' @param pattern Character vector giving the initial part of each file name.
#' @return A character vector of temporary file names. No files are actually
#'   created.
#' @author Jon Clayden
#' @seealso \code{\link{tempfile}}
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
threadSafeTempFile <- function (pattern = "file")
{
    tempDir <- file.path(tempdir(), paste("temp",Sys.getpid(),sep="_"))
    if (!file.exists(tempDir))
        dir.create(tempDir)
    return (tempfile(pattern=pattern, tmpdir=tempDir))
}

#' Compact conditional values
#' 
#' This simple function checks whether its first argument is a logical value
#' that evaluates to \code{TRUE}. If so, it returns its second argument. If
#' not, it returns its third argument.
#' 
#' This function differs from the standard \code{\link{ifelse}} function in
#' that it does not act elementwise, and that the third argument is optional,
#' defaulting to \code{NULL}.
#' 
#' @param condition An expression that resolves to a single logical value.
#' @param value,fallback Any expression.
#' @return \code{value}, if \code{condition} evaluates to \code{TRUE};
#'   otherwise \code{fallback}.
#' @author Jon Clayden
#' @seealso ifelse
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @export
where <- function (condition, value, fallback = NULL)
{
    conditionString <- deparse(substitute(condition))
    assert(is.logical(condition) && length(condition) == 1, "Condition \"#{conditionString}\" does not evaluate to a single logical value", level=OL$Warning)
    
    if (isTRUE(condition))
        return (value)
    else
        return (fallback)
}

#' Resolve a variable to a default when NULL
#' 
#' This is a very simple infix function for the common TractoR idiom whereby
#' \code{NULL} is used as a default argument value, but later needs to be
#' resolved to a meaningful value if not overridden in the call. It returns its
#' first argument unless it is \code{NULL}, in which case it falls back on the
#' second argument.
#' 
#' @param X,Y R objects, possibly \code{NULL}.
#' @return \code{X}, if it is not \code{NULL}; otherwise \code{Y}.
#' @author Jon Clayden
#' @seealso \code{\link{where}}, which resolves a value if an expression is
#'   \code{TRUE}. Several calls to that function can be conveniently chained
#'   together with this one.
#' @references Please cite the following reference when using TractoR in your
#' work:
#' 
#' J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A.
#' Clark (2011). TractoR: Magnetic resonance imaging and tractography with R.
#' Journal of Statistical Software 44(8):1-18. \doi{10.18637/jss.v044.i08}.
#' @name infix
#' @rawNamespace if (getRversion() < "4.4") export("%||%")
"%||%" <- function (X, Y)
{
    if (is.null(X)) Y else X
}
