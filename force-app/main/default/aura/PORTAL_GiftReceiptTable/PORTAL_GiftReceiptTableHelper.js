({
    getGiftReceiptDetails : function(component, helper) {

        var action = component.get("c.SERVER_getGiftReceiptDetails");
        
        action.setStorable();
        
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(JSON.stringify(response.getReturnValue()));
                console.log('Response Time: '+((new Date().getTime())-requestInitiatedTime));
                
                var totalPages = Math.ceil(response.getReturnValue().length/component.get("v.pageSize"));
                
                if (totalPages == 0) {
                    totalPages = 1;
                }
                component.set("v.totalPages", totalPages);
                component.set("v.allData", response.getReturnValue());
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
        
        console.log('data: ' + JSON.stringify(data));
        
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
    },
    
    showRowDetails : function(component, row) {

        //alert("ucinn_ascendv2__Payment_Group_ID__c: " + row.ucinn_ascendv2__Payment_Group_ID__c);
        
        var baseUrl = component.get('v.baseUrl');
        var communityPrefix = component.get('v.communityPrefix');
        
        console.log('baseUrl: ' + baseUrl);
        console.log('communityPrefix: ' + communityPrefix);
        
        var urlString = baseUrl + '/PORTAL_STRIPE_ReceiptPage?paymentGroupId=' + row.ucinn_ascendv2__Payment_Group_ID__c;
        
        window.open(urlString);
        
        // https://ucinn-portal-uat--demo--c.cs71.visual.force.com/apex/PORTAL_STRIPE_ReceiptPage?paymentGroupId=a234D0000003Fz0QAE0064D000004AMixQAGc22691dc24234d778b6c95de0eef0f88
    }
})