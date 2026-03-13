/**
 * @author      David Browaeys
 * @description Trigger handler class for before insert events of Bulk Data Processing object
 * @revision    07/02/2020 - David Browaeys - Created
 */
public inherited sharing class BDPBeforeInsertHandler extends TriggerAbstract { 
    PromiseChain chain;
    public BDPBeforeInsertHandler(){
        super();
        chain = new PromiseChain();
    }
	public override void process(SObject rec) {
       Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c) rec;
       BDPFieldUpdateService.updateRecordType(bdp);
       BDPFieldUpdateService.splitCreditDuration(bdp);
       BDPFieldUpdateService.updateOfferTemplate(bdp); // SFTG-2150 Add Offer template ID and Type 
        if (BDPFilterService.meetBDPFieldUpdateService(bdp,null) ) {
            chain.then(BDPFieldUpdateService.class, bdp);
        }
        if (BDPFilterService.meetBDPFetchOldACPService(bdp, null)) { 
            chain.then(BDPFetchOldACPService.class,bdp);
        }
    }
    public override void execute() {
        chain.execute();
    }
}