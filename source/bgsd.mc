(:background)
class bgsd extends Toybox.System.ServiceDelegate {
	const maxResults = 1;
	
	var calRequestIndex = 0;
	var calendarlist = {};
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
			    	//"maxResults" => maxResults,
			    	"fields" => "items(id,selected,backgroundColor)",
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
		    	//get calendar dict from object store
		    	var calendarlist = app.getProperty("calendarlist");
		    	
		    	//get lists of calendars
	    		var calendar_array = calendarlist.keys();
	    		calRequestIndex = 0;
    		
		    	request_url = "https://www.googleapis.com/calendar/v3/calendars/"+calendar_array[calRequestIndex]+"/events";
		    	
		    	request_params = {
		    		//"maxResults" => maxResults,
		    		"access_token" => "",
		    		"timeMin" => "",
		    		"timeMax" => "",
		    		"fields" => "summary,items(summary,start/dateTime,end/dateTime)",
		    		"timeZone" => "UTC"
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
    	
    	//make web request
	    Communications.makeWebRequest(request_url, request_params, options, method(:onReceiveWebRequest));	    
    }
    
    function onReceiveWebRequest(responseCode, data) {
    	
    	if(responseCode == 200) {
    		var app = Application.getApp();
    		
    		switch(app.getProperty("bg_phase")){
    			case GET_CALENDAR_LIST: {
    				//calendarlist may be too long to receive or return to main process
    				//get pages at a time, parse to calendarlist, then return only the necessary info
					for(var i = 0; i < data["items"].size(); i++){
						if(data["items"][i].hasKey("selected")){
							calendarlist.put(data["items"][i]["id"],data["items"][i]["backgroundColor"]);
						}
					}
					/*if(data.hasKey("nextPageToken")){
						var request_url = "https://www.googleapis.com/calendar/v3/users/me/calendarList";
						var request_params = {
					    	"maxResults" => maxResults,
					    	"pageToken" => data["nextPageToken"],
					    	"access_token" => ""
					    };					    
						request_params["access_token"] = app.getProperty("access_token");
	    				
	    				//send url and params for next request
					    requestNextPage(request_url,request_params);
					}else{
						Background.exit(calendarlist);
					}*/
					Background.exit(calendarlist);
					//Background.exit(data);
    				break;
    			}
    			case GET_EVENTS: {
    				//event list may be too long to return so we need to parse here
		    		var calendarlist = app.getProperty("calendarlist"); 
		    		
		    		//get lists of calendars
	    			var calendar_array = calendarlist.keys();
	    			
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
					
					
					//continue to get pages of events until no more pages available
					/*if(data.hasKey("nextPageToken")){
						//set request url to current calendar index
						var request_url = "https://www.googleapis.com/calendar/v3/calendars/"+calendar_array[calRequestIndex]+"/events";
    					
    					//parameters are identical to original request, plus the pagetoken
				    	var request_params = {
				    		"maxResults" => maxResults,
				    		"access_token" => "",
				    		"timeMin" => "",
				    		"timeMax" => "",
				    		"pageToken" => data["nextPageToken"]
				    	};   	
				    	request_params["access_token"] = app.getProperty("access_token");
						request_params["timeMin"] = app.getProperty("timeMin");
						request_params["timeMax"] = app.getProperty("timeMax");							
						
						//send url and params for next request
						requestNextPage(request_url,request_params);
					}else{*/
						//increment calendar index
						calRequestIndex++;
						
						//if we've reached the end of the calendar list, exit bg process, initiate new request
			    		if(calRequestIndex < calendar_array.size()){
			    			var request_url = "https://www.googleapis.com/calendar/v3/calendars/"+calendar_array[calRequestIndex]+"/events";
    	
					    	var request_params = {
					    		//"maxResults" => maxResults,
					    		"access_token" => "",
					    		"timeMin" => "",
					    		"timeMax" => "",
		    					"fields" => "summary,items(summary,start/dateTime,end/dateTime)",
		    					"timeZone" => "UTC"					    		
					    	};   	
					    	request_params["access_token"] = app.getProperty("access_token");
							request_params["timeMin"] = app.getProperty("timeMin");
							request_params["timeMax"] = app.getProperty("timeMax");	
						
			    			//send url and params for next request
			    			requestNextPage(request_url,request_params);
			    		}else{
			    			Background.exit(eventlist);
			    		}
			    		//Background.exit(eventlist);
					//}
					
					
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
		    		break;
    			}
    		}
    		  	
    	}else{
    		//Log info
    		System.println("Error ResponseCode:"+responseCode+" DATA:"+data);
    		/*var error_data = {
    			"error" => "unauthorized",
    			"ResponseCode" => "401"
    		};*/
    		Background.exit(data);
    	}    	
    }
    
    function requestNextPage(request_url,request_params){    	
	    //request options
		var options = {
	    	:method => Communications.HTTP_REQUEST_METHOD_GET,
	    	:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
	    	:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
	    };
	    
	    //make web request
	    Communications.makeWebRequest(request_url, request_params, options, method(:onReceiveWebRequest));
    }
}