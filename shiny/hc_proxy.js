/* JavaScript handler for hc_proxy.R methods */
var hcProxy = function(msg){
   var hc = $("#" + msg.id).highcharts();
   if(msg.type == "redraw"){
      hc.redraw();
   } else if(msg.type == "update"){
      hc.update({series: msg.data}, msg.redraw);
   } else if(msg.type == "add"){
      msg.data.map(function(x){hc.addSeries(x, msg.redraw);});
   } else if(msg.type == "remove"){
      msg.data.map(function(x){
         var curseries = hc.get(x);
         if(curseries !== undefined){
            curseries.remove(msg.redraw);
         }
      });
   } else if(msg.type == "remove_all"){
      /* First get ids, then remove by id, as this is more reliable */
      hc.series
         .map(function(x){return x.options.id;})
         .map(function(x){hc.get(x).remove(msg.redraw);});
   } else if(msg.type == "hide_all"){
      /* First get ids, then hide by id, as this is more reliable */
      hc.series
         .map(function(x){return x.options.id;})
         .map(function(x){
            var curseries = hc.get(x);
            if(curseries.visible){
               curseries.setVisible(false, msg.redraw);
            }
         });
   } else if(msg.type == "show_all"){
      /* First get ids, then show by id, as this is more reliable */
      hc.series
         .map(function(x){return x.options.id;})
         .map(function(x){
            var curseries = hc.get(x);
            if(!curseries.visible){
               curseries.setVisible(true, msg.redraw);
            }
         });
   }
};

$(function(){
   Shiny.addCustomMessageHandler("hc-proxy", hcProxy);
});
