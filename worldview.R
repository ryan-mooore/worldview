TILESERVER <- "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}"
ZOOM <- c(8, 14)
SIZE <- c(X=1920, Y=1080)
DOWNSAMPLE <- 1
COUNTRY <- ""
OUTPUT_LOCATION <- "~/worldview.jpg"

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
    country=COUNTRY,
    type="countries",
    returnclass = "sf"
  ) |> st_geometry()
} else {
  print("Getting random location in the World")
  ne_options <- list(
    scale=110,
    type="land",
    destdir=tempdir(),
    category = "physical",
    returnclass = "sf"
  )
  land <- tryCatch(
    do.call(rnaturalearth::ne_load, ne_options),
    error=function(e) do.call(rnaturalearth::ne_download, ne_options)
  )
}

# choose random zoom level
if (length(ZOOM) == 2) {
  ZOOM <- sample(ZOOM[1]:ZOOM[2], 1)
}

point <- st_sample(land |> st_make_valid(), size=1)
coords <- point |> st_coordinates()

location <- tidygeocoder::reverse_geo(
  long=coords[,"X"],
  lat=coords[,"Y"],
  progress_bar=F,
  quiet=T,
  custom_query = list(zoom=ZOOM))

origin <- slippymath::lonlat_to_tilenum(
  lon=coords[,"X"],
  lat=coords[,"Y"],
  zoom=ZOOM + DOWNSAMPLE
)

num_tiles <- 2 ^ DOWNSAMPLE * ceiling(SIZE / 256)

# set origin to center of image
origin$x <- origin$x - num_tiles["X"] %/% 2
origin$y <- origin$y - num_tiles["Y"] %/% 2

print("Downloading reference tile")
tile_ext <- stringr::str_interp(
  TILESERVER,
  list(x=origin$x, y=origin$y, z=ZOOM + DOWNSAMPLE)
  ) |> rast() |> ext()

# create coordinate reference matrices
x <- rep(origin$x + 1:num_tiles["X"], num_tiles["Y"]) |>
  matrix(nrow=num_tiles["Y"], ncol=num_tiles["X"], byrow=T)
y <- rep(origin$y + 1:num_tiles["Y"], num_tiles["X"]) |>
  matrix(nrow=num_tiles["Y"], ncol=num_tiles["X"])
relx <- (x - origin$x - 1) * tile_ext$xmax
rely <- (origin$y - y - 1) * tile_ext$ymax # fixes y inversion

print("Downloading image tiles")
tiles <- mapply(function(x, y) {
  tile <- str_interp(TILESERVER, list(x=x, y=y, z=ZOOM + DOWNSAMPLE)) |> rast()
  tilecoords <- matrix(ncol = 2, byrow = TRUE, c(y - origin$y, x - origin$x))
  ext(tile) <- c(
      xmin=relx[tilecoords],
      xmax=(relx[tilecoords] + tile_ext$xmax),
      ymin=rely[tilecoords],
      ymax=(rely[tilecoords] + tile_ext$ymax)
    )
  raster <- tile |> aggregate(fact=2 ^ DOWNSAMPLE)
  RGB(raster) <- c(1, 2, 3)
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

# plot(image, main=location$address)
writeRaster(image, OUTPUT_LOCATION, filetype="JPEG", overwrite=TRUE)
