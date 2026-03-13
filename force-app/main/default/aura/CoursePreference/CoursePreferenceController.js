({
	doInit : function(component, event, helper) {
        var applicationId = helper.parseApplicationId();

        component.set("v.applicationRecord", applicationId);

        // 2018/09/05 - group all initialising calls
        var actionInit = component.get("c.getInitData");
        var objParams = {
            "applicationId"  :applicationId
        };
        actionInit.setParams(objParams);
        actionInit.setCallback(this, function(response){
            
            if(response.getState() == "SUCCESS")
            {
                //console.debug('coursePreferenceController::getInitData');                
                var objResponse = response.getReturnValue();                
                // attendance types
            	helper.populateSelect(component.find("attypes"), objResponse.attendance_types);                            
                // acps
                component.set("v.applicationCourses", objResponse.acps);                
                // residency status
                component.set("v.residencyStatus", objResponse.residency_status);                
                component.set("v.appCampusLocation", objResponse.application_campus_location);
                
                // debugging
                //console.debug('coursePreferenceController::campus = ' + objResponse.application_campus_location);
                //console.debug('coursePreferenceController::citizenship = ' + objResponse.residency_status);
            }
        });        
        $A.enqueueAction(actionInit);
        
        /*
        // Added by Hardeep Singh 20/05/2018
        // The call set the residencyStatus attribute for <aura:if> conditions in component
        var action_Residency = component.get("c.retrieveResidencyStatus");
        action_Residency.setCallback(this,function(response){
            component.set("v.residencyStatus", response.getReturnValue());
        });
        $A.enqueueAction(action_Residency);
        
        var action = component.get("c.retrieveAppCourses");
        var varAppId = component.get("v.applicationRecord");
        action.setParams({"appId": varAppId});
        action.setCallback(this, function(response) {
            component.set("v.applicationCourses", response.getReturnValue());
        });

        $A.enqueueAction(action);

        helper.retrievePicklistValues(component.get("c.retrieveAttendanceType"), component.find("attypes"));
        */
    },

    showConfirmDeletePopup : function (component, event, helper){     
        /*var domEvent = event.getParams().domEvent;
        var bodySpan = domEvent.target.nextSibling;
        
        var appCourseId = bodySpan.dataset.id;*/

        var source = event.getSource(); // this would give that particular component
        var appCourseId = source.get("v.name"); // returns the id

        //assign Id and show the confirmation popup
        component.set("v.selRecToDelId", appCourseId);
        component.set("v.showConfirmPopup", true);
    },

    deleteAppCourse : function (component, event, helper){     
        var courseId = component.get("v.selRecToDelId");

        var action_deleteCourseRecord = component.get("c.deleteSelectedCourse");
        
        action_deleteCourseRecord.setParams({ "deleteThisCourse" : courseId, 
                                            "applicationId": component.get("v.applicationRecord")});
        
        action_deleteCourseRecord.setCallback(this, function(a) {
            var state = a.getState();
            if (state == "ERROR") {
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                        component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
                    }
                } else {
                    console.log("Unknown error");
                }
            }

            helper.queryApplicationCourse(component);
            //close the confirmation popup
            component.set("v.showConfirmPopup", false);
        });
        //Action 1, delete the record
        $A.enqueueAction(action_deleteCourseRecord);
        window.location.hash = '#myCourse';
    },

    cancelDelete : function (component, event, helper){     
        //close the confirmation popup
        component.set("v.showConfirmPopup", false);
        window.location.hash = '#myCourse';
    },

    searchCourses : function(component, event, helper) {
        helper.findCourseOfferings(component, "Search Courses");
        window.location.hash = '#courseList';
    },
    
    searchCoursesWhenEnterPressed : function (component, event, helper) {
        // if button enter has pressed
        if (event.getParams().keyCode == 13){
            helper.findCourseOfferings(component, "Search Courses");
        }    
    },

    ApplyFilter : function(component, event, helper) {
        helper.findCourseOfferings(component, "Apply Filters");
    },

    ResetFilter  : function(component, event, helper) {
        helper.findCourseOfferings(component, "Reset Filters");
    },

    showUnitSets : function(component, event, helper) {
        //var domEvent = event.getParams().domEvent;
        //var bodySpan = domEvent.target.nextSibling;

        var source = event.getSource(); // this would give that particular component
        var courseUniqueCode = source.get("v.name"); // returns the id
        
        //var courseUniqueCode = bodySpan.dataset.uniquecode;
        console.debug('COURSE CODE: '+courseUniqueCode);
        component.set("v.selRecToView", courseUniqueCode);

        //helper.retrieveStatusMessage(component);
        
        component.set("v.showStatusPopup", true);

        console.log(courseUniqueCode);
    },

    closeViewModal : function (component, event, helper){     
        //close the confirmation popup
        component.set("v.showStatusPopup", false);
    },

    //Pagination methods
    NextPage:function(component, event, helper) {
        //get filters
        window.location.hash = '#new';

        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = component.get("v.selectedAttendType");
        var varLocation = component.get("v.selectedLocation");
        var varPeriod = component.get("v.selectedPeriod");

        component.set("v.prev",false);
        var Currentpage = component.get("v.Currentpage");        
        var pageSize = component.get("v.pageSize"); 
        var Totalpages = component.get("v.Totalpages");
        if(Currentpage >= Totalpages){
            Currentpage=Currentpage-1;
        }

        var actionNextPage = component.get("c.getCourseOfferings");
        var nextParams = {
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize,
            "pagenumber" : Currentpage,
            "appCampusLocation" : component.get("v.appCampusLocation")
        };

        //console.log(nextParams);
        actionNextPage.setParams(nextParams);
        actionNextPage.setCallback(this, function(response) {
            var state = response.getState();

            if(state == 'SUCCESS')
            {
                var objResponse = response.getReturnValue();

                console.log('CoursePreference::' + objResponse.startIndex + ", " + objResponse.endIndex);

                var courses = objResponse.courses;
                var wrappers=new Array();
                for (var idx=0; idx<courses.length; idx++) {
                    var wrapper = { "isSelected" : false,
                        "course" : courses[idx]
                    };
                    wrappers.push(wrapper);
                }
                component.set("v.courseList", wrappers);
                Currentpage=Currentpage+1;
                if(Currentpage >= Totalpages){
                    Currentpage = Totalpages;
                    component.set("v.Currentpage", Totalpages);
                    component.set("v.next",true);
                }
                component.set("v.Currentpage",Currentpage);
            }
            else
            {
                console.error('CoursePreferenceController:: error on Next Page');
            }
        });
        $A.enqueueAction(actionNextPage);

        window.location.hash = '#courseList';
    },

    PreviousPage:function(component, event, helper) {
        //get filters
        window.location.hash = '#new';

        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = component.get("v.selectedAttendType");
        var varLocation = component.get("v.selectedLocation");
        var varPeriod = component.get("v.selectedPeriod");
        
        component.set("v.next",false);
        var Currentpage = component.get("v.Currentpage");        
        var pageSize = component.get("v.pageSize"); 
        var Totalpages = component.get("v.Totalpages");
        Currentpage=Currentpage-2;
        if(Currentpage <= 0){
            Currentpage = 0;
            component.set("v.Currentpage", 0);
            component.set("v.prev",true);
        }

        var actionPreviousPage = component.get("c.getCourseOfferings");
        actionPreviousPage.setParams({  
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize, 
            "pagenumber" : Currentpage ,
            "appCampusLocation" : component.get("v.appCampusLocation")
        });
        actionPreviousPage.setCallback(this, function(a) {
            var state = response.getState();

            if(state == 'SUCCESS')
            {
                var objResponse = response.getReturnValue();

                var courses = objResponse.courses;
                var wrappers=new Array();
                for (var idx=0; idx<courses.length; idx++) {
                    var wrapper = { "isSelected" : false,
                        "course" : courses[idx]
                    };
                    wrappers.push(wrapper);
                }
                component.set("v.courseList", wrappers);
                Currentpage=Currentpage+1;
                if(Currentpage >= Totalpages){
                    Currentpage = Totalpages;
                    component.set("v.Currentpage", Totalpages);
                    component.set("v.next",true);
                }
                component.set("v.Currentpage",Currentpage);
            }
            else
            {
                console.error('CoursePreferenceController:: error on Previous Page');
            }
        });
        $A.enqueueAction(actionPreviousPage);

        window.location.hash = '#courseList';
    },

    LastPage:function(component, event, helper) {
        //get filters
        window.location.hash = '#new';

        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = component.get("v.selectedAttendType");
        var varLocation = component.get("v.selectedLocation");
        var varPeriod = component.get("v.selectedPeriod");

        component.set("v.next",true);
        component.set("v.prev",false);
        var Totalpages = component.get("v.Totalpages"); 
        var pageSize = component.get("v.pageSize");

        var actionLastPage = component.get("c.findCourses");
        actionLastPage.setParams({  
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize, 
            "pagenumber" : Totalpages-1 ,
            "appCampusLocation" : component.get("v.appCampusLocation")
        });
        actionLastPage.setCallback(this, function(a) {
            var courses = a.getReturnValue();
            var wrappers=new Array();
            for (var idx=0; idx<courses.length; idx++) {
                var wrapper = { "isSelected" : false,
                                "course" : courses[idx] 
                                };
                wrappers.push(wrapper);
            }
            component.set("v.courseList", wrappers);
            component.set("v.Currentpage", Totalpages);
        });
        $A.enqueueAction(actionLastPage);

        window.location.hash = '#courseList';
    }, 
    
    FirstPage:function(component, event, helper) {
        //get filters
        window.location.hash = '#new';

        var varSearch = component.get("v.searchStr");
        var varSearchCode = component.get("v.applicationRecord");
        var varAttendType = component.get("v.selectedAttendType");
        var varLocation = component.get("v.selectedLocation");
        var varPeriod = component.get("v.selectedPeriod");

        component.set("v.next",false);
        component.set("v.prev",true);
        var Currentpage = 0;
        var pageSize = component.get("v.pageSize");

        var actionFirstPage = component.get("c.findCourses");
        actionFirstPage.setParams({  
            "searchStr": varSearch,
            "strCode": varSearchCode,
            "strAttType": varAttendType,
            "strLocation": varLocation,
            "strPeriod": varPeriod,
            "pagesize" : pageSize, 
            "pagenumber" : Currentpage 
        });
        actionFirstPage.setCallback(this, function(a) {
            var courses = a.getReturnValue();
            var wrappers=new Array();
            for (var idx=0; idx<courses.length; idx++) {
                var wrapper = { "isSelected" : false,
                                "course" : courses[idx] 
                                };
                wrappers.push(wrapper);
            }
            component.set("v.courseList", wrappers);
            component.set("v.Currentpage", 1);
        });
        $A.enqueueAction(actionFirstPage);

        window.location.hash = '#courseList';
    },
    //End of Pagination

    onSelectAttendanceType : function(component, event, helper) {
        var selected = component.find("attypes").get("v.value");
        component.set("v.selectedAttendType", selected);
    },

    onSelectLocation : function(component, event, helper) {
        var selected = component.find("locations").get("v.value");
        component.set("v.selectedLocation", selected);
    },

    onSelectPeriod : function(component, event, helper) {
        var selected = component.find("periods").get("v.value");
        component.set("v.selectedPeriod", selected);
    },

    cancelSearch : function(component, event, helper) {
        component.set("v.showList", false);
        component.set("v.searchStr", "");
        //clear filters
        component.set("v.selectedAttendType", "");
        component.find("attypes").set("v.value","");
        component.set("v.selectedLocation", "");
        component.find("locations").set("v.value","");
        component.set("v.selectedPeriod", "");
        component.find("periods").set("v.value","");
        component.set("v.errorMessage", "");
        window.location.hash = '#searchCourse';
    },

    addSelectedCourse : function(component, event, helper) {
        var action = component.get("c.addCourse");
        var currentCourses = component.get("v.applicationCourses");
        var appId = component.get("v.applicationRecord");
        
        var cntSelected = 0;
        //collect selected courses without unit sets
        var crsWrapper = component.get("v.courseList");
        var courseIds = new Array();

        // Courses with a Unit_Set_Code__c require an area of study selected
        
        var arrRequiresAoS = [];
        for (var idx=0; idx<crsWrapper.length; idx++)
        {
            var optionCourse = crsWrapper[idx];
            if (optionCourse.isSelected)
            {
                //helper.debugObject(optionCourse.course, 'Course['+idx+']');
                var courseId = optionCourse.course.Id;
                courseIds.push(courseId);
                
                var courseUniqueCode = optionCourse.course.Unique_Code__c;
                
                // if it has a unit_set_code, only count the area of study, not the parent course
                if(!optionCourse.course.Unit_Set_Code__c)
                {                    
                	cntSelected++;
                }
                else
                {
                    // this is a parent group, check if it has an Area of Study later
                    console.log('adding ' + courseUniqueCode);
                    helper.addCourseForArea(arrRequiresAoS, courseUniqueCode);                    
                }
            }
        }        

        //collect selected courses with unit sets
        var crsUnitSetWrapper = component.get("v.courseUnits");
        var courseUnitSetIds = new Array();

        for (var idx=0; idx<crsUnitSetWrapper.length; idx++) 
        {
            var courseUnitSet = crsUnitSetWrapper[idx];
            if (courseUnitSet.isSelected) 
            {
                var courseId = courseUnitSet.course.Id;
                courseUnitSetIds.push(courseId);
                cntSelected++;
                
                var courseUniqueCode = courseUnitSet.course.Unique_Code__c;
                // update the map to fulfil the Area of Study
            	helper.selectedAreaForCourse(arrRequiresAoS, courseUniqueCode);
                //helper.debugObject(courseUnitSet.course, 'Unit Set['+idx+']');
            }
        }
        // check that any Courses with areas of study have at least 1 selected
        var coursesHaveAreasOfStudy = helper.allCoursesHaveAreas(arrRequiresAoS);
        if(!coursesHaveAreasOfStudy)
        {
            component.set("v.errorMessage", "One or more courses require an Area of Study to be selected as well");
            // early out
            return;
        }

        //check Application courses list,maximum is 5 per application
        var cntCurrentCourse = 0;
        if(currentCourses.length >0){
            cntCurrentCourse = currentCourses.length;
        }
        console.debug('Current Course: '+cntCurrentCourse);
        var cntTotalRecords = cntCurrentCourse + cntSelected;
        console.debug('ALL COURSE: '+cntTotalRecords);
        
        if(cntTotalRecords > 5){
            component.set("v.errorMessage", "You may only apply for up to 5 course preferences. If you wish to add more, please submit this application and create a new application.");            
        }
        else{
            component.set("v.errorMessage", "");
            
            var jsonIds = JSON.stringify(courseIds);
            console.debug('IDS:'+jsonIds);
            var jsonIds_UnitSets = JSON.stringify(courseUnitSetIds);

            action.setParams({ 
                "jsonStr": jsonIds,
                "jsonStrUnitSets" : jsonIds_UnitSets,
                "applicationId": appId
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var apps=response.getReturnValue()
                    component.set("v.applicationCourses", apps);
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    alert("Error : " + JSON.stringify(errors));
                }
            });

            $A.enqueueAction(action);
            
            helper.findCourseOfferings(component, "Apply Filters");
            window.location.hash = '#myCourse';
        }
    },

    deleteCourse : function(component, event, helper) {
    	var appCourseItem = component.get("v.appCourse");    
        var deleteEvent = $A.get("e.c:deleteCourseEvent");
        deleteEvent.setParams({ "appCourse": appCourseItem }).fire();
    },

    showHideComponent : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
		component.set("v.isExpanded", isExpanded);
    },

    showCourseTable : function (component, event, helper) {
        var isShown = component.get("v.showList");
        
        if (isShown) {
            isShown = false;
        } else {
            isShown = true;
        }
		component.set("v.showForm", isShown);
    },

    reOrderUp : function (component, event, helper) {
        /*console.debug('WENT HERE UP ORDER');
        var domEvent = event.getParams().domEvent;
        var bodySpan = domEvent.target.nextSibling;
        console.debug('BODY SPAN: '+bodySpan);
        
        var appCourseId = bodySpan.dataset.id;*/

        var source = event.getSource(); // this would give that particular component
        var appCourseId = source.get("v.name"); // returns the id
        console.debug('COURSE ID: '+appCourseId);

        if(appCourseId != undefined){
            var actionReorder = component.get("c.reOrderAppCourses");
            actionReorder.setParams({"courseId" : appCourseId, "direction" : "up"});
            actionReorder.setCallback(this, function(response) {
                component.set("v.applicationCourses", response.getReturnValue());
            });
            $A.enqueueAction(actionReorder);
        }
        
    },

    reOrderDown : function (component, event, helper) {
        /*var domEvent = event.getParams().domEvent;
        var bodySpan = domEvent.target.nextSibling;
        
        var appCourseId = bodySpan.dataset.id;*/

        var source = event.getSource(); // this would give that particular component
        var appCourseId = source.get("v.name"); // returns the id

        if(appCourseId != undefined){
            var actionReorder = component.get("c.reOrderAppCourses");
            actionReorder.setParams({"courseId" : appCourseId, "direction" : "down"});
            actionReorder.setCallback(this, function(response) {
                component.set("v.applicationCourses", response.getReturnValue());
            });
            $A.enqueueAction(actionReorder);
        }
    },

    onClickCloseError:function(component, event, helper)
    {
        component.set("v.errorMessage", '');
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  show the spinner when page is loading
    * @revision     
    *******************************************************************************/
    waiting: function(component, event, helper) {
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "block";
        }
        
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  hide the spinner when finished loading
    * @revision     
    *******************************************************************************/
    doneWaiting: function(component, event, helper) {
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "none";
        }
    }
})