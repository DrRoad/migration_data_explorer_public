var HelperFuncs = function(){
   /* JS equivalent to helper_funcs.R
      For scoping reasons, major components are defined as an
       "immediately-invoked function expression" (IIFE)
       that returns a single Object.
      This returned Object contains everything that needs to be
       exported from the local scope.
      Note that the name of the returned Object within the local
       scope can (and usually is) different from the name used
       outside the scope, e.g. within the HelperFuncs scope,
       the returned Object is named "hef", but once returned it
       is assigned to "HelperFuncs".
      Typically the internal name is a shorthand, possibly shared
       across multiple IIFEs (like "me" or "self"), while the
       name that is ultimately assigned is a more verbose name.
      
      HelperFuncs is an IIFE that returns the Object: "hef"
   */
   var hef = {};
   
   hef.tab = function(tabName){
      /* tab
         Activate the tab with the given name.
         A very basic implementation, only works reliably if the
            given "tabName" is unique.
      */
      $(".nav a[data-value=" + JSON.stringify(tabName) + "]").click();
   };
   hef.gettab = function(sel){
      /* gettab
         Find the name of the tab the given selection is found.
      */
      return sel.parents(".tab-pane").attr("data-value");
   };
   
   hef.hc_download = function(){
      /* hc_download
         JS component to the R function `highchartOutputWithDownload`.
         This provides the necessary functionality to enable the PNG and Print buttons.
      */
      $(document).on("click.hc-outputgroup", ".hc-pngbtn", function(){
         var cur_hc = $(this)
            .parents(".hc-outputgroup")
            .find(".highchart")
            .highcharts();
         cur_hc.exportChartLocal({
            type: "image/png",
            filename: cur_hc.title.textStr,
            sourceWidth: cur_hc.chartWidth,
            sourceHeight: cur_hc.chartHeight
         });
      });
      $(document).on("click.hc-outputgroup", ".hc-printbtn", function(){
         var hc_con = $(this).parents(".hc-outputgroup").find(".highchart");
         hc_con.highcharts().print();
      });
   };
   
   hef.popinput = function(){
      /* popinput
         JS component to the R function `popPanel`.
         Allows the user to "pop-out" an input panel, dragging it
          around so they can keep it with them.
      */
      
      /* Handle pop-out
         1) Add class
         2) Make draggable
         3) Set position to where it is currently on-screen
         4) Add handle (for dragging) and pop-in button
         5) Hide pop-out button
      */
      $(document).on("click.popinput", ".pop-input-out", function(){
         $(this).siblings(".pop-input")
            .addClass("pop-input-active")
            .draggable({
               containment: "window",
               handle: ".pop-input-handle"
            })
            .each(function(){
               var pos = $(this).parent(".pop-input-con").offset();
               pos.top -= $(window).scrollTop();
               $(this).css(pos);
            })
            .append($("<div>", {class: "pop-input-handle"})
               .append($("<button>", {type: "button",
                     class: "pop-input-btn pop-input-in",
                     title: "Return Input Panel"})
                  .append($("<i>", {class: "glyphicon glyphicon-log-in"}))
               )
            );
         $(this).css("display", "none");
      });
      
      /* Handle pop-in
         1) Remove class
         2) Remove draggable
         3) Remove handle and pop-in button
         4) Make pop-out button visible
      */
      $(document).on("click.popinput", ".pop-input-in", function(){
         var cursel = $(this).parents(".pop-input-active");
         
         cursel
            .removeClass("pop-input-active")
            .draggable("destroy")
            .children(".pop-input-handle").remove();
         
         cursel.siblings(".pop-input-out").css("display", "");
      });
   };
   
   hef.make_bmodal = function(baseid, mlabel){
      /* init
         Sets up a bootstrap modal box.
         This should be called once per modal to create it. Once created,
            only the contents of ".modal-body" should be cleared/updated.
         
         Arguments:
         -baseid-    The id of the modal.
         -mlabel-    The title/label for the modal.
         
         Returns an Object containing:
         -sel-       Pointer to ".modal-body"
         -clear-     Function that clears the contents of ".modal-body"
         -show-      Function for displaying the modal.
         -hide-      Function for hiding the modal.
         -button-    Function taking 1 argument "cur_label" that
                      returns a jQuery(<button>) with given label,
                      that displays the modal.
         -link-      Same as "button", but returns <a> link instead.
      */
      var id_sel = "#" + baseid;
      var id_label = baseid + "-label";
      
      $("<div>", {id: baseid, class: "modal fade",
            tabindex: -1, role: "dialog",
            "aria-labelledby": id_label,
            "aria-hidden": "true"})
         .append($("<div>", {class: "modal-dialog", role: "document"})
            .append($("<div>", {class: "modal-content"}))
         )
         .appendTo("body");
      
      $(id_sel).find(".modal-content")
         .append($("<div>", {class: "modal-header"})
            .append($("<h5>", {id: id_label, class: "modal-title", text: mlabel}))
         )
         .append($("<div>", {class: "modal-body"}))
         .append($("<div>", {class: "modal-footer"})
            .append($("<button>", {type: "button", class: "btn btn-secondary", "data-dismiss": "modal", text: "Close"}))
         );
      
      var mesel = $(id_sel).find(".modal-body");
      
      return {
         sel: mesel,
         clear: function(){
            /* clear
               Clear the log by removing the contents of me.sel
            */
            mesel.children("*").remove();
         },
         show: function(){
            /* show
               Convenience function for displaying the modal.
            */
            $(id_sel).modal("show");
         },
         hide: function(){
            /* hide
               Convenience function for hiding the modal.
            */
            $(id_sel).modal("hide");
         },
         button: function(cur_label){
            /* button
               Convenience function for creating a button that displays the modal.
            */
            return $("<button>", {type: "button", text: cur_label})
               .attr("data-toggle", "modal")
               .attr("data-target", id_sel);
         },
         link: function(cur_label){
            /* link
               Convenience function for creating a link that displays the modal.
            */
            return $("<a>", {href: "#", text: cur_label})
               .attr("data-toggle", "modal")
               .attr("data-target", id_sel);
         }
      };
   };
   
   hef.validate = function(){
      /* validate
         Convenience functions for validating values against options.
         Currently supports:
         - Select Input
         - Radio Input
         
         validate is an IIFE that returns the Object: "me"
      */
      var me = {};
      
      me.select = function(iid, val){
         return $(iid).find("option")
            .map(function(){return $(this).val();})
            .get().indexOf(val) > -1;
      };
      me.radio = function(iid, val){
         return $(iid).find("input")
            .map(function(){return $(this).attr("value");})
            .get().indexOf(val) > -1;
      };
      
      return me;
   }();
   
   hef.findkind = function(sel, kind){
      return sel.find("[data-kind=" + JSON.stringify(kind) + "]");
   };
   hef.getval = function(sel){
      /* getval
         Convenience function for retrieving values from inputs.
         Detects recognised inputs and returns value.
      */
      
      if(!(sel instanceof jQuery)){sel = $(sel);}
      if(sel.is("input[type='checkbox']")){
         return sel.is(":checked");
      } else if(sel.hasClass("shiny-input-radiogroup")){
         return sel.find(":checked").val();
      } else if(sel.hasClass("insel-con")){
         return hef.BetterCSVs.panel.inselValue(sel);
      } else{
         return sel.val();
      }
   };
   hef.upval = function(sel, val){
      /* upval
         Convenience function for setting values to inputs.
         Detects recognised inputs and sets value.
      */
      
      if(!(sel instanceof jQuery)){sel = $(sel);}
      if(sel.is("input[type='checkbox']")){
         sel.prop("checked", val).change();
      } else if(sel.hasClass("shiny-input-radiogroup")){
         if(Array.isArray(val)){val = val[0];}
         sel
            .find("input[value=" + JSON.stringify(val) + "]")
            .prop("checked", true)
            .change();
      }
   };
   hef.getlabel = function(sel){
      /* getlabel
         Convenience function for retrieving label from input options.
         Detects recognised inputs and returns value.
      */
      
      if(sel.hasClass("shiny-input-radiogroup")){
         return sel.find(":checked").siblings("span")
            .text()
            .replace(/\s{2,}/g, " ");
      }
   };
   hef.upinp = function(sel, opts, presel){
      /* upinp
         Convenience function for updating options for inputs.
         Detects recognised inputs and runs update.
      */
      
      if(sel.hasClass("shiny-input-radiogroup")){
         // Remove previous values
         sel.find(".radio").remove();
         
         // Add new values
         sel.find(".shiny-options-group").append(opts.map(function(x){
            return $("<div>", {"class": "radio"}).append($("<label>")
               .append($("<input>", {
                  type: "radio",
                  name: sel.attr("id"),
                  value: x
               }))
               .append($("<span>").append(x))
            );
         }));
         
         // Handle presel
         if(presel !== undefined){
            if(presel.map === undefined){
               presel = [presel];
            }
            hef.upval(sel, presel.map(function(x){
               if(Number(x) === x){
                  /* If a number, grab corresponding option */
                  return opts[x];
               }
               return x
            }));
         }
      }
      if(sel.hasClass("insel-con")){
         var panel = hef.BetterCSVs.panel;
         var inlist = panel.inlistGet(sel);
         if(inlist.hasClass("inlist-multi")){
            panel.inlistMulti.update(inlist, opts, presel);
            panel.inlistToggle(inlist, true);
         }
      }
   };
   
   hef.queue = function(){
      /* queue
         Convenience functions for setting and retrieving data-queue attribute.
         This queue can be used to "queue" up a value, e.g. to specify a value
          to set, for an input that is about to be updated.
         Only 1 value can be queued at a time. If another is set, the previous
          value is overwritten with no warning.
         These functions only set and retrieve the queue value,
          nothing more, nothing less.
         
         queue is an IIFE that returns the Object: "me"
      */
      var me = {};
      
      me.set = function(sel, val){
         /* set
            Set the given value to the "data-queue" attribute of the
             given selection. The value is stringified for protection.
         */
         sel.attr("data-queue", JSON.stringify(val));
      };
      
      me.get = function(sel, clear){
         /* get
            Retrieve the "data-queue" value.
            Parse the value, if a valid value is found.
            The "clear" argument can be used to define if the value should
             be cleared or not after retrieval.
         */
         /* by default, clear after retrieval */
         if(clear === undefined){
            clear = true;
         }
         
         var val = sel.attr("data-queue");
         if(val !== undefined){
            val = JSON.parse(val);
            if(val === null){
               val = undefined;
            }
            if(clear){
               sel.removeAttr("data-queue");
            }
         }
         return val;
      };
      
      return me;
   }();
   
   hef.BetterCSVs = function(){
      /* BetterCSVs
         Companion JS component to the R environment BetterCSVs.
         
         There are four main components:
         1) "dstore"    - Handling the Shiny message containing dataset info
         2) "upvars"    - Updating the variable select input
         3) "cond"      - Handling of the conditions input
         4) "imexport"  - Handling the Import/Export of the current query
         5) "panel"     - Handling of the custom input side-panel
         
         BetterCSVs is an IIFE that returns the Object: "me"
      */
      var me = {};
      
      var baseid = "BetterCSVs";
      var makeid = function(x){return "#" + baseid + "_" + x;};
      me.makeid = makeid;
      var makeid_bare = function(x){return baseid + "_" + x;};
      
      /* Wrapper for retrieving currently selected dataset name */
      var get_dname = function(){
         return hef.getval($(makeid("dname")));
      };
      var prev_dname;
      /* More wrappers for retrieving other inputs */
      var get_datekind = function(){
         return hef.getval($(makeid("datekind")));
      };
      var get_dvars = function(){
         return hef.getval($(makeid("dvars")));
      };
      var get_seas = function(){
         return hef.getval($(makeid("seas")));
      };
      var get_title = function(){
         return hef.getval($(makeid("title")));
      };
      var get_subtitle = function(){
         return hef.getval($(makeid("subtitle")));
      };
      
      /* Standard strings */
      var str_nodata = "NO DATA SELECTED";
      var str_empty = "NO SELECTION";
      var str_novar = "INVALID VARIABLE SELECTED";
      var str_retrieve = "RETRIEVING DATA...";
      var str_datevar = "Date";
      
      var dstore = function(){
         /* dstore
            Handles the Shiny message containing dataset info.
            Provides accessor functions for getting and setting
             values from/to the store.
            
            dstore is an IIFE that returns the Object: "out"
         */
         var out = {};
         var store = {};
         
         out.valid = function(dname){
            /* valid
               Check for validity of given dname.
               If valid, return true.
               Else, return a string describing the failure.
            */
            var dobj = store[dname];
            if(dobj === undefined){
               if(dname === str_nodata){
                  return str_nodata;
               } else{
                  return str_retrieve;
               }
            } else{
               return true;
            }
         };
         
         out.get = function(dname, type){
            /* get
               Retrieve a specific element, from the given
                dataset, from the store.
               If no such dataset exists in the store, return
                the validity failure type, which will essentially be
                a warning message, either:
                the "NO DATA" message (if the dataset is also NO DATA)
                or the "RETRIEVING DATA" message, under the assumption
                 that the data actually exists but we're waiting to
                 receive a message from the Shiny server.
            */
            
            var dvalid = out.valid(dname);
            if(dvalid === true){
               return store[dname][type];
            } else{
               return [dvalid];
            }
         };
         
         out.set = function(dname, type, val){
            /* set
               The opposite of get. Set the value of a specific
                element, for the given dataset, in the store.
            */
            if(store[dname] !== undefined){
               store[dname][type] = val;
            }
         };
         
         out.handleMessage = function(msg){
            console.log("Message received for " + msg.dname);
            
            /* Save message contents to "store" */
            store[msg.dname] = msg;
            
            /* If the message dname matches the current dname,
                we can assume user was waiting on "RETRIEVING DATA".
               So now that we have the data, we force an update
                of the variable input. */
            if(get_dname() === msg.dname){
               me.upvars(msg.dname);
            }
         };
         
         return out;
      }();
      me.dstore = dstore;
      /* Create convenience wrappers for getting/setting things from/to dstore */
      var get_vnames = function(dname){
         return dstore.get(dname, "vnames");
      };
      var get_vnames_wdates = function(dname){
         var vnames = get_vnames(dname);
         
         if(dstore.valid(dname) === true){
            var vdates = dstore.get(dname, "vdates");
            vnames = vdates.concat(vnames);
         }
         
         return vnames;
      };
      var get_vvals = function(dname, vname){
         var vvals = dstore.get(dname, "vvals")[vname];
         if(vvals === undefined){
            vvals = [str_novar];
         }
         return vvals;
      };
      var get_presel = function(dname){
         return dstore.get(dname, "presel");
      };
      var set_presel = function(dname, val){
         dstore.set(dname, "presel", val);
      };
      
      me.upvars = function(dname){
         /* upvars
            Update the variable select input to match the
             given dname (dataset name).
            Procedure:
            1) Get the variable names and any previous selections
            2) Get the variable input
            3) Save previous selection (if applicable)
                and the previous dname
            4) Update the variable input
            5) Refresh any conditions
         */
         var vnames = get_vnames(dname);
         var presel = get_presel(dname);
         var insel = $(makeid("dvars"));
         
         /* save previous selection */
         if(prev_dname !== dname){
            set_presel(prev_dname, hef.getval(insel));
         }
         prev_dname = dname;
         
         /* check for data-queue */
         if(dstore.valid(dname) === true){
            var dqueue = hef.queue.get(insel);
            if(dqueue !== undefined){
               // data-queue overrides any presel
               presel = dqueue;
            };
         }
         
         /* update input */
         hef.upinp(insel, vnames, presel);
         insel.attr("data-dname", dname);
         
         /* refresh conditions */
         me.cond.filwell.hide();
         me.cond.refresh();
      };
      
      me.panel = function(){
         /* panel
            Handles necessary js for the custom input side-panel.
            Terminology:
            inpanel  - input panel container
            inhead   - input panel heading
            insel    - input selected values div
            inlist   - input list
            
            "inhead" is generally fixed and is the label for an input.
            
            "insel" contains "<button>" elements that denote what
             values are currently selected.
            For single-value input, this is purely a display feature.
            For multiple-value input, this is the true input.
            
            "inlist" contains the list of valid values for the user
             to make their selection.
            For single-value input, this is a radio group and is
             the true input.
            For multi-value input, this is a list of buttons that
             add/remove values to/from "insel".
            
            panel is an IIFE that returns the Object: "out"
         */
         var out = {};
         
         /* Define attribute/class names */
         var attrMaxItems = "data-max-items";
         var classSel = "list-group-item-selected";
         
         out.inselGet = function(sel){
            /* inselGet
               Given a child of an inpanel, finds and returns the insel
            */
            if(!(sel instanceof jQuery)){sel = $(sel);}
            return sel
               .parents(".inpanel")
               .children(".insel-con");
         };
         out.inlistGet = function(sel){
            /* inlistGet
               Given a child of an inpanel, finds and returns the inlist
            */
            if(!(sel instanceof jQuery)){sel = $(sel);}
            return sel
               .parents(".inpanel")
               .children(".inlist");
         };
         var inselGet = out.inselGet;
         var inlistGet = out.inlistGet;
         
         out.inselUpdate = function(sel, val, label){
            /* inselUpdate
               Used when there is a single selected value in insel.
               Simply update button text (vs remove+add).
            */
            if(label === undefined){label = val;}
            sel.find("button.insel")
               .attr("value", val)
               .text(label)
               .trigger("change");
         };
         var inselector = function(val){
            return "button.insel[value=" + JSON.stringify(val) + "]";
         }
         out.inselAdd = function(sel, val, label){
            /* inselAdd
               Add a new selection to insel.
               If there are any "empty" selections in insel,
                instead of adding a new button, the "empty" button is updated.
            */
            if(label === undefined){label = val;}
            var insel_empty = sel.find(inselector(str_empty));
            
            if(insel_empty.length > 0){
               out.inselUpdate(sel, val, label);
            } else{
               $("<button>", {type: "button", class: "btn insel"})
                  .attr("value", val)
                  .text(label)
                  .appendTo(sel);
               sel.trigger("change");
            }
         };
         out.inselRm = function(sel, val){
            /* inselRm
               Remove a selection from insel.
               If there is only 1 selection remaining, update
                this to an "empty" selection instead.
            */
            var insel_count = sel.find("button.insel").length;
            if(insel_count === 1){
               out.inselUpdate(sel, str_empty);
            } else{
               sel.find(inselector(val)).remove();
               sel.trigger("change");
            }
         };
         out.inselRmAll = function(sel){
            /* inselRmAll
               Convenience function for removing the entire selection
                from insel. An empty selection is then added back in.
               Height css is also reset.
            */
            sel.find("button.insel").remove();
            out.inselAdd(sel, str_empty);
            sel.css("height", "").trigger("change");
         };
         out.inselValue = function(sel){
            /* inselValue
               Return an array of all selected values.
            */
            return sel.find("button.insel")
               .not(inselector(str_empty))
               .map(function(){return $(this).attr("value");})
               .get();
         };
         
         out.inlistToggle = function(){
            /* inlistToggle
               Function to show/hide inlist.
               Two local functions handle most of the work.
               Main function is defined at the end.
            */
            
            /* Define functions to show/hide
               These are used in the main function */
            var tshow = function(target){
               var sel = $(target);
               sel.animate(
                  {height: target.scrollHeight},
                  {
                     start: function(){
                        /* undo visibility/aria-hidden settings */
                        sel
                           .css("visibility", "")
                           .removeAttr("aria-hidden");
                     },
                     complete: function(){
                        /* undo visibility/aria-hidden settings again
                           to be safe */
                        sel
                           .css({visibility: "", height: ""})
                           .removeAttr("aria-hidden");
                     }
                  }
               );
            };
            var thide = function(target){
               var sel = $(target);
               sel.animate(
                  {height: 0},
                  {
                     complete: function(){
                        /* set visibility hidden to prevent tabbing
                           aria-hidden set for similar reasons */
                        sel
                           .css("visibility", "hidden")
                           .attr("aria-hidden", true);
                     }
                  }
               );
            };
            
            /* Main function */
            return function(target, inlistShow){
               /* By default, the function toggles between show/hide.
                  But if "inlistShow === true", this forces a show.
                  Vice versa, a "false" will force a hide. */
               var inlist = inlistGet(target);
               inlist.each(function(i, x){
                  if($(x).attr("data-inlist") !== "never-toggle"){
                     if(inlistShow === undefined){
                        inlistShow = x.scrollHeight > 0 &&
                           x.clientHeight !== x.scrollHeight;
                     }
                     if(inlistShow){
                        tshow(x);
                     } else{
                        thide(x);
                     }
                  }
                  
                  /* If inlistMulti, we also set insel height.
                     This is so that insel height does not change as the
                     user adds/removes items (which would consequently
                     move the inlist elements up/down, which is very
                     annoying), but as it is set every toggle, the height
                     is updated eventually to its correct height. */
                  if($(x).hasClass("inlist-multi")){
                     var insel = inselGet(x);
                     var inselh = insel[0].scrollHeight;
                     if(inselh > 0){insel.animate({height: inselh});}
                  }
               });
            };
         }();
         
         out.inlistRadio = function(){
            /* inlistRadio
               Handles the selection of a new item for an inlist radio-group.
               Process is:
               1) Get required values
               2) Update insel
               3) Hide the inlist
               4) Remove selection-css from previous selection(s)
               5) Add selection-css to current selection
            */
            var sel = $(this);
            var val = hef.getval(sel);
            var label = hef.getlabel(sel);
            var insel = inselGet(sel);
            var sel_label = sel.find(":checked").parent("label");
            out.inselUpdate(insel, val, label);
            out.inlistToggle(sel, false);
            
            sel.find("." + classSel)
               .removeClass(classSel);
            sel_label.addClass(classSel);
         };
         
         out.inlistMulti = function(){
            /* inlistMulti
               Handles all required processes to turn a multi-select inlist
                into an input, similar to a checkbox group.
               A custom input is used (instead of a built-in like
                checkbox-group) for greater customisation.
               
               inlistMulti is an IIFE that returns the Object: "me"
            */
            var me = {};
            
            me.update = function(target, opts, presel){
               /* update
                  Update the given inlistMulti with new options.
                  If any "presel" is given, these options are pre-selected.
               */
               
               /* clear previous */
               target.children("button.list-group-item").remove();
               out.inselRmAll(inselGet(target));
               
               /* add new */
               opts.forEach(function(x){
                  $("<button>", {
                     type: "button",
                     class: "list-group-item",
                     value: x
                  }).append($("<span>", {class: "glyphicon glyphicon-unchecked"}))
                     .append(" ")
                     .append($("<span>", {type: "value", text: x}))
                     .appendTo(target);
               });
               
               /* presel */
               if(presel !== undefined){
                  if(presel.map === undefined){
                     presel = [presel];
                  }
                  
                  presel.map(function(x){
                     if(Number(x) === x){
                        /* If a number, grab corresponding option */
                        return opts[x];
                     }
                     return x
                  }).forEach(function(x){
                     me.add(me.find(target, x));
                  });
               }
               
               target.trigger("update");
            };
            me.find = function(inlist, val){
               /* find
                  Convenience wrapper to find item with given value.
               */
               return inlist.find("button[value=" + JSON.stringify(val) + "]")[0];
            };
            
            me.add = function(target){
               /* add
                  add/select the given item to the selection, subject to
                   max-item cap (if any)
               */
               var val = $(target).attr("value");
               var insel = inselGet(target);
               var insel_max = insel.attr(attrMaxItems);
               var insel_count = insel.find("button.insel").length;
               if(insel_max === undefined || insel_count < insel_max){
                  out.inselAdd(insel, val);
                  $(target).addClass(classSel);
                  $(target).children("span.glyphicon-unchecked")
                     .removeClass("glyphicon-unchecked")
                     .addClass("glyphicon-check");
               }
            };
            
            me.rm = function(target){
               /* rm
                  remove/unselect the given item from the selection
               */
               var val = $(target).attr("value");
               var insel = inselGet(target);
               out.inselRm(insel, val);
               $(target).removeClass(classSel);
               $(target).children("span.glyphicon-check")
                  .removeClass("glyphicon-check")
                  .addClass("glyphicon-unchecked");
            };
            
            me.click = function(){
               /* click
                  click handler
               */
               if($(this).hasClass(classSel)){
                  me.rm(this);
               } else{
                  me.add(this);
               }
            };
            
            me.autovis = function(){
               /* autovis
                  handler for automatic hiding of inlist
               */
               var sel = $(this);
               sel.on("mouseleave.inselMultiVis", function(){
                  var to = setTimeout(function(){
                     out.inlistToggle(sel, false);
                     sel.off("mouseenter.inselMultiVis");
                  }, 2100);
                  sel.on("mouseenter.inselMultiVis", function(){
                     clearTimeout(to);
                     sel.off("mouseenter.inselMultiVis");
                  });
               });
            };
            
            return me;
         }();
         
         out.init = function(){
            /* Bind inlistToggle */
            $(".inpanel").on("click.inlistToggle",
               ".panel-heading, .panel-body",
               function(){out.inlistToggle(this);}
            );
            
            /* Bind inlistRadio */
            $(".inpanel .shiny-input-radiogroup")
               .on("change.inselUpdate", out.inlistRadio)
               .each(out.inlistRadio);
            /* Bind inlistMulti */
            $(".inpanel .inlist-multi")
               .on("click.inselMulti",
                  "button.list-group-item",
                  out.inlistMulti.click
               )
               .each(out.inlistMulti.autovis);
            
            /* Clear text nodes (whitespace introduced by shiny) for .insel-con
               (otherwise it can result in inconsistent spacing between insel buttons) */
            $(".insel-con")
               .contents()
               .filter(function(){return this.nodeType === Node.TEXT_NODE})
               .remove();
            
            /* Show all inlist to begin with */
            out.inlistToggle($(".inlist"), true);
            
            /* Make dvars insel into a Shiny Input */
            $(makeid("dvars")).on("change", function(){
               Shiny.onInputChange(
                  makeid_bare("dvars"),
                  out.inselValue($(this))
               );
            });
            
            /* Activate any panel-heading tooltips */
            $(".panel-heading[title]").tooltip({placement: "right"});
         };
         
         return out;
      }();
      
      me.cond = function(){
         /* cond
            Handles:
               1) Creation and removal of conditions.
               2) Condition selection interface ("filwell").
               3) Collection, packaging and messaging of conditions to Shiny.
            Due to legacy code that never got a chance to go through a code-refactor,
             naming conventions are inconsistent.
            "Conditions" were rebranded "Filters", and code written since the
             rebranding (mainly "filwell") use the new naming, while legacy code
             and most references still use "cond".
            Because of this, "condition" and "filter" should be considered
             equivalent and interchangeable in the documentation.
            
            Each condition is stored in a "container", and is comprised of
             three components:
               1) Variable - Variable to condition
               2) Type     - Condition type magic-word
               3) Value    - Values to apply condition to
            `out.add` is used to create such a container, while
            `out.rm` and `out.rmAll` are used to remove containers.
            
            A specialised interface, "filwell", is used to select/change
             these three components.
            `fillwell.show($(container))` is used to open up an interface linked
             to the given container.
            As the filwell interface is used to alter the condition, the components
             of the container are updated automatically.
            `out.set` can be used to set a condition programmatically, bypassing the ui.
            
            Ultimately, valid conditions from the containers are collected and sent
             as a stringified JSON to Shiny for use.
            `out.send` is the function that handles this.
            
            cond is an IIFE that returns the Object: "out"
         */
         var out = {};
         var cond_types = ["CONTAINS", "DOES NOT CONTAIN"];
         var cond_types_date = ["EQUALS", "AFTER", "BEFORE"];
         
         var filwell = function(){
            /* filwell
               Handles the functionality for the specialised interface for
                selecting/changing filter settings.
               The ui itself is mostly defined in the shiny ui code.
               
               filwell is an IIFE that returns the Object: "fil"
            */
            var fil = {};
            
            var up_vvals = function(){
               /* up_vvals
                  Update the variable values input, i.e. the input
                   where you choose which values within the selected
                   variable to condition for.
                  This function is bound to an onchange event for the
                   variable input, so that when the variable is changed,
                   the values are updated to match that variable.
                  If a value is queued (via `hef.queue`), then this
                   queued value is set.
               */
               
               var dname = $(this).attr("data-dname");
               var vname = hef.getval($(this));
               var vvals;
               
               /* Handle queued data */
               var presel_type, presel_vvals;
               if([null, "", str_nodata, str_retrieve].indexOf(vname) === -1){
                  presel_type = hef.queue.get(fil.refs.condtype);
                  presel_vvals = hef.queue.get(fil.refs.condval);
               }
               if(presel_type === undefined){
                  presel_type = 0;
               }
               
               /* get appropriate values */
               if([null, "", str_nodata].indexOf(vname) > -1){
                  vvals = [str_nodata];
               } else{
                  vvals = get_vvals(dname, vname);
               }
               
               hef.upinp(fil.refs.condval, vvals, presel_vvals);
            };
            
            fil.update = function(selcon){
               /* update
                  Retrieve the current filter settings then set
                   the filwell components to the same values.
               */
               var dname = selcon.attr("data-dname");
               var vnames = get_vnames_wdates(dname);
               
               /* Retrieve values in selcon */
               var prevar = hef.findkind(selcon, "var").val();
               if(["", str_retrieve].indexOf(prevar) > -1){prevar = 0;}
               var pretype = hef.findkind(selcon, "type").val();
               if(pretype === ""){pretype = cond_types[0];}
               var preval = hef.findkind(selcon, "val").val();
               if(preval !== ""){
                  hef.queue.set(fil.refs.condval, JSON.parse(preval));
               }
               
               fil.refs.condvar.attr("data-dname", dname);
               hef.upinp(fil.refs.condvar, vnames, prevar);
               if(prevar === 0){
                  me.panel.inlistToggle(fil.refs.condvar, true);
               }
               hef.upval(fil.refs.condtype, pretype);
            };
            
            fil.show = function(selcon){
               /* show
                  Show the filwell interface and link it to the given
                   filter container.
               */
               fil.refs.con = selcon;
               // Save current filter settings in case user wants to cancel
               fil.refs.prev = out.get(selcon);
               
               /* un-link previous */
               ["condvar", "condtype", "condval"].forEach(
                  function(x){fil.refs[x].off("change.link");}
               );
               
               /* link to current
                  This is what keeps the container in-sync with the filwell
               */
               fil.refs.condvar.on("change.link", function(){
                  var curval = hef.getval(this);
                  set_filsel(selcon, "var", curval);
               });
               fil.refs.condtype.on("change.link", function(){
                  var curval = hef.getval(this);
                  set_filsel(selcon, "type", curval);
               });
               fil.refs.condval.on("change.link", function(){
                  var curval = hef.getval(this);
                  set_filsel(selcon, "val", curval);
               });
               
               /* update */
               fil.update(selcon);
               
               /* visibility */
               fil.sel.animate({left: 280}, 500);
               
               /* scrolling */
               var page = $("html");
               var seltop = fil.sel.offset().top;
               if(page.scrollTop() > seltop){
                  page.animate({scrollTop: seltop}, 500, "linear");
               }
            };
            
            fil.cancel = function(){
               /* cancel
                  Cancel out of current changes, reverting to the
                   original filter settings.
               */
               var selcon = fil.refs.con;
               var prev = fil.refs.prev;
               
               if(prev !== undefined){
                  out.set(prev[0], selcon);
               } else{
                  set_filsel(selcon, "val", []);
               }
               
               fil.hide();
            };
            
            fil.hide = function(){
               /* hide
                  Perform clean-up and hide the filwell interface.
               */
               fil.sel.animate({left: 0}, 500);
               var inlist = me.panel.inlistGet(fil.refs.condvar);
               me.panel.inlistToggle(inlist, false);
               var inlist = me.panel.inlistGet(fil.refs.condval);
               inlist.find(".list-group-item").remove();
               fil.refs.prev = undefined;
            };
            
            fil.search = function(){
               /* search
                  Handles the search functionality for the condval input
               */
               
               // For literal strings, need to escape special characters
               var escape_re = function(){
                  var to_escape = /[.*+?^${}()|[\]\\]/g;
                  var escape_to = "\\$&";
                  return function(str){
                     return str.replace(to_escape, escape_to);
                  };
               }();

               // Return a function to test the regular expression
               // Handles show/hide, along with search-highlighting
               var test_rex = function(rex){
                  return function(){
                     var sel = $(this);
                     var val = sel.val();
                     var seltext = sel.find('span[type="value"]');
                     if(!rex.test(val)){
                        sel.css("display", "none");
                     } else{
                        sel.css("display", "");
                     }
                     seltext.html(val.replace(rex, '<span class="search-text">$&</span>'));
                  };
               };
               
               var oninput = function(inlist){
                  /* Returns the function to apply the search of the given
                     inlist, that is bound to .on("input") of the search box.
                  */
                  return function(){
                     var sstr = this.value;
                     var seach;
                     
                     // Check for special commands
                     if(sstr === "<selected>"){
                        // Return all currently selected values
                        seach = function(){
                           if($(this).hasClass("list-group-item-selected")){
                              $(this).css("display", "");
                           } else{
                              $(this).css("display", "none");
                           }
                        }
                     } else{
                        // A real search
                        if(sstr.charAt(0) === "/" &&
                           sstr.charAt(sstr.length - 1) === "/"){
                           // Regular Expression
                           var sstr = sstr.slice(1, sstr.length - 1);
                           var rex;
                           try{
                              rex = new RegExp(sstr, "i");
                           } catch(e){
                              rex = new RegExp(escape_re(sstr), "i");
                           }
                           seach = test_rex(rex);
                        } else{
                           // Literal, need to escape
                           sstr = escape_re(sstr);
                           seach = test_rex(new RegExp(sstr, "i"));
                        }
                     }
                     
                     inlist.find("button.list-group-item").each(seach);
                  };
               };
               
               return function(insel){
                  /* Given the condval input selection (insel), insert
                     the search box ui and bind the necessary events.
                  */
                  var inlist = me.panel.inlistGet(insel);
                  var insearch = $("<div>", {class: "has-feedback"})
                     .append($("<input>", {
                        type: "text",
                        placeholder: "Search for specific criteria",
                        class: "form-control search-box"
                     }))
                     .append($("<span>", {
                        class: "glyphicon glyphicon-filter form-control-feedback",
                        "aria-hidden": "true"
                     }))
                     .insertBefore(inlist);
                  var searchinput = insearch.children("input");
                  inlist.on("update.search", function(){searchinput.val("");});
                  
                  searchinput.on("input.search", oninput(inlist));
                  insel.on("click.search", ".filsel", function(){
                     searchinput.val("<selected>").trigger("input");
                  });
               };
            }();
            
            fil.init = function(refs){
               /* init
                  "refs" is passed from `cond.init` and is an Object that contains:
                  - "selwell" - selection of filwell
                  - "condvar"  - selection of condvar  ui
                  - "condtype" - selection of condtype ui
                  - "condval"  - selection of condval  ui
                  
                  Take these selections, find some additional selections we need,
                   then bind various event handlers.
               */
               fil.refs = refs;
               fil.sel = refs.selwell;
               fil.sel.find("button.btn-ok").on("click.condok", fil.hide);
               fil.sel.find("button.btn-cancel").on("click.condcan", fil.cancel);
               fil.sel.find("button.btn-delete").on("click.conddel", function(){
                  out.rm(fil.refs.con);
                  fil.hide();
               });
               refs.condvar.on("change.condvar", up_vvals);
               
               /* When insel is added, need to add filsel class for styling */
               refs.condval.on("change.filsel", function(){
                  $(this).find(".insel").not(".filsel").addClass("filsel");
               });
               
               fil.search(refs.condval);
            };
            
            return fil;
         }();
         out.filwell = filwell;
         
         var create_filsel = function(kind){
            /* create_filsel
               Create a new "filsel", a button which holds one of the
                components of a filter (depending on the "kind").
               Use `set_filsel` when changing the value of a "filsel".
            */
            return $("<button>", {
               type: "button",
               class: "btn insel filsel",
               "data-kind": kind
            }).text("Initialising")
         };
         var set_filsel = function(con, kind, val, send){
            /* set_filsel
               Update the value of a "filsel" with the given value.
               The "filsel" itself is not passed to this function, instead
                the container ("con"), and the type of filsel ("kind") are
                used to identify the correct filsel to update.
               All kinds except "val" are of length 1, so both the value and
                the visible text are the same.
               For kind "val", as this is an Array, it must be converted to
                a single-length string. For the value, this is done via
                `JSON.stringify`, for the visible text, we just use a join.
            */
            var vtext;
            if(kind === "val"){
               if(val.length === 0){
                  vtext = str_empty;
               } else{
                  vtext = val.join(", ");
               }
               val = JSON.stringify(val);
            } else{
               vtext = val;
            }
            hef.findkind(con, kind)
               .val(val)
               .text(vtext);
            
            if(send !== false){
               out.send();
            }
         };
         
         out.add = function(silent){
            /* add
               Add a new condition container.
               If silent !== true, the ui to change the condition
                is opened automatically.
               Returns the newly created container.
            */
            
            var dname = get_dname();
            var con = $("<div>", {
                  class: "filsel-con",
                  "data-dname": dname
               })
               .on("click.filsel", function(){filwell.show($(this));})
               .insertBefore(out.addcon);
            
            con
               .append(create_filsel("var"))
               .append(create_filsel("type"))
               .append(create_filsel("val"));
            
            /* Mark if retrieve-type.
               It will then get updated during a `refresh` to the real options.
            */
            if(dstore.valid(dname) === str_retrieve){
               con.attr("data-retrieve", "true");
            }
            
            /* toggle button */
            togglebtn.make()
               .appendTo(con)
               .on("click.toggle", togglebtn.click(con));
            
            /* finish */
            if(silent !== true){
               con.click();
               me.panel.inlistToggle($(".inwell").find(".inlist"), false);
            }
            
            return con;
         };
         
         out.disable = function(con, send){
            /* disable
               Set the "data-disable" attribute, which the other
                functions use to tell if a condition should be disabled.
               Only the existence of the attribute is currently checked,
                so the value does not matter.
            */
            con.attr("data-disable", "disable");
            if(send !== false){
               out.send();
            }
         };
         out.enable = function(con, send){
            /* enable
               Clear the "data-disable" attribute.
            */
            con.removeAttr("data-disable");
            if(send !== false){
               out.send();
            }
         };
         
         var togglebtn = function(){
            /* togglebtn
               Handles the functionality for the toggle filter button,
                that enables users to easily toggle a filter on/off.
               
               togglebtn is an IIFE that returns the Object: "tob"
            */
            var tob = {};
            
            tob.disable = function(con, send){
               /* disable
                  Make the necessary ui changes, then
                   call `out.disable`.
               */
               var btn = con.find(".filsel-toggle");
               btn
                  .attr("title", btn.attr("data-title-enable"))
                  .removeClass("filsel-disable")
                  .addClass("filsel-enable")
                  .children("i")
                     .removeClass("glyphicon-ok-circle")
                     .addClass("glyphicon-ban-circle");
               out.disable(con, send);
            };
            
            tob.enable = function(con, send){
               /* enable
                  Make the necessary ui changes, then
                   call `out.enable`.
               */
               var btn = con.find(".filsel-toggle");
               btn
                  .attr("title", btn.attr("data-title-disable"))
                  .removeClass("filsel-enable")
                  .addClass("filsel-disable")
                  .children("i")
                     .removeClass("glyphicon-ban-circle")
                     .addClass("glyphicon-ok-circle");
               out.enable(con, send);
            };
            
            tob.click = function(con){
               /* click
                  Returns the onclick function to bind to the button,
                   for the given container.
               */
               return function(e){
                  e.stopPropagation();
                  var to_disable = $(this).hasClass("filsel-disable");
                  
                  if(to_disable){
                     tob.disable(con);
                  } else{
                     tob.enable(con);
                  }
               };
            };
            
            tob.make = function(){
               /* make
                  Create the ui button element.
                  This function just creates the element. It's `out.add`
                   that actually uses this to add the button to a
                   condition container and bind the events.
               */
               return $("<button>", {
                  type: "button", class: "filsel-toggle filsel-disable",
                  "title": "Disable filter",
                  "data-title-enable": "Enable filter",
                  "data-title-disable": "Disable filter"
               }).append($("<i>", {class: "glyphicon glyphicon-ok-circle"}));
            };
            
            return tob;
         }();
         out.togglebtn = togglebtn;
         
         out.set = function(cond, con){
            /* set
               Set the given condition, to the given condition container (if supplied)
                or to a newly created condition container.
               The condition should be of the same form produced by `collect`,
                that is, an Object containing "vname", "vtype" and/or "vvals".
               Incomplete conditions (with missing entries) are accepted.
            */
            if(con === undefined){
               con = out.add(true);
               con.removeAttr("data-retrieve");
            }
            
            set_filsel(con, "var", cond.vname, false);
            set_filsel(con, "type", cond.vtype, false);
            set_filsel(con, "val", cond.vvals, false);
            if(cond.disable === true){
               togglebtn.disable(con, false);
            } else{
               togglebtn.enable(con, false);
            }
            out.send();
            
            return con;
         };
         
         out.rm = function(con){
            /* rm
               Remove the given condition container.
            */
            con.remove();
            
            out.send();
         };
         
         out.rmAll = function(dname){
            /* rmAll
               Remove all conditions (if no arguments supplied),
               OR remove all conditions relating to the specific dname.
            */
            out.getcons(dname).remove();
            
            // Send a message to update Shiny's record of conditions
            out.send();
         };
         
         out.get = function(con){
            /* get
               Retrieve the condition values from the given container.
               If the condition is invalid, returns undefined.
               Otherwise, returns an Array containing an Object.
            */
            var vname = hef.findkind(con, "var").val();
            if(vname === ""){return;}
            var vtype = hef.findkind(con, "type").val();
            if(vtype === ""){return;}
            
            var vvals = JSON.parse(hef.findkind(con, "val").val());
            if(vvals.length === 0){return;}
            
            var res = {vname: vname, vtype: vtype, vvals: vvals};
            
            if(con.attr("data-disable") !== undefined){
               res.disable = true;
            }
            
            return [res];
         };
         
         out.collect = function(only_enabled){
            /* collect
               Collect all valid conditions.
               Procedure:
               1) Get all condition containers for the given dataset.
               2) Retrieve all valid conditions from the containers.
               3) Collect the valid conditions into a single Array
                   (with undefined values discarded automatically)
               4) If the Array is of length 0 (i.e. no valid conditions),
                  then set to null
            */
            var dname = get_dname();
            var all_conds = out.getcons(dname)
               .map(function(){return out.get($(this));})
               .get();
            
            if(only_enabled === true){
               all_conds = all_conds.filter(function(x){return x.disable !== true;});
            }
            
            if(all_conds.length === 0){all_conds = null;}
            
            return all_conds;
         };
         
         out.send = function(){
            /* send
               Call `collect` and use it to send a message to Shiny.
               Procedure:
               1) Call `collect`
               2) Stringify the returned Array to JSON, to protect the data
                  structure from processing by Shiny's own methods
               3) Send as a character string to Shiny
            */
            var all_conds = out.collect(true);
            
            /* Send message to Shiny */
            Shiny.onInputChange(makeid_bare("conds"), JSON.stringify(all_conds));
         };
         
         out.refresh = function(){
            /* refresh
               Run a refresh of conditions.
               This has two parts:
               1) Toggle visibility of conditions depending on whether they
                   are applicable to the current dataset or not.
               2) Update any temporary "RETRIEVING" type conditions, to the
                   actual data.
            */
            var dname = get_dname();
            out.getcons().each(function(){
               var sel = $(this);
               
               // Toggle visibility
               var vis = sel.attr("data-dname") === dname;
               if(vis){
                  sel.css("display", "");
               } else{
                  sel.css("display", "none");
               }
               
               // Update if a temporary input
               if(sel.attr("data-retrieve") === "true"){
                  sel.removeAttr("data-retrieve").click();
               }
            });
            
            /* Send a message to update Shiny's record of conditions.
               refresh itself doesn't affect how the conditions
                are collected and processed (that's handled by `collect`)
                but if a refresh is needed, then Shiny's record of conditions
                probably also need refresh.
            */
            out.send();
         };
         
         out.getcons = function(dname){
            /* getcons
               Returns all condition containers for the given dataset
                (if no dataset name provided, returns all containers).
            */
            var cons = out.addcon
               .parent(".inpanel")
               .children(".filsel-con[data-dname]");
            if(dname !== undefined){
               cons = cons.filter("[data-dname=" + JSON.stringify(dname) + "]");
            }
            return cons
         };
         
         out.init = function(addcon, filrefs){
            out.addcon = addcon;
            addcon.on("click.condadd", out.add);
            
            me.cond.filwell.init(filrefs);
         };
         
         return out;
      }();
      
      me.imexport = function(){
         /* imexport
            Handle Import/Export of the current query.
            
            imexport is an IIFE that returns the Object: "out"
         */
         var out = {};
         
         out.getquery = function(){
            /* getquery
               Collects the relevant input values to construct the query.
            */
            return {
               title: get_title(),
               subtitle: get_subtitle(),
               dname: get_dname(),
               datekind: get_datekind(),
               seas: get_seas(),
               dvars: get_dvars(),
               conds: me.cond.collect()
            };
         };
         
         out.str_title = function(query){
            /* str_title
               When provided with a query, constructs an appropriate
                string using the title and subtitle values.
            */
            var out = undefined;
            if(query.title !== undefined){
               var title = query.title;
               var subtitle = query.subtitle;
               if(title.length > 0){
                  out = title;
               } else{
                  out = query.dname;
               }
               if(subtitle.length > 0){
                  out = out + " " + subtitle;
               }
            }
            return out;
         };
         
         out.qarea = function(){
            /* qarea
               Returns the textarea containing the query.
               This needs to be called when needed, as the textarea itself
                  is removed/created as modal is hidden/shown.
            */
            return out.modal.sel.find(".query-textarea");
         };
         
         out.show = function(){
            /* show
               Display the import/export modal and update the textarea.
            */
            out.qarea().val(JSON.stringify(out.getquery(), null, 2));
         };
         
         out.export = function(curval){
            /* export
               "Export" the current query.
               Essentially a "download textarea contents as text file" function.
               Procedure:
               1) Retrieve current contents of the textarea
               2) Create a download link, containing the text as its data
               3) Append the link, click it, then remove
            */
            if(curval === undefined){curval = out.qarea().val();}
            var cura = $("<a>", {
               style: "display: none;",
               href: "data:text/plain," + curval,
               download: "migration_data_explorer_csv_query"
            }).appendTo(out.modal.sel);
            cura[0].click();
            cura.remove();
         };
         
         out.import = function(curval){
            /* import
               Import the current query (the contents of the textarea).
               Some checks are done to validate the query and provide an error
                message if something is wrong.
               If the query seems valid, it is applied to the input components.
               This process is a little convoluted due to the cascading/updating
                nature of the inputs.
               The variables input (dvars) updates when the dataset input (dname)
                is changed, so the dvars value must be set via a queue first.
               Likewise, the conditions have a few cascading updates, though
                this is handled within the "conds" IIFE itself.
               Procedure:
               1) Retrieve current contents of the textarea
               2) Conduct various validation checks, generating an error
                   message as necessary.
               3) Assuming all validation checks pass, set the "dvars" value
                   via a queue first, then update "dname" and "datekind".
                  The update of "dname" will trigger an update of the "dvars"
                   input, which will pick up the queued value and set it.
               4) Remove any existing conditions (if any).
               5) If there are any conditions to add, add the appropriate
                   number of condition rows.
               6) Loop through each condition row and set it using `cond.set`.
               7) Hide the import/export modal.
            */
            if(curval === undefined){
               var qarea = out.qarea();
               curval = qarea.val();
            }
            var errmarker = "Something went wrong!\n" +
                  "If you received this query from someone, please contact them" +
                  " to let them know the query is invalid.\n\n" +
                  "ERROR MESSAGE\n";
            /* If current "query" is already an error message, don't do anything */
            if(curval.substring(0, errmarker.length) === errmarker){
               return;
            }
            
            /* Parse query */
            var vparse;
            try{
               vparse = JSON.parse(curval);
            } catch(e){
               var errmsg = errmarker + e;
               if(qarea !== undefined){qarea.val(errmsg);}
               return;
            }
            
            /* If valid query */
            if(vparse !== undefined){
               /* Validate dname and datekind */
               if(!hef.validate.radio(makeid("dname"), vparse.dname)){
                  var errmsg = errmarker + "Unrecognised dname!";
                  if(qarea !== undefined){qarea.val(errmsg);}
                  return;
               }
               if(!hef.validate.radio(makeid("datekind"), vparse.datekind)){
                  var errmsg = errmarker + "Unrecognised datekind!";
                  if(qarea !== undefined){qarea.val(errmsg);}
                  return;
               }
               
               /* Set data-queue attribute for dvars */
               hef.queue.set($(makeid("dvars")), vparse.dvars);
               
               /* Set dname and datekind */
               hef.upval($(makeid("dname")), vparse.dname);
               hef.upval($(makeid("datekind")), vparse.datekind);
               hef.upval($(makeid("seas")), vparse.seas);
               
               /* Handle conditions */
               me.cond.rmAll(vparse.dname);
               if(vparse.conds !== null){
                  for(var i = 0; i < vparse.conds.length; i++){
                     me.cond.set(vparse.conds[i]);
                  }
               }
               
               /* Hide all inlist */
               me.panel.inlistToggle($(".inlist"), false);
               
               /* Hide the modal */
               out.modal.hide();
            }
         };
         
         out.makekey = function(x){
            return "mde-save-" + x;
         };
         out.localSave = function(i){
            /* localSave
               Save to localStorage.
            */
            var query = out.getquery();
            var key = out.makekey(i);
            window.localStorage.setItem(key, JSON.stringify(query));
         };
         out.do_localSave = function(){
            /* do_localSave
               Called via a "click" event.
            */
            var irow = $(this).parent("[data-i]")
            var i = irow.attr("data-i");
            out.localSave(i);
            out.refresh_localSave(irow);
         };
         out.get_localSave = function(i){
            /* get_localSave
               Retrieve save details from localStorage.
            */
            var key = out.makekey(i);
            return window.localStorage.getItem(key);
         };
         out.load_localSave = function(){
            /* load_localSave
               Called via a "click" event to get, then load, a save.
            */
            var i = $(this).parent("[data-i]").attr("data-i");
            var query = out.get_localSave(i);
            if(query !== null){
               out.import(query);
            }
            
            /* Hide the modal */
            out.modal.hide();
         };
         out.refresh_localSave = function(irow){
            /* refresh_localSave
               Update UI to reflect current save data.
            */
            var i = irow.attr("data-i");
            var query = out.get_localSave(i);
            if(query === null){
               // No save data
               var txt_load = "" + (Number(i) + 1) + ". " + txt_nosave;
               irow.find("[value='Load']").text(txt_load);
               irow.find("[value='Save']").text("Save");
            } else{
               // Save data exists
               var str_title = out.str_title(JSON.parse(query));
               
               var txt_load = "" + (Number(i) + 1) + ". LOAD: " + str_title;
               irow.find("[value='Load']").text(txt_load);
               irow.find("[value='Save']").text("Overwrite");
            }
         };
         
         var btn_title = "Save/Load Query";
         var txt_import = "To import, paste your query into the text box, " +
            "then press the [Import query as inputs] button.";
         var txt_export = "To export, press the [Export query as a text file] button.";
         var txt_localStorage = "This provides a quick and easy way to save and load queries." +
            " However for reliable long-term storage, or to share your query" +
            " with others, export to a text file instead.";
         var txt_localStorage_where = "The data is kept on your computer in a storage area" +
            " managed by your web browser. As the data is held locally by your browser," +
            " you will not be able to access it if you change browsers or use a different" +
            " computer. Additionally, your save data may be lost if the browser storage is" +
            " cleared for any reason.";
         var txt_nosave = "NO SAVE DATA";
         out.init = function(){
            /* init
               1) Prepare the modal for displaying the query
               2) Populate the modal interface
               3) Create the button that shows the modal (using `out.show`).
            */
            out.modal = hef.make_bmodal(makeid_bare("query-modal"), btn_title);
            out.modal.sel.parents(".modal-dialog").addClass("modal-lg");
            
            /* Construct the modal contents, which is comprised of three parts:
               i)    Description/Instructions
               ii)   Save/Load to localStorage
               ii)   Import/Export to text file
            */
            /* Description/Instructions */
            var div_desc = $("<div>")
               .append($("<p>")
                  .append("There are two options for saving and loading your query.")
               )
               .append($("<ol>")
                  .append($("<li>", {text: "Save/Load to temporary local storage"}))
                  .append($("<li>", {text: "Export to & Import from text file"}))
               );
            
            /* Save/Load to localStorage
               This part is comprised of:
               
            */
            var div_saveload_main = $("<div>", {class: "row-alternating"});
            for(var i = 0; i < 10; i++){
               var currow = $("<div>", {class: "altrow altrow-flex", "data-i": i})
                  .append($("<button>", {
                        class: "btn btn-default", type: "button", value: "Load"
                     }).on("click.saveload", out.load_localSave)
                  )
                  .append($("<button>", {
                        class: "btn btn-default", type: "button", value: "Save"
                     }).on("click.saveload", out.do_localSave)
                  );
               currow.appendTo(div_saveload_main);
               out.refresh_localSave(currow);
            }
            var div_saveload = $("<div>")
               .append($("<h6>")
                  .append("1. Temporary local storage")
               )
               .append($("<p>", {text: txt_localStorage}))
               .append($("<a>", {
                  text: "Where is this data stored?",
                  href: "#bG9jYWxTdG9yYWdl", "data-toggle": "collapse",
                  "aria-expanded": "false", "aria-controls": "collapseExample"
               }))
               .append($("<div>", {id: "bG9jYWxTdG9yYWdl", class: "collapse"})
                  .append($("<div>", {class: "well"})
                     .append($("<p>", {text: txt_localStorage_where}))
                  )
               )
               .append(div_saveload_main);
            
            /* Import/Export to text file
               This part is comprised of:
               i)    A list containing instructions
               ii)   A textarea for the query (populated by `out.show`)
               iii)  A button to export the query (using `out.export`)
               iv)   A button to import the query (using `out.import`) */
            var div_imexport = $("<div>")
               .append($("<h6>")
                  .append("2. Export to & Import from text file")
               )
               .append($("<ul>")
                  .append($("<li>", {text: txt_import}))
                  .append($("<li>", {text: txt_export}))
               )
               .append(
                  $("<textarea>", {class: "query-textarea"})
                     .on("focus.imexport", function(){this.select();})
               )
               .append(
                  $("<button>", {class: "btn btn-default", text: "Export query as a text file"})
                     .on("click.imexport", function(){out.export();})
               )
               .append(
                  $("<button>", {class: "btn btn-default", text: "Import query as inputs", style: "float:right;"})
                     .on("click.imexport", function(){out.import();})
               );
            
            out.modal.sel
               .append(div_desc)
               .append(div_saveload)
               .append(div_imexport);
            
            $(makeid("querybtn-con")).append(
               out.modal.button(btn_title)
                  .addClass("btn btn-default")
                  .on("click.imexport", out.show)
                  .prepend(" ")
                  .prepend($("<span>", {
                     class: "glyphicon glyphicon-floppy-disk",
                     "aria-hidden": true
                  }))
            );
         };
         
         return out;
      }();
      
      me.autosave = function(){
         /* autosave
            Periodically saves the current query to localStorage
              so that it can be restored in the next session.
            In particular, this guards against shinyapps disconnects.
         */
         var out = {};
         var key = me.imexport.makekey("auto");
         
         var delay_ms = 25 * 1000;
         var delay_ms_dc = 3 * 1000;
         
         out.preserve = function(){
            /* preserve
               Save previous query so it doesn't get overwritten.
            */
            out.last_query = window.localStorage.getItem(key);
         };
         
         out.save = function(){
            /* save
               Retrieve current query and save to localStorage.
            */
            var query = me.imexport.getquery();
            if(query.dname !== str_nodata){
               window.localStorage.setItem(key, JSON.stringify(query));
            }
         };
         out.savedc = function(){
            /* savedc
               A special case of `save` that activates on disconnect.
               Once this activates and saves, both repeating timers are stopped.
            */
            var isConnected = Shiny.shinyapp.isConnected();
            if(isConnected === "false"){
               out.stop();
               out.save();
            }
         };
         
         out.load = function(){
            /* load
               Load the query from the previous session.
            */
            return out.last_query;
         };
         
         out.stop = function(){
            /* stop
               Stops all repeating timers.
            */
            clearInterval(out.timer);
            clearInterval(out.timerdc);
         };
         
         out.init = function(){
            out.preserve();
            
            /* Start repeating timer */
            out.timer = window.setInterval(out.save, delay_ms);
            out.timerdc = window.setInterval(out.savedc, delay_ms_dc);
         };
         
         return out;
      }();
      
      me.toggle_ts_type = function(){
         var hc = $(makeid("hc-ts")).highcharts();
         if(hc.options.chart.type === "line"){
            hc.update({
               chart: {type: "area"},
               plotOptions: {area: {stacking: "normal", fillOpacity: 0.3}}
            });
         } else{
            hc.update({chart: {type: "line"}});
         }
      };
      
      me.update_titles = function(){
         /* update_titles
            When user enters customised titles, this handles the
             on-the-fly updates of the titles.
            
            update_titles is an IIFE that returns the Object: "out"
         */
         var out = {};
         
         var update_ts_title = function(title, subtitle){
            var hc_con = $(makeid("hc-ts"));
            if(hc_con.is(":visible")){
               var hc = hc_con.highcharts();
               hc.setTitle({text: title}, {text: subtitle});
            }
         };
         
         var update_table_title = function(title, subtitle){
            var capt = $(makeid("preview-table")).find("caption");
            if(capt.is(":visible")){
               capt.find(".mbie_preview_key").text(title);
               if(subtitle.length > 0){subtitle = " " + subtitle;}
               capt.find(".mbie_preview_subkey").text(subtitle);
            }
         };
         
         out.run = function(force){
            var do_update = !hef.getval($(makeid("auto-title")));
            if(force === true){do_update = true;}
            
            if(do_update){
               var title = $(makeid("title")).val();
               var subtitle = $(makeid("subtitle")).val();
               
               update_ts_title(title, subtitle);
               update_table_title(title, subtitle);
            }
         };
         
         out.init = function(){
            // Bind events
            $(makeid("title")).on("change.uptitle", function(){out.run();});
            $(makeid("subtitle")).on("change.uptitle", function(){out.run();});
         };
         
         return out;
      }();
      
      me.init = function(){
         /* Save initial dname */
         prev_dname = get_dname();
         
         /* Shiny message handler */
         Shiny.addCustomMessageHandler("dstore", dstore.handleMessage);
         
         /* Bind event to update variables on dataset selection */
         $(makeid("dname")).on("change.upvars", function(){
            me.upvars(get_dname());
         });
         
         /* Condition inputs */
         me.cond.init($(makeid("cond-add")), {
            selwell: $(".filwell"),
            condvar: $(makeid("cond-var")),
            condtype: $(makeid("cond-type")),
            condval: $(makeid("cond-vals"))
         });
         
         /* Import/Export Query */
         me.imexport.init();
         
         /* Auto-save */
         me.autosave.init();
         
         /* Side-panel JS */
         me.panel.init();
         
         /* Toggle ts type */
         // $(makeid("ts-type")).on("click", me.toggle_ts_type);
         
         /* Update Titles */
         me.update_titles.init();
         
         /* HACK for datekinds for pop and flow
            Sorry, not enough time to do it properly
         */
         $(makeid("dname")).on("change.datekindhack", function(){
            var dname = get_dname();
            var datekind_input = $(makeid("datekind"));
            var datekind_notm_radio = datekind_input
               .find("input")
               .not("[value='m']")
               .closest("div.radio");
            if(["pop", "flow"].indexOf(dname) > -1){
               hef.upval(datekind_input, "m");
               datekind_notm_radio.css("display", "none");
            } else{
               datekind_notm_radio.css("display", "");
            }
         });
         /* Add a linebreak to datekind labels */
         $(makeid("datekind"))
            .find("div.radio")
            .find("span")
            .each(function(){
               var old_html = $(this).html();
               var new_html = old_html.replace(
                  / \(Year Ended/,
                  "<br/>" + "&nbsp;".repeat(3) + "(Year Ended"
               );
               $(this).html(new_html);
            });
         
         /* apply defs */
         if(typeof defs_apply === "object"){
            defs_apply.init(me);
         } else{
            console.log("warning: no defs found");
         }
      };
      
      return me;
   }();
   
   hef.qjump = function(){
      /* qjump
         Javascript component of the "qjump" (quick-jump) functionality
            defined in "ui_doctabs.R"
      */
      
      var bc = hef.BetterCSVs;
      var tabName = $(bc.makeid("con")).closest(".tab-pane").attr("data-value");
      
      /* Activate links */
      $(".hjump").on("click", "a", function(){
         var query = $(this).attr("data-query");
         if(query !== undefined){
            hef.tab(tabName);
            bc.imexport.import(query);
            var newTop = $(bc.makeid("con")).find(".panel-row").offset().top;
            $("html").animate({scrollTop: newTop}, 2000, "linear");
         }
      });
      
      /* Add auto-save link if available */
      var last_query = hef.BetterCSVs.autosave.load();
      if(last_query !== null){
         var last_query_parse = JSON.parse(last_query);
         var query_title = bc.imexport.str_title(last_query_parse);
         if(query_title !== undefined){
            query_title = " (" + query_title + ")";
         } else{
            query_title = "";
         }
         $(".hjump").find("ul").prepend(
            $("<li>").append(
               $("<a>", {href: "#", value: "last-query", "data-query": last_query})
                  .append($("<span>", {class: "bold", text: "Restore previous session"}))
                  .append(query_title)
            )
         );
      }
   };
   
   hef.init = function(){
      hef.BetterCSVs.init();
      
      hef.hc_download();
      hef.qjump();
      
      release_notes_apply.init();
      
      /* IE check
         If user is using Internet Explorer, show a warning
          and recommend some better browsers.
      */
      if(/MSIE|Trident/.test(navigator.userAgent)){
         setTimeout(function(){
            window.alert(
               "We have detected that your browser is Internet Explorer." +
               " Some features may not work with Internet Explorer." +
               " If something doesn't seem to work, try using a different browser" +
               " (e.g. Google Chrome, Mozilla Firefox or Microsoft Edge) instead."
            );
         }, 1200);
      }
   };
   
   return hef;
}();
