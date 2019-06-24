/*
   Tour defs
*/
var mbiekun_tour = function(){
   /* ---- helpers   ---- ---- ---- ---- ---- ---- ---- ---- ---- */
   var panel = HelperFuncs.BetterCSVs.panel;
   var makeid = HelperFuncs.BetterCSVs.makeid;
   
   var uncheck_all = function(callback){
      $("input[type='checkbox']")
         .filter(":checked")
         .prop("checked", false)
         .change();
      
      if(callback !== undefined) callback(10);
   };
   
   var reset_presel = function(selector){
      /* override any stored presel by using data-queue */
      return function(callback){
         HelperFuncs.queue.set($(selector), 0);
         
         if(callback !== undefined) callback(10);
      };
   };
   
   var cond_clear = function(dname){
      return function(callback){
         HelperFuncs.BetterCSVs.cond.rmAll(dname);
         
         if(callback !== undefined) callback(10);
      };
   };
   var cond_set = function(cond_toset, btnSelector){
      return function(callback){
         if(btnSelector !== undefined){mbiekun.signal($(btnSelector))};
         var cond = HelperFuncs.BetterCSVs.cond;
         vvals_str = cond_toset.vvals.reduce(
            function(a, b){return a + "[" + b + "]";}, ""
         );
         var con = cond.set(cond_toset);
         /* create a log message */
         var log = mbiekun.log;
         var msg = $("<p>")
            .append(log.keyword("<ACTION>"))
            .append(" create ")
            .append(log.linksel(con, log.keyword("FILTER")))
            .append(" for ")
            .append(log.keyword("[" + cond_toset.vname + "]"))
            .append(" " + cond_toset.vtype + " ")
            .append(log.keyword(vvals_str));
         log.create(msg);
         
         if(callback !== undefined) callback();
      };
   };
   
   var change_tab = function(tabName){
      return function(callback){
         HelperFuncs.tab(tabName);
         
         if(callback !== undefined) callback(10);
      };
   };
   
   var hc_interactive = function(callback){
      /* hack to allow interaction of highchart through mbiekun blocker
         Note: This does not carry through re-renders of the chart.
      */
      $(".highcharts-container").css("z-index", 255);
      mbiekun.me.css("z-index", 255);
      
      if(callback !== undefined) callback(10);
   };
   var hc_ireset = function(callback){
      /* reset changes made by `hc_interactive` */
      $(".highcharts-container").css("z-index", 0);
      mbiekun.me.css("z-index", "");
      
      if(callback !== undefined) callback(10);
   };
   
   /* ---- prompts   ---- ---- ---- ---- ---- ---- ---- ---- ---- */
   var prompts = {};
   prompts.intro = {
      msg: "Welcome to the Migration Data Explorer. The following tours are available:",
      items: [
         /* Quick tour */
         {
            msg: "Quick tour of the Data Explorer tab",
            schedule: "quick_pop"
         },
         /* In-depth tours */
         {
            msg: "Understand the Population of Temporary Workers",
            schedule: "work_pop"
         },
         {
            msg: "Explore the Visa Flows data (How migrants move in and out of Visa Categories and New Zealand)",
            schedule: "explore_flow"
         }
      ]
   };
   
   /* ---- defs      ---- ---- ---- ---- ---- ---- ---- ---- ---- */
   var defs = {};
   defs.init_csv = {
      schedule: [
         [undefined, change_tab("Chart")],
         ["#BetterCSVs_dname", "NO DATA SELECTED"],
         ["#BetterCSVs_datekind", "m"],
         ["#BetterCSVs_seas", false],
         [undefined, reset_presel("#BetterCSVs_dvars")]
      ]
   };
   
   defs.intro = {
      intro: "Hello!",
      prompt: {bigTour: defs, prompt: prompts.intro}
   };
   
   quick_pop_conds = {
      "vname": "Visa_Type",
      "vtype": "CONTAINS",
      "vvals": ["Student"]
   };
   var insels = {
      dname: panel.inselGet($(makeid("dname"))[0]),
      dvars: panel.inselGet($(makeid("dvars"))[0])
   };
   var inlists = {
      dname: panel.inlistGet($(makeid("dname"))[0]),
      dvars: panel.inlistGet($(makeid("dvars"))[0])
   };
   var inlistToggle = function(inlist, inlistShow){
      return function(callback){
         panel.inlistToggle(inlist, inlistShow);
         if(callback !== undefined) callback(10);
      };
   };
   defs.quick_pop = {
      blocker: true,
      init: defs.init_csv,
      intro: "Hello! Let me give you a quick tour of the Data Explorer.",
      name_tab: "Data Explorer",
      schedule: [
         [undefined, cond_clear("pop")],
         [undefined, reset_presel("#BetterCSVs_dvars")],
         [insels.dname, "<moveonly>"],
         [undefined, inlistToggle(inlists.dname, true)],
         ["#BetterCSVs_dname", "<noscroll>pop", "First, select the dataset of interest."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "The time-series chart provides an overview of the data."],
         ["a[data-value='Table']", undefined, "You can view the data as a table instead."],
         ["div.preview-table", "<moveonly>"],
         ["#BetterCSVs_csv-down", "<moveonly>", "This is only a preview table, the full data is available in the CSV download."],
         [undefined, undefined, "", 1, 600],
         [insels.dvars, "<moveonly>"],
         [undefined, inlistToggle(inlists.dvars, true)],
         [makeid("dvars") + " + .inlist button[value=" + JSON.stringify("Nationality") + "]"],
         [undefined, undefined, "Add variables for further breakdowns of the data."],
         [undefined, inlistToggle(inlists.dvars, false)],
         ["div.preview-table thead th:nth-child(3)", "<moveonly>"],
         ["div.preview-table tbody tr:nth-child(15) td:nth-child(3)", "<noscroll><moveonly>"],
         ["div.preview-table thead th:nth-child(3)", "<moveonly>"],
         ["#BetterCSVs_cond-add", "<noscroll>"],
         ["#BetterCSVs_cond-var", "<noscroll>Visa_Type"],
         ["#BetterCSVs_cond-vals ~ .inlist > button[value=" + JSON.stringify("Student") + "]", "<noscroll>"],
         [".filwell .btn-ok", "<noscroll>"],
         [undefined, undefined, "Use filters to narrow down the data."],
         ["div.preview-table thead th:nth-child(2)", "<moveonly>"],
         ["div.preview-table tbody tr:nth-child(15) td:nth-child(2)", "<noscroll><moveonly>"],
         ["div.preview-table thead th:nth-child(2)", "<moveonly>"],
         ["a[data-value='Chart']"],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "The time-series only displays the 5 largest series."],
         ["#BetterCSVs_ts-more", undefined, "More series can be added using the 'Add more series' button."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "", 1, 400],
         ["#BetterCSVs_seas", "<moveonly>"],
         ["#BetterCSVs_seas", true, "Seasonally adjusted trends can also be added on-the-fly."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, mbiekun.hideslow, "That concludes the quick tour. Additional tours are available in the Help tab if you need more assistance."]
      ]
   };
   
   defs.work_pop = {
      blocker: true,
      init: defs.init_csv,
      intro: "Let's learn more about the Population of Temporary Workers.",
      name_tab: "Data Explorer",
      schedule: [
         [undefined, cond_clear("pop")],
         [undefined, reset_presel("#BetterCSVs_dvars")],
         [insels.dname, "<moveonly>"],
         [undefined, inlistToggle(inlists.dname, true)],
         ["#BetterCSVs_dname", "<noscroll>pop", "First, we need to select the Population dataset."],
         [undefined, undefined, "By default, all Visa Types are shown. However we are only interested in the Work visa."],
         ["#BetterCSVs_cond-add", "<noscroll>", "We can add a filter to restrict the data."],
         ["#BetterCSVs_cond-var", "<noscroll>Visa_Type"],
         ["#BetterCSVs_cond-vals ~ .inlist > button[value=" + JSON.stringify("Work") + "]", "<noscroll>"],
         [".filwell .btn-ok", "<noscroll>"],
         [undefined, undefined, "You can see that the number of workers has been increasing over time. There is also a strong seasonal pattern in the data."],
         [undefined, undefined, "We can get a more detailed breakdown of the visa types by adding Application_Substream to our variables."],
         [insels.dvars, "<moveonly>"],
         [undefined, inlistToggle(inlists.dvars, true)],
         [makeid("dvars") + " + .inlist button[value=" + JSON.stringify("Application_Substream") + "]", "<noscroll>"],
         [undefined, undefined, "A large part of the seasonal pattern was driven by the highly seasonal Working Holiday Scheme and the Horticulture and Viticulture population"],
         [undefined, undefined, "The other types of workers do not display such a strong seasonal effect, only a minor dip over around year end."],
         [undefined, undefined, "It can sometimes be misleading when looking only at the aggregate level, so it is important to dig deeper."],
         [undefined, undefined, "Another situation where this is important are for German workers."],
         ["#BetterCSVs_cond-add", "<noscroll>", "Let's add a filter to restrict the data to just Germans."],
         ["#BetterCSVs_cond-var", "<noscroll>Nationality"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>G"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>Ge"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>Ger"],
         ["#BetterCSVs_cond-vals ~ .inlist > button[value=" + JSON.stringify("Germany") + "]", "<noscroll>"],
         [".filwell .btn-ok", "<noscroll>"],
         [undefined, undefined, "We see that the vast majority of German Workers are in New Zealand for a Working Holiday."],
         [undefined, undefined, "Now what happens if we remove the Substream breakdown and add Nationality..."],
         [insels.dvars, "<moveonly>"],
         [undefined, inlistToggle(inlists.dvars, true)],
         [makeid("dvars") + " + .inlist button[value=" + JSON.stringify("Application_Substream") + "]", "<noscroll>"],
         [makeid("dvars") + " + .inlist button[value=" + JSON.stringify("Nationality") + "]", "<noscroll>"],
         [undefined, undefined, "The seasonal effect of the Working Holiday makers dominate the aggregate series."],
         [undefined, undefined, "If we remove the filter to Germany, so we can compare the different Nationalities."],
         [".filsel[value=" + JSON.stringify(JSON.stringify(["Germany"])) + "]", "<noscroll>"],
         [".filwell .btn-delete", "<noscroll>"],
         [undefined, undefined, "It looks like German workers as a whole have a really strong seasonal pattern that is very different from other nationalities."],
         [undefined, undefined, "But we know that German workers are dominated by Working Holiday makers, so this is not a fair comparison."],
         ["#BetterCSVs_cond-add", "<noscroll>", "What we want to compare, are Working Holiday makers for the different Nationalities."],
         ["#BetterCSVs_cond-var", "<noscroll>Application_Substream"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>w"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>wo"],
         ["#BetterCSVs_cond-vals ~ .has-feedback > .search-box", "<noscroll>wor"],
         ["#BetterCSVs_cond-vals ~ .inlist > button[value=" + JSON.stringify("Working Holiday Scheme") + "]", "<noscroll>"],
         [".filwell .btn-ok", "<noscroll>"],
         [undefined, undefined, "Now we have a fair comparison, and it appears that German Working Holiday makers are still more seasonal than other Nationalities."],
         ["#BetterCSVs_seas", "<moveonly>"],
         ["#BetterCSVs_seas", true, "We can add seasonal adjustment to better compare these effects."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "", 1, 600],
         ["#BetterCSVs_hc-seaseff", "<moveonly>"],
         [undefined, undefined, "This graph displays the average seasonal effect, and we can see Germany clearly stands out in having much stronger effects."],
         [undefined, mbiekun.hideslow, "That's it from me, have a play yourself to discover more!"]
      ]
   };
   
   flow_conds = {
      "vname": "Outflow_from",
      "vtype": "CONTAINS",
      "vvals": ["Student"]
   };
   defs.explore_flow = {
      blocker: true,
      init: defs.init_csv,
      name_tab: "Data Explorer",
      schedule: [
         [undefined, cond_clear("flow")],
         [undefined, reset_presel("#BetterCSVs_dvars")],
         [insels.dname, "<moveonly>"],
         [undefined, inlistToggle(inlists.dname, true)],
         ["#BetterCSVs_dname", "<noscroll>flow", "We then select Visa Flows from the list of datasets."],
         [undefined, undefined, "It takes a short time for the data to be loaded into the data explorer."],
         ["#BetterCSVs_dvars", "<moveonly>"],
         [undefined, undefined, "We can add more variables here, but Visa_Flows is already selected by default so let's leave this alone for now."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "A preview time-series is provided for the selected variables, it displays the five largest series for the given selection."],
         [undefined, hc_interactive],
         [undefined, undefined, "This chart is interactive, but I am currently blocking all interaction with the data explorer. Let me bring this chart forward so you can interact with it."],
         [undefined, undefined, "Now that the chart has been brought forward, you can interact with it by moving your mouse cursor over the chart."],
         [undefined, undefined, "These 'flows' represent the number of people changing or renewing their visas, and entering or leaving New Zealand."],
         [undefined, undefined, "e.g. [OUTSIDE NZ to Work] are new migrants entering New Zealand on temporary work visas."],
         [undefined, undefined, "e.g. [Work to OUTSIDE NZ] are migrants who were on temporary work visas leaving New Zealand"],
         [undefined, undefined, "e.g. [Work to Work] are migrants on temporary work visas who have transitioned to another work visa, or have renewed the same visa."],
         [undefined, undefined, "Refer to the Help tab for more details on how the flows are measured."],
         ["#BetterCSVs_ts-more", undefined, "Additional series can be added by using the 'Add more' button."],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, undefined, "This hides any existing series, but they can be toggled back on by clicking the series name in the legend below the chart."],
         ["#BetterCSVs_cond-add", "<moveonly>", "Let's go back to the data, specifically how migrants flow out of Student visas. We can add filters to look at specific features."],
         [undefined, hc_ireset],
         ["#BetterCSVs_cond-add", "<noscroll>"],
         ["#BetterCSVs_cond-var", "<noscroll>Outflow_from", "Let me create a filter to examine how migrants flow out of Student visas."],
         ["#BetterCSVs_cond-vals ~ .inlist > button[value=" + JSON.stringify("Student") + "]", "<noscroll>"],
         [".filwell .btn-ok", "<noscroll>"],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, hc_interactive],
         [undefined, undefined, "The two main flows we see are [Student to OUTSIZE NZ] and [Student to Student]."],
         [undefined, undefined, "[Student to Student] represent renewals of Student visas by those continuing their study."],
         [undefined, undefined, "[Student to OUTSIDE NZ] include both those students who have completed study and leave New Zealand for good, and also those who leave for a long holiday, e.g. to visit their home country over the long Christmas and New Year break."],
         [undefined, undefined, "There is a corresponding [OUTSIDE NZ to Student] flow, which will be those students returning, along with new students entering for the first-time. But due to our filter, we currently only see flows going out of Student."],
         [undefined, undefined, "We also see a number of [Student to Work] and [Student to Recent Resident] flows, though these are comparatively much smaller."],
         [undefined, undefined, "You can click on the legend for [Student to OUTSIZE NZ] and [Student to Student] to hide those series. The chart will then dynamically zoom in, providing a better view of these smaller flows."],
         [insels.dvars, "<moveonly>"],
         [undefined, inlistToggle(inlists.dvars, true)],
         [makeid("dvars") + " + .inlist button[value=" + JSON.stringify("Nationality") + "]", "<noscroll>", "We can add more variables to the mix. Let's try adding Nationality."],
         [undefined, inlistToggle(inlists.dvars, false)],
         ["#BetterCSVs_hc-ts", "<moveonly>"],
         [undefined, hc_interactive],
         [undefined, undefined, "We can see Chinese students represent a large proportion of the flows, followed by India and South Korea."],
         ["#BetterCSVs_ts-more", undefined, "Again, we can see more series by using the 'Add more' button."],
         [undefined, hc_ireset],
         [undefined, mbiekun.hideslow, "That's it from me, have a play yourself to discover more about Migration Trends!"]
      ]
   };
   
   return defs;
}();

var mbiekun_tour_begin = function(tourName){
   if(tourName === undefined){tourName = "intro";}
   /* If mbiekun has not been init, launch intro tour */
   if(mbiekun.me === undefined){
      mbiekun.runTour(mbiekun_tour, tourName);
   } else{
      /* Check tour isn't already in progress, then launch intro tour */
      if(mbiekun.me.css("display") === "none"){
         mbiekun.runTour(mbiekun_tour, tourName);
      }
   }
};
