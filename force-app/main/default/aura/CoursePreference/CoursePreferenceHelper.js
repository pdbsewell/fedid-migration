({
    parseApplicationId:function()
    {
        //get and set Application Id
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        //console.log('sURLVariables: '+sURLVariables);
        var sParameterName;
        var sValue;
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for(var x = 0; x < sParameterName.length; x++){
                if(sParameterName[x] === 'appId'){
                    sValue = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1];
                    return sValue;
                }
            }
        }

        return null;
    },

    queryApplicationCourse : function(component, event, helper) {
        var action = component.get("c.retrieveAppCourses");
        var varAppId = component.get("v.applicationRecord");
        action.setParams({"appId": varAppId});
        action.setCallback(this, function(response) {
            component.set("v.applicationCourses", response.getReturnValue());
        });

        $A.enqueueAction(action);
    },

    retrievePicklistValues : function(actionToRun, inputsel) {
        var opts=[];
        actionToRun.setCallback(this, function(a) {
            opts.push({"class": "optionClass", label: "--Select--", value: ""});
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(actionToRun);
    },


    populateSelect:function(inputSel, arrOptions)
    {
        var iLen = arrOptions.length;
        var opts = [];

        // default blank selection
        opts.push({"class": "optionClass", label: "--Select--", value: ""});
        for(var i = 0; i < iLen; ++i)
        {
            var sOption = arrOptions[i];
            opts.push({"class": "optionClass"
                , label: sOption
                , value: sOption});
        }
        inputSel.set("v.options", opts);
    },

    findCourseOfferingsBak : function(component, actionName) {
        // added by Majid in order to show the spinner for waiting
        // added on 26-04-2018
        document.getElementById("waitingDiv").style.display = "block";
        component.set("v.showList", false);

        //search filters
        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = "";
        var varLocation = "";
        var varPeriod = "";

        if(actionName === "Apply Filters") {
            varAttendType = component.get("v.selectedAttendType");
            varLocation = component.get("v.selectedLocation");
            varPeriod = component.get("v.selectedPeriod");
        }

        else{
            //clear filters
            component.set("v.selectedAttendType", "");
            component.find("attypes").set("v.value","");
            component.set("v.selectedLocation", "");
            component.find("locations").set("v.value","");
            component.set("v.selectedPeriod", "");
            component.find("periods").set("v.value","");

            //retrive Location base on course location
            var actionSetLocationValues = component.get("c.retrieveLocation");
            actionSetLocationValues.setParams({"searchStr": varSearch});
            var optsLoc=[];
            actionSetLocationValues.setCallback(this, function(a) {
                optsLoc.push({"class": "optionClass", label: "--Select--", value: ""});
                for(var i=0;i< a.getReturnValue().length;i++){
                    optsLoc.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
                }
                component.find("locations").set("v.options", optsLoc);

            });
            $A.enqueueAction(actionSetLocationValues);

            //retrive Location base on course location
            var actionSetPeriodValues = component.get("c.retrieveCommencementPeriod");
            actionSetPeriodValues.setParams({"searchStr": varSearch});
            var optsPeriod=[];
            actionSetPeriodValues.setCallback(this, function(a) {
                optsPeriod.push({"class": "optionClass", label: "--Select--", value: ""});
                for(var i=0;i< a.getReturnValue().length;i++){
                    optsPeriod.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
                }
                component.find("periods").set("v.options", optsPeriod);

            });
            $A.enqueueAction(actionSetPeriodValues);
        }

        var Currentpage = 0;
        var pageSize = component.get("v.pageSize");

        //get total number of records for pagination
        var actionGetTotalRecords = component.get("c.retrieveCoursesTotalRecord");
        actionGetTotalRecords.setParams({
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod
        });
        actionGetTotalRecords.setCallback(this, function(a) {
            var courseData = a.getReturnValue();
            component.set("v.TotalRecords", courseData);
            component.set("v.Totalpages", Math.ceil(courseData/pageSize));
            component.set("v.prev",true);
            if(courseData <= pageSize){
                component.set("v.next",true);
            }
            else{
                component.set("v.next",false);
            }
        });
        $A.enqueueAction(actionGetTotalRecords);

        //collect unique courses
        var action = component.get("c.findCourses");
        action.setParams({
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize,
            "pagenumber" : Currentpage
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var courses=response.getReturnValue()
                var wrappers=new Array();
                for (var idx=0; idx<courses.length; idx++) {

                    var objCourse = courses[idx];
                    //console.log(objCourse.Course_Title__c + ' ' + objCourse.Unit_Set_Code__c);
                    var wrapper = { "isSelected" : false,
                        "course" : objCourse
                    };
                    wrappers.push(wrapper);
                }
                component.set("v.courseList", wrappers);
                //console.debug('COURSE LIST: '+wrappers.length);

                Currentpage=Currentpage+1;
                component.set("v.Currentpage",Currentpage);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error : " + JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);

        //collect course with unit sets
        var actionGetCourseUnits = component.get("c.retrieveCoursesWithUnitSets");

        actionGetCourseUnits.setParams({
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod
        });
        actionGetCourseUnits.setCallback(this, function(a) {
            var courseUnitData = a.getReturnValue();
            var unitWrappers = new Array();
            for (var idx=0; idx<courseUnitData.length; idx++) {
                var wrapper = { "isSelected" : false,
                    "course" : courseUnitData[idx]
                };
                unitWrappers.push(wrapper);
            }
            component.set("v.courseUnits", unitWrappers);
            //console.debug('COURSE WITH UNIT SETS: '+unitWrappers.length);

            // added by Majid in order to stop showing the spinner
            // added on 26-04-2018
            document.getElementById("waitingDiv").style.display = "none";
            console.log('finished');
        });
        $A.enqueueAction(actionGetCourseUnits);

        component.set("v.showList", true);
    },

    findCourseOfferings : function(component, actionName) {
        document.getElementById("waitingDiv").style.display = "block";
        component.set("v.showList", false);

        //search filters
        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = "";
        var varLocation = "";
        var varPeriod = "";
        
        // limited by campus locations
        var appCampusLocation = component.get("v.appCampusLocation");
        console.log('CoursePreference app location::' + appCampusLocation);

        if(actionName === "Apply Filters") {
            varAttendType = component.get("v.selectedAttendType");
            varLocation = component.get("v.selectedLocation");
            varPeriod = component.get("v.selectedPeriod");
        }

        else{
            //clear filters
            component.set("v.selectedAttendType", "");
            component.find("attypes").set("v.value","");
            component.set("v.selectedLocation", "");
            component.find("locations").set("v.value","");
            component.set("v.selectedPeriod", "");
            component.find("periods").set("v.value","");

        }

        var Currentpage = 0;
        var pageSize = component.get("v.pageSize");
        var actionGetCourseOfferings = component.get("c.getCourseOfferings");
        var objParams = {
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize,
            "pagenumber" : Currentpage,
            "appCampusLocation":appCampusLocation
        };
        actionGetCourseOfferings.setParams(objParams);
        actionGetCourseOfferings.setCallback(this, function(response){
            var state = response.getState();
            //console.log('CoursePreferenceHelper:: getCourseOfferings = ' + state);
            if(state == "SUCCESS")
            {
                var objResponse = response.getReturnValue();
                
                console.log('CoursePreference::' + objResponse.startIndex + ", " + objResponse.endIndex);

                // total records
                this.parsePagination(component, objResponse.total_courses, pageSize);

                // unique courses
                this.parseCourses(component, objResponse.courses, Currentpage);

                // unit sets
                this.parseUnitSets(component, objResponse.course_units);

                // location filter
                this.populateSelect(component.find("locations"), objResponse.course_locations);
                
                // commencement period
                this.populateSelect(component.find("periods"), objResponse.commencement_periods);

                component.set("v.showList", true);

                // TODO - change to show/hide
                document.getElementById("waitingDiv").style.display = "none";
                //console.log('CoursePreferenceHelper::getCourseOfferings finished');
            }
            else
            {
                var errors = actionGetCourseOfferings.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('CoursePreferenceHelper::getCourseOfferings:' + errors[0].message);
                    }
                }
            }
        });

        $A.enqueueAction(actionGetCourseOfferings);
    },

    parsePagination:function(component, totalRecords, pageSize)
    {
        component.set("v.TotalRecords", totalRecords);
        component.set("v.Totalpages", Math.ceil(totalRecords/pageSize));
        component.set("v.prev",true);
        if(totalRecords <= pageSize){
            component.set("v.next",true);
        }
        else{
            component.set("v.next",false);
        }
    },

    parseCourses:function(component, courses, Currentpage)
    {
        var wrappers=new Array();
        for (var idx=0; idx<courses.length; idx++)
        {
            var objCourse = courses[idx];
            //console.log(objCourse.Course_Title__c + ' ' + objCourse.Unit_Set_Code__c);
            var wrapper = { "isSelected" : false,
                "course" : objCourse
            };
            wrappers.push(wrapper);
        }
        component.set("v.courseList", wrappers);
        //console.debug('COURSE LIST: '+wrappers.length);

        Currentpage=Currentpage+1;
        component.set("v.Currentpage",Currentpage);

    }

    , parseUnitSets:function(component, courseUnitData)
    {
        var unitWrappers = new Array();
        for (var idx=0; idx<courseUnitData.length; idx++) {
            var wrapper = { "isSelected" : false,
                "course" : courseUnitData[idx]
            };
            unitWrappers.push(wrapper);
        }
        component.set("v.courseUnits", unitWrappers);
        //console.debug('COURSE WITH UNIT SETS: '+unitWrappers.length);
    }
    
    , addCourseForArea:function(arrMap, courseUniqueCode)
    {
        var objCourse = {};
        objCourse.code = courseUniqueCode;
        arrMap.push(objCourse);
    }
    
    , selectedAreaForCourse:function(arrMap, courseUniqueCode)
    {
        for(var i = 0; i < arrMap.length;++i)
        {
            var objCourse = arrMap[i];
            
            console.log('course id = ' + objCourse.code + ", " + courseUniqueCode + ", equals?" + (objCourse.code == courseUniqueCode));
            if(objCourse.code == courseUniqueCode)
            {
                objCourse.has_area = true;
                console.log('course id = ' + objCourse.code + ", " + courseUniqueCode);
                return;
            }
        }
    }
    
    , allCoursesHaveAreas:function(arrMap)
    {
        console.log('allCoursesHaveAreas::' + arrMap.length);
        for(var i = 0; i < arrMap.length; ++i)
        {
            var objCourse = arrMap[i];
            if(!objCourse.has_area)
            {
                console.error('CoursePreferenceHelper:: Course ID without area of study selected :' + objCourse.code);
                return false;
            }
        }
        return true;
    }

    , debugObject:function(obj, sTag)
    {
        console.debug(sTag + ' {');
        for(var k in obj)
        {
            console.debug(k + ':' + obj[k]);
        }
        console.debug('}');
    }
})