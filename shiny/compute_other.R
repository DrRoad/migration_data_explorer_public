compute_other =
   ## A generalised function to compute 'Other' categories.
   ## Given a specific variable "curvar" which is to be filtered
   ##  down to a selection "sel_curvar", the remaining unselected
   ##  elements of "curvar" are summarised into 'Other' categories
   ##  as specified in "other_levels".
   ##
   ## Arguments:
   ## -fulldat-
   ## The dataset, before filtering "curvar" to its selection "sel_curvar".
   ##
   ## -curvar-
   ## The variable of interest, given as a character.
   ##  e.g. "Age_band"
   ##
   ## -sel_curvar-
   ## A vector of elements of "curvar" to keep.
   ## Or in other words, the elements of "curvar" that should NOT
   ##  be summarised into the 'Other' categories.
   ## If this vector encompasses all of "curvar", then no 'Other'
   ##  categories are computed.
   ##
   ## -other_levels-
   ## The 'Other' categories to compute. This specifies both the
   ##  name of the category, and the function to use to generate it.
   ## "other_levels" as given are used as the names.
   ## Then anything outside of the brackets "(" and ")" are stripped
   ##  (if there are brackets. If there isn't, nothing is stripped),
   ##  to get the function to apply.
   ## As a special case, if the remaining function is "average", this
   ##  is converted to "mean".
   ## e.g. "Other (sum)", "Other (average)" -> "sum", "mean"
   ##
   ## -groupvars-
   ## Any variables to group by (using the dplyr `group_by`), before
   ##  applying summarising functions.
   ## Default: NULL (no groups)
   ##
   ## -valvar-
   ## The name of the variable with the value to be summarised.
   ## Default: "Value"
   ##
   ## -valdp-
   ## Rounding is applied using `round` on the 'Other' categories.
   ## This is typically most important for summarising functions like
   ##  `mean`, which can result in a lot of decimal places.
   ## Default: 1
   ##
   function(fulldat, curvar, sel_curvar, other_levels,
            groupvars = NULL, valvar = "Value", valdp = 1){
      library(dplyr)
      
      ## Filter to selected main variable options
      dat_part_main = fulldat %>%
         filter_at(curvar, all_vars(. %in% sel_curvar)) %>%
         group_by_at(c(curvar, groupvars)) %>%
         summarise_at(valvar, sum) %>%
         ungroup() %>%
         mutate_at(curvar, factor)
      
      ## Keep order of levels as given
      var_levels = sel_curvar[sel_curvar %in% levels(dat_part_main[[curvar]])]
      
      ## Compute "Other" if required
      if(length(other_levels) > 0 &&
         any(!(levels(fulldat[[curvar]]) %in% sel_curvar))){
         ## If no non-other selected, then rename other_levels
         if(length(var_levels) == 0){
            other_names = gsub("Other", "Total", other_levels)
         } else{
            other_names = other_levels
         }
         var_levels = c(var_levels, other_names)
         
         dat_part_main = dat_part_main %>%
            mutate_at(curvar, factor, levels = var_levels)
         dat_part_other = fulldat %>%
            filter_at(curvar, all_vars(!. %in% sel_curvar))
         if(!is.null(groupvars)) dat_part_other = group_by_at(dat_part_other, groupvars)
         dat_parts = list(main = dat_part_main)
         for(i in seq(along = other_levels)){
            cur_other = other_levels[i]
            cur_name = other_names[i]
            cur_func = gsub("(.*\\()|()\\).*", "", cur_other)
            if(cur_func == "average") cur_func = "mean"
            dat_parts[[cur_other]] = dat_part_other %>%
               summarise_at(valvar, funs(do.call(cur_func, list(., na.rm = TRUE)))) %>%
               mutate_at(valvar, round, valdp) %>%
               mutate_at(1, structure(funs(factor(cur_name, levels = var_levels)),
                                      names = curvar, have_name = TRUE))
         }
         
         ## Combine
         do.call(bind_rows, dat_parts)
      } else{
         ## Ensure the ordering of levels is preserved
         dat_part_main %>%
            mutate_at(curvar, factor, levels = var_levels)
      }
   }
