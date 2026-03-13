({
    doInit: function(component, event, helper) {
        var recid = component.get("v.recordId");
        console.log("program data id: " + recid);

        var action = component.get("c.getEDInfo");
        
        if(!component.get("v.explanationCollapsible") || !component.get("v.explanationCollapsedByDefault")){
			helper.toggleShowHide(component,event,'explanation');
        }
        if(!component.get("v.recommendationCollapsible") || !component.get("v.recommendationCollapsedByDefault")){
			helper.toggleShowHide(component,event,'recommendation');
        }
        
        var paramMap = {};
            paramMap['recId'] = recid;
            paramMap['outcomeField'] = component.get("v.outcomeField");
            if (component.get("v.explanationField") != null) 
            {
                paramMap['explanationField'] = component.get("v.explanationField");
            }
            if (component.get("v.recommendationField") != null) 
            {
              paramMap['recommendationField'] = component.get("v.recommendationField");
            }

            action.setParams({
                "params": JSON.stringify(paramMap)
            });

        
        action.setCallback(component, function(response) {
            var resp = JSON.parse(response.getReturnValue());
            var globalId = component.getGlobalId();
            
            if (resp.status === 'ERROR') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": resp.msg,
                    "mode": "sticky",
                    "type": "error"
                });
                toastEvent.fire();
            } else {
                $('.slds-card__header slds-grid').hide();
                
                var outcome = helper.round(resp.data.outcomeField, 1);
                var unit = component.get('v.outcomeUnit');
                var outcomeColor = component.get('v.outcomeColor').trim().split('|');
                var explanationColor = component.get('v.explanationColor').trim().split('|');
                var recommendationColor = component.get('v.recommendationColor').trim().split('|');
                var pass = 1;
                var color = helper.getColor(outcome, outcomeColor);
                /*
                var color = 'score-grey';
                for (var i=0; i<ranges.length; i++)
                {
                  console.log('range='+ranges[i]);
                  var tmpStr = ranges[i].split(',');
                  var lower = parseInt(tmpStr[0].trim());
                  var upper = parseInt(tmpStr[1].trim());
                  
                  if (pass == 1)
                  {
                    if (outcome >= lower && outcome <= upper )
                    {
                      color = 'score-red';
                      break;
                    }
                  }
                  else
                  {
                    if (outcome > lower && outcome <= upper )
                    {
                      if (pass == 2) color = 'score-yellow';
                      if (pass == 3) color = 'score-green';
                      break;
                    }
                  }
                  pass++;
                }
                */
                
                //$('#score').html('<div class="' + color + '">' + outcome + '</div>');
                var globalIdSel = '#' + globalId;
                console.log('globalIdSel=' + globalIdSel);
                console.log('element=' + document.getElementById(globalId + '_score').innerHtml);
                console.log('jquery=' + $('#' + globalId + '_score'));
                
                if (component.get('v.outcomeUnitBefore'))
                {
                  document.getElementById(globalId + '_score').innerHTML = '<div class="' + color + '">' + (unit == null ? '' : unit) + (component.get('v.outcomeUnitSpace') ? ' ': '') + outcome + '</div>';
                }
                else
                {
                  document.getElementById(globalId + '_score').innerHTML = '<div class="' + color + '">' + outcome + (component.get('v.outcomeUnitSpace') ? ' ': '') + (unit == null ? '' : unit) + '</div>';
                }
                
                if (resp.data.explanationField != undefined)
                {
                  var fieldData = resp.data.explanationField.replace(/<p>/gi, "").replace(/<\/p>/gi, '<br>').replace(/\n/gi, '<br>');
                    document.getElementById(globalId + '_explanation').innerHTML = helper.populateTable(fieldData,{ ranges: explanationColor, unit: '', space: component.get('v.outcomeUnitSpace')}, component.get('v.explanationRowLimit'));
                  //$('#explanation').html(myUtil.populateTable(fieldData));
                  //$('#explanation').html(myUtil.populateTable(resp.data.explanationField));
                }
                else {
                  document.getElementById(globalId + '_explanation').innerHTML = component.get("v.explanationEmptyMsg");
                }
                
                if (resp.data.recommendationField != undefined)
                {
                  var fieldData = resp.data.recommendationField.replace(/<p>/gi, "").replace(/<\/p>/gi, '<br>').replace(/\n/gi, '<br>');
                  document.getElementById(globalId + '_recommendation').innerHTML = helper.populateTable(fieldData,{ ranges: recommendationColor, unit: '', space: component.get('v.outcomeUnitSpace') }, component.get('v.recommendationRowLimit'));
                  //$('#recommendation').html(myUtil.populateTable(fieldData));
                  //$('#recommendation').html(myUtil.populateTable(resp.data.recommendationField));
                }
                else {
                  document.getElementById(globalId + '_explanation').innerHTML = component.get("v.recommendationEmptyMsg");
                }
                
                var threshold1 = component.get('v.threshold1UpperLimit');                
                var threshold1cardLabel = component.get('v.threshold1cardLabel');      
                var threshold1cardLabelColor = component.get('v.threshold1cardLabelColor');      
                var threshold1headerLogoIcon = component.get('v.threshold1headerLogoIcon');      
                var threshold1headerBackgroundImage = component.get('v.threshold1headerBackgroundImage');      
                var threshold1headerBackgroundColor = component.get('v.threshold1headerBackgroundColor');                
                
                var threshold2 = component.get('v.threshold2UpperLimit');
                var threshold2cardLabel = component.get('v.threshold2cardLabel');      
                var threshold2cardLabelColor = component.get('v.threshold2cardLabelColor');      
                var threshold2headerLogoIcon = component.get('v.threshold2headerLogoIcon');      
                var threshold2headerBackgroundImage = component.get('v.threshold2headerBackgroundImage');      
                var threshold2headerBackgroundColor = component.get('v.threshold2headerBackgroundColor');      
                
                var threshold3 = component.get('v.threshold3UpperLimit');
                var threshold3cardLabel = component.get('v.threshold3cardLabel');      
                var threshold3cardLabelColor = component.get('v.threshold3cardLabelColor');      
                var threshold3headerLogoIcon = component.get('v.threshold3headerLogoIcon');      
                var threshold3headerBackgroundImage = component.get('v.threshold3headerBackgroundImage');      
                var threshold3headerBackgroundColor = component.get('v.threshold3headerBackgroundColor');    
                
                var threshold;
                
                if(threshold1 !=null){
                    threshold1 = threshold1/100;
                	if(outcome <= threshold1){
                    	threshold = 'threshold1';
                    }
                }
                if(threshold1 !=null && threshold2 != null){
                    threshold2 = threshold2/100;         
                	if(outcome > threshold1 && outcome <= threshold2){
                    	threshold = 'threshold2';
                    }
				}                
                if(threshold1 !=null && threshold2 != null && threshold3 != null){   
                    threshold3 = threshold3/100;              
                	if(outcome>  threshold1 && outcome > threshold2 && outcome <= threshold3){
                    	threshold = 'threshold3';
                    }
				}
                
                if(threshold == 'threshold1'){
                    component.set('v.cardLabel',threshold1cardLabel);
                    component.set('v.cardLabelColor',threshold1cardLabelColor);
                    component.set('v.headerLogoIcon',threshold1headerLogoIcon);
                    component.set('v.headerBackgroundImage',threshold1headerBackgroundImage);
                    component.set('v.headerBackgroundColor',threshold1headerBackgroundColor);
                } else if(threshold == 'threshold2'){
                    component.set('v.cardLabel',threshold2cardLabel);
                    component.set('v.cardLabelColor',threshold2cardLabelColor);
                    component.set('v.headerLogoIcon',threshold2headerLogoIcon);
                    component.set('v.headerBackgroundImage',threshold2headerBackgroundImage);
                    component.set('v.headerBackgroundColor',threshold2headerBackgroundColor);
                } else if(threshold == 'threshold3'){
                    component.set('v.cardLabel',threshold3cardLabel);
                    component.set('v.cardLabelColor',threshold3cardLabelColor);
                    component.set('v.headerLogoIcon',threshold3headerLogoIcon);
                    component.set('v.headerBackgroundImage',threshold3headerBackgroundImage);
                    component.set('v.headerBackgroundColor',threshold3headerBackgroundColor);
                }

            }
        });
        $A.enqueueAction(action);
    },
    refresh: function(component, event, helper) {
        var action = component.get('c.getEDInfo');
        action.setCallback(component,
            function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    $A.get('e.force:refreshView').fire();
                } else {
                    //do something
                }
            }
        );
        $A.enqueueAction(action);
    },
    explanationLabelClick : function(component, event, helper) {
       helper.toggleShowHide(component,event,'explanation');
    },
    recommendationLabelClick : function(component, event, helper) {
       helper.toggleShowHide(component,event,'recommendation');
    },
})