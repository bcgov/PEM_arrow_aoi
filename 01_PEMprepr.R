
remotes::install_github("bcgov/PEMprepr", build_vignettes = FALSE)
devtools::load_all("D:\\PEM_DATA\\PEMprepr")

# load in library's needed

library(PEMprepr)
library(ggplot2)
library(sf)
library(terra)
library(bcmaps)


# create the initial file structure 
fid <- setup_folders("Arrow_AOI")

# save your basic aoi in the file location "fid$shape_dir_0010[2]". 
#If you are unsure you can check by pasting this in the console. 

aoi_raw <- st_read(file.path(fid$shape_dir_0010[2], "arrow_aoi.gpkg"))

# expand the AOI to a square grid
aoi <- aoi_snap(aoi_raw, "expand")

# write out into the cleaned shapefile location"
sf::st_write(aoi, file.path(fid$shape_dir_1010[1], "aoi_snapped.gpkg"))

# pull in the raw vector data for the study area. Note this is saved in raw loaction folder
create_base_vectors(in_aoi = aoi,
                    out_path = fid$shape_dir_0010[1])

# check the covars were created created
v <- list.files(path = fid$shape_dir_0010[1], pattern = ".gpkg",
                recursive = TRUE)
v

# you will need to manually download the "private layers" data, see manual for details. 



# Review and shift to the other file location 
origindir <- fid$shape_dir_0010[1]
filestocopy <- list.files(path = fid$shape_dir_0010[1], pattern = ".gpkg",recursive = TRUE)
targetdir <- fid$shape_dir_1010[1]
lapply(filestocopy, function(x) file.copy(paste (origindir, x , sep = "/"),  
                                          paste (targetdir,x, sep = "/"), recursive = FALSE,  copy.mode = TRUE))
#file.remove(filestocopy)



###############################
# Prepare Raster Data
res_scale = "25m"
cov.dir <- file.path(fid$cov_dir_1020[2], "25m")

# create a blank raster template
r25 <- create_template(aoi, 25)
terra::writeRaster(r25, file.path(cov.dir, "template.tif"), overwrite = TRUE)

# read in base raster
trim_raw <- cded_raster(aoi)

# convert the trim to matching raster 
trim <- terra::rast(trim_raw)
trim <- terra::project(trim, r25)


# generate BEC raster 

bec_sf <- sf::st_read(file.path(fid$shape_dir_1010[1], "bec.gpkg")) %>%
  sf::st_cast(., "MULTIPOLYGON") 

bec_code <- bec_sf %>% st_drop_geometry()  %>% dplyr::select(MAP_LABEL) %>%
  unique() 

bec_code <- bec_code %>% 
  mutate(bgc_unique_code = seq(1, length(bec_code$MAP_LABEL),1))

bec_sf <- dplyr::left_join(bec_sf, bec_code)

bec_vec <- terra::vect(bec_sf)

# generate a 25m raster

bec_ras25 <- terra::rasterize(bec_vec, r25, field = "MAP_LABEL")

terra::writeRaster(bec_ras25, file.path(cov.dir, "bec.tif"), overwrite = TRUE)



