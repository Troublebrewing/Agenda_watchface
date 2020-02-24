(:background)
class bgsd extends Toybox.System.ServiceDelegate {
	
	var pendingrequests = 0;
	var eventlist = {};
	
	function initialize() {
		System.ServiceDelegate.initialize();
	}
			
	//every time timer expires
    function onTemporalEvent() {
    	//System.println("Entered onTemporalEvent()");
    	
    	var app = Application.getApp();
    	
    	var request_url = "";
    	var request_params = {};
    	var options = {};
    	
    	switch(app.getProperty("bg_phase")){
    		case NO_DEVICE_CODE: {
    			request_url = "https://oauth2.googleapis.com/device/code";
    			request_params = {
			    	"client_id" => "1037421753678-7nt6q3fdfkhvtoct8ddhi5vp6odjps2d.apps.googleusercontent.com",
					"scope" => "https://www.googleapis.com/auth/calendar.readonly"
			    };
			    options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_POST,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };
	    		break;
    		}
    		
    		case NO_ACCESS_TOKEN: {
    			request_url = "https://oauth2.googleapis.com/token";
    			request_params = {
			    	"client_id" => "1037421753678-7nt6q3fdfkhvtoct8ddhi5vp6odjps2d.apps.googleusercontent.com",
					"client_secret" => "GqKFxCAQYzq9yjbLkIO5YjRL",
					"device_code" => "",
					"grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
			    };
			    request_params["device_code"] = app.getProperty("device_code");
			    options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_POST,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };
    			break;
    		}
    		
    		case EXPIRED_ACCESS_TOKEN: {
    			request_url = "https://oauth2.googleapis.com/token";
    			request_params = {
			    	"client_id" => "1037421753678-7nt6q3fdfkhvtoct8ddhi5vp6odjps2d.apps.googleusercontent.com",
					"client_secret" => "GqKFxCAQYzq9yjbLkIO5YjRL",
					"refresh_token" => "",
					"grant_type" => "refresh_token"
			    };
			    request_params["refresh_token"] = app.getProperty("refresh_token");
				options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_POST,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };
    			break;
    		}

    		case GET_CALENDAR_LIST: {
    			request_url = "https://www.googleapis.com/calendar/v3/users/me/calendarList";
    			request_params = {
			    	"access_token" => ""
			    };
			    request_params["access_token"] = app.getProperty("access_token");
			    options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_GET,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };
			    break;
    		}
    		case GET_EVENTS: {
    			//request parameters are the same for each calendar
		    	request_params = {
		    		"access_token" => "",
		    		"timeMin" => "",
		    		"timeMax" => ""
		    	};   	
		    	request_params["access_token"] = app.getProperty("access_token");
				request_params["timeMin"] = app.getProperty("timeMin");
				request_params["timeMax"] = app.getProperty("timeMax");			
								
				//request options
				options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_GET,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };	
			    break;
    		}
    		/*case GET_TEMP: {
    			//var latitude = "";
    			//var longitude = "";
    			//if((app.getProperty("latitude") != null) && (app.getProperty("latitude") != null)){
    				//latitude = app.getProperty("latitude");
    				//longitude = app.getProperty("longitude");
    			//}
    				
    			//request_url = "https://api.darksky.net/forecast/ae02f1341527b55ecd98fe2774e77929/"+latitude+","+longitude;
	    		request_url = "https://api.darksky.net/forecast/ae02f1341527b55ecd98fe2774e77929/39.231864,-84.520454";
	    
	    		request_params = {};
	    
			    options = {
			    	:method => Communications.HTTP_REQUEST_METHOD_GET,
			    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
			    };
			    break;
    		}*/
    	}
    	
    	if(app.getProperty("bg_phase") != GET_EVENTS){
	    	//make web request
	    	Communications.makeWebRequest(request_url, request_params, options, method(:onReceiveWebRequest));
	    }else{
	    	//get calendar dict from object store
	    	var calendarlist = app.getProperty("calendarlist");
	    	
	    	//get lists of calendars
    		var calendar_array = calendarlist.keys();
    		
    		//request for every calendar
	    	for(var c = 0; c < calendarlist.size(); c++){
	    	
	    		var request_url = "https://www.googleapis.com/calendar/v3/calendars/"+calendar_array[c]+"/events";
	    		
	    		//make actual web request
	    		Communications.makeWebRequest(request_url, request_params, options, method(:onReceiveWebRequest));
	    		
	    		pendingrequests++;
	    	}
	    }
    }
    
    function onReceiveWebRequest(responseCode, data) {
    	if(responseCode == 200) {
    		var app = Application.getApp();
    		
    		switch(app.getProperty("bg_phase")){
    			case GET_CALENDAR_LIST: {
    				//calendarlist may be too long to return through background.exit so we need to parse here
    				//parse calendarlist to smaller dict
					var calendarlist = {};
					for(var i = 0; i < data["items"].size(); i++){
						if(data["items"][i].hasKey("selected")){
							calendarlist.put(data["items"][i]["id"],data["items"][i]["backgroundColor"]);
						}
					}
					Background.exit(calendarlist);
    				break;
    			}
    			case GET_EVENTS: {
    				//event list may be too long to return so we need to parse here
		    		var calendarlist = app.getProperty("calendarlist"); 
		    		
		    		//parse events out			
					for(var i = 0; i < data["items"].size(); i++){
						//filters out all day events
						if(data["items"][i]["start"].hasKey("dateTime")){
							eventlist.put(
								data["items"][i]["summary"],
								{
									"start" => data["items"][i]["start"]["dateTime"],
									"end" => data["items"][i]["end"]["dateTime"],
									"color" => calendarlist[data["summary"]]
								}
							);
						}
					}
					
					pendingrequests--;
    				break;
    			}
    			/*case GET_TEMP: {
    				var ret = {"current_temperature" => ""};
    				ret["current_temperature"] = data["currently"]["temperature"];
    				Background.exit(ret);
    				break;
    			}*/
    			default: {
    				//set received data directly back to main process
		    		//this is size limited
		    		Background.exit(data);
    			}
    		}
    		  	
    	}else{
    		//send responseCode back
    		Background.exit(data);
    	}
    	 	
    	if(pendingrequests == 0){
    		//send eventlist back
    		Background.exit(eventlist);
    	}
    	
    }
}