/**
* @description        : schedulable class of BTExpireWaitlistedAttendeeBatch
 * @author            : Ibrahim Rumi 
 * @group             : Event Management
 * @created date      : 12-07-2021
**/
public class BTExpireWaitlistedAttendeeSchd implements Schedulable{

    @TestVisible
    private Integer batchsize;
    
    //constructor retrieves batch size from the blackthorn event custom setting
    public BTExpireWaitlistedAttendeeSchd(){
        this.batchsize = (Integer)BTAttendeeServices.defaultSettings.Expire_Waitlist_Attendee_Batch_size__c;
    }
    
    //constructor allows parameter to overwrite the batchsize
    public BTExpireWaitlistedAttendeeSchd(Integer i){
        this.batchsize = i;
    }
    public void execute(SchedulableContext sc) {
        //sets batch size as 100 if no value is provided through constructor or in the event setting
        BTExpireWaitlistedAttendeeBatch btExpireAttendeebatchObj = new  BTExpireWaitlistedAttendeeBatch(); 
        ID batchprocessidOpp = Database.executeBatch(btExpireAttendeebatchObj,this.batchsize);
    }
    
}