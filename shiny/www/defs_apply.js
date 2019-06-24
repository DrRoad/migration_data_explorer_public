defs_apply = function(){
   /* Retrieve data definitions from JSON and bind tooltips
       to provide "just-in-time" dataset descriptors.
      The data definitions are defined in separate JSON files to make it easier
       tweak. The path to each definition must be specified in `init`.
      Each definition JSON file can be a "singleton" (containing a single definition),
       or an Array of definitions.
      A definition is an Object containing the following special keys:
         ".applyTo"
         The datasets to apply the definitions to, can be a String
          or an Array of Strings (if the definitions apply to multiple datasets)
         
         ".dset"
         The descriptor for the dataset itself.
         
         ".links" (optional - currently unused)
         Where variables are related to each other, define these links.
      
      Any additional keys in the definitions Object is treated to be the
       description for a variable (of the same name) in the dataset.
   */
   var defs_dname = {};
   var defs_dvars = {};
   
   var handleJSON = function(data){
      /* handle singleton definitions and Arrays of definitions */
      if(!Array.isArray(data)){
         dapply(data);
      } else{
         data.forEach(dapply);
      }
   };
   
   var dapply = function(cdef){
      /* handle definitions for a single dataset and Arrays of datasets */
      if(!Array.isArray(cdef[".applyTo"])){
         dparse(cdef[".applyTo"], cdef);
      } else{
         for(var i = 0; i < cdef[".applyTo"].length; i++){
            dparse(cdef[".applyTo"][i], cdef);
         }
      }
   };
   
   var dparse = function(dname, cdef){
      /* store the definitions for the dataset */
      // dataset descriptors
      if(cdef[".dset"] !== undefined){
         defs_dname[dname] = cdef[".dset"];
      }
      
      // variable descriptions for the dataset
      if(defs_dvars[dname] === undefined){
         defs_dvars[dname] = [];
      }
      defs_dvars[dname].push(cdef);
   };
   
   /* helper functions for binding tooltips */
   var tooltip_inlist = function(sel, selector, title){
      sel.tooltip({
         container: "body",
         selector: selector,
         placement: "right",
         title: title
      });
   };
   var tooltip_insel = function(sel, title){
      sel.tooltip({
         container: "body",
         selector: "button.insel",
         placement: "top",
         title: title
      });
   };
   
   var bind_tooltips = function(){
      /* bind tooltips */
      var makeid = iife.makeid;
      var inselGet = iife.panel.inselGet;
      var inlistGet = iife.panel.inlistGet;
      
      /* dname inlist */
      tooltip_inlist($(makeid("dname")), "div.radio",
         function(){
            var val = $(this).find("input").attr("value");
            return defs_dname[val];
         }
      );
      
      /* dname insel */
      tooltip_insel(inselGet($(makeid("dname"))),
         function(){
            var val = $(this).attr("value");
            return defs_dname[val];
         }
      );
      
      /* dvars */
      var get_dvardef = function(val){
         var dname = $(makeid("dvars")).attr("data-dname");
         var cdefs = defs_dvars[dname];
         if(cdefs !== undefined){
            var vdef;
            for(var i = 0; i < cdefs.length; i++){
               if(cdefs[i][val] !== undefined){
                  vdef = cdefs[i][val];
               }
            }
            return vdef;
         } else{
            return;
         }
      };
      var get_dvardef_button = function(){
         var val = $(this).attr("value");
         return get_dvardef(val);
      };
      
      /* dvars insel */
      tooltip_insel($(makeid("dvars")), get_dvardef_button);
      
      /* dvars inlist */
      tooltip_inlist(inlistGet($(makeid("dvars"))),
         ".list-group-item", get_dvardef_button);
      
      /* table columns */
      $(makeid("preview-table")).tooltip({
         container: makeid("preview-table"),
         selector: "th",
         placement: "top",
         title: function(){
            return get_dvardef($(this).text());
         }
      });
   };
   
   var iife;
   var init = function(iife_ref){
      iife = iife_ref;
      $.getJSON("defs_immidata.json", handleJSON);
      $.getJSON("defs_spells.json", handleJSON);
      
      bind_tooltips();
   };
   
   return {
      init: init,
      dname: defs_dname,
      dvars: defs_dvars
   };
}();
