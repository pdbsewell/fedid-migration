/*
* @author Nitin Khandelwal
* @date 19.09.201
* @description  Platform Event handler for ACPs. Call from subscribing trigger on the IbdACP__e object.
*
* @revision
* 20.04.2020 Shalini - Added ability to swap to v2 of the services class.
*
*/
trigger IbdACPTrigger on IbdACP__e (after insert) {
    
    new Triggers() 
        .bindExtended(Triggers.Evnt.afterinsert, new IbdACPServicesV2.EventHandler())
        .execute();
        
}