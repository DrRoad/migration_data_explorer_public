####################################################################
## This should be run in the working directory of the source repo ##
####################################################################

## path defs, tweak if required
repo_public = "migration_data_explorer_public"
path_prel = function(x) paste0("../", repo_public, "/", x)

## Create public README
source("README_public_tweaks.R")
writeLines(README_public_tweaks(), path_prel("README.md"))

## Copy shiny files (excl data)
copy_ext = c("css", "js", "R", "json", "csv", "png")
copy_ext_rx = paste0("\\.(", paste0("(", copy_ext, ")", collapse = "|"), ")$")
copy_paths = list.files("shiny", pattern = copy_ext_rx,
                        full.names = TRUE, recursive = TRUE)
skip_files = c("random_rounding.R", "ga_tracker.js")
copy_paths = copy_paths[!grepl(paste(skip_files, collapse = "|"), copy_paths)]

for(cur_path in copy_paths){
   ## Check if directory exists, if not, create
   cur_dir = dirname(cur_path)
   if(!dir.exists(path_prel(cur_dir)))
      dir.create(path_prel(cur_dir), recursive = TRUE)
   
   ## Copy file
   file.copy(cur_path, path_prel(cur_path), overwrite = TRUE)
}

## "Copy" data files
source("shiny/random_rounding.R")
data_paths = list.files("shiny", pattern = "\\.rda$", full.names = TRUE)
copy_direct = "all_csv_names"
for(cur_path in data_paths){
   if(grepl(paste(copy_direct, collapse = "|"), cur_path)){
      ## Copy directly
      file.copy(cur_path, path_prel(cur_path), overwrite = TRUE)
   } else{
      ## Load, pre-aggregate/round, then save
      cenv = new.env()
      load(cur_path, envir = cenv)
      dnames = ls(cenv)
      for(dname in dnames){
         if(grepl("_precomp", dname)){
            for(i in 1:length(cenv[[dname]]))
               cenv[[dname]][[i]]$dset$Count = do_round(cenv[[dname]][[i]]$dset$Count)
         } else{
            cenv[[dname]]$Count = do_round(cenv[[dname]]$Count)
         }
      }
      save(list = ls(cenv), envir = cenv, file = path_prel(cur_path))
   }
}
