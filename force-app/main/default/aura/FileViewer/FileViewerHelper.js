/**
 * Created by smen0015 on 26/04/2019.
 */
({
    initLoad:  function(component, event, helper)
    {
           console.log(' var state = response.getState()');
        		var appId = component.get("v.appId");
        		var docType = component.get("v.docType");

                var action = component.get("c.getContactDocuments");
                    action.setParams({
                        "appId" : appId ,
                        "docType" : docType
                    });
                    action.setCallback(this, function(response){
                        //Get State
                        var state = response.getState();
                        console.log(' var state = response.getState()'+ state);
                        if(state == "SUCCESS")
                        {
                            var mapRx = response.getReturnValue();
                            for(var key in mapRx)
                            {
                                console.log('key=='+key+'&&&'+mapRx[key]);
                            }
                            var custs = [];
                            var conts = mapRx['idLinkMap'];
                            for ( var key in conts ) {
                                     custs.push({value:conts[key], key:key});
                                 }
                            component.set("v.customers", custs);
                            var conts1 = mapRx['documents'];
                            console.log('conts1=='+conts1);
                            component.set("v.documents", conts1);



                        }



                    });
                    $A.enqueueAction(action);


                }

})