ZOOM <- 10
TILESERVER <- "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}"
SIZE <- list(x=6, y=6)
COUNTRY <- "New Zealnd"

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
    returnclass = "sf") |>
    st_geometry()
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
    error=function() do.call(rnaturalearth::ne_download, ne_options)
  )
}

point <- st_sample(land |> st_make_valid(), size=1)
coords <- point |> st_coordinates()
origin <- slippymath::lonlat_to_tilenum(
  lon=coords[,"X"],
  lat=coords[,"Y"],
  zoom=ZOOM
)

location <- tidygeocoder::reverse_geo(
  long=coords[,"X"],
  lat=coords[,"Y"],
  progress_bar=F,
  quiet=T,
  custom_query = list(zoom=ZOOM))

print("Downloading reference tile")
tile_ext <- stringr::str_interp(
  TILESERVER, 
  list(x=origin$x, y=origin$y, z=ZOOM)
  ) |> rast() |> ext()

# create coordinate reference matrices
x <- rep(origin$x + 1:SIZE$x, SIZE$y) |>
  matrix(nrow=SIZE$y, ncol=SIZE$x, byrow=T)
y <- rep(origin$y + 1:SIZE$y, SIZE$x) |>
  matrix(nrow=SIZE$y, ncol=SIZE$x)
relx <- (x - origin$x - 1) * tile_ext$xmax
rely <- (origin$y - y - 1) * tile_ext$ymax # fixes y inversion

print("Downloading image tiles")
tiles <- mapply(function(x, y) {
  tile <- str_interp(TILESERVER, list(x=x, y=y, z=ZOOM)) |> rast()
  tilecoords <- matrix(ncol = 2, byrow = TRUE, c(y - origin$y, x - origin$x))
  ext(tile) <- c(
      xmin=relx[tilecoords],
      xmax=(relx[tilecoords] + tile_ext$xmax),
      ymin=rely[tilecoords],
      ymax=(rely[tilecoords] + tile_ext$ymax)
    )
  tile
  }, x, y)

print("Merging image tiles")
image <- sprc(tiles) |> merge()
plot(image, main=location$address)