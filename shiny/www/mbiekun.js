var mbiekun = function(){
   /* mbiekun
      An experimental tool for providing integrated guided tours.
      Though originally created for use with a shiny app,
         the tool is entirely JavaScript-based, so it should be easy
         to extend to non-Shiny tools.
      In addition to mbiekun.js and mbiekun.css, there must also be a
         "Tour", that defines what the tour(s) will be.
   */
   var kun = {};
   
   /* Animation speeds in ms */
   kun.speedpp = 2.5;      /* Speed per pixel */
   kun.speedppMax = 1500;  /* Maximum cap for "speed per pixel" duration */
   kun.speedppFF = 0.2;    /* Speed modifier used during "fast-forward" */
   kun.fadetime = 500;     /* Fade-away time */
   kun.delaytime = 500;
   kun.msgmin = 2000;      /* Base message duration */
   kun.msgtime = 300;      /* Additional message duration in ms per " " found in the message */
   kun.msgfade = 400;      /* Fade-away time for message (doesn't add to total duration) */
   
   /* ---- */
   kun.init = function(){
      /* Init the mbiekun container div, and store a pointer as `kun.me`. */
      if(kun.me === undefined){
         kun.me = $("<div>", {id: "mbiekun", "aria-live": "polite"}).appendTo("body");
         kun.make();
         kun.hide();
         
         kun.log.init();
         kun.builder.init();
      }
   };
   
   kun.make = function(){
      /* make
         Create the "icon", a proxy pointer, the visual cue to guide the user.
         This icon is based on the "MBIE rhombus".
         Strictly speaking, an "MBIE rhombus" should have a 26 degree angle,
            but the mbiekun icon uses 24 and 32.5 degree angles instead.
      */
      kun.me.append($("<svg><polygon/><polygon/><polygon/></svg>"));
      kun.me.find("svg")
         .attr("width", 27)
         .attr("height", 20);
      kun.me.find("polygon:nth-child(2n+1)")
         .attr("points", "2 0, 11 20, 23 20, 14 0")
         .attr("fill", "#97D700");
      kun.me.find("polygon:nth-child(2)")
         .attr("points", "0 0, 20 0, 27 11, 7 11")
         .attr("fill", "#006272");
      kun.me.find("polygon:nth-child(-n+2)")
         .attr("fill-opacity", 1);
      kun.me.find("polygon:nth-child(3)")
         .attr("fill-opacity", 0.4);
   };
   
   kun.show = function(){
      /* show
         Make the icon visible.
      */
      kun.me
         .css("opacity", "1")
         .css("display", "block");
      
      kun.clearauto();
   };
   kun.hide = function(){
      /* hide
         Hide the icon from view, but also conduct clean-up.
      */
      kun.me
         .css("opacity", "0")
         .css("display", "none")
         .finish("kun")
         .clearQueue("delay")
         .find(".speech").remove();
      
      kun.blocker.destroy();
      kun.skip.reset();
   };
   kun.hideslow = function(){
      /* hideslow
         An animated fade-out for the icon, before calling
            `kun.hide` to ensure clean-up.
      */
      kun.me.animate({"opacity": 0}, kun.fadetime, "swing", kun.hide);
   };
   
   kun.showauto = function(bigTour, cur_name){
      /* showauto
         Automatically start an introductory tour at
            the start of every session.
         Can be disabled via `kun.endauto`
      */
      if(window.localStorage.getItem("mbiekun-noautotour") !== "true"){
         mbiekun.runTour(bigTour, cur_name);
      }
   };
   kun.endauto = function(){
      /* endauto
         Sets the local Storage value to prevent `kun.showauto`
      */
      window.localStorage.setItem("mbiekun-noautotour", "true");
   };
   kun.clearauto = function(){
      /* clearauto
         Remove the local Storage value, re-enabling `kun.showauto`
      */
      window.localStorage.removeItem("mbiekun-noautotour");
   };
   
   kun.scroll = function(top, duration){
      /* scroll
         Attempt to vertically scroll the screen
            to roughly centre display on target.
      */
      var wheight = $(window).height();
      var desired = Math.floor(top - wheight/4);
      $("html").animate({scrollTop: desired}, duration, "linear");
   };
   
   kun.moveto = function(target, callback, noscroll){
      /* moveto
         Mimic a mouse movement-and-click, by moving the icon
            to the target, and then executing the actions via
            a callback function that is executed when the
            move completes. So the user can keep track, the
            screen is also scrolled to the target.
         The speed of the mouse movement is based on pixel distance
            (kun.speedpp) capped at a maximum (kun.speedppMax).
         Depending on the skip setting, the speed may be sped-up
            by a factor (kun.speedppFF), or shortened to a very
            short duration (1ms).
      */
      if(target === undefined){
         var pos = {top: $(window).scrollTop(), left: 0};
         target = $(window);
      } else{
         var pos = target.offset();
      }
      var offsetprop = [0.3, 0.3];
      pos.top += target.outerHeight() * offsetprop[0];
      pos.left += target.outerWidth() * offsetprop[1];
      var curpos = kun.me.offset();
      var dist = Math.floor(Math.hypot(pos.top - curpos.top, pos.left - curpos.left));
      var duration = Math.min(kun.speedppMax, dist * kun.speedpp);
      /* Handle skipping */
      duration = kun.skip.switch(duration, duration * kun.speedppFF, 1);
      
      kun.me.animate(pos, duration, "linear", callback);
      if(!noscroll){
         kun.scroll(pos.top, duration);
      }
   };
   
   kun.highlight = function(sel){
      /* highlight
         Create a "signal" div, matching the (rectangular) size of
            the target, which is used to visually highlight the target.
      */
      return $("<div>", {class: "mbiekun-signal"})
         .css({
            width: sel.outerWidth(),
            height: sel.outerHeight(),
            top: sel.offset().top,
            left: sel.offset().left
         })
         .insertBefore(kun.me);
   };
   
   kun.signal = function(sel){
      /* signal
         Signal interaction with the target, by creating a visual highlight,
            then fading it away. Use a callback to ensure the highlight is
            removed once we no longer need it.
      */
      if(kun.skip.switch(true, true, false)){
         kun.highlight(sel)
            .animate({opacity: 0}, kun.fadetime, "linear", function(){$(this).remove();});
      }
   };
   
   kun.change = function(selector, value, next, noscroll){
      /* change
         Handler for interacting with the target. Interaction means
            moving the icon to the target, and then changing the value,
            or simply clicking on it.
         The different types of inputs require slightly different
            requirements for interacting, and signalling this interaction.
         The handler is by no means complete, and is updated on an
            as-required basis.
         Depending on the skip setting, the move part may be skipped.
      */
      if(next === undefined){next = function(){return;}};
      if(noscroll === undefined){noscroll = false;}
      var sel = $(selector);
      
      if(sel.length < 1){
         actf = next;
         movesel = $("body");
      } else if(sel.hasClass("selectized")){
         /* selectize input */
         var sel_input = sel[0].selectize;
         var sel_con = sel.parents(".shiny-input-container");
         movesel = sel.parent("div");
         actf = function(){
            kun.signal(sel_con);
            sel_input.addItem(value);
            next();
         };
      } else if(sel.prop("tagName") === "SELECT"){
         /* select input */
         movesel = sel;
         actf = function(){
            kun.signal(sel);
            sel.val(value);
            sel.change();
            next();
         };
      } else if(sel.hasClass("shiny-input-radiogroup")){
         /* radio input */
         var sel_input = $(sel).find("input[value=" + JSON.stringify(value) + "]");
         var sel_con = sel_input.parent("label").parent("div.radio");
         
         movesel = sel_input;
         actf = function(){
            kun.signal(sel_con);
            sel_input.prop("checked", true);
            sel_con.change();
            next();
         };
      } else if(sel.attr("type") === "checkbox"){
         /* checkbox input */
         var sel_input = $(sel);
         var sel_con = sel_input.parent("label").parent("div.checkbox");
         
         movesel = sel_input;
         actf = function(){
            kun.signal(sel_con);
            sel_input.prop("checked", value).change();
            next();
         };
      } else if(sel.attr("type") === "text"){
         /* text input */
         var sel_input = $(sel);
         var sel_con = sel_input;
         
         movesel = sel_input;
         actf = function(){
            kun.signal(sel_con);
            sel_input.val(value).change().trigger("input");
            next();
         };
      } else{
         /* All others that can simply be clicked */
         movesel = sel;
         actf = function(){
            if(value !== "<clickonly>"){kun.signal(sel);}
            sel.click();
            next();
         };
      }
      
      var movef = function(){kun.moveto(movesel, actf, noscroll);};
      kun.skip.switch(movef, movef, actf)();
      
      kun.log.action(sel, value);
   };
   
   kun.next = function(){
      /* next
         A wrapper for working with jQuery queue.
            `dequeue` is used to trigger the next item on the queue.
         Allows for pausing, but this only stops the execution of the
            next queue item, and does not affect queue items that
            have already started.
         If execution is stalled by the pause, then set "kun.stalled"
            flag to true, so that it can be executed on unpause.
      */
      if(!kun.pause){
         kun.me.dequeue("kun");
      } else{
         kun.stalled = true;
      }
   };
   kun.nextdelay = function(delay){
      /* nextdelay
         Wrapper for calling `kun.next` but with a delay.
         Depending on the skip setting, the delay may be adjusted to
            a very short duration (10ms, to allow for possible desync issues).
      */
      if(delay === undefined){
         delay = kun.skip.switch(kun.delaytime, kun.delaytime, 10);
      }
      kun.me
         .delay(delay, "delay")
         .queue("delay", kun.next)
         .dequeue("delay");
   };
   kun.unpause = function(){
      /* unpause
         Sets "kun.pause" flag to false, and if execution had been
            stalled due to the pause, trigger execution.
      */
      if(kun.pause){
         kun.pause = false;
         if(kun.stalled){
            kun.stalled = false;
            kun.next();
         }
      }
   };
   
   kun.talkduration = function(msg){
      /* talkduration
         Automatic calculation of an appropriate message duration.
         The calculation is based on a base duration (kun.msgmin),
            plus a variable duration using the number of spaces
            (a proxy for number of words).
         Formerly used a calculation based on number of letters,
            but the word-proxy calculation seems to work better.
      */
      return kun.msgmin + kun.msgtime * msg.match(/ |$/g).length;
   };
   kun.talk = function(msg, duration){
      /* talk
         Create a speech bubble to display a message, which will
            fade away after the given duration.
         If the message is empty, then don't create a speech bubble.
            Such empty messages can be used to delay schedule execution.
         A log of the message is also kept.
         The speech div has its own queue to handle fade-out and removal,
            to allow for an independent delay from the main queue.
      */
      if(msg.length > 0){
         kun.me.append(
            $("<div>", {class: "speech"})
               .append($("<p>", {text: msg}))
               .delay(duration - kun.msgfade, "talk")
               .queue("talk", function(next){
                  $(this)
                     .animate({opacity: 0}, kun.msgfade, "linear", function(){
                        $(this).remove();
                     });
                  next();
               })
               .dequeue("talk")
         );
         kun.log.message(msg);
      }
   };
   kun.queuetalk = function(msg, waitprop, duration){
      /* queuetalk
         A wrapper for calling `kun.talk` in the main "kun" queue.
         If no duration is specified, it is calculated using `kun.talkduration`.
         The duration may further be adjusted to account for message
            fade-out time, and for the skip setting.
         Duration is calculated within the queued function, to ensure
            calculation is based on the skip setting at run-time.
      */
      return kun.me.queue("kun",
         function(){
            if(waitprop === undefined){
               waitprop = 1;
            }
            if(duration === undefined){
               duration = kun.talkduration(msg);
            }
            /* Ensure duration is at least the fade-out time */
            duration = Math.max(kun.msgfade + 100, duration);
            /* Handle skipping */
            duration = kun.skip.switch(duration, kun.msgfade, 0);
            
            /* Execution */
            kun.talk(msg, duration);
            kun.nextdelay(duration * waitprop);
         });
   };
   
   kun.prompt = function(def){
      /* prompt
      */
      var bub = $("<div>", {class: "speech speech-wider"});
      
      var pdef = def.prompt;
      
      var items = pdef.items.concat([
         {
            msg: "I don't need help at the moment (End the tour)",
            fun: kun.hideslow
         }/* ,
         {
            msg: "I'm fine on my own, goodbye and don't come back! (End the tour and prevent the tour from starting automatically)",
            fun: function(){kun.endauto(); kun.hideslow();}
         } */
      ]);
      
      bub.append($("<p>", {text: pdef.msg}));
      bub.append($("<ul>")
         .append(
            items.map(function(x){
               var lcontent = $("<a>", {class: "pseudo-link", text: x.msg})
                  .on("click.kun", function(){
                     bub.remove();
                     if(x.schedule !== undefined){
                        kun.runTour(def.bigTour, x.schedule);
                     }
                     if(x.fun !== undefined){
                        x.fun();
                     }
                  });
               return $("<li>").append(lcontent);
            })
         )
      );
      
      kun.me.append(bub);
   };
   
   kun.run = function(tour, skip){
      /* run
         Main function for executing a tour schedule.
         The "tour" is a named object that can contain:
         
         -blocker- (optional)
         If true, a blocker is created for the duration of the
            schedule to prevent undesired user interaction
            during the tour. The blocker is automatically removed
            when the tour ends.
         
         -intro- (optional)
         An introduction message.
         
         -name_tab- (optional)
         Name of the tab the tour applies to.
         If supplied, will swap tabs as needed with a message
            to the user saying why.
         
         -schedule- (optional)
         The actual tour schedule, which is a nested array.
         See below ("Schedule definition") for details.
         The entire queue is built here, but the delay timings
            are computed at run-time, to allow for dynamic speed adjustments.
         
         -prompt- (optional)
         Definitions for a prompt to be displayed once the schedule
            completes execution. The prompt can be used to ask the user
            for the next step, usually to specify another tour to run,
            or to end the tour.
      */
      
      /* Housekeeping */
      kun.skip.setwhistory(skip);
      kun.log.clear();
      kun.show();
      if(tour.blocker){kun.blocker.create()};
      
      /* Show intro message, if given */
      if(tour.intro !== undefined){
         kun.me
            .queue("kun", function(){
               kun.moveto(undefined, kun.next);
            });
         kun.queuetalk(tour.intro);
      }
      
      /* Switch tabs, if needed */
      if(tour.name_tab !== undefined){
         var name_tab_str = JSON.stringify(tour.name_tab);
         var tab_active = $("div.tab-pane[data-value=" + name_tab_str + "]").hasClass("active");
         if(!tab_active){
            var tab_button = "a[data-value=" + name_tab_str + "]";
            if(kun.skip.switch(true, true, false)){
               var tab_msg = "First we need to change tabs to " + name_tab_str + "...";
               kun.queuetalk(tab_msg)
                  .queue("kun", function(){
                     kun.change(tab_button, undefined, kun.nextdelay);
                  });
            } else{
               kun.change(tab_button, undefined, kun.next);
            }
         }
      }
      
      /* Run through schedule */
      /* Schedule definition:
         [0] - Selector
               The selector for the element we want to interact with.
               Can be undefined if no specific element to interact.
         [1] - Value
               The value to set the element chosen via the Selector.
               Can be "<moveonly>", in which case only movement is conducted.
               If Selector is undefined and Value is a function, the function
                  is queued to be called.
         [2] - Message
               A message can be specified, to be displayed as a "speech bubble".
         [3] - Message wait proportion
               Proportion of message duration time to delay next queued action.
               [3] == 1 means wait for full message duration.
               [3] == 0 means don't wait.
               Waits for full duration by default.
         [4] - Message duration
               Specify the message duration.
               If undefined, computed using `kun.talkduration`.
      */
      if(tour.schedule !== undefined){
         tour.schedule.forEach(function(x){
            /* Whether to display a message */
            if(x[2] !== undefined){
               kun.queuetalk(x[2], x[3], x[4]);
            }
            
            if(x[0] !== undefined){
               /* Regular action */
               kun.me.queue("kun", function(){
                  /* Handle <noscroll> in value */
                  var noscroll = false;
                  var re_noscroll = /<noscroll>/;
                  if(re_noscroll.test(x[1])){
                     noscroll = true;
                     x[1] = x[1].replace(re_noscroll, "");
                  }
                  
                  if(x[1] === "<moveonly>"){
                     var movesel = $(x[0]);
                     if(movesel.length < 1){movesel = $("body");}
                     kun.moveto(movesel, kun.nextdelay, noscroll);
                  } else{
                     kun.change(x[0], x[1], kun.nextdelay, noscroll);
                  }
               });
            } else{
               /* Special cases where Selector is undefined */
               if(typeof x[1] === "function"){
                  /* Queue function call */
                  kun.me.queue("kun", function(){
                     x[1](kun.nextdelay);
                  });
               }
            }
         });
      }
      
      /* Housekeeping */
      kun.me.queue("kun", function(){
         kun.blocker.destroy();
         kun.skip.reset();
         kun.next();
      });
      
      /* Display prompt (if supplied) */
      if(tour.prompt !== undefined){
         kun.me.queue("kun", function(){
            kun.prompt(tour.prompt);
         });
      }
      /* kun.me.queue("kun", kun.hideslow); */
      
      kun.next();
   };
   kun.runTour = function(bigTour, cur_name){
      /* runTour
         Wrapper to `kun.run` which runs any init schedule that might
            exist in the big tour object.
         The init schedule is used to "reset" specific input settings,
            (by setting it to a known value), to ensure schedule
            execution proceeds as intended.
      */
      kun.init();
      var cur_tour = bigTour[cur_name];
      var runf = function(){kun.run(cur_tour);};
      
      if(cur_tour.init !== undefined){
         kun.run(cur_tour.init, "i");
         kun.me.queue("kun", runf);
      } else{
         runf();
      }
   };
   
   /* Modules
      Various large sub-components of mbiekun are grouped
         into modules for easier management.
      Each module has its own namespace.
   */
   kun.skip = function(){
      /* Skip Module
         Handles skip settings, which are used to run through the
            tour quickly ("fast-foward") or almost instantly ("instant").
         Valid settings:
            - "n" /default        : normal
            - "ff"/"fast-foward"  : fast-forward
            - "i" /"instant"      : instant
      */
      var me = {type: "n", oldtype: "n"};
      
      me.set = function(skip_type){
         /* set
            Set the skip setting to the given type.
         */
         if(skip_type !== undefined){
            me.type = skip_type;
         }
      };
      me.setwhistory = function(skip_type){
         /* setwhistory
            Wrapper for `me.set` but store the previous type.
         */
         me.oldtype = me.type;
         me.set(skip_type);
      };
      me.reset = function(){
         /* reset
            Restore the previously saved setting.
            Fairly simple implementation, so not that robust.
         */
         me.type = me.oldtype;
      };
      
      me.switch = function(r_n, r_ff, r_i){
         /* switch
            An accessor function used by other components of mbiekun
               to switch between the inputs depending on the current
               skip setting.
         */
         switch(me.type){
            case "i":
            case "instant":
               return r_i;
               break;
            case "ff":
            case "fast-forward":
               return r_ff;
               break;
            default:
               return r_n;
         };
      };
      
      return me;
   }();
   
   kun.blocker = function(){
      /* Blocker Module
         Handles the "blocker", which is used to block interaction with
            the app while a tour is in progress.
         User interaction may result in unintended input changes that
            result in unexpected results as a tour executes.
         To ensure a predictable tour, the blocker is used.
         If the user tries to interact while the blocker is in place,
            a warning is presented to them explaining the situation,
            along with options for ending the tour
            (and thus removing the blocker).
      */
      var me = {};
      
      me.create = function(){
         /* create
            Create the blocker, and store a pointer as `me.sel`.
            A number of actions are taken to prevent unwanted user interaction
               with the rest of the page, taking into account navigation by
               mouse, keyboard, and jump-to-landmark.
            Finally, the warning box is also created immediately, to indicate
               to the user that a tour is in progress.
         */
         if(me.sel === undefined){
            me.sel = $("<div>", {class: "mbiekun-blocker", tabindex: 0})
               .attr("role", "region")
               .attr("aria-live", "polite")
               .on("blur", me.warn)
               .on("click", me.warn)
               .prependTo($("body"));
            
            /* Set aria-hidden for landmarks, to prevent navigation */
            if(me.landmarks === undefined){
               me.landmarks = $("body").children("header,nav,main,footer");
            }
            me.landmarks.attr("aria-hidden", "true");
         }
         me.warn();
      };
      
      me.destroy = function(){
         /* destroy
            Remove the blocker, the warning, and conduct general housekeeping.
         */
         if(me.sel !== undefined){
            me.warnclose();
            me.sel.remove();
            me.sel = undefined;
            me.landmarks.removeAttr("aria-hidden");
         }
      };
      
      /* When user tries to interact while blocker in place,
         Give warning and option to end tour.
      */
      me.warnmsg = "A guided tour is currently in progress and interaction is disabled." +
         " You can choose to view a log, pause the tour, continue the tour," +
         " or to end it so you may regain interactivity.";
      me.warn = function(){
         /* warn
            A warning explaining the blocker, and giving the user various options.
         */
         if(me.warnsel === undefined){
            me.warnsel = $("<div>", {class: "mbiekun-warning", tabindex: 0})
               .appendTo(me.sel);
            
            me.warnsel.append($("<p>", {text: me.warnmsg}));
            
            me.warnsel.append($("<div>", {class: "mbiekun-warning-btncon"})
               .append(
                  $("<button>", {type: "button", text: "Pause"})
                     .on("click", me.pause)
               )
               .append(
                  $("<button>", {type: "button", text: "Play"})
                     .on("click", function(){
                        kun.skip.set("n");
                        kun.unpause();
                     })
               )
               .append(
                  $("<button>", {type: "button", text: "Fast-forward"})
                     .on("click", function(){
                        kun.skip.set("ff");
                        kun.unpause();
                        kun.me.dequeue("delay");
                        kun.me.find(".speech").dequeue("talk");
                     })
               )
            );
            
            me.warnsel.append($("<div>", {class: "mbiekun-warning-btncon"})
               .append(kun.log.button("View Log"))
               .append(
                  $("<button>", {type: "button", text: "End Tour"})
                     .on("click", kun.hide)
                     .on("blur", function(){me.warnsel.focus();})
               )
               .append(
                  $("<button>", {type: "button", text: "Hide Message"})
                     .on("click", me.warnclose)
               )
            );
         }
         me.warnsel.focus();
      };
      me.warnclose = function(e){
         /* warnclose
            Close the warning, and conduct general housekeeping.
            This also serves as a "continue" button, and clears the pause flag.
         */
         if(e !== undefined){e.stopPropagation();}
         me.sel.focus();
         kun.unpause();
         if(me.warnsel !== undefined){
            me.warnsel.remove();
            me.warnsel = undefined;
         }
      };
      
      me.pause = function(){
         kun.pause = true;
      };
      
      return me;
   }();
   
   kun.log = function(){
      /* Log Module
         Used to keep a log of messages and actions.
         The log is presented via a bootstrap modal box.
      */
      var me = {};
      
      me.init = function(){
         /* init
            Set up the bootstrap modal box.
            This is called via `kun.init`.
         */
         var out = make_bmodal("mbiekun-log", "Tour Log");
         
         me.sel = out.sel;
         me.clear = out.clear;
         me.button = out.button;
      };
      
      me.create = function(cur_html){
         /* create
            Create a new entry in the log.
         */
         if(kun.skip.switch(true, true, false)){
            me.sel.append(cur_html);
         }
      };
      
      me.message = function(msg){
         /* message
            Wrapper for creating a new log entry for messages.
         */
         me.create($("<p>", {text: msg}));
      };
      
      me.keyword = function(ctext){
         /* keyword
            Trivial wrapper for creating a span with class "mbiekun-log-key"
         */
         return $("<span>", {class: "mbiekun-log-key", text: ctext});
      };
      
      me.getlabel = function(sel){
         /* getlabel
            Convenience function for retrieving an appropriate
               label for the given selection.
         */
         var labsel = $("label.control-label[for=" + JSON.stringify(sel.attr("id")) + "]");
         if(labsel.length > 0){
            return labsel.text().replace(/:$/, "");
         } else{
            var label = sel.attr("name");
            if(label === undefined){
               label = sel.attr("title");
            }
            if(label === undefined){
               if(sel.attr("id") !== undefined){
                  label = "#" + sel.attr("id");
               }
            }
            if(label === undefined){
               label = sel.attr("value");
            }
            if(label === undefined){
               label = sel.attr("class");
            }
            return label;
         }
      };
      
      me.linksel = function(sel, label){
         /* linksel
            Convenience function for creating a "link" for the selection.
            Results in a moveto (and thus also a scroll), and a signal.
         */
         return $("<a>", {href: "#"})
            .on("click", function(e){
               e.preventDefault();
               
               /* Pause, and if hidden, show again */
               kun.pause = true;
               if(kun.me.css("display") === "none"){kun.show();}
               /* If blocker does not exist, create */
               if(kun.blocker.sel === undefined){
                  kun.blocker.create();
               }
               
               /* Execute moveto and signal */
               kun.moveto(sel, function(){
                  kun.signal(sel);
               });
            })
            .append(label);
      };
      
      me.action = function(sel, value){
         /* action
            A wrapper for creating a sensible log message for actions.
         */
         var msg = $("<p>")
            .append(me.keyword("<ACTION>"));
         
         /* Find a sensible label */
         var label = me.getlabel(sel);
         
         /* Add type-specific message */
         if(sel.hasClass("selectized")){
            /* selectize input */
            msg
               .append(" add ")
               .append(me.keyword(value))
               .append(" to ")
               .append(me.keyword("SELECT"))
               .append(" Input ")
               .append(me.linksel(sel.parents(".shiny-input-container"), me.keyword(label)));
         } else if(sel.prop("tagName") == "SELECT"){
            /* Select */
            value = sel.find("option[value=" + JSON.stringify(value) + "]").text();
            msg
               .append(" change ")
               .append(me.keyword("SELECT"))
               .append(" Input ")
               .append(me.linksel(sel, me.keyword(label)))
               .append(" to ")
               .append(me.keyword(value));
         } else if(sel.hasClass("shiny-input-radiogroup")){
            /* Radio */
            value = sel.find("input[value=" + JSON.stringify(value) + "]")
               .parent("label").children("span").text();
            msg
               .append(" change ")
               .append(me.keyword("RADIO"))
               .append(" Input ")
               .append(me.linksel(sel, me.keyword(label)))
               .append(" to ")
               .append(me.keyword(value));
         } else if(sel.attr("type") === "button"){
            /* Button */
            msg
               .append(" click ")
               .append(me.keyword("BUTTON"))
               .append(" - ")
               .append(me.linksel(sel, me.keyword(label)));
         } else if(sel.attr("data-toggle") === "tab"){
            /* Tab */
            msg
               .append(" change ")
               .append(me.keyword("TAB"))
               .append(" to ")
               .append(me.linksel(sel, me.keyword(sel.attr("data-value"))));
         } else{
            msg = undefined;
         }
         
         /* Create log message */
         if(msg !== undefined){me.create(msg);}
      };
      
      return me;
   }();
   
   kun.builder = function(){
      /* Builder Module
         Provide a "build-your-own-tour" interface, which
            simultaneously serves as an easy-to-use interface
            for new users, and a teaching tool to graduate them
            into advanced users.
         The builder ui is enclosed in a bootstrap modal box.
      */
      var me = {};
      
      me.init = function(){
         /* init
            Set up the bootstrap modal box.
            This is called via `kun.init`.
         */
         var out = make_bmodal("mbiekun-builder", "What do you want to know about?");
         
         me.sel = out.sel;
         me.clear = out.clear;
         me.show = out.show;
      };
      
      return me;
   }();
   
   kun.collect = function(){
      /* Collect Module
         A helper module for creating new tour schedules.
         The functions provided in this module collect information
            relating to specific, recognised types of inputs.
         This information makes it slightly easier to create the schedule,
            compared to a more direct, inspect element and trawl through
            the DOM method.
      */
      var me = {};
      
      me.select = function(){
         me.last = $("select.shiny-bound-input").filter(":visible").map(function(){
            var cursel = $(this);
            
            var curid = cursel.attr("id");
            var curlabel = cursel.parent("div").parent("div").children("label").text();
            var curopts = cursel.children("option")
               .map(function(x){return $(this).text();}).get();
            
            return [[curid, curlabel, curopts]];
         }).get();
         
         return me.last;
      };
      
      me.radio = function(){
         me.last = $(".shiny-input-radiogroup").filter(":visible").map(function(){
            var cursel = $(this);
            
            var curid = cursel.attr("id");
            var curlabel = cursel.children("label").text();
            var curopts = cursel.find("input[type='radio']")
               .map(function(x){return $(this).attr("value");}).get();
            
            return [[curid, curlabel, curopts]];
         }).get();
         
         return me.last;
      };
      
      me.checkbox = function(){
         me.last = $(".shiny-input-checkboxgroup").filter(":visible").map(function(){
            var cursel = $(this);
            
            var curid = cursel.attr("id");
            var curlabel = cursel.children("label").text();
            var curopts = cursel.find("input[type='checkbox']")
               .map(function(x){return $(this).attr("value");}).get();
            
            return [[curid, curlabel, curopts]];
         }).get();
         
         return me.last;
      };
      
      me.button = function(){
         me.last = $("button").filter(":visible").map(function(){
            var cursel = $(this);
            
            var curid = cursel.attr("id");
            var curlabel = cursel.text();
            
            return [[curid, curlabel, undefined]];
         }).get();
         
         return me.last;
      };
      
      me.tabs = function(){
         me.last = $(".navbar-nav, .nav-tabs").filter(":visible").map(function(){
            var parent_id = $(this).attr("id");
            
            return $(this).find("a").map(function(){
               var cursel = $(this);
               var dval = JSON.stringify(cursel.attr("data-value"));
               var selector = parent_id + " a[data-value=" + dval + "]";
               var curlabel = cursel.text();
               
               return [[selector, curlabel, undefined]];
            }).get();
         }).get();
         
         return me.last;
      };
      
      me.get = function(i, j){
         if(me.last !== undefined){
            var curarr = me.last[i];
            var val = undefined
            if(j !== undefined){
               val = curarr[2][j];
            }
            return ["#" + curarr[0], val];
         }
      };
      
      return me;
   }();
   
   /* Misc functions
      These are used in various parts, but are not exported.
   */
   var make_bmodal = function(baseid, mlabel){
      /* init
         Sets up a bootstrap modal box.
         This should be called once per modal, ideally in `kun.init`.
         Only the contents of ".modal-body" should be cleared/updated.
         
         Arguments:
         -baseid-    The id of the modal.
         -mlabel-    The title/label for the modal.
         
         Returns an Object containing:
         -sel-       Pointer to ".modal-body"
         -clear-     Function that clears the contents of ".modal-body"
         -show-      Function for displaying the modal.
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
   
   return kun;
}();

/* Math.hypot polyfill, taken from:
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/hypot
*/
Math.hypot = Math.hypot || function() {
  var y = 0, i = arguments.length;
  while (i--) y += arguments[i] * arguments[i];
  return Math.sqrt(y);
};
