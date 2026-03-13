/**
* @author Martin Cadman
* @date   23-09-2019
* @group  Qualification
* @description Subscribed trigger to the Unit Set Attempt platform event
*
* @revision
* 23.09.2019 Martin Cadman - Initial version<br/>
*
**/
trigger IbdUnitSetAttemptTrigger on IbdUnitSetAttempt__e (after insert) {
    
    new Triggers() 
    	.bindExtended(Triggers.Evnt.afterInsert, new IbdUnitSetAttemptServices.EventHandler())
        .execute();
}