using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class Agenda_watchfaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        //setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        var app = Application.getApp();
        var centerx = dc.getWidth()/2;
        var centery = dc.getHeight()/2;
    	
    	//draw time
    	var clockTime = System.getClockTime();
        var hour = clockTime.hour;
    	hour = hour%12;
    	if(hour == 0){
    		hour = 12;
    	}
        var timeString = Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
        
        //paint background black
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.clear();
        
        //draw shadow color first
        var myStats = System.getSystemStats();
        if(myStats.battery > 36){
        	dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);}
        if((myStats.battery <= 36) && (myStats.battery > 12)){
        	dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);}
        if(myStats.battery <= 12){
        	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);}
        dc.drawText(centerx+5,centery+5,Graphics.FONT_NUMBER_THAI_HOT ,timeString,Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
        
        //draw main clock time
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerx,centery,Graphics.FONT_NUMBER_THAI_HOT ,timeString,Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
        
        //draw date        
        var dow = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var datetime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var date_string = dow.day_of_week.toUpper() + "." + datetime.month + "." + datetime.day + "." + datetime.year;
        dc.drawText(centerx, centery-40, Graphics.FONT_MEDIUM, date_string, Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
        
        //draw temperature        
        //Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:getLocation));
        if(app.getProperty("current_temperature") != null){
        	dc.drawText(centerx, centery-80, Graphics.FONT_MEDIUM, app.getProperty("current_temperature").toNumber()+"°", Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(centerx, centery-80, Graphics.FONT_MEDIUM, app.getProperty("bg_phase").toNumber(), Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);        
               
        //draw arc for each event
        dc.setPenWidth(10);
        
        //get size of googleOAuth.eventlist
        var event_array = eventlist.keys();        
        
        for(var i = 0; i < event_array.size(); i++){
        	//translate start time to degrees
        	if((eventlist[event_array[i]]["start"] != null) && (eventlist[event_array[i]]["end"] != null)){
	        	var start_hr = eventlist[event_array[i]]["start"].substring(11,13).toNumber();
	        	var start_min = eventlist[event_array[i]]["start"].substring(14,16).toNumber();
	        	var degreeStart = ((810-(30*(start_hr%12)))-((start_min.toFloat()/60.0)*30.0).toNumber())%360;
        	        	
        		//translate end time to degrees
	        	var end_hr = eventlist[event_array[i]]["end"].substring(11,13).toNumber();
	        	var end_min = eventlist[event_array[i]]["end"].substring(14,16).toNumber(); //0-60 min ~ 30 degree
	        	var degreeEnd = ((810-(30*(end_hr%12)))-((end_min.toFloat()/60.0)*30.0).toNumber())%360;
	        	
	        	//set color to match calendar source
	        	var arc_color = Graphics.COLOR_BLUE;
	        	if(eventlist[event_array[i]]["color"] != null){
	        		arc_color = eventlist[event_array[i]]["color"].substring(1,7).toNumberWithBase(16);
	        	}
	        	dc.setColor(arc_color, Graphics.COLOR_TRANSPARENT);
	        	
	        	//draw arc
	        	dc.drawArc(centerx,centery,120,Graphics.ARC_CLOCKWISE,degreeStart,degreeEnd);
        	}
        }
        
        //draw pointer to current time
		var hour_angle = ((810-(30*(clockTime.hour%12)))-((clockTime.min.toFloat()/60.0)*30.0).toNumber())%360;
        var tip = [(110.0*Math.cos(Math.toRadians(hour_angle.toFloat())))+centerx,centery-(110.0*Math.sin(Math.toRadians(hour_angle.toFloat())))];
        var point1 = [tip[0]-(14*Math.cos(Math.toRadians(hour_angle+45))),tip[1]+(14*Math.sin(Math.toRadians(hour_angle+45)))];
        var point2 = [tip[0]-(14*Math.cos(Math.toRadians(hour_angle-45))),tip[1]+(14*Math.sin(Math.toRadians(hour_angle-45)))];
        
        var pointlist = [tip, point1, point2];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pointlist);
        
        if(app.getProperty("bg_phase") == NO_ACCESS_TOKEN){
        	dc.drawText(centerx, centery+50, Graphics.FONT_XTINY, "visit:google.com/device", Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
	    	dc.drawText(centerx, centery+70, Graphics.FONT_XTINY,"CODE:"+ app.getProperty("user_code"), Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
	    }else{
	        //list upcoming event
	        var now = Time.now();
	        //System.println("NOW (UNIX):"+now.value());
	        if(event_array.size() != 0){
		        //init index variable outside loop so we know where it stopped
		        var upcoming_event_index = 0;
		        var upcoming_event_delay = "";
		        for(upcoming_event_index = 0; upcoming_event_index < event_array.size(); upcoming_event_index++){
		        	//convert RFC3339 timestamp to UNIX UTC
		        	var upcoming_event_moment = RFC3339toMoment(eventlist[event_array[upcoming_event_index]]["start"]);
		        	
		        	upcoming_event_delay = upcoming_event_moment.compare(now);
		        	
		        	if(upcoming_event_delay > 0){
		        		break;
		        	}
		        }
		        
		        //check if loop exited early
		        if(upcoming_event_index < event_array.size()){        
		        	//draw text
		        	dc.drawText(centerx, centery+50, Graphics.FONT_XTINY, event_array[upcoming_event_index].substring(0,12), Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
		        	dc.drawText(centerx, centery+70, Graphics.FONT_XTINY,"in "+ (upcoming_event_delay/60) +" min", Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
		        }
	        }    
	    }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }
    
    function RFC3339toMoment(RFC3339_string){
    	//System.println(RFC3339_string);
    	
    	var year = RFC3339_string.substring(0,4).toNumber();
    	var month = RFC3339_string.substring(5,7).toNumber();
    	var day = RFC3339_string.substring(8,10).toNumber();
    	var hour = RFC3339_string.substring(11,13).toNumber();
    	var minute = RFC3339_string.substring(14,16).toNumber();
    	var second = RFC3339_string.substring(17,19).toNumber();
    	var timezone_offset = RFC3339_string.substring(20,22).toNumber();
    	
    	var options = {
    		:year => year,
    		:month => month,
    		:day => day,
    		:hour => hour,
    		:minute => minute,
    		:second => second
    	};
    	
    	var localtime = Gregorian.moment(options);
    	
    	//System.println("timezone:"+timezone_offset);
    	
    	var utc_time = localtime;    	
    	if(RFC3339_string.substring(19,20).equals("-")){
    		utc_time = localtime.add(new Time.Duration(timezone_offset*3600));
    	}else{
    		utc_time = localtime.subtract(new Time.Duration(timezone_offset*3600));
    	}
    	
    	return(utc_time);
    }
    
    	
	function getLocation(info){
	    var app = Application.getApp();
	    var myLocation = info.position.toDegrees();
	    app.setProperty("latitude",myLocation[0]);
	    app.setProperty("longitude",myLocation[1]);	    
	}
}
