/**
 * Services class to provide Payment Support
 * 
 * @author Charlie Park - UC Innovation
 */

public class EngagePaymentService {
	/*******************************************************************************
	* @description 	Set authorize and charge field to false UNLESS tender type category is set to 'Credit Card'
	*******************************************************************************/
	public class setAuthorizeAndCharge implements Triggers.Handler {
		public void run() {
			List<ucinn_ascendv2__Gift_Processing_Tender_Type__mdt> tenderTypeMDList = [SELECT ucinn_ascendv2__Tender_Type_Category__c, DeveloperName FROM ucinn_ascendv2__Gift_Processing_Tender_Type__mdt 
												WHERE ucinn_ascendv2__Tender_Type_Category__c = 'Credit Card'];
			Set<String> tenderTypesToAuthAndCharge = new Set<String>();
			for (ucinn_ascendv2__Gift_Processing_Tender_Type__mdt eachMD: tenderTypeMDList) {
				tenderTypesToAuthAndCharge.add(eachMD.DeveloperName);
			}

			// Loop through trigger new, if tender type is not in tenderTypesToAuthAndCharge set, then set authorize_and_charge__c to false
			List<ucinn_ascendv2__Payment__c> paymentList = (List<ucinn_ascendv2__Payment__c>) Trigger.New;
            for (ucinn_ascendv2__Payment__c eachPayment: paymentList) {
				if (!tenderTypesToAuthAndCharge.contains(eachPayment.ucinn_ascendv2__Tender_Type_for_Gifts__c) 
                    	&& !tenderTypesToAuthAndCharge.contains(eachPayment.ucinn_ascendv2__Tender_Type_for_Pledges__c)) {
					eachPayment.ucinn_ascendv2__Authorize_and_Charge__c = false;
				}
			}
		}
	}
}