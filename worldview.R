ZOOM <- 12
TILESERVER <- "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}"
SIZE <- list(x=5, y=3)
COUNTRY <- "New Zealand"

library(rnaturalearth)
library(sf)
library(slippymath)
library(stringr)
library(terra)
library(lwgeom) # required by sf

countries <- ne_countries()

if (COUNTRY %in% countries@data$name_long) {
  print(paste("Getting random location in", COUNTRY))
  land <- ne_countries(country=COUNTRY, type="countries", returnclass = "sf") |>
    st_geometry()
} else {
  print("Getting random location in the World")
  land <- ne_download(scale=110, type="land", category = "physical", returnclass = "sf")
}
point <- st_sample(land |> st_make_valid(), size=1)
coords <- point |> st_coordinates()
origin <- lonlat_to_tilenum(lon=coords[[1]], lat=coords[[2]], zoom=ZOOM)

print("Downloading reference tile")
tile_ext <- str_interp(TILESERVER, list(x=origin$x, y=origin$y, z=ZOOM)) |> 
  rast() |> ext()

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
s
print("Merging image tiles")
image <- sprc(tiles) |> merge()
plot(image)