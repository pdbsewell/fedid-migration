({
    
    init : function(component, event, helper) {       
        var columns = [
            { 
                label: '', 
                type: 'button-icon', 
                iconName: '',
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }, 
                typeAttributes: {
                    name: 'addUnitPreference',
                    iconName: 'utility:add',
                    variant: 'border',
                    disabled: {
                        fieldName: 'isDisabled'
                    }
                }
            },
            { 
                label: 'Unit Code', 
                fieldName: 'Unit_Code__c', 
                type: 'text',
                hideDefaultActions: true,
                fixedWidth: 100,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                } 
            },
            { 
                label: 'Unit Title', 
                fieldName: 'Title__c',
                type: 'text',
                hideDefaultActions: true,
                wrapText: true,
                fixedWidth: 300,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            },
            { 
                label: 'Campus', 
                fieldName: 'Location__c', 
                type: 'text', 
                hideDefaultActions: true,
                fixedWidth: 100,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            },
            { 
                label: 'Faculty', 
                fieldName: 'Managing_Faculty_Name__c', 
                type: 'text',
                hideDefaultActions: true,
                wrapText: true,
                fixedWidth: 100,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            },
            { 
                label: 'Teaching Period', 
                fieldName: 'Calendar_Name__c', 
                type: 'text',
                hideDefaultActions: true,
                wrapText: true,
                fixedWidth: 150,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            },
            { 
                label: 'PreRequisite', 
                fieldName: 'MA_Status__c', 
                type: 'text',
                hideDefaultActions:true,
                wrapText: true,
                fixedWidth: 0,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            },
            { 
                label: 'UOID', 
                fieldName: 'UO_ID__c', 
                type: 'text',
                hideDefaultActions:true,
                wrapText: true,
                fixedWidth: 0,
                resizeColumnDisabled: true,
                cellAttributes: {
                    class: {
                        fieldName: 'rowClass'
                    }
                }
            }
        ];
        
        let mycolumns = columns.filter(col => col.label !== 'PreRequisite');
         let mycolumns1 = mycolumns.filter(col => col.label !== 'UOID');
        component.set('v.mycolumns', mycolumns1);
        helper.loadStudyPlan(component, event, helper);
    }, 
    loadMoreData : function(component, event, helper) {
        //component.set('v.loadMoreStatus',true); 
        console.log('*** loadMoreData....'+component.get("v.currentCount")+'>='+component.get("v.selectedRowsCount"));

        if(!(component.get("v.currentCount") >=component.get("v.selectedRowsCount")))
        {
            event.getSource().set("v.isLoading", true); 
            //var len = component.get('v.uoList').length;
            helper.fetchUnitOfferingsMoreLoad(component, event).then(function(data){ 
            var currentData =  component.get("v.uoList");   
                component.set("v.uoList", currentData.concat(data.results));
                event.getSource().set("v.isLoading", false); 
            });
           component.set('v.loadMoreStatus',true);
            component.set("v.searchClick",false );  
            component.set("v.facultyChange",false );  
        }
       else
        {
            event.getSource().set("v.isLoading", false); 

            component.set('v.enableInfiniteLoading', false);
            component.set('v.loadMoreStatus',false);
            component.set("v.showSearchSpinner", false);
           
        }


    },
   
    fetchUnitOfferings:function(component, event, helper)
    {
        if(!component.get("v.onesem") && !component.get("v.twosem"))
        {
            component.set("v.selectDurationOfStudyMsg", "Please select Duration of Study.");
            return;
        }
        component.set('v.showPageLoading', true);
        component.set('v.uoList',null);
        if(event.getSource().get("v.name")=="btn")
        {
            console.log('inside btn click');
            component.set("v.searchClick",true );  

            component.set("v.facultyChange",false ); 
            component.set("v.currentCount", 10)
            component.set("v.showRes", false);
            //component.set("v.uoFacultyKey", null); 
            component.set('v.loadMoreStatus',false);
            event.getSource().set("v.isLoading", true); 
            component.set("v.enableInfiniteLoading", true);
            
        }
        if(event.getSource().get("v.name")=="fac")
        {
            console.log('inside fac change');
            component.set("v.showRes", false);
            component.set("v.searchClick",false );  
            component.set("v.facultyChange",true );  
            component.set('v.loadMoreStatus',false);
            component.set("v.currentCount", 10)
            event.getSource().set("v.isLoading", true); 
            component.set("v.enableInfiniteLoading", true);
           

        }
        
        if(component.get("v.uosearchKey").length>0)
        {
            component.set("v.showSearchSpinner", true);
            helper.fetchUnitOfferings(component, event, 0);
        }
       


    },
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'addUnitPreference':
                    //component.set('v.showPageLoading', true);
                    component.set('v.selectedRow', row);
                    helper.addUnitPreference(component, event, helper);
                break;
            default:
                break;
        }
    },
    handleKeyUp:function(cmp, event, helper)
    {
        var isEnterKey = event.keyCode === 13; 
        if(isEnterKey)
        {
            cmp.set("v.searchClick",true );  
            cmp.set("v.facultyChange",false ); 
            //cmp.set("v.uoFacultyKey", null); 
            cmp.set('v.loadMoreStatus',false);
            cmp.set("v.showRes",false ); 
            var a = cmp.fetchUnitOffC();
        }else{
            cmp.set("v.searchClick",false );  
            cmp.set("v.showRes",false ); 
        }
    },
    capturechange:function(cmp, eve, helper)
    {
        cmp.set("v.showRes",false ); 
        cmp.set("v.showNoResults", false);

    },
    handleRemoveItem: function(component, event, helper) {
        var removedItem = event.getParam("removedUnit");

        let counter = 0;
        let removeCounter = 0;
        let selectedRows = component.get("v.selectedRowsList");
        let removedRow;
        selectedRows.forEach(function (unitOffering) {
          if (unitOffering.UnitCode === removedItem.UnitCode) {
            removeCounter = counter;
            removedRow = unitOffering;
          }
          counter = counter + 1;
        });
        selectedRows.splice(removeCounter, 1);
        //component.set("v.selectedRowsList", selectedRows);

        //add the unit back if the search text is in the unit code or unit name
        let searchKey = component.get("v.uosearchKey");
        let unitCode = removedRow.UnitCode.toLowerCase();
        let unitTitle = removedRow.UnitTitle.toLowerCase();
        if (searchKey &&((unitCode && unitCode.includes(searchKey)) ||(unitTitle && unitTitle.includes(searchKey)))) 
        {
          let tableData = component.get("v.uoList");
            tableData.unshift({
                Unit_Code__c: removedRow.UnitCode,
                Title__c: removedRow.UnitTitle,
                Managing_Faculty_Name__c: removedRow.FacName,
                Location__c: removedRow.Campus,
                Academic_Year__c: removedRow.Year,
                Calendar_Year__c: removedRow.Year,
                Calendar_Name__c: removedRow.TP,
                Studyabroad_Exchange_Ind__c: true,
                Id: removedRow.UnitOffering,
                isDisabled: false,
                rowClass: ""
          });
          component.set("v.uoList", tableData);
        }

        var action = component.get("c.removeUnitPreference");
        action.setParams({
            appId: component.get("v.appId"),
            uoId: removedItem.UnitOffering
        });
        action.setCallback(this, function (response) {
          var state = response.getState();
          var selectedRowObj = null;
          var newList = [];
            var retObj = response.getReturnValue();

            let rowColor = '';
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
                  PreReq:rowColor,
                  UnitOffering: uo.UO_ID__c,
                  StDt: uo.Start_Date__c,
                  Sem: uo.Semester__c,
                  Order :uo.Preference_Number__c
                });
              });

              component.set("v.selectedRowsList", newList);
             
              helper.populateStudyPlanTables(retObj.ACPAdmType,retObj.ACPAdmYr, component);
            } else{
                var errors = response.getError();
                if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("1 Error message: " + errors[0].message);
                        }
                    } 
           }
          
        });
        $A.enqueueAction(action);
        //validate selected if higher than 16
        helper.validateSelectedRows(component, event, helper);

    }
})