/* This is the public version of the google analytics tracker
   It just accumulates a local Array, rather than sending anything to google */

galog = [];
ga = function(){galog.push(arguments);};
