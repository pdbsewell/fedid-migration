({
  fetchUnitOfferingsMoreLoad: function (component, event) {
    return new Promise(
      $A.getCallback(function (resolve) {
        var action = component.get("c.searchUnitOfferings");
        var numSem = component.get("v.onesem") ? 1 : 2;
        var offSetCount = component.get("v.currentCount");
        //mark selected rows to be excluded
        let selectedRowIds = [];
        /*
        let selectedRows = component.get('v.selectedRows');
        selectedRows.forEach(function(courseOffering) {
            selectedRowIds.push(courseOffering.Id);
        }); */

        var excludeList = component.get("v.selectedRowsList");
        excludeList.forEach(function (uo) {
          selectedRowIds.push(uo.UnitOffering);
        });

        action.setParams({
          offsetRange: offSetCount,
          appId: component.get("v.appId"),
          unitCodeorTitle: component.get("v.uosearchKey"),
          numSemesters: numSem,
          faculty: component.get("v.uoFacultyKey")
            ? component.get("v.uoFacultyKey")
            : null,
          excludedIds: selectedRowIds
        });
        action.setCallback(this, function (response) {
          var state = response.getState();
          if (state == "SUCCESS") {
            var newData = response.getReturnValue();
            var fullData = newData.results;
            resolve(newData);
            var currentCount = component.get("v.currentCount");
            currentCount += 10;
            component.set("v.currentCount", currentCount);
          } else {
            var errors = response.getError();
            if (errors) {
              if (errors[0] && errors[0].message) {
                console.error("Error message: " + errors[0].message);
              }
            }
          }
        });
        $A.enqueueAction(action);
      })
    );
  },

  fetchUnitOfferings: function (component, event, offSetCount) {
    let selectedRowIds = [];
    //mark selected rows to be excluded
    if (selectedRowIds.length == 0) {
      var excludeList = component.get("v.selectedRowsList");
      excludeList.forEach(function (up) {
        selectedRowIds.push(up.UnitOffering);
      });
    }
    var action = component.get("c.searchUnitOfferings");
    var numSem = component.get("v.onesem") ? 1 : 2;
    action.setParams({
      offsetRange: offSetCount,
      appId: component.get("v.appId"),
      unitCodeorTitle: component.get("v.uosearchKey"),
      numSemesters: numSem,
      faculty: component.get("v.uoFacultyKey")
        ? component.get("v.uoFacultyKey")
        : null,
      excludedIds: selectedRowIds
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      //successful main action
      if (state === "SUCCESS") {
        var res = response.getReturnValue();
        var records = res.results;
        //mark disabled rows / excluded selected rows
        let newRecords = [];
        records.forEach(function (courseOffering) {
          //courseOffering.isDisabled = false;
          courseOffering.isDisabled = !courseOffering.Studyabroad_Exchange_Ind__c;
          if (courseOffering.isDisabled) {
            courseOffering.rowClass = "disabledRow";
          }
        });
        var totalSearchRes = res.TotRes;
        component.set("v.selectedRowsCount", totalSearchRes.length);
        if (component.get("v.selectedRowsCount") > 5) {
          component.set(
            "v.divStyle",
            "width:800px !important;height:500px !important"
          );
        } else {
          component.set(
            "v.divStyle",
            "width:800px !important;height:300px !important"
          );
        }
        if (records.length == 0 && component.get("v.searchClick")) {
          component.set("v.showNoResults", true);
        } else {
          component.set("v.showNoResults", false);
        }

        var currentData = component.get("v.uoList");
        component.set("v.uoList", records);
        if(component.get("v.uoList").length>0 && component.get("v.uosearchKey").length>0 )
        {
          component.set("v.showRes", true);
        }else{
          component.set("v.showRes", false);
        }

        //load faculty select
        if (!component.get("v.facultyChange")) {
          var pickListAction = component.get(
            "c.searchUnitOfferingsForPicklist"
          );
          var numSem = component.get("v.onesem") ? 1 : 2;
          pickListAction.setParams({
            appId: component.get("v.appId"),
            unitCodeorTitle: component.get("v.uosearchKey"),
            numSemesters: numSem,
            excludedIds: selectedRowIds
          });
          pickListAction.setCallback(this, function (response) {
            var state = response.getState();
            //successful factulty loading
            if (state === "SUCCESS") {
              var records1 = response.getReturnValue();
              var rec2 = records1.FacultyOptions;
              var rec3 = records1.Totalcount;
              var facultymap = [];
              rec2.forEach((item) => {
                facultymap.push({ label: item, value: item });
              });
              facultymap.unshift({ label: "Faculty", value: "" });
              component.set("v.facultyOptions", facultymap);
            } else {
              var errors = response.getError();
              if (errors) {
                if (errors[0] && errors[0].message) {
                  console.error("Error message: " + errors[0].message);
                }
              }
            }
          });
          $A.enqueueAction(pickListAction);
          component.set("v.showSearchSpinner", false);
        }
        //unsuccessful main action
      } else {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error("Error message: " + errors[0].message);
          }
        }
      }
      component.set("v.showPageLoading", false);
    });
    $A.enqueueAction(action);
  },
  addUnitPreference: function (component, event, helper) {
    //validate selected if higher than 8/16
    helper.validateSelectedRows(component, event, helper);

    let selectedRow = component.get("v.selectedRow");
    var action = component.get("c.createUnitPreference");
    component.set('v.showPageLoading', true);
    action.setParams({
      appId: component.get("v.appId"),
      uoId: selectedRow.Id
    });
    action.setCallback(this, function (response) {
      var state = response.getState();

      var retObj = response.getReturnValue();
      var newList = [];
      let rowColor = "color:black";
      if (state == "SUCCESS") {
          var upList = retObj.UPList;
          upList.forEach(function (uo) {
          if(uo.MA_Status__c!=null && (uo.MA_Status__c.toLowerCase() =='red' || uo.MA_Status__c.toLowerCase() =='yellow'))
          {
              rowColor = "color:#FF0000";
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
            PreReq: rowColor,
            UnitOffering: uo.UO_ID__c,
            StDt: uo.Start_Date__c,
            Sem: uo.Semester__c,
            Order :uo.Preference_Number__c
          });
        });
        component.set("v.selectedRowsList", newList);
        let tableData = component.get("v.uoList");

        let markCounter;
        let brkOutLoop = false;
        //delete the created UP from the search result list table
        for (let counter = 0; counter < tableData.length; counter++) {
          if(brkOutLoop)
          {
              break;
          }
          for (let cnt = 0; cnt < newList.length; cnt++) {
            if (tableData[counter] && tableData[counter].Unit_Code__c === newList[cnt].UnitCode) {
              markCounter = counter;
              tableData.splice(markCounter, 1);
              brkOutLoop = true;
            }
          }
        }
          component.set("v.uoList", tableData);
          helper.populateStudyPlanTables(retObj.ACPAdmType,retObj.ACPAdmYr, component);
           //stop load page
           component.set("v.showPageLoading", false);
      } else {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error("Error message: " + errors[0].message);
          }
        }
      }
    });
    $A.enqueueAction(action);
    //}
  },
  validateSelectedRows: function (component, event, helper) {
    //mark selected rows to be excluded
    let numSem = component.get("v.onesem") ? 1 : 2;

    let selectedRowIds = [];
    let selectedRows = component.get("v.selectedRowsList");
    let selectedRows1 = component.get("v.selectedSem1RowsList");

    selectedRows.forEach(function (courseOffering) {
      selectedRowIds.push(courseOffering.Id);
    });

    //enable / disable table
    let tableData = component.get("v.uoList");
    
      tableData.forEach(function (courseOffering) {
        courseOffering.isDisabled = !courseOffering.Studyabroad_Exchange_Ind__c;
        if (courseOffering.isDisabled) {
          courseOffering.rowClass = "disabledRow";
        } else {
          courseOffering.rowClass = "";
        }
      });
    component.set("v.uoList", tableData);
  },
  loadStudyPlan: function (component, eve, helper) {
    var action = component.get("c.fetchUnitPreferences");
    action.setParams({
      appId: component.get("v.appId")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var retObj = response.getReturnValue();
      var upList = retObj.UPList;
      var newList = [];
      let rowColor = '';
      if (state == "SUCCESS") {
        upList.forEach(function (uo) {
          if(uo.MA_Status__c!=null && (uo.MA_Status__c.toLowerCase() =='red' || uo.MA_Status__c.toLowerCase() =='yellow'))
          {
              rowColor = "color:#FF0000";
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
            StDt: uo.Start_Date__c,
            Sem: uo.Semester__c,
            Order :uo.Preference_Number__c
          });
        });
        component.set("v.selectedRowsList", newList);
        component.set("v.minimumUnits", retObj.minimumUnits);
        component.set("v.maximumUnits", retObj.maximumUnits);
        helper.populateStudyPlanTables(retObj.ACPAdmType,retObj.ACPAdmYr,component);
      } else {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error("Error message: " + errors[0].message);
          }
        }
      }
    });
    $A.enqueueAction(action);
  },
  populateStudyPlanTables: function (ACPAdmType,ACPAdmYr, component) {
    console.log(ACPAdmYr+'::'+ACPAdmType);
    var sem1text = '';
    var sem2text = '';
    if(ACPAdmType=='ADM-2')
    { 
      sem1text =
      "Semester of study (July - December " +
       ACPAdmYr +")";
       sem2text =
      "Semester of study (January - June " +
       (parseInt(ACPAdmYr)+1) +")";
    }else if(ACPAdmType=='ADM-1'){
      sem1text =
      "Semester of study (January - June " +
       ACPAdmYr +")";
       sem2text =
      "Semester of study (July - December " +
       (ACPAdmYr) +")";
    }
    
    component.set("v.sem1StudyPlanDesc", sem1text);
    component.set("v.sem2StudyPlanDesc", sem2text);
   
    let sem1RowsList = [];
    let sem2RowsList = [];
    let fullList = component.get("v.selectedRowsList");
    fullList.forEach((item) => {
    if(component.get("v.applicationCampusLocation") != 'Online'){
      if( ACPAdmType=='ADM-2')
      {
        if(item.Sem ==1)
          sem2RowsList.push(item);
        else
          sem1RowsList.push(item);
      }else if(ACPAdmType=='ADM-1'){

        if(item.Sem ==1)
          sem1RowsList.push(item);
        else
          sem2RowsList.push(item);
      }
    }else{
      sem1RowsList.push(item);
    }

    });
   

    sem1RowsList.sort((a, b) => (a.Order > b.Order) ? 1 : -1)
    component.set("v.selectedSem1RowsList", sem1RowsList);
   
  }
});