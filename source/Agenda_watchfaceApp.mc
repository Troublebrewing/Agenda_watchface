using Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;

enum
{
	NO_DEVICE_CODE,
	NO_ACCESS_TOKEN,
	EXPIRED_ACCESS_TOKEN,
	GET_CALENDAR_LIST,
	GET_EVENTS,
	//GET_TEMP
}

//var eventlist = {};

(:background)
class Agenda_watchfaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        
        var app = Application.getApp();
        
        if(app.getProperty("bg_phase") == null){
        	app.setProperty("bg_phase", 0);
        }
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        //start temporal event to trigger auth complete check every 5 minutes
		Background.registerForTemporalEvent(new Time.Duration(5 * 60));
		
		//get location once
		return [ new Agenda_watchfaceView() ];
    }
    
    // This method runs each time the background process starts.
    function getServiceDelegate(){
        //return array of System.ServiceDelegate to handle background tasks
        return [new bgsd()];
    }
    
    function onBackgroundData(data) {    	
    	var app = Application.getApp();
    	//System.println(data);
    	if(data.hasKey("error")){
    		//bad response
    		System.println("bad response:"+data);
    		if((app.getProperty("bg_phase") == GET_CALENDAR_LIST) || (app.getProperty("bg_phase") == GET_EVENTS)){
    			//token expired, set bg phase to renew next cycle
    			app.setProperty("bg_phase", EXPIRED_ACCESS_TOKEN);
    		}
    	}else{
    		//received background data
    		switch(app.getProperty("bg_phase")){
    			case NO_DEVICE_CODE: {
    				app.setProperty("device_code",data["device_code"]);
    				//app.setProperty("verification_url",data["verification_url"];
    				app.setProperty("user_code", data["user_code"]);
    				app.setProperty("bg_phase", NO_ACCESS_TOKEN);
    				break;
    			}
    			case NO_ACCESS_TOKEN:
    			case EXPIRED_ACCESS_TOKEN: {
    				System.println("Token expired. Renewing...");
    				app.setProperty("access_token",data["access_token"]);
    				app.setProperty("expires_in",data["expires_in"]);
    				app.setProperty("token_type",data["token_type"]);
    				if(data.hasKey("refresh_token")){
    					app.setProperty("refresh_token",data["refresh_token"]);
    				}
    				app.setProperty("bg_phase",GET_CALENDAR_LIST);
    				break;
    			}
    			case GET_CALENDAR_LIST: {
	    			//parse in background process, write directly to object store    	
			 		app.setProperty("calendarlist",data);
			 		System.println("Calendar List Retrieved:"+app.getProperty("calendarlist"));
			 		
			 		//prep times for event query
			 		//get seconds in 2 hours
			    	var offsetduration = new Time.Duration(60*60*2);
			    	
			    	//get minimum time
			    	var datetime = Gregorian.utcInfo(Time.now().subtract(offsetduration), Time.FORMAT_SHORT);
			    	
			    	//create RFC3339 time string for timemin
			    	var timeMin = Lang.format(
			    		"$1$-$2$-$3$T$4$:$5$:$6$Z",
			    		[
			    			datetime.year,
			    			datetime.month.format("%02d"),
			    			datetime.day.format("%02d"),
			    			datetime.hour.format("%02d"),
			    			datetime.min.format("%02d"),
			    			datetime.sec.format("%02d")
			    		]
			    	);
			    	
			    	app.setProperty("timeMin",timeMin);
			    	
			    	//get seconds in 10 hours
			    	offsetduration = new Time.Duration(60*60*10);
			    	
			    	//increment current time by 10 hours
			    	datetime = Gregorian.utcInfo(Time.now().add(offsetduration), Time.FORMAT_SHORT);
			    	
			    	//create RFC3339 time string for timemax
			    	var timeMax = Lang.format(
			    		"$1$-$2$-$3$T$4$:$5$:$6$Z",
			    		[
			    			datetime.year,
			    			datetime.month.format("%02d"),
			    			datetime.day.format("%02d"),
			    			datetime.hour.format("%02d"),
			    			datetime.min.format("%02d"),
			    			datetime.sec.format("%02d")
			    		]
			    	);
			    	
			    	app.setProperty("timeMax",timeMax);
			 		
			 		app.setProperty("bg_phase",GET_EVENTS);
	    			break;
	    		}
	    		case GET_EVENTS: {
	    			//eventlist = data;
	    			app.setProperty("eventlist",data);
	    			System.println("Event list retrieved:"+app.getProperty("eventlist"));
	    			//app.setProperty("bg_phase",GET_TEMP);
	    			app.setProperty("bg_phase",GET_CALENDAR_LIST);
	    			
	    			break;
	    		}
	    		/*case GET_TEMP: {
	    			app.setProperty("current_temperature",data["current_temperature"]);
	    			System.println("Updated temperature:"+app.getProperty("current_temperature"));
	    			app.setProperty("bg_phase",GET_CALENDAR_LIST);
	    		}*/
    		}
    		
    		//show verification url and user code on screen
			WatchUi.requestUpdate();
    	}
    	    	    	
    }
}