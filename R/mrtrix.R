readMrtrix <- function (fileNames)
{
    if (!is.list(fileNames))
        fileNames <- identifyImageFileNames(fileNames)
    if (!file.exists(fileNames$headerFile))
        report(OL$Error, "File #{fileNames$headerFile} not found")
    
    # The gzfile function can handle uncompressed files too
    connection <- gzfile(fileNames$headerFile, "rb")
    on.exit(close(connection))
    
    # Find the end of the header
    match <- ore.search("\nEND\n", connection)
    assert(!is.null(match), "File #{fileNames$headerFile} does not seem to contain a well-formed MRtrix header")
    endOffset <- match$byteOffsets
    
    # Rewind the connection and check for a magic number
    seek(connection, 0)
    magic <- rawToChar(stripNul(readBin(connection, "raw", n=12)))
    assert(magic == "mrtrix image", "File #{fileNames$headerFile} does not appear to be a valid MRtrix image")
    
    fields <- rawToChar(stripNul(readBin(connection, "raw", n=endOffset-11)))
    match <- ore.search("^\\s*(\\w+): (.+)\\s*$", fields, all=TRUE)
    fields <- structure(as.list(match[,2]), names=match[,1])
    mergedFields <- list()
    for (fieldName in unique(names(fields)))
        mergedFields[[fieldName]] <- unlist(fields[names(fields) == fieldName], use.names=FALSE)
    
    pad <- function (x, minLength = 3L, value = 1)
    {
        length <- length(x)
        if (length >= minLength)
            return (x)
        else
            return (c(x, rep(value, minLength-length)))
    }
    
    # Extract and remove the specified field, splitting up elements
    getField <- function (name, split = "\\s*,\\s*", required = TRUE)
    {
        value <- mergedFields[[name]]
        if (required && is.null(value))
            report(OL$Error, "Required MRtrix header field \"#{name}\" is missing")
        else if (!is.null(value) && !is.null(split))
            value <- unlist(ore.split(split, value))
        mergedFields[[name]] <<- NULL
        return (value)
    }
    
    dims <- as.integer(getField("dim"))
    voxelDims <- as.numeric(getField("vox"))
    voxelDims[!is.finite(voxelDims)] <- 0
    
    layoutMatch <- ore.search("^(\\+|-)(\\d)$", getField("layout"), simplify=FALSE)
    signs <- ifelse(layoutMatch[,,1] == "+", 1, -1)
    axes <- as.integer(layoutMatch[,,2]) + 1L
    blockOrder <- (length(axes) <= 3 || all(which(axes > 3) > 3))
    
    # Find the inverse axis permutation and create an orientation string matching the data layout
    perm <- match(seq_along(axes), axes)
    spacePerm <- perm[perm <= 3]
    orientation <- implode(c("I","P","L","","R","A","S")[pad(signs[spacePerm]*spacePerm,3L,3L)[1:3]+4], sep="")
    
    # MRtrix stores the transform relative to the basic layout, and without
    # scaling for voxel dimensions, so we have to restore the scale factors and
    # convert from effective RAS to the actual orientation
    xform <- diag(c(pad(abs(voxelDims),3)[1:3], 1))
    if (!is.null(mergedFields$transform))
    {
        mrtrixTransform <- rbind(matrix(as.numeric(getField("transform")), nrow=3, ncol=4, byrow=TRUE), c(0,0,0,1))
        xform <- structure(mrtrixTransform %*% xform, imagedim=dims)
    }
    orientation(xform) <- orientation
    
    datatypeString <- as.character(getField("datatype"))
    assert(datatypeString != "Bit", "Bit datatype is not supported")
    
    datatypeMatch <- ore.search("^(C)?(U?Int|Float)(8|16|32|64)(LE|BE)?$", datatypeString)
    if (datatypeMatch[,2] == "Float")
        datatype <- tolower(es("#{datatypeMatch[,1]}#{ifelse(datatypeMatch[,3]=='32','float','double')}"))
    else
        datatype <- tolower(es("#{datatypeMatch[,2]}#{datatypeMatch[,3]}"))
    endianString <- ifelse(is.na(datatypeMatch[,4]), "", datatypeMatch[,4])
    endian <- switch(endianString, LE="little", BE="big", .Platform$endian)
    
    fileMatch <- ore.search("^\\s*(\\S+) (\\d+)\\s*$", getField("file"))
    
    scaling <- as.numeric(getField("scaling", required=FALSE))
    if (length(scaling) == 0)
        scaling <- c(0, 1)
    
    # Create a default header
    header <- niftiHeader()
    
    nDims <- length(dims)
    header$dim[seq_len(nDims+1)] <- c(nDims, dims[perm])
    qform(header) <- structure(xform, code=2L)
    header$pixdim[seq_len(nDims)+1] <- voxelDims[perm]
    
    # Set the intercept and slope values
    header$scl_inter <- scaling[1]
    header$scl_slope <- scaling[2]
    
    # MRtrix spatial units are always millimetres; temporal units are unclear
    header$xyzt_units <- 2L
    
    # Extract a diffusion gradient scheme into standard tags, if available
    tags <- NULL
    scheme <- getField("dw_scheme", required=FALSE)
    if (!is.null(scheme))
    {
        # Again, the diffusion directions are relative to real-world RAS space, so permute and flip as needed
        scheme <- matrix(as.numeric(scheme), ncol=4, byrow=TRUE)
        bVectors <- scheme[,pad(perm,3L,3L)[1:3],drop=FALSE]
        flip <- which(signs < 0)
        if (any(flip <= 3))
            bVectors[,flip] <- -bVectors[,flip]
        tags <- list(bVectors=bVectors, bValues=scheme[,4])
    }
    
    # Change case of history field, as it's now a standard tag
    history <- getField("command_history", required=FALSE)
    if (!is.null(history))
        tags <- c(tags, list(commandHistory=history))
    
    # Fields are removed as they are used; remaining ones become tags
    tags <- c(tags, mergedFields)
    
    storage <- list(offset=as.integer(fileMatch[,2]), datatype=datatype, endian=endian, blockOrder=blockOrder)
    invisible (list(image=NULL, header=header, storage=storage, tags=tags))
}
