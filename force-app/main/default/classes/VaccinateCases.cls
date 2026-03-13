/**
 * @description      : Allow SMS to query/aggregate Vaccinate cases
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   19-10-2021 - Angelo Rivera - Initial Creation
 * 1.1   27-10-2021 - Angelo Rivera - Added logic for getting vouchers
 * 2.0   28-02-2022 - Tom Gangemi   - SA-1312
**/

@RestResource(UrlMapping='/VaccinateCases/*')
global without sharing class VaccinateCases {

    @HttpGet
    webService static void getCases() {
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;

        // Route request
        if(req.requestURI.endsWith('/VaccinateCases/V2')) {
            resp.responseBody = Blob.valueOf(JSON.serialize(getCasesV2()));
        } else {
            resp.responseBody = Blob.valueOf(JSON.serialize(getCasesV1()));
        }
    }

    webService static List<VaccinateMonashV2Wrapper> getCasesV2() {
        List<VaccinateMonashV2Wrapper> cases = new List<VaccinateMonashV2Wrapper>();

        VaccinateMonashV2Wrapper vmStudent = new VaccinateMonashV2Wrapper();
        vmStudent = generateV2Wrapper(Label.Vaccinate_Monash_Students);
        cases.add(vmStudent);

        VaccinateMonashV2Wrapper vmStaff = new VaccinateMonashV2Wrapper();
        vmStaff = generateV2Wrapper(Label.Vaccinate_Monash_Staff);
        cases.add(vmStaff);

        return cases;
    }

    webService static List<VaccinateMonashWrapper> getCasesV1() {
        List<VaccinateMonashWrapper> listCases = new List<VaccinateMonashWrapper>();

        VaccinateMonashWrapper vmStudent = new VaccinateMonashWrapper();
        vmStudent = generateWrapper(Label.Vaccinate_Monash_Students);
        listCases.add(vmStudent);

        VaccinateMonashWrapper vmStaff = new VaccinateMonashWrapper();
        vmStaff = generateWrapper(Label.Vaccinate_Monash_Staff);
        listCases.add(vmStaff);

        return listCases;
    }

    // returns count of awaiting cases
    webService static Integer getAwaiting(String strEnqType, Id gId){
        return [SELECT COUNT() FROM Case
                WHERE Enquiry_Type__c =: strEnqType
                AND OwnerId !=: gId
                AND IsClosed = FALSE];
    }

    // returns count of all submissions
    webService static Integer getAllSubmissions(String strEnqType, Id gId){
        return [SELECT COUNT() FROM Case
                WHERE Enquiry_Type__c =: strEnqType
                AND OwnerId !=: gId];
    }

    // returns count of approved cases
    webService static Integer getApproved(String strEnqType, Id gId){
        String strOutcomes = Label.Vaccinate_Monash_Approved_Case_Outcome;
        String[] arrString = strOutcomes.split(',');
        Set<String> setOutcomes = new Set<String>();
        for(String str : arrString){
            setOutcomes.add(str);
        }
        return [SELECT COUNT() FROM Case
                WHERE Enquiry_Type__c =: strEnqType
                AND Case_Outcome__c IN: setOutcomes
                AND OwnerId !=: gId];
    }

    // returns count of all vouchers
    webService static List<AggregateResult> getVouchers(String strEnqType, Id gId){
        return [SELECT SUM(Granted_Amount__c) Amount, COUNT(Id) Vouchers
                    FROM Case
                    WHERE Enquiry_Type__c =: strEnqType
                    AND Article_Number__c != NULL
                    AND Granted_Amount__c != NULL
                    AND Case_Outcome__c =:  Label.Vaccinate_Monash_Approved_Vax_Cert
                    AND OwnerId !=: gId];
    }

    @TestVisible
    private static List<AggregateResult> getVouchersV2(String enquiryType, Id gId){
        return [
            SELECT SUM(Granted_Amount__c) Amount, COUNT(Id) Vouchers
            FROM Case
            WHERE Enquiry_Type__c =: enquiryType
            AND Article_Number__c != NULL
            AND Granted_Amount__c > 0
            AND OwnerId !=: gId
        ];
    }

    // generates wrapper class
    webService static VaccinateMonashWrapper generateWrapper(String strEnqType){
        Id gId = [SELECT Id FROM Group WHERE Type ='Queue' AND Name =: Label.Spam].Id;
        VaccinateMonashWrapper vm =  new VaccinateMonashWrapper();
        vm.awaiting = 0;
        vm.submitted = 0;
        vm.approved = 0;
        vm.voucher = 0;
        vm.amount = 0;
        vm.enquiryType = strEnqType;
        vm.awaiting = getAwaiting(strEnqType, gId);
        vm.submitted = getAllSubmissions(strEnqType, gId);
        vm.approved = getApproved(strEnqType, gId);

        List<AggregateResult> ar = new List<AggregateResult>(getVouchers(strEnqType, gId));
        if(!ar.isEmpty()){
            vm.voucher = (Integer)ar[0].get('Vouchers');
            Decimal dAmount = ((Decimal)ar[0].get('Amount') == null) ? 0 : (Decimal)ar[0].get('Amount');
            vm.amount = dAmount.setScale(0);
        }
        return vm;
    }

    global class VaccinateMonashWrapper{
        webService String enquiryType;
        webService Integer submitted;
        webService Integer approved;
        webService Integer awaiting;
        webService Integer voucher;
        webService Decimal amount;
        public VaccinateMonashWrapper(){
        }
    }

    /**
     * Returns the count of cases based on the given list of caseOutcomes
     */
    private static Integer getOutcomeCount(String enquiryType, String caseOutcomes, Id excludedOwnerId) {
        Set<String> outcomeSet = new Set<String>(caseOutcomes.split(','));
        return [
            SELECT COUNT() FROM Case
            WHERE Enquiry_Type__c = :enquiryType AND
                Case_Outcome__c IN :outcomeSet AND
                OwnerId != :excludedOwnerId
        ];
    }

    webService static VaccinateMonashV2Wrapper generateV2Wrapper(String enquiryType) {
        Id excludedOwnerId = [SELECT Id FROM Group WHERE Type ='Queue' AND Name =: Label.Spam].Id;
        VaccinateMonashV2Wrapper vm =  new VaccinateMonashV2Wrapper();
        vm.enquiryType = enquiryType;
        vm.awaiting = getAwaiting(enquiryType, excludedOwnerId);
        vm.twoDosesOrExempt = getOutcomeCount(enquiryType, Label.Vaccinate_Monash_Two_Doses_Or_Exempt, excludedOwnerId);
        vm.threeDoses = getOutcomeCount(enquiryType, Label.Vaccinate_Monash_Three_Doses, excludedOwnerId);

        List<AggregateResult> ar = new List<AggregateResult>(getVouchersV2(enquiryType, excludedOwnerId));
        if(!ar.isEmpty()) {
            vm.voucher = (Integer)ar[0].get('Vouchers');
            Decimal dAmount = ((Decimal)ar[0].get('Amount') == null) ? 0 : (Decimal)ar[0].get('Amount');
            vm.amount = dAmount.setScale(0);
        } else {
            vm.voucher = 0;
            vm.amount = 0;
        }
        return vm;
    }

    global class VaccinateMonashV2Wrapper {
        webService String enquiryType;
        // Vax fields
        webService Integer twoDosesOrExempt;
        webService Integer threeDoses;
        webService Integer awaiting;
        // Voucher Fields
        webService Integer voucher;
        webService Decimal amount;
        public VaccinateMonashV2Wrapper() {}
    }
}