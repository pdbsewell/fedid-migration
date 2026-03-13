/**
 * @author      David Browaeys
 * @description Trigger handler class for before update events of Bulk Data Processing object
 * @revision    07/02/2020 - David Browaeys - Created
 */
public inherited sharing class BDPBeforeUpdateHandler extends TriggerAbstract { 
    PromiseChain chain = new PromiseChain();
	public override void process(SObject rec, SObject oldRec) { 
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c) rec;
        Bulk_Data_Processing__c bdpOld = (Bulk_Data_Processing__c) oldRec;
        if (BDPFilterService.meetBDPFieldUpdateService(bdp,bdpOld) ) {
            chain.then(BDPFieldUpdateService.class, bdp);
        }
        if (BDPFilterService.meetBDPFetchOldACPService(bdp, bdpOld)) { 
            chain.then(BDPFetchOldACPService.class,bdp);
        }
        if(BDPFilterService.meetACPMatchingService(bdp,bdpOld)){
            BDPFieldUpdateService.updateStatus(bdp);
        }
        if(BDPFilterService.meetOfferTemplateMatchingService(bdp,bdpOld)){ // SFTG-2150 Add Offer template ID and Type 
            BDPFieldUpdateService.updateOfferTemplate(bdp);
        }
        if (BDPFilterService.meetBDPCourseOfferingMatchingService(bdp,bdpOld)){
            chain.then(BDPCourseOfferingResetService.class,bdp);
        }
    }
    public override void execute() {
        chain.execute();
    }
}