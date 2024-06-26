# Define class for data storage

#' @importClassesFrom Matrix Matrix
.onLoad <- function(libname, pkgname){

  methods::setOldClass("prcomp")
  methods::setClass(
    "raw.sims.data",
    methods::representation(
      data = "Matrix",
      index = "numeric",
      sample.id = "character",
      x.max = "numeric",
      z.max = "numeric",
      y.max = "numeric",
      pca = "prcomp"
    ),
    prototype = methods::prototype(pca = structure(list(), class = "prcomp"))
  )

}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("ToF-SIMS image analysis toolkit loaded")
}

#' Function to load and pre-process ToF-SIMS images in .txt format
#'
#' @return A raw.sims.data object
#' @export
open_raw_txt <- function() {
  files <- choose.files(caption = "Select .txt files for import")
  sample.id <- readline(prompt = "Enter sample id: ")

  # Extract data dimensions
  cat("Extracting data dimensions\n")
  maximums <- col.max(utils::read.table(files[1]))
  z.max <- as.numeric(maximums[3]) + 1
  x.max <- as.numeric(maximums[1]) + 1
  y.max <- as.numeric(maximums[2]) + 1
  number.data <- z.max * x.max * y.max * length(files)

  # Create index
  cat("Generating index\n")
  index <- vector(length = length(files))
  for (i in 1:length(files)) {
    mass = sub(pattern = "^.*- ", replacement = "", files[i])
    mass = as.numeric(substr(mass, 1, nchar(mass) - 6))
    index[i] = mass
  }

  # Read text files in parallel
  cat("Detecting cores\n")
  cores <- parallel::detectCores() - 2
  cat("Initialising cluster\n")
  cluster <- parallel::makeCluster(cores)
  doParallel::registerDoParallel(cluster)
  cat("Reading data into memory\n")
  data <-
    foreach::foreach(file.temp = files[1:length(files)],
            .combine = cbind,
            .export = "files") %dopar%
    (utils::read.table(file.temp, colClasses = rep("numeric", 4))[, 4])
  cat("Closing cluster\n")
  parallel::stopCluster(cluster)

  # Compress data matrix into sparse format
  colnames(data) <- index
  cat("Compressing matrix\n")
  data <- Matrix::Matrix(data)

  all.data <- methods::new(
    "raw.sims.data",
    data = data,
    index = index,
    sample.id = sample.id,
    x.max = x.max,
    z.max = z.max,
    y.max = y.max
  )
  gc()
  return(all.data)

}

#' Perform PCA with poisson scaling
#'
#' @param data Raw sims data
#'
#' @return A scaled sims data object
#' @export
#'
ppca <- function(data) {
  # Generate scaling matrix
  cat("Scaling data\n")
  q <- sqrt(colMeans(data@data))
  h <- sqrt(rowMeans(data@data))
  scaling.matrix <- outer(h, q)

  # Divide data by scaling matrix
  scaled.data <- data@data / scaling.matrix

  # Perform PCA
  cat("Performing PCA\n")
  pca.scaled.data <-
    stats::prcomp(scaled.data, center = FALSE, scale. = FALSE)

  # Plot PCA
  plot(pca.scaled.data)

  # Transform scores back to normal space
  cat("De-scaling scores")
  pca.scaled.data$x <- pca.scaled.data$x * scaling.matrix

  # Return PCA
  return(pca.scaled.data)
}

#' Select component corresponding to coverslip
#'
#' @param data A raw sims data object
#' @param component Principal component corresponding to the coverslip
#' @param coverslip Logical: Is there a coverslip
#' @param median.filter.size Size of median kernel for filtering noise
#' @param threshold Threshold to identify coverslip signal
#'
#' @return A scaled data matrix
#' @export
correct_z <-
  function(data,
           component = 1,
           coverslip = TRUE,
           median.filter.size = 2,
           threshold = 0.2) {
    # Convert (x, y, z) to position in 2D data matrix
    coordinate.convert <- function(x, y, z) {
      position <-
        x + ((y - 1) * data@y.max) + ((z - 1) * data@y.max * data@x.max)
      return(position)
    }

    # And to convert position into coordinates
    position.convert <- function(position, return.value = TRUE) {
      z <- position %/% (data@y.max * data@x.max) + 1
      z.leftover <- position - ((z - 1) * data@y.max * data@x.max)
      y <- z.leftover %/% data@x.max + 1
      x <- z.leftover - ((y - 1) * data@x.max) + 1

      if (return.value == TRUE) {
        return(c(x, y, z))
      } else if (return.value == 'x') {
        return(x)
      } else if (return.value == 'y') {
        return(y)
      } else if (return.value == 'z') {
        return(z)
      }
    }

    # Generate and display substrate image
    substrate.image <- EBImage::normalize(plot.scores(data, component))

    # Smooth noise in component image
    substrate.median <-
      EBImage::medianFilter(substrate.image, median.filter.size)
    EBImage::display(substrate.median, method = "raster", all = TRUE)

    # Threshold image
    if (coverslip == TRUE) {
      substrate.thresholded <- substrate.median > threshold
    } else if (coverslip == FALSE) {
      substrate.thresholded <- substrate.median < threshold
    } else {
      cat("Invalid value for \'coverslip\'")
    }
    false.floor <-
      matrix(TRUE, ncol = data@x.max, nrow = data@y.max)
    substrate.thresholded[, , data@z.max] <- false.floor
    EBImage::display(substrate.thresholded, method = "raster", all = TRUE)

    # Ask if user is happy to continue with these settings
    cat("Would you like to continue with these settings? [y/n]\n")
    line <- readline()

    if (line == "y") {
      cat("Continuing with these settings\n")
    } else if (line == "n") {
      return("")
    } else {
      cat("\nCommand not understood")
      return("")
    }

    # Identify co-ordinates of top layer of substrate in parallel
    cat("Establishing cluster\n")
    number.of.cores <- parallel::detectCores() - 2
    doParallel::registerDoParallel(number.of.cores)
    cat("Determining z=0 position\n")
    substrate.levels <-
      foreach::foreach(column = 1:data@x.max, .combine = 'cbind') %:%
      foreach::foreach(row = 1:data@y.max, .combine = 'c') %dopar%
      (which.max(substrate.thresholded[row, column, ]))
    cat("Closing cluster\n")
    doParallel::stopImplicitCluster()
    colnames(substrate.levels) <- NULL

    # Correct z axis of original data
    # Generate new matrix of nulls
    cat("Initialising corrected data array\n")
    corrected.data <- array(0, dim = dim(data@data))

    cat("Writing corrected data\n")

    new.index <- vector(mode = 'numeric', length = nrow(data@data))
    for (pixel in 1:nrow(data@data)) {
      coord <- position.convert(pixel)
      baseline <- substrate.levels[coord[1], coord[2]]
      new.z <- coord[3] + data@z.max - baseline
      if (new.z <= data@z.max) {
        position <- coordinate.convert(coord[1], coord[2], new.z)
        new.index[position] <- pixel
      }
    }
    new.index <- (NA ^ !new.index) * new.index
    data.as.matrix <- matrix(data@data, nrow = nrow(data@data))
    corrected.data <- data.as.matrix[new.index, ]
    rm(data.as.matrix)
    corrected.data <-
      replace(corrected.data, is.na(corrected.data), 0)
    corrected.data <- Matrix::Matrix(corrected.data)

    cat("Correction complete")
    return(corrected.data)
  }

