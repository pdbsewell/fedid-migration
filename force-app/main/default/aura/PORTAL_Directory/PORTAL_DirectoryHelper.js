({
    getContacts : function(component, helper) {

      	var searchForSelected = component.get('v.selectedOptionValue');

        var classYear = component.get('v.classYear');
        var constituentType = component.get('v.constituentType');
        var department = component.get('v.department');
        var contact = component.get('v.contact');
        
        var baseUrl = component.get('v.baseUrl');
        
        console.log('classYear: ' + classYear);
        console.log('constituentType: ' + constituentType);
        console.log('department: ' + department);
        console.log('contact.Account__c: ' + contact.Account__c);
        console.log('baseUrl: ' + baseUrl)

        var searchText = component.find('enter-search').get('v.value');
        
        var action = component.get("c.SERVER_getContacts");
      	action.setParams({"searchString": searchText,
                          "classYear": classYear,
                          "constituentType": constituentType,
                          "department": department,
                          "employer": contact.Account__c});
        
        action.setStorable();
        
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Response Time: '+((new Date().getTime())-requestInitiatedTime));
                
                var totalPages = Math.ceil(response.getReturnValue().length/component.get("v.pageSize"));
                
                if (totalPages == 0) {
                    totalPages = 1;
                }
                
                var records = response.getReturnValue();
                
                records.forEach(function(record) {
                    record.linkName = baseUrl + '/s/contact/'+record.Id;
                    console.log('record: ' + JSON.stringify(record));                    
                });
                
                component.set("v.totalPages", totalPages);
                component.set("v.allData", records);
                component.set("v.currentPageNumber",1);
                helper.buildData(component, helper);
            }
        });
        
        var requestInitiatedTime = new Date().getTime();
        
        $A.enqueueAction(action);
    },
    
    /*
     * this function will build table data
     * based on current page selection
     * */
    buildData : function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.allData");
        var x = (pageNumber-1)*pageSize;
        
        //creating data-table data
        for(; x<=(pageNumber)*pageSize; x++){
            if(allData[x]){
            	data.push(allData[x]);
            }
        }
        component.set("v.data", data);
        
        helper.generatePageList(component, pageNumber);
    },
    
    /*
     * this function generate page list
     * */
    generatePageList : function(component, pageNumber){

        pageNumber = parseInt(pageNumber);
        var pageList = [];
        var totalPage = component.get("v.totalPages");
                
        if (pageNumber < 5) {
            //pageList.push(2,3,4,5,6);
            
            var startPage = 2;

            var count = 0;
            for (var i = startPage; i < totalPage; i++) {
                pageList.push(i);
                count++;
                
                if (count >= 5) {
                    break;
                }
            }
        } else if (pageNumber > (totalPage - 5)) {
            pageList.push(totalPage-5, totalPage-4, totalPage-3, totalPage-2, totalPage-1);
        } else {
            pageList.push(pageNumber-2, pageNumber-1, pageNumber, pageNumber+1, pageNumber+2);
        }
        
        component.set("v.pageList", pageList);
    },
    
    
	sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
/*    
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
	}
*/
    //  to make it case insensitive and consider blank fields on top for ASC:
    //  https://success.salesforce.com/ideaView?id=0873A000000E8qiQAC
	sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
            function(x) {return x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    } 
})