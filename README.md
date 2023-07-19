# worldview

![Banner](images/composite2.png)

Create an image of a random location in the world. The sequel to [earthview-desktop](https://github.com/ryan-mooore/earthview-desktop).

## Installation and running

This project uses `renv` for R dependency management.

### Script options:

| Option       | Description                                                                                                                                  |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `TILESERVER` | XYZ Server to download tiles from. Use `${x}` etc. for substitution.                                                                         |
| `ZOOM`       | Zoom level of XYZ tiles to choose from (1-16). If passed a vector of length 2, will choose a random tile zoom level between the two numbers. |
| `SIZE`       | SIze in pixels of resulting image.                                                                                                           |
