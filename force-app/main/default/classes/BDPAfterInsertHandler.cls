/**
 * Trigger handler class for after insert events of Bulk Data Processing object
 * @author David Browaeys
 * @group Bulk Data Processing
 */
public inherited sharing class BDPAfterInsertHandler extends TriggerAbstract { 
    PromiseChain chain = new PromiseChain();
    public override void process(SObject rec) {
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c) rec;
        if (BDPFilterService.meetBDPCourseOfferingMatchingService(bdp,null) ) {
            chain.then(BDPCourseOfferingMatchingService.class, bdp);
        }
    }
    public override void execute() {
        chain.execute();
    }
}