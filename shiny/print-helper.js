var PrintHelper = function(){
   /* PrintHelper
      An experimental tool to generate print-ready A4-type pages with
       arbitrary selection and layout of outputs and narrative text.
      This is the JS component of the tool, there are also
       R and CSS components.

      Required External Libraries:
      - jQueryUI (Resizable and Draggable only)
      - Summernote
   */
   var ph = {};
   
   /* Names and IDs */
   var tabname, id_div, id_selmode, id_moveresize, id_printmode, id_textarea;
   /* jQuery selections */
   var sel_div, sel_page, sel_notme;
   /* Non-exported Functions */
   var tab_click, untick_selmode;
   /* Non-exported Variables */
   var index_id, pWidth, pHeight;
   
   ph.init = function(){
      /* Save passed arguments to parent scope
         Ensure order is correct in the R code that calls this function.
      */
      tabname = arguments[0];
      id_div = arguments[1];
      id_selmode = arguments[2];
      id_moveresize = arguments[3];
      id_printmode = arguments[4];
      id_textarea = arguments[5];
      
      /* jQuery selections */
      sel_div = $("#" + id_div);
      sel_page = sel_div.find(".print-helper");
      sel_notme = $("body").children().not(sel_div.parents("*"));
      
      /* Non-exported Functions */
      tab_click = function(){$("a[data-value=" + JSON.stringify(tabname) + "]").click();};
      untick_selmode = function(){$("#" + id_selmode).prop("checked", false).change();};
      
      /* Non-exported Variables */
      index_id = 0;
      pWidth = sel_page.width();
      pHeight = sel_page.height();
      
      /* Other evaluations */
      ph.moveresize.init(id_moveresize);
      ph.print.init(id_printmode);
      ph.text.init(id_textarea, sel_div.find(".print-helper-texteditor"));
      
      /* Bind Events */
      $(document).on("click", ".ph-output .action-button", function(){
         tab_click();
         untick_selmode();
      });
      Shiny.addCustomMessageHandler("print-helper", function(msg){
         if(msg.type == "create-con"){
            ph.con.create(msg.id);
         } else if(msg.type == "move"){
            ph.con.move(msg.cur_id, msg.con_id);
         }
      });
   };
   
   ph.gen_unique_id = function(){
      index_id++;
      return id_div + "_js_" + index_id;
   };
   
   /* Modules
      Various components of the Print Helper grouped into modules.
      Each module has its own namespace and has shared names for similar tasks.
      
      -init-
      Called by the main `PrintHelper.init` function.
      Usually responsible for storing the id of related input controls,
       and to bind the required event handlers.
      
      -toggle-
      Where there is a related input element, this function handles
       the necessary enable/disable procedures.
      
      -create-
      
      
      
   */
   ph.con = function(){
      /* Container
         Creates containers for the copied ouput,
          and has the function that moves the output from
          the temporary area to the created container.
         The process is:
            1) Copy button is pressed.
            2) R component of PrintHelper creates the required output UI
               and prints to a temporary area.
            3) R component sends a Message, which triggers `me.create`
               to create a container for this UI in the page-proxy.
            4) R component sends a Message, which triggers `me.move`
               to move the rendered UI from the temporary
               area to the newly created container.
            5) R component renders a copy of the output to the UI.
      */
      var me = {};
      
      me.create = function(con_id){
         sel_page.append($("<div>", {id: con_id, class: "ph-con"}));
      };
      
      me.move = function(cur_id, con_id){
         $("#" + cur_id).appendTo("#" + con_id);
      };
      
      return me;
   }();
   
   ph.moveresize = function(){
      /* Move/Resize
         Methods for interacting with containers,
          to make it easier to move/resize/edit them.
         This handles the (de)selection of containers.
         The actual interactive features are handled by
          ph.interactive.
      */
      var me = {};
      
      me.init = function(id_moveresize){
         me.sel = $("#" + id_moveresize);
         me.sel.on("click", me.toggle);
         sel_div.on("click", ".ph-sel-intent", me.select);
      };
      
      me.toggle = function(){
         if(me.sel.prop("checked")){
            $(".ph-con").addClass("ph-sel-intent");
         } else{
            me.clear();
            $(".ph-con").removeClass("ph-sel-intent");
         }
      };
      
      /* forceon
         A way to force the move/resize mode to on.
         If given a selection, this selection is also selected.
      */
      me.forceon = function(cur_sel){
         if(!me.sel.prop("checked")){
            me.sel.click();
         }
         if(cur_sel !== undefined){
            cur_sel.addClass("ph-sel-intent");
            cur_sel.click();
         }
      };
      
      /* Clear all selections */
      me.clear = function(){
         if($(".ph-sel-active").length > 0){
            $(".ph-sel-active").each(function(){
               me.deselect($(this));
            });
         }
      };
      
      /* Remove a selection
         In theory, there should only be a single selection at
          any given time, but just in case there are multiple,
          use `me.clear` as a generalised deselect.
      */
      me.deselect = function(cur_sel){
         /* PrintHelper class specific methods */
         var phClass = cur_sel.data("phClass");
         if(phClass !== undefined){
            ph[phClass].deselect(cur_sel);
         }
         
         /* Remove interaction and class */
         ph.interactive.disable(cur_sel).removeClass("ph-sel-active");
      };
      
      /* Make a selection */
      me.select = function(){
         var cur_sel = $(this);
         if(!cur_sel.hasClass("ph-sel-active")){
            me.clear();
            
            /* Add class and interaction */
            ph.interactive.enable(cur_sel).addClass("ph-sel-active");
            
            /* PrintHelper class specific methods */
            var phClass = cur_sel.data("phClass");
            if(phClass !== undefined){
               ph[phClass].select(cur_sel);
            }
         }
      };
      
      return me;
   }();
   
   ph.print = function(){
      /* Print
         Methods for the print-friendly mode.
         This is not responsible for any actual printing.
         It's simply for toggling visibility of the other elements
          so that you can get a clean print with the browser's
          own print functionality.
         "sel_page" and "sel_notme" are defined in ph.init.
         sel_page is the jQuery selection for the page proxy container.
         sel_notme are the direct children of the <body> tag, that is not
          a parent of sel_page. Thus it's important to note that other
          children of sel_page's parent will not be hidden.
          In particular, this includes the input controls for PrintHelper
           (which is important so that the user can still access the
            print mode control, to toggle it off), which are instead
            hidden by the css rule "@media print".
      */
      var me = {};
      
      me.init = function(id_printmode){
         me.sel = $("#" + id_printmode);
         me.sel.on("click", me.toggle);
      };
      
      me.toggle = function(){
         if($(this).prop("checked")){
            sel_notme.css("display", "none");
            sel_page.css("pointer-events", "none");
         } else{
            sel_notme.css("display", "");
            sel_page.css("pointer-events", "");
         }
      };
      
      return me;
   }();
   
   ph.text = function(){
      /* Text
         Module for adding arbitrary text, for adding titles,
          narrative text, etc.
         It uses "summernote" to provide an editor interface,
          so users can create styled text easily.
         Adding text works in the following way:
         1) Add a text container.
         2) Edit the text container, this brings up a "window",
            a free-moving container, in which the summernote
            editor resides.
         3) As the text is modified in the editor, the text container
            is updated to match the contents in the editor.
         4) As a container, the text container can be moved and
            resized, via `ph.interactive`.
         5) When the text container is deselected, the text editor
            "window" is hidden.
      */
      var me = {};
      
      me.init = function(id_textarea, sel_con){
         /* Bind Event */
         me.sel = $("#" + id_textarea);
         me.sel.on("click", me.create);
         
         /* Create editor */
         if(me.ed === undefined){
            me.edcon = sel_con;
            me.ed = $("<div>").appendTo(sel_con);
         }
         
         /* Make container draggable by editor toolbar */
         sel_con.draggable({
            handle: ".note-toolbar-wrapper"
         });
      };
      
      /* Callback used by the summernote editor.
         "contents" provides the raw html behind the styled text
          created via the editor.
         Thus we can simply set the bound element html to this,
          to update it synchronously.
         This allows the user to see what their text will look like
          in the page proxy, as they edit.
      */
      me.change = function(contents){
         if(me.bind !== undefined){
            me.bind.html(contents);
         }
      };
      
      /* When a text container is selected, need to
          show the editor "window".
         For convenience, we also move this "window" to
          appear slightly to the right of the text container,
          and give it focus when it appears.
      */
      me.show = function(){
         if(me.bind !== undefined){
            me.edcon.css("display", "block");
            me.edcon.css({
               top: me.bind.offset().top + 10,
               left: me.bind.offset().left + me.bind.width() + 50
            });
            
            if(me.edinit === undefined){
               /* If editor hasn't been initialised, do so */
               me.ed.summernote(me.options);
               me.edinit = true;
            }
            
            me.ed.summernote("code", me.bind.html());
            me.ed.summernote("focus");
         }
      };
      
      /* For hiding the editor "window". */
      me.hide = function(){
         me.edcon.css("display", "none");
      };
      
      /* For creating the text container.
         The text is actually stored in another <div>
          nested within the container, to separate it from
          other child elements appended for the interactive features.
         When created, we use `ph.moveresize.forceon` to immediately
          select it for editing.
      */
      me.create = function(){
         var curid = ph.gen_unique_id();
         var out = $("<div>", {
               id: curid,
               class: "ph-con ph-textcon"
            })
            .data("phClass", "text")
            .append($("<div>", {
                  class: "ph-textarea"
               })
               .html("<p>lorem ipsum</p>")
            );
         
         sel_page.append(out);
         ph.moveresize.forceon(out);
      };
      
      /* When selected, we need to save the selected text container
          to `me.bind`, so we can refer to it.
         We also need to show the editor "window".
      */
      me.select = function(cur_sel){
         me.bind = cur_sel.children(".ph-textarea");
         me.show();
      };
      
      /* When deselected, we need to clear the binding.
         We also need to hide the editor "window".
      */
      me.deselect = function(cur_sel){
         me.bind = undefined;
         me.hide();
      };
      
      /* Summernote options
         Attempts have been made to make it appear similar to Word.
         And to use MBIE fonts & colours.
      */
      me.options = {
         height: 280,
         followingToolbar: false,
         toolbar: [
            ['style', ['style', 'clear']],
            ['font', ['bold', 'italic', 'underline']],
            ['font2', ['strikethrough', 'subscript', 'superscript']],
            ['color', ['color']],
            ['fontdefs', ['fontsize', 'fontname']],
            ['commands', ['help', 'undo', 'redo']],
            ['para', ['ul', 'ol', 'paragraph']],
            ['table', ['table']],
            ['image', ['picture']]
         ],
         fontNames: ["Fira Sans", "Gustan"],
         fontNamesIgnoreCheck: ["Fira Sans", "Gustan"],
         colors: [
            ["#000000","#2B2B2B","#555555","#808080","#AAAAAA","#D4D4D4","#FFFFFF"],
            ["#006272","#97D700","#00B5E2","#753BBD","#DF1995","#FF6900","#FBE122"],
            ["#CCE0E3","#EAF7CC","#CCF0F9","#E3D8F2","#F9D1EA","#FFE1CC","#FEF9D3"]
         ],
         callbacks: {
            onChange: me.change
         }
      };
      
      return me;
   }();
   
   ph.interactive = function(){
      /* For making an arbitrary selection interactive.
         Specifically, adds the draggable and resizable features from jQueryUI.
      */
      var me = {};
      
      me.enable = function(cur_sel){
         return cur_sel
            .draggable()
            .resizable({maxWidth: pWidth, maxHeight: pHeight, handles: "all"});
      };
      
      me.disable = function(cur_sel){
         return cur_sel
            .draggable("destroy")
            .resizable("destroy");
      };
      
      return me;
   }();
   
   return ph;
}();
