# worldview

![Banner](images/composite2.png)

Create an image of a random location in the world (from an XYZ server). The sequel to [earthview-desktop](https://github.com/ryan-mooore/earthview-desktop).

## Installation and running

This project uses [renv](https://rstudio.github.io/renv/articles/renv.html) for dependency management.

Simply run `Rscript worldview.R` to execute.

### Script options

| Option            | Description                                                                                                                                                                                                                                                                                                           |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TILESERVER`      | XYZ Server to download tiles from. Use `${x}` etc. for substitution.                                                                                                                                                                                                                                                  |
| `ZOOM`            | Zoom level of XYZ tiles to choose from (1-16). If passed a vector of length 2, will choose a random tile zoom level between the two numbers. Risk of unavailable data at higher zoom levels if using a worldwide composite basemap.                                                                                   |
| `SIZE`            | Size in pixels of resulting image.                                                                                                                                                                                                                                                                                    |
| `DOWNSAMPLE`      | If set to 1 or above, will gather tiles at that number of zoom levels higher than chosen and then downsample back to original resolution. Helpful for normalizing spatial resolution if the basemap varies. Setting this downloads exponentially more tiles and can result in unavailable data at higher zoom levels. |
| `COUNTRY`         | Optionally select a country which the script will pick a random location within. If not a valid country or is an empty string, will pick from the world instead.                                                                                                                                                      |
| `OUTPUT_LOCATION` | Location to save the resulting image                                                                                                                                                                                                                                                                                  |
