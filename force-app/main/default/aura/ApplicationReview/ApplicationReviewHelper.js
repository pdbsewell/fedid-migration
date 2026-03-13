/**
 * Created by trentdelaney on 17/9/18.
 */
({
    getFullApplication : function (component, event, helper, appId) {
        console.log(appId);
        var action = component.get("c.GetFullApplication");
        action.setParams({
            "appId" : appId
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var application = response.getReturnValue();
                var applicationObject = JSON.parse(application);
                
                if (applicationObject.Application.Source_System__c === 'CCT') {
                    //redirect to the home page when user trying to access Course Transfer Application
                    window.location.href = '/admissions/s/';
                }
                component.set("v.fullApplication", applicationObject);
                component.set("v.tertiaryQualifications", applicationObject.Qualifications['Tertiary Education']);
                component.set("v.secondaryQualifications", applicationObject.Qualifications['Secondary Education']);
                component.set("v.otherQualifications", applicationObject.Qualifications['Other Qualification']);
                component.set("v.englishQualifications", applicationObject.Qualifications['English Test']);
                
                if (applicationObject.Application.Duration_of_Study__c == '1' || applicationObject.Application.Duration_of_Study__c == '2') {
                  component.set("v.durationAvailable", true);
                }

                if ( applicationObject.UnitPreferenceList != null && applicationObject.UnitPreferenceList.length != 0 ) {
                  component.set("v.showUnitsSection", true);
                  component.set("v.UnitPreferenceList", applicationObject.UnitPreferenceList);
                } else {
                  component.set("v.showUnitsSection", false);
                }

                console.log(applicationObject.Qualifications['Tertiary Education']);
                //var applicationObject  = component.get("v.fullApplication");
                var acpList = applicationObject.Preferences;
                if (acpList != null && acpList.length !=0){
                  component.set("v.preferencesAvailable", true);
                  if(applicationObject.Application.Type_of_Study__c=='Study Abroad' || applicationObject.Application.Type_of_Study__c=='Exchange')
                  {
                    helper.loadStudyPlan( acpList[0].Course_Offering__r.Start_Date__c,component);
                    helper.populateStudyPlanTables(acpList[0].Calendar_Code__r.Type__c, acpList[0].Calendar_Code__r.Year__c, component);
                  }
                } else {
                  component.set("v.preferencesAvailable", false);
                }

                // set minimum and maximum units
                component.set("v.minimumUnits", applicationObject.minimumUnits);
                component.set("v.maximumUnits", applicationObject.maximumUnits);

                // Handle Salutation when blank
                var title = applicationObject.Application.Applicant__r.Salutation;
                component.set("v.salutation", title ? title : '-');
                
                // Handle Mononymous names
                var firstname = applicationObject.Application.Applicant__r.First_Name__c;
                if (!firstname || !firstname.trim()) {
                  component.set("v.isMononymousName", true);
                }
                
                component.set("v.showSpinner", false);
                
            }
        });

        $A.enqueueAction(action);

    },
    loadStudyPlan: function ( stdt,component) {
       
          var upList = component.get("v.UnitPreferenceList");
          var newList = [];
            let rowColor ='';
            upList.forEach(function (uo) {
              if(uo.MA_Status__c!=null && (uo.MA_Status__c.toLowerCase() =='red' || uo.MA_Status__c.toLowerCase() =='yellow'))
              {
                  rowColor = "color:#FF0000";
                  component.set("v.showPreReq", true);
              }else{
                  rowColor = "color:black";
              }
              newList.push({
                Id: uo.Id,
                UnitCode: uo.Unit_Code__c,
                UnitTitle: uo.Title__c,
                FacName: uo.Managing_Faculty_Name__c,
                Campus: uo.Location__c,
                Year: uo.Academic_Year__c,
                TP: uo.Calendar_Name__c,
                PreReq:rowColor,
                UnitOffering: uo.UO_ID__c,
                StDt: uo.Start_Date__c
              });
            });
            component.set("v.upList", newList);
            
      },
      populateStudyPlanTables: function ( ACPAdmType, ACPAdmYr, component) {
        var sem1text = "";
        if(ACPAdmType=='ADM-2')
        { 
          sem1text =
          "Semester of study (July - December " +
           ACPAdmYr +")";
        }else if(ACPAdmType=='ADM-1'){
          sem1text =
          "Semester of study (January - June " +
           ACPAdmYr +")";
        }
        component.set("v.sem1StudyPlanDesc", sem1text);
        let sem1RowsList = [];
        let fullList = component.get("v.upList");
        fullList.forEach((item) => {
          sem1RowsList.push(item);
        });
        component.set("v.selectedSem1RowsList", sem1RowsList);

      }
})