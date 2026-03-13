({
    onLoad : function(component, event, helper) {
        var errMsgAction1 = '### Cannot fetch column definitions. Please contact your system administrator.';
        var errMsgAction2 = '### Cannot fetch applicant record details. Please contact your system administrator.';
        var errMsgAction3 = '### Cannot fetch duplicate contact records. Please contact your system administrator.';
        component.set("v.aSelectedRows",[]);
        component.set("v.masterSelectedRows",[]);
        component.set('v.selectedRowsCount',0);
        var action1 = component.get('c.getDataTableColumns');
        helper.serverSideCall(component,action1,errMsgAction1).then(
            function(response) {
                var vColumns = response.getReturnValue();
                if (vColumns.length > 0) {
                    component.set('v.columns', vColumns);
                } else {
                    // if there is no records then display message
                    component.set("v.bNoFieldSetFound" , true);
                }
                
                var action2 = component.get('c.showMasterContact');
                action2.setParams({
                    "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId")
                });
                return helper.serverSideCall(component,action2,errMsgAction2);
            }
        ).then(
            function (response) {
                var vMasterRecords = response.getReturnValue();
                if(vMasterRecords.length > 0) {
                    var masterSelectedRows = [];
                    vMasterRecords.forEach(function(record) {
                        record.linkName = '/' + record.Id;
                        masterSelectedRows.push(record.Id);
                    });
                    component.set('v.MasterContact', vMasterRecords);
                    //component.set("v.masterSelectedRows",masterSelectedRows);
                    //var dTable = component.find("masterContactTable");
                    //dTable.set("v.selectedRows", masterSelectedRows);
                } else {
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                    console.log('### No master contact record found.');
                }
                var action3 = component.get('c.showDupContacts');
                action3.setParams({
                    "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId"),
                    "limits": component.get("v.initialRows"),
                    "offsets": component.get("v.rowNumberOffset")
                });
                return helper.serverSideCall(component,action3,errMsgAction3);
            }
        ).then(
            function (response) {
                var vChildRecords = response.getReturnValue();
                if (vChildRecords != null && vChildRecords.length > 0) {
                    vChildRecords.forEach(function(record) {
                        record.linkName = '/' + record.Id;
                    });
                    component.set('v.data', vChildRecords);
                    var totalCnt = component.get('v.data').length;
                    component.set("v.totalNumberOfRows", totalCnt);
                } else {
                    // if there is no records then display message
                    //component.set("v.bNoRecordsFound" , true);
                    component.set("v.bNoDuplicateRecordsFound" , true);
                    console.log('### No duplicate contact records found.');
                }
                component.set("v.showSpinner",false);
            }
        ).catch(
            function(error) {
                //component.set("v.status" ,error );
                console.log(error);
            }
        );
    },

    fetchData: function(component , rows){
        return new Promise($A.getCallback(function(resolve, reject) {
            var currentDatatemp = component.get('c.showDupContacts');
            var counts = component.get("v.currentCount");
            currentDatatemp.setParams({
                "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId"),
                "limits": component.get("v.initialRows"),
                "offsets": counts
            });
            currentDatatemp.setCallback(this, function(a) {
                resolve(a.getReturnValue());
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);

            });
            $A.enqueueAction(currentDatatemp);
        }));

    },

    mergeContacts : function(component, event, helper) {
        var errMsgAction1 = '### Cannot merge contacts. Please contact your system administrator.';
        var dTable = component.find("dupContactTable");
        console.log('### Selected records after merge button click:' + JSON.stringify(dTable.getSelectedRows()));
        var listSelected = dTable.getSelectedRows();
        var listIds = new Array();
        for (var i = 0; i < listSelected.length; i++) {
            var objSel = listSelected[i];
            listIds.push(objSel.Id);
        }
        component.set("v.showSpinner",true);
        if (listIds.length > 0) {
            console.log('### Selected Contact Ids:' + JSON.stringify(listIds));
            var action1 = component.get('c.mergeContacts');
            action1.setParams({
                "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId"),
                "childContactIds": JSON.stringify(listIds)
            });
            helper.serverSideCall(component, action1, errMsgAction1).then(
                function (response) {
                    console.log('### Successfully merging contact records.');
                    // SFTLG-849 start
                    var type= 'success';
                    var msg = 'Merge process is completed';
                    helper.displayToast(type, msg);
                    // SFTLG-849 end
                    helper.onLoad(component, event, helper);
                    //component.set("v.showSpinner",false);
                }
            ).catch(
                function (error) {
                    //component.set("v.status" ,error );
                    console.log(error);
                }
            );
        } else {
            console.log('### No selected records.');
        }
        /*var dTable = component.find("dupContactTable");
        console.log('### Selected Records:' + JSON.stringify(dTable.getSelectedRows()));
        var listSelected = dTable.getSelectedRows();
        var listIds = new Array();
        for (var i = 0; i < listSelected.length; i++) {
            var objSel = listSelected[i];
            listIds.push(objSel.Id);
        }
        if (listIds.length > 0) {
            console.log('### Selected Contact Ids:' + JSON.stringify(listIds));
            var initialRows = component.get("v.initialRows");
            var offSets = component.get("v.rowNumberOffset");
            console.log('### initialRows:' + JSON.stringify(initialRows));
            console.log('### offSets:' + JSON.stringify(offSets));
            var action = component.get('c.mergeContacts');
            action.setParams({
                "applicationId": component.get("v.applicationId"),
                "childContactIds": JSON.stringify(listIds),
                "limits": initialRows,
                "offsets": offSets
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === 'SUCCESS' && component.isValid()) {
                    console.log('### Successfully merging contact records.');
                    component.set("v.showSpinner",false);
                    this.onLoad(component, event, helper);
                } else {
                    //alert('ERROR: Cannot merge contacts. Please contact your system administrator.');
                    console.log('### Cannot merge contacts. Please contact your system administrator.');
                }
            });
            $A.enqueueAction(action);
        } else {
            console.log('### No selected records.');
        }*/
    },
    
    serverSideCall : function(component,action,errorMsg) {
        return new Promise(function(resolve, reject) {
            action.setCallback(this,
                function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        console.log('### SUCCESSFUL SERVER SIDE CALL');
                        resolve(response);
                    } else {
                        console.log('### ERROR MSG: '+errorMsg);
                        reject(new Error(response.getError()));
                    }
                });
            $A.enqueueAction(action);
        });
    },
    
    doFetchColumnDefinitions : function(component) {
        var action = component.get('c.getDataTableColumns');
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('### doFetchColumnDefinitions state:'+JSON.stringify(state));
            if (state === 'SUCCESS' && component.isValid()) {
                var oRes = response.getReturnValue();
                if(oRes.length > 0) {
                    component.set('v.columns', response.getReturnValue());
                } else {
                    // if there is no records then display message
                    component.set("v.bNoFieldSetFound" , true);
                }
            } else {
                //alert('ERROR: Cannot fetch column definitions. Please contact your system administrator.');
                console.log('### Cannot fetch column definitions. Please contact your system administrator.');
            }
        });
        $A.enqueueAction(action);
    },
    
    doFetchMasterContact : function(component) {
        var action = component.get('c.showMasterContact');
        action.setParams({
            "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('### doFetchMasterContact state:'+JSON.stringify(state));
            if (state === 'SUCCESS' && component.isValid()) {
                var records = response.getReturnValue();
                if(records.length > 0) {
                    records.forEach(function(record) {
                        record.linkName = '/' + record.Id;
                    });
                    component.set('v.MasterContact', records);
                } else {
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                    console.log('### No master contact record found.');
                }
            } else {
                //alert('ERROR: Cannot fetch applicant record details. Please contact your system administrator.');
                console.log('### Cannot fetch applicant record details. Please contact your system administrator.');
            }
        });
        $A.enqueueAction(action);
    },
    
    doFetchDupContacts : function(component) {
        var action = component.get('c.showDupContacts');
        action.setParams({
            "applicationId": component.get("v.applicationId") ? component.get("v.applicationId") : component.get("v.recordId"),
            "limits": component.get("v.initialRows"),
            "offsets": component.get("v.rowNumberOffset")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('### doFetchDupContacts state:'+JSON.stringify(state));
            if (state === 'SUCCESS' && component.isValid()) {
                var records = response.getReturnValue();
                if (records != null && records.length > 0) {
                    records.forEach(function(record) {
                        record.linkName = '/' + record.Id;
                    });
                    component.set('v.data', records);
                    var totalCnt = component.get('v.data').length;
                    component.set("v.totalNumberOfRows", totalCnt);
                } else {
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                    console.log('### No duplicate contact records found.');
                }
            } else {
                //alert('ERROR: Cannot fetch duplicate contact records. Please contact your system administrator.');
                console.log('### Cannot fetch duplicate contact records. Please contact your system administrator.');
            }
        });
        $A.enqueueAction(action);
    },

    // SFTLG-849 start
    displayToast : function (type, msg) {
        var toast = $A.get("e.force:showToast");
        if (toast){
            //fire the toast event in Salesforce app and Lightning Experience
            toast.setParams({
                "type": type,
                "message": msg
            });
            toast.fire();
        } else {
            //your toast implementation for a standalone app here
        }
    }
    // SFTLG-849 end
});