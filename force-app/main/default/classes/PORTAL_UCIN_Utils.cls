/**
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Util class for portal code
 *  * Modifications Log 
 * Date         Author         		 	Modification
 * 2025-06-17   Matthew Maramot         Fixing gift receipt for logged in user (EPCP-4946)
 * 2022-07-14   Inderpal Dhanoa   		Updated reference to RT V2 (PENGAGE-2434)
 * 2020-10-15   Ken McGuire				Ken McGuire modified for moving processing from client to server.
 */
public class PORTAL_UCIN_Utils {

    public static String namespacePrefix {
        get {
            if (namespacePrefix == null) {
                String[] parts = String.valueOf(PORTAL_UCIN_Utils.class).split('\\.', 2);
                namespacePrefix = parts.size() == 2 ? parts[0] : '';
            }
            return namespacePrefix;
        }
        private set;
    }

    public static String namespacePrefixWithDoubleUnderscoresOrEmpty {
        get {
            if (namespacePrefix != '') {
                namespacePrefixWithDoubleUnderscoresOrEmpty = namespacePrefix + '__';
            }
            else {
                namespacePrefixWithDoubleUnderscoresOrEmpty = '';
            }
            return namespacePrefixWithDoubleUnderscoresOrEmpty;
        }
        private set;
    }

    public static Boolean ascendAppInstalledAndLicensed {
        get {
            if (ascendAppInstalledAndLicensed == null) {
                ascendAppInstalledAndLicensed = UserInfo.isCurrentUserLicensed('ucinn_ascendv2');
            }
            return ascendAppInstalledAndLicensed;
        }
        private set;
    }

    public static void onelineDonationParseParams(Map<String, Object> params, Map<String, Object> devParams) {
        Contact constituentRec = (Contact) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('constituentRec'), Contact.Class);
        Account organizationRec = (Account) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('organizationRec'), Account.Class);
        Opportunity giftRec = (Opportunity) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('giftRec'), Opportunity.Class);
        List<ucinn_ascendv2__Designation_Detail__c> designationDetailRecList = (List<ucinn_ascendv2__Designation_Detail__c>) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('designationDetailRecList'), List<ucinn_ascendv2__Designation_Detail__c>.Class);
        List<ucinn_ascendv2__Tribute__c> tributeRecList = (List<ucinn_ascendv2__Tribute__c>) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('tributeRecList'), List<ucinn_ascendv2__Tribute__c>.Class);
        Opportunity pledgeRec = (Opportunity) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('pledgeRec'), Opportunity.Class);
        ucinn_ascendv2__Payment__c paymentRecWrapper = (ucinn_ascendv2__Payment__c) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('paymentRecWrapper'), ucinn_ascendv2__Payment__c.Class);
        List<ucinn_ascendv2__Installment__c> installmentRecList = (List<ucinn_ascendv2__Installment__c>) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('installmentRecList'), List<ucinn_ascendv2__Installment__c>.Class);
        Opportunity selectedPledgeRec = (Opportunity) PORTAL_UCIN_Utils.parseLightningObjectToTargetType(params.get('selectedPledgeRec'), Opportunity.Class);

        params.put('constituentRec', constituentRec);
        params.put('organizationRec', organizationRec);
        params.put('giftRec', giftRec);
        params.put('designationDetailRecList', designationDetailRecList);
        params.put('tributeRecList', tributeRecList);
        params.put('pledgeRec', pledgeRec);
        params.put('paymentRecWrapper', paymentRecWrapper);
        params.put('installmentRecList', installmentRecList);
        params.put('selectedPledgeRec', selectedPledgeRec);
        
    }

    public static Object parseLightningObjectToTargetType(Object record, System.Type targetType) {

        if (record == null) {
            return null;
        }
        Object convertedType = (Object) System.Json.deserialize(System.Json.serialize(record), targetType);
        return convertedType;
    }

    // Compatibility
    public static String ascendCompatibilityQueryParser(String queryStr) {
        return '';
    }

    public static string getBaseURL() {
        String siteURL = Site.getBaseUrl();
        if (String.isNotEmpty(siteURL)){
            // Only return siteURL if called from site
            return siteURL;
        } 
        else{
            // Return org URL
            return URL.getOrgDomainURL().toExternalForm();
        }
    }

    // Generate gift receipt as a pdf and save as a file, return ContentVersionId
    public static Id createGiftReceiptFile(Id parentObjectId, String paymentGroupId, string receiptURL, String netId) {
 		PageReference ref = new PageReference(receiptURL);

        ContentVersion cont = new ContentVersion();
        cont.Title = 'Gift Receipt';
        cont.PathOnClient = 'file.pdf';
        if(test.isRunningTest()){
            cont.VersionData = Blob.valueOf('test');
        } else{
        	cont.VersionData = ref.getContentAsPdf();
        }
        cont.Origin = 'H';
        cont.FirstPublishLocationId = parentObjectId;
        cont.NetworkId = netId;
        insert cont;

        ContentVersion cont2 = [SELECT ContentDocumentId FROM ContentVersion WHERE ID =: cont.ID];
        
        try {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cont2.ContentDocumentId;
            cdl.LinkedEntityId = parentObjectId;
            cdl.ShareType = 'V';
            insert cdl;
        } catch (Exception ex) {
            PORTAL_UCIN_Donation_Raw_Document_Link__c drdl = new PORTAL_UCIN_Donation_Raw_Document_Link__c();
            drdl.Review_Transaction_v2__c = parentObjectId;
            drdl.ContentDocumentId__c = cont2.ContentDocumentId;
            insert drdl;
        }
        
        return cont.Id;
    }
    
    /**
    * Return the URL for a custom visulaforce page that generates review transaction receipts.l
    *                   
    * @return: String			The URL for the receipt page                    
    * @param: Sobject Id 		The Id for the review transaction.
    */
    public static string getReviewTransactionReceiptURL(string reviewTransactionId) {
        string baseUrl = getBaseURL();
        if (baseUrl.contains('ascendportal')) return baseUrl + '/PORTAL_UCIN_ReceiptPage?reviewTransactionId=' + reviewTransactionId;
        return baseUrl + '/apex/PORTAL_UCIN_ReceiptPage?reviewTransactionId=' + reviewTransactionId;
    }
    

    /**
    * Removes <p> html tags from given text and replaces instances of 
    * [FirstName] with the current user's Contact's first name.
    *
    * @param: entryText     The string that should have text replaced
    */
    public static String replaceSelectedText (String entryText){
        if (!string.isBlank(entryText)) {
            String replacementText = entryText.replaceAll('<p>','');
            replacementText = replacementText.replaceAll('</p>','');

            if(replacementText.contains('[FirstName]')) {
                Id userId = UserInfo.getUserId();
                User usr = [SELECT Id,
                        ContactId
                        FROM User
                        WHERE Id = :userId];
                Id contactId = usr.ContactId;

                if(contactId != null){
                    Contact con = [SELECT FirstName FROM Contact WHERE Id =:contactId];
                    if(con.FirstName != null) {
                        replacementText = replacementText.replaceAll('\\[FirstName\\]',con.FirstName);
                    } else {
                        replacementText = replacementText.replaceAll('\\[FirstName\\]', '');
                    }
                    
                }
            }
            return replacementText;
        }
        return null;
    }
}