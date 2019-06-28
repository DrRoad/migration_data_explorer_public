release_notes_apply = function(){
   /* Retrieve release notes from JSON and insert them to div
      The release notes themselves are defined separately in
       "release_notes.json" to make it easier to tweak
      New release notes should be added at the top of the JSON
   */
   var defs_rn = [];
   var max_recent = 3;
   var recent_id = "#m_release_notes_recent";
   var full_id = "#m_release_notes";
   var full_title = $("<h3>", {text: "Full Release Notes"});
   
   var handleJSON = function(data){
      if(Array.isArray(data)){
         if(data.length > 0){
            parseRN(data);
         }
      }
   };
   
   var parseRN = function(rn){
      var recent_div = $(recent_id);
      var full_div = $(full_id).append(full_title);
      
      for(var i = 0; i < rn.length; i++){
         // add to "defs_rn" so it's accessible outside via "defs".
         defs_rn.push(rn[i]);
         // Always render to the full release notes div
         renderRN(rn[i]).appendTo(full_div);
         // Only render the first n release notes for the recent div
         if(i < max_recent){
            renderRN(rn[i]).appendTo(recent_div);
         }
      }
   };
   
   var renderRN = function(cur_rn){
      var out = $("<div>");
      
      // date (also the heading)
      $("<h6>")
         .append("Release: " + cur_rn.date)
         .appendTo(out);
      
      // title
      $("<p>", {class: "intro"})
         .append(cur_rn.title)
         .appendTo(out);
      
      // description
      $("<p>")
         .append(cur_rn.desc)
         .appendTo(out);
      
      // related files
      if(cur_rn.rel_files !== undefined){
         var rel_ul = $("<ul>");
         cur_rn.rel_files.forEach(function(x){
            $("<li>")
               .append($("<a>", {
                  text: x.name,
                  href: x.path,
                  target: "_blank",
                  rel: "noreferrer"
               }))
               .appendTo(rel_ul);
         });
         
         out
            .append($("<p>", {text: "Related files:"}))
            .append(rel_ul);
      }
      
      return out;
   };
   
   var init = function(){
      $.getJSON("release_notes.json", handleJSON);
   };
   
   return {
      init: init,
      defs: defs_rn
   };
}();
