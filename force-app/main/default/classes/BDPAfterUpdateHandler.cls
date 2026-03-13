/**
 * Trigger handler class for after update events of Bulk Data Processing object
 * @author David Browaeys
 * @group Bulk Data Processing
 */
public inherited sharing class BDPAfterUpdateHandler extends TriggerAbstract { 
    PromiseChain chain = new PromiseChain();
	public override void process(SObject rec, SObject oldRec) { 
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c) rec;
        Bulk_Data_Processing__c bdpOld = (Bulk_Data_Processing__c) oldRec;
        if (BDPFilterService.meetBDPCourseOfferingMatchingService(bdp,bdpOld) ) {
            chain.then(BDPCourseOfferingMatchingService.class, bdp);
        }
        if (BDPFilterService.hasTransferToAcp(bdp) && BDPFilterService.isOfferConditionChanged(bdp, bdpOld)) {
            chain.then(BDPAcpOfferConditionSync.class, bdp);
        }
    }
    public override void execute() {
        chain.execute();
    }
}