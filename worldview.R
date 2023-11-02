#!/usr/bin/env Rscript

# TILESERVER <- "https://map.cazzaserver.com/linz_topo/${z}/${x}/${y}.png"
TILESERVER <- "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}"
COUNTRY <- ""
ZOOM <- 15

SIZE <- c(X = 2560, Y = 1600)
# SIZE <- c(X = 480, Y = 320)
DOWNSAMPLE <- 0

WRITE_IMAGE <- TRUE
WRITE_LOCATION <- TRUE
WRITE_COORDINATES <- TRUE
OUTPUT_DIR <- "~"
FILENAME <- "worldview"
PLOT <- FALSE

# main libraries
library(sf)
library(lwgeom) # required by sf
library(terra)

# helper libraries
library(slippymath)
library(stringr)

# other libraries
library(tidygeocoder)
library(rnaturalearth)

if (COUNTRY %in% rnaturalearth::ne_countries()@data$name_long) {
  print(paste("Getting random location in", COUNTRY))
  land <- rnaturalearth::ne_countries(
    country = COUNTRY,
    type = "countries",
    returnclass = "sf"
  ) |> st_geometry()
} else {
  print("Getting random location in the World")
  ne_options <- list(
    scale = 110,
    type = "land",
    destdir = tempdir(),
    category = "physical",
    returnclass = "sf"
  )
  land <- tryCatch(
    do.call(rnaturalearth::ne_load, ne_options),
    error = function(e) do.call(rnaturalearth::ne_download, ne_options)
  )
}

# choose random zoom level
if (length(ZOOM) == 2) {
  ZOOM <- sample(ZOOM[1]:ZOOM[2], 1)
}

point <- st_sample(land |> st_make_valid(), size = 1)
coords <- point |> st_coordinates()

location <- tidygeocoder::reverse_geo(
  long = coords[, "X"],
  lat = coords[, "Y"],
  progress_bar = F,
  quiet = T,
  custom_query = list(
    zoom = ZOOM,
    `accept-language` = "en"
  )
)

origin <- slippymath::lonlat_to_tilenum(
  lon = coords[, "X"],
  lat = coords[, "Y"],
  zoom = ZOOM + DOWNSAMPLE
)

num_tiles <- 2^DOWNSAMPLE * ceiling(SIZE / 256)

# set origin to center of image
origin$x <- origin$x - num_tiles["X"] %/% 2
origin$y <- origin$y - num_tiles["Y"] %/% 2

print("Downloading reference tile")
ref_tile <- stringr::str_interp(
  TILESERVER,
  list(x = origin$x, y = origin$y, z = ZOOM + DOWNSAMPLE)
) |> rast()

# create coordinate reference matrices
x <- rep(origin$x + 1:num_tiles["X"], num_tiles["Y"]) |>
  matrix(nrow = num_tiles["Y"], ncol = num_tiles["X"], byrow = T)
y <- rep(origin$y + 1:num_tiles["Y"], num_tiles["X"]) |>
  matrix(nrow = num_tiles["Y"], ncol = num_tiles["X"])
relx <- (x - origin$x - 1) * ext(ref_tile)$xmax
rely <- (origin$y - y - 1) * ext(ref_tile)$ymax # fixes y inversion

tiles <- mapply(function(x, y) {
  url <- str_interp(TILESERVER, list(x = x, y = y, z = ZOOM + DOWNSAMPLE))
  print(paste("Downloading", url))
  tile <- tryCatch(url |> rast(),
    error = function(e) setValues(ref_tile, NA)
  )
  tilecoords <- matrix(ncol = 2, byrow = TRUE, c(y - origin$y, x - origin$x))
  ext(tile) <- c(
    xmin = relx[tilecoords],
    xmax = (relx[tilecoords] + ext(ref_tile)$xmax),
    ymin = rely[tilecoords],
    ymax = (rely[tilecoords] + ext(ref_tile)$ymax)
  )
  raster <- tile |> aggregate(fact = 2^DOWNSAMPLE)
  raster
}, x, y)

print("Merging image tiles")
image <- sprc(tiles) |> merge()
image <- image |> crop(ext(
  ext(image)$xmin,
  ext(image)$xmin + SIZE["X"],
  ext(image)$ymin,
  ext(image)$ymin + SIZE["Y"]
))

if (PLOT) plot(image, main = location$address)
if (WRITE_IMAGE) {
  writeRaster(
    image,
    paste0(file.path(OUTPUT_DIR, FILENAME), ".jpg"),
    filetype = "JPEG",
    overwrite = TRUE
  )
}
if (WRITE_LOCATION || WRITE_COORDINATES) {
  strings <- c()
  if (WRITE_LOCATION) strings <- c(strings, location$address)
  if (WRITE_COORDINATES) {
    strings <- c(strings, paste(
      sprintf(location$lat, fmt = "%#.2f"),
      sprintf(location$long, fmt = "%#.2f")
    ))
  }
  writeLines(
    paste(strings, sep = "\n"),
    paste0(file.path(OUTPUT_DIR, FILENAME), ".txt"),
    useBytes = TRUE
  )
}
