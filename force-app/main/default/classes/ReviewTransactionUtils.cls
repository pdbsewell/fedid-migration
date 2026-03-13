//Added by UC Innovation to override out of the box Review Transaction logic - 2019-09-19
 /**
 * @author          UC Innovation
 * @description     This class contains trigger logic (handler classes) for the Review Transaction object
 * @group           Service Class
 * @revision
 * 1.1					12/08/2022 - Inderpal D        		- SOQL vulnerability PENGAGE-2471
 * 1.0                  19/09/2019 - UC Innovation     	  	 - Initial version
 */
public without sharing class ReviewTransactionUtils {

    //List of Objects to Insert
    public List<sObject> allObjects;

    //Opportunity for each Review Transaction
    public Map<String, Opportunity> mapOfOpportunities;

    //Designation Detail for each Review Transaction
    public List<ucinn_ascendv2__Designation_Detail__c> listOfDesignationDetails;
    public Map<String, List<ucinn_Ascendv2__Installment__c>> installmentMap = new Map<String, List<ucinn_ascendv2__Installment__c>>();

    //Giving History for each Review Transaction
    public List<ucinn_ascendv2__Payment__c> listOfPayments;

    //Hard and Soft Credits for each Review Transaction
    public List<ucinn_ascendv2__Hard_and_Soft_Credit__c> listOfHandSCredits;

    //Installments for each Pledge Review Transaction
    public List<ucinn_ascendv2__Installment__c> listOfInstallments;

    //Spouse Map
    public Map<Id, Id> mapOfSpouses;

    //External Pledge ID, Contact/Account Map
    public Map<String, sObject> mapOfDonorsByExternalPledge;

    //Map<String, Oportunity> - External Pledge No. , Opportunity
    public Map<String, Opportunity> mapOfPledgesByExternalID;

    //Map for Active Pledges - If containsKey, then Contact/Account has an Active Pledge
    //Map<Contact/Account, List<Map<Opportunity, List<Designation Detail>>>>
    //public Map<Id, Map<Opportunity, Map<String, Designation_Detail__c>>> mapOfActivePledges;
    
    //Map<Contact/Account, List<Opportunity>>
    public Map<Id, List<Opportunity>> mapOfActivePledges;

    

    //Map<Opportunity ID, Opportunity> For Updates With OpportunityTrigger false
    public Map<Id,Opportunity> mapOfPledgesForUpdate;

    //Map for Review Transaction Settings
    public static Map<String, Review_Transaction_Setting__mdt> mapOfRTSettings;

    //Opportunity Record Type Id
    private Id oppRecordTypeId;

    //Creates Session Container
    public ucinn_ascendv2__Session__c defaultSession;

    //Boolean to flag whether Matching Gift functionality should run
    public Boolean Payment_CreateMatchingGift_WantRun = true;
    //Counter for Hard and Soft Credits
    public Integer hardCtr = 0;

    public Integer softCtr = 0;

    public Map<String, String> opportunityIDToSessionNameMap = new Map<String, String>();
    
    //Map for Manual Review reasons
    public static Map<String, List<String>> mapOfManualReviewReasons;                              //[20191022 SC]: Map<RT.ucinn_ascendv2__External_System_ID__c , List<of Reason>>
    
    public ReviewTransactionUtils(){
        if (mapOfManualReviewReasons == null) {
            mapOfManualReviewReasons = new Map<String, List<String>>();
        }
        
        //Initialize Custom Metadata Type Review Transaction Settings
        mapOfRTSettings = new Map<String, Review_Transaction_Setting__mdt>();
        for(Review_Transaction_Setting__mdt oneMDT : [Select Id, Label, DeveloperName, Text_Value__c, Boolean_Value__c From Review_Transaction_Setting__mdt]){
            mapOfRTSettings.put(oneMDT.DeveloperName, oneMDT);
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Initialization entry point. Creates default session
    *******************************************************************************/
    public void initializeSession(ucinn_ascendv2__Session__c oneSession){
        defaultSession = oneSession;
        initializeTransactionObjects();
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Initialization of the review transaction object
    *******************************************************************************/
    public void initializeTransactionObjects(){
        //Initalize record Types
        oppRecordTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Pledge').RecordTypeId;

        //Initialize container
        allObjects = new List<sObject>();
        mapOfOpportunities = new Map<String,Opportunity>();
        listOfDesignationDetails = new List<ucinn_ascendv2__Designation_Detail__c>();
        listOfPayments = new List<ucinn_ascendv2__Payment__c>();
        listOfHandSCredits = new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>();
        listOfInstallments = new List<ucinn_ascendv2__Installment__c>();
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Gets the Spouses of the Contacts in the Transactions
    *******************************************************************************/
    public void getSpouses(List<sObject> sObjects){

        Set<Id> contactIds = new Set<Id>();
        //Gets the Spouses for each Hard Credit
        for(sObject so: sObjects){
            ucinn_ascendv2__Review_Transaction__c oneRT = (ucinn_ascendv2__Review_Transaction__c) so;
            if(oneRT.ucinn_ascendv2__Contact__c != null){
                contactIds.add(oneRT.ucinn_ascendv2__Contact__c);
            }
        }


        Map<Id, Contact> spouseDirectedMap = new Map<Id, Contact>();

    
        // Find the designated soft credits who have spouses checked as prevent
        // If the spouse is prevented from getting soft credit, then we don't include them in the map
        String soql = 'select ucinn_ascendv2__Contact__c, ucinn_ascendv2__Related_Contact__c, ucinn_ascendv2__Contact__r.Name, ucinn_ascendv2__Related_Contact__r.Name ' +
                                        'From ucinn_ascendv2__Relationship__c ' +
                                        'where (ucinn_ascendv2__Related_Contact_Role__c = \'Spouse\' OR ucinn_ascendv2__Related_Contact_Role__c = \'Husband\' OR ucinn_ascendv2__Related_Contact_Role__c = \'Wife\' OR ucinn_ascendv2__Related_Contact_Role__c = \'Partner\') ' +
                                          'and ucinn_ascendv2__Apply_Soft_Credit__c = false ' + // this means prevent the Related_Contact__c from getting soft credit
                                          'and ucinn_ascendv2__Contact__c in :contactIds';

        List<SObject> relationships = Database.query(soql);

        for (SObject relationship : relationships) {
            ucinn_ascendv2__Relationship__c theRelationship = (ucinn_ascendv2__Relationship__c)relationship;
            
            
            if (theRelationship.ucinn_ascendv2__Contact__c != null) {
               Id contact = theRelationship.ucinn_ascendv2__Contact__c;

                if (contactIds.contains(contact)) {
                    contactIds.remove(contact);
                }
            }
            
        }


        List<Contact> listOfContacts = [Select Id, ucinn_ascendv2__Preferred_Spouse__c from Contact where Id IN :contactIDs AND ucinn_ascendv2__Preferred_Spouse__c != null];

        mapOfSpouses = new Map<Id, Id>();

        for(Contact oneContact : listOfContacts){
            mapOfSpouses.put(oneContact.Id, oneContact.ucinn_ascendv2__Preferred_Spouse__c);
        }

    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Gets the Designations and returns a map of the External System Id with the Salesforce IDs as values
    *******************************************************************************/
    public static Map<String, Id> getValidDesignations (List<sObject> sObjects){

        Map<String, Id> mapOfDesignations = new Map<String, Id>();

        String extIDs = '';

        for(sObject oneSObject : sObjects){

            ucinn_ascendv2__Review_Transaction__c oneRT = (ucinn_ascendv2__Review_Transaction__c) oneSObject;

            if(oneRT.ucinn_ascendv2__Designation_1_Name__c != null){
               extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Designation_1_Name__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Designation_1_Name__c +'\'';
            }
            if(oneRT.ucinn_ascendv2__Designation_2_Name__c != null){
               extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Designation_2_Name__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Designation_2_Name__c +'\'';
            }
            if(oneRT.ucinn_ascendv2__Designation_3_Name__c != null){
               extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Designation_3_Name__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Designation_3_Name__c +'\'';
            }
            if(oneRT.ucinn_ascendv2__Designation_4_Name__c != null){
               extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Designation_4_Name__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Designation_4_Name__c +'\'';
            }
            if(oneRT.ucinn_ascendv2__Designation_5_Name__c != null){
               extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Designation_5_Name__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Designation_5_Name__c +'\'';
            }


        }

        if(extIDs != ''){
            String whereClause = 'ucinn_ascendv2__Status_Formula__c = \'Active\' AND ucinn_ascendv2__External_System_ID__c IN ('+extIDs+')';
            String soqlString = DynamicSoqlBuilder.getInstance()
                                    .showSOQLStatement(true)
                                    .setEnforced(false)
                                    .setLimit(null) 
                                    .querySObject('ucinn_ascendv2__Designation__c')
                                    .queryFields(new Set<String> {'Id', 'ucinn_ascendv2__External_System_ID__c'})
                                    .getQuery(whereClause);
            for(ucinn_ascendv2__Designation__c oneDesignation : Database.query(soqlString)){
                mapOfDesignations.put(oneDesignation.ucinn_ascendv2__External_System_ID__c, oneDesignation.Id);
            }
        }

        return mapOfDesignations;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Get all active pledges associated with a contact or acc
    *******************************************************************************/
    public void getActivePledges(List<sObject> sObjects, Map<String, Id> mapOfDesignations){
        
        //If Query returned with rows, it means there are active pledges for that person
        //mapOfActivePledges = new Map<Id,Map<Opportunity,Map<String,ucinn_ascendv2__Designation_Detail__c>>>();

        mapOfActivePledges = new Map<Id, List<Opportunity>>();
        mapOfDonorsByExternalPledge = new Map<String,sObject>();
        mapOfPledgesByExternalID = new Map<String,Opportunity>();

        //Store the Interface source (bofa/prax/wkdy/etc)
        String prefixRT = '';

        Set<Id> giftDesignations = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> pledgeNumbers = new Set<String>();
        Set<Id> recurringGiftIds = new Set<Id>();   // Hold a set of recurring gift id (opportunity__c field) from recurring gift payment RTs

        for(sObject so : sObjects){

            ucinn_ascendv2__Review_Transaction__c oneRT = (ucinn_ascendv2__Review_Transaction__c) so;
            if(prefixRT == '') {
                prefixRT = oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4);
            }
            
            Boolean isValidDesignation = false;

            //Check Designation
            //07202016 - Add multiple designations up to 5
            if(oneRT.ucinn_ascendv2__Designation_1_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_1_Name__c)){
               giftDesignations.add(mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_1_Name__c));
               isValidDesignation = true;
            }
            if(oneRT.ucinn_ascendv2__Designation_2_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_2_Name__c)){
               giftDesignations.add(mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_2_Name__c));
               isValidDesignation = true;
            }
            if(oneRT.ucinn_ascendv2__Designation_3_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_3_Name__c)){
               giftDesignations.add(mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_3_Name__c));
               isValidDesignation = true;
            }
            if(oneRT.ucinn_ascendv2__Designation_4_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_4_Name__c)){
               giftDesignations.add(mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_4_Name__c));
               isValidDesignation = true;
            }
            if(oneRT.ucinn_ascendv2__Designation_5_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_5_Name__c)){
               giftDesignations.add(mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_5_Name__c));
               isValidDesignation = true;
            }      
            
            if(isValidDesignation || oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment'){
                if(oneRT.ucinn_ascendv2__Contact__c != null){
                    contactIds.add(oneRT.ucinn_ascendv2__Contact__c);
                }
                else if(oneRT.ucinn_ascendv2__Account__c != null){
                    accountIds.add(oneRT.ucinn_ascendv2__Account__c);
                }
            }
            
            if(oneRT.Pledge_No__c != null) {
                pledgeNumbers.add(oneRT.Pledge_No__c);
            }
            
            if (oneRT.ucinn_ascendv2__Opportunity__c != null) {
                recurringGiftIds.add(oneRT.ucinn_ascendv2__Opportunity__c);
            }
        }

        //Contains the Id and the Opportunity Object
        Map<Id, Opportunity> mapOfOpportunities = new Map<Id, Opportunity>();

        //If Transaction is Workday, then Query for Pledge Type == Payroll, else != Payroll

        String oppQuery = 'Select Id, Type, Name, ucinn_ascendv2__Contact__c, AccountId,External_Pledge_No__c, '+
            '(Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Amount__c, ucinn_ascendv2__Campaign__c,'+
            'ucinn_ascendv2__Designation__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Unit_1__c, ucinn_ascendv2__Number_of_Payments__c,'+
            'ucinn_ascendv2__Number_of_Payments_to_Date_Roll_Up__c, ucinn_ascendv2__Account__c, ucinn_ascendv2__Opportunity__c,'+
            'ucinn_ascendv2__Opportunity__r.CreatedDate, ucinn_ascendv2__Session__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c, '+
            'ucinn_ascendv2__Campaign__r.ucinn_ascendv2__Motivation_Code__c '+
            'From ucinn_ascendv2__Designation_Details_Opportunity__r Order By CreatedDate)'+
                'From Opportunity';

        //String oppWhereClause = '(ucinn_ascendv2__Contact__c IN :contactIDs OR AccountId IN :accountIds OR Name IN :pledgeNumbers OR External_Pledge_No__c IN :pledgeNumbers) ';

        String oppWhereClause = '((ucinn_ascendv2__Remaining_Amount_Due_Formula__c > 0 OR Type = \'Recurring\')';
        oppWhereClause += ' AND StageName = \'Active\' ';
        oppWhereClause += ' AND (ucinn_ascendv2__Contact__c IN :contactIDs OR AccountId IN :accountIds)) OR Name IN :pledgeNumbers OR External_Pledge_No__c IN :pledgeNumbers OR ID IN: recurringGiftIds';

        //Include Where in oppQuery
        oppQuery += ' WHERE ' + oppWhereClause;
        
        //[20191026 SC]: Include Order By Recent Credit Date
        oppQuery += ' ORDER By ucinn_ascendv2__Credit_Date__c ASC';

        for(Opportunity oneOpp : Database.Query(oppQuery)) {
            if (oneOpp.ucinn_ascendv2__Contact__c != null) {
                if (!mapOfActivePledges.containsKey(oneOpp.ucinn_ascendv2__Contact__c)) {
                    mapOfActivePledges.put(oneOpp.ucinn_ascendv2__Contact__c, new List<Opportunity>());
                }  
                mapOfActivePledges.get(oneOpp.ucinn_ascendv2__Contact__c).add(oneOpp);
            } else if (oneOpp.AccountId != null) {
                if (!mapOfActivePledges.containsKey(oneOpp.AccountId)) {
                    mapOfActivePledges.put(oneOpp.AccountId, new List<Opportunity>());
                }  
                mapOfActivePledges.get(oneOpp.AccountId).add(oneOpp);
            }
            
            if (oneOpp.External_Pledge_No__c != null) {
                if (oneOpp.ucinn_ascendv2__Contact__c != null) {
                    if (!mapOfDonorsByExternalPledge.containsKey(oneOpp.External_Pledge_No__c)) {
                        mapOfDonorsByExternalPledge.put(oneOpp.External_Pledge_No__c, new Contact(Id=oneOpp.ucinn_ascendv2__Contact__c));
                    }
                }
                else if (oneOpp.AccountId != null) {
                    if (!mapOfDonorsByExternalPledge.containsKey(oneOpp.External_Pledge_No__c)) {
                        mapOfDonorsByExternalPledge.put(oneOpp.External_Pledge_No__c, new Account(Id=oneOpp.AccountId));
                    }
                }
                if (!mapOfPledgesByExternalID.containsKey(oneOpp.External_Pledge_No__c)) {
                    mapOfPledgesByExternalID.put(oneOpp.External_Pledge_No__c, oneOpp);
                }
            }
            
            if (oneOpp.ucinn_ascendv2__Contact__c != null) {
                if (!mapOfDonorsByExternalPledge.containsKey(oneOpp.Name)) {
                    mapOfDonorsByExternalPledge.put(oneOpp.Name, new Contact(Id=oneOpp.ucinn_ascendv2__Contact__c));
                }
            } else if (oneOpp.AccountId != null) {
                if (!mapOfDonorsByExternalPledge.containsKey(oneOpp.Name)) {
                    mapOfDonorsByExternalPledge.put(oneOpp.Name, new Account(Id=oneOpp.AccountId));
                }
            }
            
            if (!mapOfPledgesByExternalID.containsKey(oneOpp.Name)) {
                mapOfPledgesByExternalID.put(oneOpp.Name, oneOpp);
            }
            
        }
    }
    
    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Get all valid appeal codes that are associated with the transaction
    *******************************************************************************/
    public static Map<String, Id> getValidAppealCodes(List<sObject> sObjects){
        Map<String, Id> mapOfAppealCodes= new Map<String, Id>();

        String extIDs = '';

        for(sObject oneSObject : sObjects){

            ucinn_ascendv2__Review_Transaction__c oneRT = (ucinn_ascendv2__Review_Transaction__c) oneSObject;

            if(oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c != null){
                extIDs += extIDs.equals('')? '\''+ oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c + '\'' :',\'' + oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c +'\'';
            }
        }

        if(extIDs != ''){
            String whereClause = 'IsActive = true AND ucinn_ascendv2__Motivation_Code__c IN ('+extIDs+')';
            String soqlString = DynamicSoqlBuilder.getInstance()
                                    .showSOQLStatement(true)
                                    .setEnforced(false)
                                    .setLimit(null) 
                                    .querySObject('Campaign')
                                    .queryFields(new Set<String> {'Id', 'ucinn_ascendv2__Motivation_Code__c'})
                                    .getQuery(whereClause);
            for(Campaign oneCampaign: Database.query(soqlString)){
                mapOfAppealCodes.put(oneCampaign.ucinn_ascendv2__Motivation_Code__c , oneCampaign.Id);
            }
        }
        return mapOfAppealCodes;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Gets the Record Type Based on the ID from the Transaction (First 4 Characters)
    *******************************************************************************/
    public static Map<String, Id> getRecordTypes(){

        Map<String,Schema.RecordTypeInfo> mapOfRecordTypes = Schema.SObjectType.ucinn_ascendv2__Review_Transaction__c.RecordTypeInfosByName;

        Map<String, Id> mapOfRecordTypes_final = new Map<String, Id>();

        Map<String,ucinn_ascendv2__Review_Transaction_Prefixes__c> r = ucinn_ascendv2__Review_Transaction_Prefixes__c.getAll();


        try{
            for(String rtPrefix : r.keySet()){
                // Review_Transaction_Prefixes__c onePrefix = r.get(rtPrefix);
                
                if (mapOfRecordTypes.get(r.get(rtPrefix).ucinn_ascendv2__Record_Type_API_Name__c) != null) {
                    mapOfRecordTypes_final.put(r.get(rtPrefix).ucinn_ascendv2__Prefix__c, mapOfRecordTypes.get(r.get(rtPrefix).ucinn_ascendv2__Record_Type_API_Name__c).recordTypeId);
                }
                else {
                    mapOfRecordTypes_final.put(r.get(rtPrefix).ucinn_ascendv2__Prefix__c, null);
                }
               
            }
        }
        catch(Exception e){
            //Do Nothing. Record Type Id will be null therefore defaulting it to Master.
        }

        return mapOfRecordTypes_final;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates a session and all the Transactions associated with a particular session
    *******************************************************************************/
    public Boolean addTransaction(ucinn_ascendv2__Review_Transaction__c oneRT){

        //Check Transaction type = Pledge. If not, then process as normal Gift/Pledge Payment

        if(oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge'){
            createPledge(oneRT);
            return true;
        } else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
            createRecurringGift(oneRT);
            return true;
        }
        //GIFT OR PLEDGE PAYMENT
        else{
            createGiftOrPledgePayment(oneRT);
            return true;
        }
    }
    
    
    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates opportunity record
    *******************************************************************************/
    public void createRecurringGift(ucinn_ascendv2__Review_Transaction__c oneRT){
        //Default Values
        String opportunityTransactionType = 'Recurring Gift';
        
        //Date for Payment GroupID
        String runDate = String.valueOf(datetime.now().getTime());
         
       
        Id donor;
        // opportunityOwnerId to store the owner of Contact or Account
        Id opportunityOwnerId;
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            donor = oneRT.ucinn_ascendv2__Contact__c;
            opportunityOwnerId = [select id,OwnerId from Contact where id =: donor].OwnerId;
        }
        //Assumption - Account is populated if Contact is not.
        else{
            if(oneRT.ucinn_ascendv2__Account__c != null){
            	donor = oneRT.ucinn_ascendv2__Account__c;
            	opportunityOwnerId = [select id,OwnerId from Account where id =: donor].OwnerId;
            }
        }
                
        Id sessionId = defaultSession != null ? defaultSession.Id : oneRT.ucinn_ascendv2__Session__c;
        String sessionName = defaultSession != null ? defaultSession.Name : oneRT.ucinn_ascendv2__Session_Name_Formula__c;
        
        Opportunity oneOpp;
        Opportunity opportunityReference;
        ucinn_ascendv2__Designation_Detail__c designationDetail_1;
        
        //Appeal Code and Designation References
        Campaign campaignReference;

        if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c == null && oneRT.ucinn_ascendv2__Appeal_Code__c != null) {
            campaignReference = new Campaign(Id = oneRT.ucinn_ascendv2__Appeal_Code__c);
        } else {       
            campaignReference = new Campaign(ucinn_ascendv2__Motivation_Code__c = oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c);
        }
        
        ucinn_ascendv2__Designation__c designationReference, designation2Reference, designation3Reference, designation4Reference, designation5Reference;
        
        if (oneRT.ucinn_ascendv2__Designation_1_Name__c == null && oneRT.ucinn_ascendv2__Designation_1__c != null) {
            designationReference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_1__c);
        } else {       
            designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_1_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_2_Name__c == null && oneRT.ucinn_ascendv2__Designation_2__c != null) {
            designation2Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_2__c);
        } else {       
            designation2Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_2_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_3_Name__c == null && oneRT.ucinn_ascendv2__Designation_3__c != null) {
            designation3Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_3__c);
        } else {       
            designation3Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_3_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_4_Name__c == null && oneRT.ucinn_ascendv2__Designation_4__c != null) {
            designation4Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_4__c);
        } else {       
            designation4Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_4_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_5_Name__c == null && oneRT.ucinn_ascendv2__Designation_5__c != null) {
            designation5Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_5__c);
        } else {       
            designation5Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_5_Name__c);
        }

        //IF TRANSACTION = RECURRING GIFT

        //////////////////////////
        //Create the Opportunity
        oneOpp = new Opportunity();
        //References
        opportunityReference = new Opportunity(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c);
        // populate opportunity to session map for payment group id
        opportunityIDToSessionNameMap.put(oneRT.ucinn_ascendv2__External_System_ID__c, sessionName);
        
        oneOpp.ucinn_ascendv2__Session__c = sessionId;
        oneOpp.Name = oneRT.ucinn_ascendv2__Remitter_Name_Formula__c + ' - ' + String.valueOf(oneRT.ucinn_ascendv2__File_Creation_Date__c);
        oneOpp.ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c;
        oneOpp.ownerId = (UserInfo.getUserType() =='CSPLitePortal' && opportunityOwnerId !=null) ? opportunityOwnerId : UserInfo.getUserId();
            
        oneOpp.Type = 'Recurring';
        
        // Pratibha: As part of record type change, Funded_Amount__c = Amount
        oneOpp.Amount = oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
        oneOpp.RecordTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Recurring Gift').RecordTypeId;
        
        // New Fields for Opportunity
        oneOpp.ucinn_ascendv2__Is_Anonymous__c = oneRT.Is_Anonymous__c;
        
        oneOpp.ucinn_ascendv2__Review_Transaction__c = oneRT.Id;
        
        oneOpp.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
        oneOpp.ucinn_ascendv2__Start_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
        oneOpp.ucinn_ascendv2__End_Date__c = oneRT.ucinn_ascendv2__Pledge_End_Date__c;
        oneOpp.ucinn_ascendv2__Frequency__c = oneRT.ucinn_ascendv2__Payment_Frequency__c;
        oneOpp.ucinn_ascendv2__Tender_Type_For_Gifts__c = oneRT.ucinn_ascendv2__Tender_Type__c;
        oneOpp.CloseDate = oneRT.ucinn_ascendv2__Transaction_Date__c.addYears(5);
        oneOpp.ucinn_ascendv2__Notes__c = oneRT.Gift_Comments__c;
        oneOpp.Learn_About_Will__c = oneRT.Learn_About_Will__c;
        oneOpp.Gifted_in_Will__c = oneRT.Gifted_in_Will__c;

        if (oneRT.ucinn_ascendv2__Pledge_Status__c == 'Terminated') {   
            oneOpp.StageName = 'Cancelled';
        } else if (oneRT.ucinn_ascendv2__Pledge_Status__c == 'Completed') {
            oneOpp.StageName = 'Completed';
        } else {
            oneOpp.StageName = 'Active';
        }
        
        oneOpp.ucinn_ascendv2__Review_Transaction__c = oneRT.Id;
        //oneOpp.recordTypeId = oppRecordTypeId;
        oneOpp.ucinn_ascendv2__Gift_Processor__c = UserInfo.getUserId();
        
        //Assign the Constituent or Organization
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            oneOpp.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
            oneOpp.PrimaryContact__c = oneRT.ucinn_ascendv2__Contact__c;
        } else{
            oneOpp.AccountId = oneRT.ucinn_ascendv2__Account__c;
        }

        // If from community, then mark it as such
        if (oneRT.ucinn_ascendv2__External_System_ID__c.startsWith('PRAX-')) {
            oneOpp.ucinn_ascendv2__Is_Ascend_Community_Gift__c = true;
        }
        
        if(oneRT.ucinn_ascendv2__Designation_1__c != null){
            ucinn_ascendv2__Designation_Detail__c dd1 = createDesignationDetail(oneRT, 1, sessionId, opportunityReference, designationReference);
            ucinn_ascendv2__Payment__c onePayment;// = createPayment(1, dd1, designationReference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
            
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(1, oneRT, onePayment, sessionId, opportunityReference, dd1, 'Recurring Gift');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
            listOfDesignationDetails.add(dd1);
            //listOfPayments.add(onePayment);
        }
        if(oneRT.ucinn_ascendv2__Designation_2__c != null){
            ucinn_ascendv2__Designation_Detail__c dd2 = createDesignationDetail(oneRT, 2, sessionId, opportunityReference, designation2Reference);
            ucinn_ascendv2__Payment__c onePayment;// = createPayment(2, dd2, designation2Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
            
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(2, oneRT, onePayment, sessionId, opportunityReference, dd2, 'Recurring Gift');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
            listOfDesignationDetails.add(dd2);
            //listOfPayments.add(onePayment);
        }
        if(oneRT.ucinn_ascendv2__Designation_3__c != null){
            ucinn_ascendv2__Designation_Detail__c dd3 = createDesignationDetail(oneRT, 3, sessionId, opportunityReference, designation3Reference);
            ucinn_ascendv2__Payment__c onePayment;// = createPayment(3, dd3, designation3Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
            
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(3, oneRT, onePayment, sessionId, opportunityReference, dd3, 'Recurring Gift');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
            listOfDesignationDetails.add(dd3);
            //listOfPayments.add(onePayment);
        }
        if(oneRT.ucinn_ascendv2__Designation_4__c != null){
            ucinn_ascendv2__Designation_Detail__c dd4 = createDesignationDetail(oneRT, 4, sessionId, opportunityReference, designation4Reference);
            ucinn_ascendv2__Payment__c onePayment;// = createPayment(4, dd4, designation4Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
            
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(4, oneRT, onePayment, sessionId, opportunityReference, dd4, 'Payment');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
            listOfDesignationDetails.add(dd4);
            //listOfPayments.add(onePayment);
        }
        if(oneRT.ucinn_ascendv2__Designation_5__c != null){
            ucinn_ascendv2__Designation_Detail__c dd5 = createDesignationDetail(oneRT, 5, sessionId, opportunityReference, designation5Reference);
            ucinn_ascendv2__Payment__c onePayment;// = createPayment(5, dd5, designation5Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
            
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(5, oneRT, onePayment, sessionId, opportunityReference, dd5, 'Recurring Gift');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
            listOfDesignationDetails.add(dd5);
            //listOfPayments.add(onePayment);
        }
        
        //Add the newly created records to the list;
        if(!mapOfOpportunities.containsKey(oneOpp.ucinn_ascendv2__External_System_ID__c)){
            mapOfOpportunities.put(oneOpp.ucinn_ascendv2__External_System_ID__c, oneOpp);
        }
    }
    
    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates opportunity record
    *******************************************************************************/
    public void createGiftOrPledgePayment(ucinn_ascendv2__Review_Transaction__c oneRT){
        
        //Default Values
        String opportunityTransactionType = 'Outright';
        String paymentTransactionType = 'Outright Gift';
        
        //Date for Payment GroupID
        String runDate = String.valueOf(datetime.now().getTime());
        
        //Active Pledge if the Transaction is a Pledge payment
        Opportunity activePledge = getPledge(oneRT);
        
        //Assign either a Pledge Payment or an Outright Gift.
        Id donor;
        // opportunityOwnerId to store the owner of Contact or Account
        Id opportunityOwnerId;
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            donor = oneRT.ucinn_ascendv2__Contact__c;
            opportunityOwnerId = [select id,OwnerId from Contact where id =: donor].OwnerId;
        }
        //Assumption - Account is populated if Contact is not.
        else{
            if(oneRT.ucinn_ascendv2__Account__c != null){
            	donor = oneRT.ucinn_ascendv2__Account__c;
            	opportunityOwnerId = [select id,OwnerId from Account where id =: donor].OwnerId;
            }
        }
        
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Matching Gift') {
            opportunityTransactionType = 'Matching';
            paymentTransactionType = 'Matching Gift';
        } else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Gift') {                        // Stela 10/11/2019 
            opportunityTransactionType = 'Outright';
            paymentTransactionType = 'Outright Gift';
        } else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge Payment') {              //[20191026 SC]
            //If there is no Pledge Active, Consider an outright Gift
            if (activePledge != null) {
                opportunityTransactionType = 'Pledge Payment';
                paymentTransactionType = 'Pledge Payment';
            } else {
                opportunityTransactionType = 'Outright';
                paymentTransactionType = 'Outright Gift';
            }
        } else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
            opportunityTransactionType = 'Pledge Payment';
            paymentTransactionType = 'Pledge Payment';
        }
                
        Id sessionId = defaultSession != null ? defaultSession.Id : oneRT.ucinn_ascendv2__Session__c;
        String sessionName = defaultSession != null ? defaultSession.Name : oneRT.ucinn_ascendv2__Session_Name_Formula__c;
        Opportunity oneOpp;
        ucinn_ascendv2__Designation_Detail__c designationDetail_1;
        
        Opportunity opportunityReference;
        
        //Appeal Code and Designation References
        Campaign campaignReference;

        if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c == null && oneRT.ucinn_ascendv2__Appeal_Code__c != null) {
            campaignReference = new Campaign(Id = oneRT.ucinn_ascendv2__Appeal_Code__c);
        } else {       
            campaignReference = new Campaign(ucinn_ascendv2__Motivation_Code__c = oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c);
        }
        
        ucinn_ascendv2__Designation__c designationReference, designation2Reference, designation3Reference, designation4Reference, designation5Reference;
        
        if (oneRT.ucinn_ascendv2__Designation_1_Name__c == null && oneRT.ucinn_ascendv2__Designation_1__c != null) {
            designationReference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_1__c);
        } else {       
            designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_1_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_2_Name__c == null && oneRT.ucinn_ascendv2__Designation_2__c != null) {
            designation2Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_2__c);
        } else {       
            designation2Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_2_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_3_Name__c == null && oneRT.ucinn_ascendv2__Designation_3__c != null) {
            designation3Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_3__c);
        } else {       
            designation3Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_3_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_4_Name__c == null && oneRT.ucinn_ascendv2__Designation_4__c != null) {
            designation4Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_4__c);
        } else {       
            designation4Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_4_Name__c);
        }
        if (oneRT.ucinn_ascendv2__Designation_5_Name__c == null && oneRT.ucinn_ascendv2__Designation_5__c != null) {
            designation5Reference = new ucinn_ascendv2__Designation__c(Id = oneRT.ucinn_ascendv2__Designation_5__c);
        } else {       
            designation5Reference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_5_Name__c);
        }
        //////////////////////////////////
        //IF TRANSACTION = PLEDGE PAYMENT
        //////////////////////////////////
        if(opportunityTransactionType == 'Pledge Payment') {
            
            opportunityReference = new Opportunity(Id = activePledge.Id);
            String source = 'Payment';
                
            if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
                source = 'Recurring Gift Payment';
            }

            //Map<Designation, Designation Detail>
            Map<String,ucinn_ascendv2__Designation_Detail__c> tempMapOfDesignations = new Map<String,ucinn_ascendv2__Designation_Detail__c>();
            Map<String,ucinn_ascendv2__Designation_Detail__c> tempMapOfDesignationsById = new Map<String,ucinn_ascendv2__Designation_Detail__c>();
            
            for(ucinn_ascendv2__Designation_Detail__c tempDD : activePledge.ucinn_ascendv2__Designation_Details_Opportunity__r){
                if (tempDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c != null) {
                	tempMapOfDesignations.put(tempDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c, tempDD);
                } else {
                	tempMapOfDesignationsById.put(tempDD.ucinn_ascendv2__Designation__r.Id, tempDD);
            	}
            }
            
            // populating map to create payment group id
            opportunityIDToSessionNameMap.put(opportunityReference.Id, sessionName);
            
            if(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_1_Name__c) || tempMapOfDesignationsById.containsKey(oneRT.ucinn_ascendv2__Designation_1__c)){
                ucinn_ascendv2__Designation_Detail__c designationDetailReference;
                
                if (oneRT.ucinn_ascendv2__Designation_1_Name__c != null) {
                    designationDetailReference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_1_Name__c).Id);
                } else {
                    designationDetailReference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignationsById.get(oneRT.ucinn_ascendv2__Designation_1__c).Id);
                }

                ucinn_ascendv2__Payment__c payment1 = createPayment(1, designationDetailReference, designationReference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(1, oneRT, payment1, sessionId, opportunityReference, designationDetailReference, source);
                
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                    listOfHandSCredits.add(oneHSC);
                }
                listOfPayments.add(payment1);
            }
            if(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_2_Name__c) || tempMapOfDesignationsById.containsKey(oneRT.ucinn_ascendv2__Designation_2__c)){
                ucinn_ascendv2__Designation_Detail__c designationDetail2Reference;
                
                if (oneRT.ucinn_ascendv2__Designation_2_Name__c != null) {
                    designationDetail2Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_2_Name__c).Id);
                } else {
                    designationDetail2Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignationsById.get(oneRT.ucinn_ascendv2__Designation_2__c).Id);
                }
                
                ucinn_ascendv2__Payment__c payment2 = createPayment(2, designationDetail2Reference, designation2Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(2, oneRT, payment2, sessionId, opportunityReference, designationDetail2Reference, source);
                
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfPayments.add(payment2);
            }
            if(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_3_Name__c) || tempMapOfDesignationsById.containsKey(oneRT.ucinn_ascendv2__Designation_3__c)){
                ucinn_ascendv2__Designation_Detail__c designationDetail3Reference;
                
                if (oneRT.ucinn_ascendv2__Designation_2_Name__c != null) {
                    designationDetail3Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_3_Name__c).Id);
                } else {
                    designationDetail3Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignationsById.get(oneRT.ucinn_ascendv2__Designation_3__c).Id);
                }
                ucinn_ascendv2__Payment__c payment3 = createPayment(3, designationDetail3Reference, designation3Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(3, oneRT, payment3, sessionId, opportunityReference, designationDetail3Reference, source);
                
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfPayments.add(payment3);
            }
            if(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_4_Name__c) || tempMapOfDesignationsById.containsKey(oneRT.ucinn_ascendv2__Designation_4__c)){
                ucinn_ascendv2__Designation_Detail__c designationDetail4Reference;
                
                if (oneRT.ucinn_ascendv2__Designation_4_Name__c != null) {
                    designationDetail4Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_4_Name__c).Id);
                } else {
                    designationDetail4Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignationsById.get(oneRT.ucinn_ascendv2__Designation_4__c).Id);
                }
                ucinn_ascendv2__Payment__c payment4 = createPayment(4, designationDetail4Reference, designation4Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(4, oneRT, payment4, sessionId, opportunityReference, designationDetail4Reference, source);
                
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfPayments.add(payment4);
            }
            if(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_5_Name__c) || tempMapOfDesignationsById.containsKey(oneRT.ucinn_ascendv2__Designation_5__c)){
                ucinn_ascendv2__Designation_Detail__c designationDetail5Reference;
                
                if (oneRT.ucinn_ascendv2__Designation_5_Name__c != null) {
                    designationDetail5Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_5_Name__c).Id);
                } else {
                    designationDetail5Reference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignationsById.get(oneRT.ucinn_ascendv2__Designation_5__c).Id);
                }
                ucinn_ascendv2__Payment__c payment5 = createPayment(5, designationDetail5Reference, designation5Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(5, oneRT, payment5, sessionId, opportunityReference, designationDetail5Reference, source);
                
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                    listOfHandSCredits.add(oneHSC);
                }
                listOfPayments.add(payment5);
            }
            
            //[20191027 SC]: If matching Pledge No. is found and no designation
            if (oneRT.Pledge_No__c != null && activePledge != null
                && tempMapOfDesignations.size() >= 1
                && !(tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_1_Name__c)
                     || tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_2_Name__c)
                     || tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_3_Name__c)
                     || tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_4_Name__c)
                     || tempMapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_5_Name__c) ) ) {
                         String firstKey = (new List<String>(tempMapOfDesignations.keySet()))[0];
                         designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = ((ucinn_ascendv2__Designation_Detail__c)tempMapOfDesignations.get(firstKey)).ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c);
                         
                         ucinn_ascendv2__Designation_Detail__c designationDetailReference = new ucinn_ascendv2__Designation_Detail__c(Id = tempMapOfDesignations.get(firstKey).Id);
                         
                         //Set campaignreference using the Designation Detail appeal
                         if (campaignReference == null && designationDetailReference.ucinn_ascendv2__Campaign__r.ucinn_ascendv2__Motivation_Code__c != null) {
                             campaignReference = new Campaign(ucinn_ascendv2__Motivation_Code__c = designationDetailReference.ucinn_ascendv2__Campaign__r.ucinn_ascendv2__Motivation_Code__c);
                         }
                         
                         ucinn_ascendv2__Payment__c payment1 = createPayment(1, designationDetailReference, designationReference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                         List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempHSC = createHardAndSoftCredit(1, oneRT, payment1, sessionId, opportunityReference, designationDetailReference, 'Payment');
                         
                         for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempHSC){
                             listOfHandSCredits.add(oneHSC);
                         }
                         listOfPayments.add(payment1);
            }
            
            oneOpp = opportunityReference;
        }
        //IF TRANSACTION = OUTRIGHT GIFT
        else {
            //////////////////////////
            //Create the Opportunity
            oneOpp = new Opportunity();
            //References
            opportunityReference = new Opportunity(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c);
            // populate opportunity to session map for payment group id
            opportunityIDToSessionNameMap.put(oneRT.ucinn_ascendv2__External_System_ID__c, sessionName);
            oneOpp.ucinn_ascendv2__Session__c = sessionId;
            oneOpp.Name = oneRT.ucinn_ascendv2__Remitter_Name_Formula__c + ' - ' + String.valueOf(oneRT.ucinn_ascendv2__File_Creation_Date__c);
            oneOpp.ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c;
            
            // Opportunity owner assignment to internal user
            oneOpp.ownerId = (UserInfo.getUserType() =='CSPLitePortal' && opportunityOwnerId !=null) ? opportunityOwnerId : UserInfo.getUserId();
            
            oneOpp.StageName = 'Funded';
            // Pratibha: As part of record type change, Funded_Amount__c = Amount
            oneOpp.Amount = oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
            oneOpp.Learn_About_Will__c = oneRT.Learn_About_Will__c;
            oneOpp.Gifted_in_Will__c = oneRT.Gifted_in_Will__c;
            if (opportunityTransactionType == 'Matching') {
                oneOpp.RecordTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Matching Gift').RecordTypeId;
            } else {
                oneOpp.RecordTypeId = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Gift').RecordTypeId;
            }
            
            // New Fields for Opportunity (Gift Only)
            oneOpp.ucinn_ascendv2__Is_Anonymous__c = oneRT.Is_Anonymous__c;
            
            oneOpp.ucinn_ascendv2__Review_Transaction__c = oneRT.Id;
            if(oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'BOFA'){
                oneOpp.ucinn_ascendv2__Funded_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.ucinn_ascendv2__Entry_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.CloseDate = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
            }
            else if(oneRT.ucinn_ascendv2__Transaction_Date__c != null){
                oneOpp.ucinn_ascendv2__Funded_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
                oneOpp.ucinn_ascendv2__Entry_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
                oneOpp.CloseDate = oneRT.ucinn_ascendv2__Transaction_Date__c;
                oneOpp.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
            }
            else if(oneRT.ucinn_ascendv2__File_Creation_Date__c != null){
                oneOpp.ucinn_ascendv2__Funded_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.ucinn_ascendv2__Entry_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.CloseDate = oneRT.ucinn_ascendv2__File_Creation_Date__c;
                oneOpp.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
            }
            else{
                oneOpp.ucinn_ascendv2__Funded_Date__c = Date.Today();
            }
            
            oneOpp.ucinn_ascendv2__Review_Transaction__c = oneRT.Id;
            //oneOpp.recordTypeId = oppRecordTypeId;
            oneOpp.ucinn_ascendv2__Gift_Processor__c = UserInfo.getUserId();
            oneOpp.CampaignId = oneRT.ucinn_ascendv2__Appeal_Code__c;
            // Pratibha: Record Type Change, Gift_Type_Formula__c = Type
            oneOpp.Type = opportunityTransactionType;
            oneOpp.ucinn_ascendv2__Notes__c = oneRT.Gift_Comments__c;
            if (String.isNotBlank(oneRT.Gift_Type__c) && oneRT.Gift_Type__c != opportunityTransactionType) { // Stela
                oneOpp.Type = oneRT.Gift_Type__c;
            }
            
            //Assign the Constituent or Organization
            if(oneRT.ucinn_ascendv2__Contact__c != null){
                oneOpp.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
                oneOpp.PrimaryContact__c = oneRT.ucinn_ascendv2__Contact__c;
                
                //oneOpp.AccountId = oneRT.Contact__r.AccountId;  04/26/2016 - No Need for Contact's Account on Opportunity
            }
            else{
                oneOpp.AccountId = oneRT.ucinn_ascendv2__Account__c;
            }

            // If from community, then mark it as such
            if (oneRT.ucinn_ascendv2__External_System_ID__c.startsWith('PRAX-')) {
                oneOpp.ucinn_ascendv2__Is_Ascend_Community_Gift__c = true;
            }
            
            if(oneRT.ucinn_ascendv2__Designation_1__c != null){
                ucinn_ascendv2__Designation_Detail__c dd1 = createDesignationDetail(oneRT, 1, sessionId, opportunityReference, designationReference);
                ucinn_ascendv2__Payment__c onePayment = createPayment(1, dd1, designationReference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(1, oneRT, onePayment, sessionId, opportunityReference, dd1, 'Payment');
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfDesignationDetails.add(dd1);
                listOfPayments.add(onePayment);
            }
            if(oneRT.ucinn_ascendv2__Designation_2__c != null){
                ucinn_ascendv2__Designation_Detail__c dd2 = createDesignationDetail(oneRT, 2, sessionId, opportunityReference, designation2Reference);
                ucinn_ascendv2__Payment__c onePayment = createPayment(2, dd2, designation2Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(2, oneRT, onePayment, sessionId, opportunityReference, dd2, 'Payment');
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfDesignationDetails.add(dd2);
                listOfPayments.add(onePayment);
            }
            if(oneRT.ucinn_ascendv2__Designation_3__c != null){
                ucinn_ascendv2__Designation_Detail__c dd3 = createDesignationDetail(oneRT, 3, sessionId, opportunityReference, designation3Reference);
                ucinn_ascendv2__Payment__c onePayment = createPayment(3, dd3, designation3Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(3, oneRT, onePayment, sessionId, opportunityReference, dd3, 'Payment');
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfDesignationDetails.add(dd3);
                listOfPayments.add(onePayment);
            }
            if(oneRT.ucinn_ascendv2__Designation_4__c != null){
                ucinn_ascendv2__Designation_Detail__c dd4 = createDesignationDetail(oneRT, 4, sessionId, opportunityReference, designation4Reference);
                ucinn_ascendv2__Payment__c onePayment = createPayment(4, dd4, designation4Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(4, oneRT, onePayment, sessionId, opportunityReference, dd4, 'Payment');
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfDesignationDetails.add(dd4);
                listOfPayments.add(onePayment);
            }
            if(oneRT.ucinn_ascendv2__Designation_5__c != null){
                ucinn_ascendv2__Designation_Detail__c dd5 = createDesignationDetail(oneRT, 5, sessionId, opportunityReference, designation5Reference);
                ucinn_ascendv2__Payment__c onePayment = createPayment(5, dd5, designation5Reference, campaignReference, oneRT, sessionId, sessionName, runDate, opportunityReference, paymentTransactionType);
                
                List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(5, oneRT, onePayment, sessionId, opportunityReference, dd5, 'Payment');
                for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                    listOfHandSCredits.add(oneHSC);
                }
                
                listOfDesignationDetails.add(dd5);
                listOfPayments.add(onePayment);
            }
        }
        //Add the newly created records to the list;
        if(opportunityTransactionType != 'Pledge Payment'){  
            if(!mapOfOpportunities.containsKey(oneOpp.ucinn_ascendv2__External_System_ID__c)){
                mapOfOpportunities.put(oneOpp.ucinn_ascendv2__External_System_ID__c, oneOpp);
            }
            
        } else { // Stela 10/11/2019
            if(!mapOfOpportunities.containsKey(oneOpp.Id)){
                mapOfOpportunities.put(oneOpp.Id, oneOpp);
            }
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates transaction records
    *******************************************************************************/
    public void createTransactionRecords(){
        
        try{
        //Once all Review Transaction - derived Records have been created, DML Insert
        List<Opportunity> listOfOpportunities = new List<Opportunity>();

        for(String externalID: mapOfOpportunities.keySet()){
           
            Opportunity o = mapOfOpportunities.get(externalID);
             if (o.Id == null) {   //Stela 10/11/2019
                 listOfOpportunities.add(o);  
             }
        }
        if(!listOfOpportunities.isEmpty()){
            insert listOfOpportunities;
        }

        if(!listOfDesignationDetails.isEmpty()){
            insert listOfDesignationDetails;
        }

        if(!listofInstallments.isEmpty()){
            
            for (ucinn_ascendv2__Installment__c inst : listOfInstallments) {
                inst.ucinn_Ascendv2__Opportunity__c = inst.ucinn_ascendv2__Opportunity__r.Id;
               
            }

            insert listOfInstallments;
        }

        //Matching Gift Functionality
        asc_TriggerController.Payment_CreateMatchingGift_WantRun = Payment_CreateMatchingGift_WantRun;

        // get opportunity record associated with it to ge the Id and create payment group id
        //Id opportunityID = null;
        Map<String, String> opportunityIDTopaymentGroupIDMap = new Map<String, String>();

        if(!listOfPayments.isEmpty()){
            // generate payment group id by opportunity and session
            for (String externalID : mapOfOpportunities.keySet()) {
                String sessionName = opportunityIDToSessionNameMap.get(externalID);
                String paymentGroupID = null;
                String pledgeID = mapOfOpportunities.get(externalID).Id;
                if (sessionName != null && pledgeID != null) {
                    paymentGroupID = sessionName +pledgeID + generateGUID();
                } else if (sessionName != null) {
                    paymentGroupID = sessionName + generateGUID();
                } else if (pledgeID != null){
                    paymentGroupID = pledgeID + generateGUID();
                }
                opportunityIDTopaymentGroupIDMap.put(externalID, paymentGroupID);
            }

            // assign payment group id to payments
            for (ucinn_ascendv2__Payment__c payment : listOfPayments) {
                // opportunity Id or external Id
                if (payment.ucinn_ascendv2__Opportunity__c != null && opportunityIDTopaymentGroupIDMap.containsKey(payment.ucinn_ascendv2__Opportunity__c)) {
                    payment.ucinn_ascendv2__Payment_Group_ID__c = opportunityIDTopaymentGroupIDMap.get(payment.ucinn_ascendv2__Opportunity__c);
                } else if(payment.ucinn_ascendv2__Opportunity__r != null && opportunityIDTopaymentGroupIDMap.containsKey(payment.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_System_ID__c)){
                    payment.ucinn_ascendv2__Payment_Group_ID__c = opportunityIDTopaymentGroupIDMap.get(payment.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_System_ID__c);
                }
            }
            insert listOfPayments;

        }

        //System.Debug('Hard and Soft Credit Count:' + listOfHandSCredits.size());

        //Set Global Variable here
        asc_TriggerController.HardSoftTriggerIsRunning = false;

        if(!listOfHandSCredits.isEmpty()){

            for (ucinn_ascendv2__Hard_and_Soft_Credit__c oneHardAndSoftCredit : listOfHandSCredits) {
                if (oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__r != null && opportunityIDTopaymentGroupIDMap.containsKey(oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_System_ID__c)) {
                    oneHardAndSoftCredit.ucinn_ascendv2__Payment_Group_ID__c = opportunityIDTopaymentGroupIDMap.get(oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_System_ID__c);
                } else if (oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__c != null && opportunityIDTopaymentGroupIDMap.containsKey(oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__c)) {
                   
                    oneHardAndSoftCredit.ucinn_ascendv2__Payment_Group_ID__c = opportunityIDTopaymentGroupIDMap.get(oneHardAndSoftCredit.ucinn_ascendv2__Opportunity__C);  // Stela 10/11/2019
                }
            }

            insert listOfHandSCredits;

       		 }

        	return;
        }
        catch (Exception ex) {
            System.debug('### review Transation exception: ' + ex);
            LogUtilityException.logExceptionMSG('ReviewTransactionUtils','',ex.getMessage());
  
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates designation details
    *******************************************************************************/
    public ucinn_ascendv2__Designation_Detail__c createDesignationDetail(ucinn_ascendv2__Review_Transaction__c oneRT, Integer designationDetailCtr, Id sessionId, Opportunity opportunityReference, ucinn_ascendv2__Designation__c designationReference){

        ucinn_ascendv2__Designation_Detail__c oneDD = new ucinn_ascendv2__Designation_Detail__c();

        oneDD.ucinn_ascendv2__Session__c = sessionId;
        oneDD.ucinn_ascendv2__Opportunity__r = opportunityReference;

        if(designationDetailCtr == 1){
            oneDD.ucinn_ascendv2__Amount__c = (Decimal) oneRT.ucinn_ascendv2__Amount_1__c;
        }
        else{
            oneDD.ucinn_ascendv2__Amount__c = (Decimal) oneRT.get('ucinn_ascendv2__Amount_'+designationDetailCtr+'__c');
        }
        oneDD.ucinn_ascendv2__External_System_ID__c = 'DD-'+ oneRT.get('ucinn_ascendv2__Designation_'+designationDetailCtr+'_Name__c') + '-' + oneRT.ucinn_ascendv2__External_System_ID__c + '-' + String.valueOf(designationDetailCtr);
        //designationDetailReference = new Designation_Detail__c(External_System_ID__c = oneRT.External_System_ID__c + String.valueOf(designationDetailCtr));
        oneDD.ucinn_ascendv2__Campaign__c = oneRT.ucinn_ascendv2__Appeal_Code__c;

        //10202016 - If No to Tax Receipt
        if(oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge' || oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift'){

            if(mapOfRTSettings.containsKey('Pledge_Has_Tax_Receipt')){
                oneDD.ucinn_ascendv2__Has_Tax_Receipt__c = mapOfRTSettings.get('Pledge_Has_Tax_Receipt').Boolean_Value__c;
            }
            else{
                oneDD.ucinn_ascendv2__Has_Tax_Receipt__c = false;
            }
        }
        else{
            oneDD.ucinn_ascendv2__Has_Tax_Receipt__c = true;
        }
        
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
            oneDD.ucinn_ascendv2__Start_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
            oneDD.ucinn_ascendv2__End_Date__c = oneRT.ucinn_ascendv2__Pledge_End_Date__c;
        }

        if(oneRT.ucinn_ascendv2__Number_of_Payments__c != null){
            oneDD.ucinn_ascendv2__Number_of_Payments__c = Integer.valueOf(oneRT.ucinn_ascendv2__Number_of_Payments__c.trim());
        }
        //Assign the Constituent or Organization
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            oneDD.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
        }
        else{
            oneDD.ucinn_ascendv2__Account__c= oneRT.ucinn_ascendv2__Account__c;
        }

        if(designationDetailCtr == 1){
            oneDD.ucinn_ascendv2__Designation__c = oneRT.ucinn_ascendv2__Designation_1__c;
        }
        else{
            oneDD.ucinn_ascendv2__Designation__c = (Id) oneRT.get('ucinn_ascendv2__Designation_'+designationDetailCtr+'__c');
        }
        return oneDD;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates Hard and soft credits
    *******************************************************************************/
    public List<ucinn_ascendv2__Hard_and_Soft_Credit__c> createHardAndSoftCredit(Integer ctr, ucinn_ascendv2__Review_Transaction__c oneRT, ucinn_ascendv2__Payment__c paymentReference, Id sessionId, Opportunity opportunityReference, ucinn_ascendv2__Designation_Detail__c designationDetailReference, String source){

        List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListOfHSCs = new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>();

        ucinn_ascendv2__Hard_and_Soft_Credit__c oneHardHSC = new ucinn_ascendv2__Hard_and_Soft_Credit__c();

        if(paymentReference != null){
            oneHardHSC.ucinn_ascendv2__Payment__r = new ucinn_ascendv2__Payment__c(ucinn_ascendv2__External_System_ID__c = paymentReference.ucinn_ascendv2__External_System_ID__c);
        }
        oneHardHSC.ucinn_ascendv2__Session__c =  sessionId;
        if(opportunityReference.get('Id') != null){
            oneHardHSC.ucinn_ascendv2__Opportunity__c = opportunityReference.Id;
        }
        else{
            oneHardHSC.ucinn_ascendv2__Opportunity__r = new Opportunity(ucinn_ascendv2__External_System_ID__c = opportunityReference.ucinn_ascendv2__External_System_ID__c);
        }
        if(designationDetailReference != null){
            if(designationDetailReference.get('Id') != null){
                oneHardHSC.ucinn_ascendv2__Designation_Detail__c = designationDetailReference.Id;
            }
            else{
                oneHardHSC.ucinn_ascendv2__Designation_Detail__r = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = designationDetailReference.ucinn_ascendv2__External_System_ID__c);
            }

            //oneHardHSC.ucinn_ascendv2__Designation__c = designationDetailReference.ucinn_ascendv2__Designation__c;
            if(ctr == 1){
                oneHardHSC.ucinn_ascendv2__Designation__c = oneRT.ucinn_ascendv2__Designation_1__c;
            }
            else{
                oneHardHSC.ucinn_ascendv2__Designation__c = (id)oneRT.get('ucinn_ascendv2__Designation_'+ctr+'__c');
            }
        }
        //oneHardHSC.ownerId = UserInfo.getUserId();
        oneHardHSC.ucinn_ascendv2__Credit_Type__c = 'Hard';

        //if(oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge'){
            //oneHardHSC.ucinn_ascendv2__Credit_Amount__c = (Decimal) oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
        //}
        //else{
            if(ctr == 1){
            oneHardHSC.ucinn_ascendv2__Credit_Amount__c = (Decimal) oneRT.ucinn_ascendv2__Amount_1__c;
            }
            else{
                oneHardHSC.ucinn_ascendv2__Credit_Amount__c = (Decimal) oneRT.get('ucinn_ascendv2__Amount_'+ctr+'__c');
            }
        //}
        

        oneHardHSC.ucinn_ascendv2__Source__c = source;
        oneHardHSC.ucinn_ascendv2__Credit_ID__c = String.valueOf(oneRT.ucinn_ascendv2__Contact__c);

        //Assign the Constituent or Organization
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            oneHardHSC.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
            oneHardHSC.ucinn_ascendv2__Hard_Credit_Recipient_Contact__c = oneRT.ucinn_ascendv2__Contact__c;
        }
        else{
            oneHardHSC.ucinn_ascendv2__Account__c = oneRT.ucinn_ascendv2__Account__c;
            oneHardHSC.ucinn_ascendv2__Hard_Credit_Recipient_Account__c = oneRT.ucinn_ascendv2__Account__c;
        }

        // ---Mark Edit 10/6/2017
        if (oneRT.ucinn_ascendv2__Soft_Credit_Contact__c != null) {
            ucinn_ascendv2__Hard_and_Soft_Credit__c newSoftCredit = oneHardHSC.clone();
            newSoftCredit.ucinn_ascendv2__Account__c = null;
            newSoftCredit.ucinn_ascendv2__Credit_Type__c = 'Soft';
            newSoftCredit.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Soft_Credit_Contact__c;
            newSoftCredit.ucinn_ascendv2__Credit_ID__c = oneRT.ucinn_ascendv2__Soft_Credit_Contact__c;

            newSoftCredit.ucinn_ascendv2__External_System_ID__c = 'HS-' + String.valueOf(oneRT.ucinn_ascendv2__File_Creation_Date__c) + '-' + oneHardHSC.ucinn_ascendv2__Designation__c + '-'+ oneRT.ucinn_ascendv2__External_System_ID__c + '-S-1'; 

            tempListOfHSCs.add(newSoftCredit);
        }
        
        //Add External System ID 
        oneHardHSC.ucinn_ascendv2__External_System_ID__c = 'HS-' + String.valueOf(oneRT.ucinn_ascendv2__File_Creation_Date__c) + '-' +oneHardHSC.ucinn_ascendv2__Designation__c + '-'+ oneRT.ucinn_ascendv2__External_System_ID__c + '-H'; 

        tempListOfHSCs.add(oneHardHSC);

        return tempListOfHSCs;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates Installments for each designation detail
    *******************************************************************************/
    public ucinn_ascendv2__Installment__c createInstallment(ucinn_ascendv2__Review_Transaction__c oneRT, Date paymentDate, Integer Times,Integer designationDetailCtr, ucinn_ascendv2__Designation_Detail__c oneDD, Integer installmentCounter){
        
        ///////////////////////////////
        //Create Installment for each Designation Detail
        ucinn_ascendv2__Installment__c oneInstallment = new ucinn_ascendv2__Installment__c();
        
        List<ucinn_ascendv2__Installment__c> installmentList = installmentMap.get(oneRT.ucinn_ascendv2__External_System_ID__c);
        installmentList.add(oneInstallment);
        
        oneInstallment.ucinn_ascendv2__Opportunity__r = mapOfOpportunities.get(oneRT.ucinn_ascendv2__External_System_ID__c);
        oneInstallment.ucinn_ascendv2__Expected_Date__c = paymentDate;
        oneInstallment.ucinn_ascendv2__Amount__c = ((Decimal) oneRT.get('ucinn_ascendv2__Amount_'+designationDetailCtr+'__c')) / Times;
        oneInstallment.ucinn_ascendv2__Designation_Detail__r = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneDD.ucinn_ascendv2__External_System_ID__c);
        oneInstallment.ucinn_ascendv2__Designation__c = (Id) oneRT.get('ucinn_ascendv2__Designation_'+designationDetailCtr+'__c');
        if(designationDetailCtr == 1){
            oneInstallment.ucinn_ascendv2__G_L_Account__c = oneRT.ucinn_ascendv2__Designation_1_Name__c;
        }
        else{
            oneInstallment.ucinn_ascendv2__G_L_Account__c = String.valueOf(oneRT.get('ucinn_ascendv2__Designation_'+designationDetailCtr+'__c'));
        }
        
        //oneInstallment.ucinn_ascendv2__External_System_ID__c = 'INST-' + String.valueOf(rt.ucinn_ascendv2__File_Creation_Date__c) + '-' + oneRT.ucinn_ascendv2__External_System_ID__c + '-' + String.valueOf(installmentCounter);
        return oneInstallment;

    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates Installments based on the number of payments
    *******************************************************************************/
    public List<ucinn_ascendv2__Installment__c> createInstallments(ucinn_ascendv2__Review_Transaction__c oneRT, Integer designationDetailCtr, ucinn_ascendv2__Designation_Detail__c oneDD){
        
        //Create list of installments depending on the number of payments
        List<ucinn_ascendv2__Installment__c> listOfInstallments = new List<ucinn_ascendv2__Installment__c>();

        Date startDate = oneRT.ucinn_ascendv2__First_Payment_Date__c;
        Date lastdate = startDate;
        Integer Times = Integer.valueOf(oneDD.ucinn_ascendv2__Number_Of_Payments__c);

        String Frequency = oneRT.ucinn_ascendv2__Payment_Frequency__c;
        Integer interval;
        
        installmentMap.put(oneRT.ucinn_ascendv2__External_System_ID__c, new List<ucinn_ascendv2__Installment__c>());


        //Frequency For Installment per Drew's Code
        if (Frequency == 'Annual') {interval = 12;}
        if (Frequency == 'Irregular') {interval = 12;}
        if (Frequency == 'Semi-Annual') {interval = 6;}
        if (Frequency == 'Quarterly') {interval = 3;}
        if (Frequency == 'Monthly') {interval = 1;}
        if (Frequency == 'Bi-Weekly') {interval = 14;}


        for (Integer i = 0; i < Times; i++) {

            listOfInstallments.add(createInstallment(oneRT, lastdate, Times, designationDetailCtr, oneDD, i));

            if (Frequency == 'Bi-Weekly') {
                lastdate = lastdate.addDays(interval);
              } else {
                lastdate = lastdate.addMonths(interval);
              }

        }
        
        return listOfInstallments;

    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Creates Payment records
    *******************************************************************************/
    public ucinn_ascendv2__Payment__c createPayment(Integer ctr, ucinn_ascendv2__Designation_Detail__c designationDetailReference, ucinn_ascendv2__Designation__c designationReference, Campaign campaignReference, ucinn_ascendv2__Review_Transaction__c oneRT, Id sessionId, String sessionName, String runDate, Opportunity opportunityReference, String paymentTransactionType){
        
        ucinn_ascendv2__Payment__c onePayment = new ucinn_ascendv2__Payment__c();
        onePayment.ucinn_ascendv2__Session__c = sessionId;
        if(designationDetailReference.get('Id') != null){
            onePayment.ucinn_ascendv2__Designation_Detail__c = designationDetailReference.Id;
        }
        else{
            onePayment.ucinn_ascendv2__Designation_Detail__r = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = designationDetailReference.ucinn_ascendv2__External_System_ID__c);
        }

        onePayment.ucinn_ascendv2__External_System_ID__c = 'T-' + String.valueOf(oneRT.ucinn_ascendv2__File_Creation_Date__c) + '-' + oneRT.ucinn_ascendv2__External_System_ID__c + '-' + String.valueOf(ctr);
        onePayment.ucinn_ascendv2__Designation__r = designationReference;
        onePayment.ucinn_ascendv2__Campaign__r = campaignReference;
        onePayment.ucinn_ascendv2__G_L_Account__c = oneRT.ucinn_ascendv2__Designation_1_Name__c;
       
        if(opportunityReference.get('Id') != null){
            onePayment.ucinn_ascendv2__Opportunity__c = opportunityReference.Id;
        }
        else{
            onePayment.ucinn_ascendv2__Opportunity__r = opportunityReference;
        }

        if(oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'BOFA'){
            onePayment.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c; // Stela 1229 update this for Jan. Need to change it back after Jan.
            onePayment.ucinn_ascendv2__Check_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
        }
        else{
            onePayment.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
            onePayment.ucinn_ascendv2__Check_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
        }

        if (oneRT.ucinn_ascendv2__Tender_Type__c != 'Cheque') {
            onePayment.ucinn_ascendv2__Check_Date__c = null;
        }

        onePayment.ucinn_ascendv2__Transaction_Type__c = paymentTransactionType;
        
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
        	onePayment.ucinn_ascendv2__Transaction_Type__c = 'Recurring Gift Payment';
        }
        
        //onePayment.Payment_Group_ID__c = sessionName + runDate;
        //onePayment.Payment_Group_ID__c = asc_UTIL_Helper.createPaymentGroupID(sessionName, opportunityReference.Id);


        //10202016 - If Ruffalo Cody Transaction (Non Pledge), No to Tax Receipt
        if(mapOfRTSettings.containsKey('Pledge_Payment_Is_Tax_Receipt')){
            onePayment.ucinn_ascendv2__Is_Tax_Receipt__c = mapOfRTSettings.get('Pledge_Payment_Is_Tax_Receipt').Boolean_Value__c;
        }
        else{
            onePayment.ucinn_ascendv2__Is_Tax_Receipt__c = true;
        }


        if(ctr == 1){
            onePayment.ucinn_ascendv2__Payment_Amount__c = (Decimal) oneRT.ucinn_ascendv2__Amount_1__c;
        }
        else{
            onePayment.ucinn_ascendv2__Payment_Amount__c = (Decimal) oneRT.get('ucinn_ascendv2__Amount_'+ctr+'__c');
        }

        //onePayment.Payment_Amount__c = oneRT.Amount_1__c;
        onePayment.ucinn_ascendv2__Check_Number__c = oneRT.ucinn_ascendv2__MICR_Check_Number__c;
        onePayment.ucinn_ascendv2__Status__c = 'Paid';
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment' || paymentTransactionType != 'Pledge Payment') {
            
            if(oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'ATHL' || oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'CYBS'){
                onePayment.ucinn_ascendv2__Tender_Type_for_Gifts__c = oneRT.ucinn_ascendv2__CC_Type__c;
            }
            else{
                onePayment.ucinn_ascendv2__Tender_Type_for_Gifts__c = oneRT.ucinn_ascendv2__Tender_Type__c;
            }
            
            if (onePayment.ucinn_ascendv2__Tender_Type_for_Gifts__c == 'Credit Card') {                
                onePayment.ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Credit/Debit Card - Other';
            }
        } else {
            onePayment.ucinn_ascendv2__Tender_Type_for_Pledges__c = oneRT.ucinn_ascendv2__Tender_Type__c;   // Stela updated 10/10/2019
        }
        
        onePayment.ucinn_ascendv2__Send_to_G_L__c = true; 
        onePayment.ucinn_ascendv2__Gift_Processor__c = UserInfo.getUserId();
        onePayment.ucinn_ascendv2__Transaction_ID__c = oneRT.ucinn_ascendv2__Transaction_ID__c;
        onePayment.ucinn_ascendv2__Has_Correspondence__c = oneRT.ucinn_ascendv2__Is_Handwriting_Present__c;
        onePayment.ucinn_ascendv2__Has_Handwriting_Present__c = oneRT.ucinn_ascendv2__Is_Handwriting_Present__c;
        onePayment.ucinn_ascendv2__Is_Payment_Matching__c = oneRT.ucinn_ascendv2__Is_Payment_Match__c;
        onePayment.ucinn_ascendv2__File_Creation_Date__c = oneRT.ucinn_ascendv2__File_Creation_Date__c;
        onePayment.ucinn_ascendv2__Non_Gift_Amount__c = 0;

        //Assign the Constituent or Organization
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            onePayment.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
        }
        else{
            onePayment.ucinn_ascendv2__Account__c = oneRT.ucinn_ascendv2__Account__c;
        }

        //New Fields for Monash only
        onePayment.ucinn_ascendv2__Bank_Reference_Number__c = oneRT.ucinn_ascendv2__Sequence_Number__c;
        onePayment.ucinn_ascendv2__Is_Anonymous__c = oneRT.Is_Anonymous__c;
        onePayment.ucinn_ascendv2__Authorization_Code__c = oneRT.ucinn_ascendv2__Authorization_Code__c;
        // Move from oppo to payment.
        onePayment.ucinn_ascendv2__Notes__c = oneRT.Gift_Comments__c;
        return onePayment;
    }
    public void createPledge(ucinn_ascendv2__Review_Transaction__c oneRT){

        //Gets the Session ID
        Id sessionId;
        String sessionName;

        //Create the Pledge
        Opportunity oneOpp;

        //References
        Opportunity opportunityReference = new Opportunity(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c);
        ucinn_ascendv2__Designation_Detail__c desigD1Reference, desigD2Reference, desigD3Reference, desigD4Reference, desigD5Reference;
        
        if(defaultSession!=null){
            sessionId = defaultSession.Id;
            sessionName = defaultSession.Name;
        }
        else{
            sessionId = oneRT.ucinn_ascendv2__Session__c;
            sessionName = oneRT.ucinn_ascendv2__Session_Name_Formula__c;
        }

        //Populate the Opportunity
        oneOpp = new Opportunity();
        oneOpp.Name = oneRT.ucinn_ascendv2__External_System_ID__c;
        oneOpp.External_Pledge_No__c = oneRT.Pledge_No__c;
        oneOpp.ucinn_ascendv2__Session__c = sessionId;
        oneOpp.CampaignId = oneRT.ucinn_ascendv2__Appeal_Code__c;
        //oneOpp.Type = 'Annual';
        oneOpp.Type = oneRT.ucinn_ascendv2__Pledge_Type__c; // Stela updated 10/10/2019
        oneOpp.StageName = 'Active';
        oneOpp.ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c;
        oneOpp.ownerId = UserInfo.getUserId();
        oneOpp.CloseDate = oneRT.ucinn_ascendv2__Transaction_Date__c;
        oneOpp.Amount = oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
        // Pratibha: As part of record type change, Funded_Amount__c = Amount.
        //oneOpp.Funded_Amount__c = oneRT.Amount_1__c;
        oneOpp.ucinn_ascendv2__Send_Pledge_Reminder__c = oneRT.ucinn_ascendv2__Is_Pledge_Reminder__c;
        // Pratibha: Record type change. Pledge_End_Date__c = CloseDate
        oneOpp.ucinn_ascendv2__Funded_Date__c = oneRT.ucinn_ascendv2__Pledge_End_Date__c;
        oneOpp.ucinn_ascendv2__Credit_Date__c = oneRT.ucinn_ascendv2__Transaction_Date__c;
        oneOpp.RecordTypeId = oppRecordTypeId;
        oneOpp.ucinn_ascendv2__Review_Transaction__c = oneRT.Id;
        oneOpp.ucinn_ascendv2__Frequency__c =  oneRT.ucinn_ascendv2__Payment_Frequency__c;
        //Assign the Constituent or Organization
        if(oneRT.ucinn_ascendv2__Contact__c != null){
            oneOpp.ucinn_ascendv2__Contact__c = oneRT.ucinn_ascendv2__Contact__c;
            oneOpp.PrimaryContact__c = oneRT.ucinn_ascendv2__Contact__c;
        }
        else{
            oneOpp.AccountId = oneRT.ucinn_ascendv2__Account__c;
        }
        
        mapOfOpportunities.put(oneOpp.ucinn_ascendv2__External_System_ID__c, oneOpp);
        
        ///////////////////////////////
        //Create Designation Detail

        Integer designationDetailCtr = 1 ;

        if(oneRT.ucinn_ascendv2__Amount_1__c != null && oneRT.ucinn_ascendv2__Designation_1_Name__c != null){

            desigD1Reference = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c + String.valueOf(designationDetailCtr));
            ucinn_ascendv2__Designation__c designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_1_Name__c);
            ucinn_ascendv2__Designation_Detail__c oneDD = createDesignationDetail(oneRT, designationDetailCtr, sessionId, opportunityReference, designationReference );
            
            listOfDesignationDetails.add(oneDD);

            //TODO : Create the installment depending on the number of payments
            for(ucinn_ascendv2__Installment__c oneInstallment : createInstallments(oneRT,designationDetailCtr,oneDD)){
                listOfInstallments.add(oneInstallment);
            }

            designationDetailCtr++;

            // --- Mark Edit 10/6/2017
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(1, oneRT, null, sessionId, opportunityReference, oneDD, 'Pledge');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            
        }
        if(oneRT.ucinn_ascendv2__Amount_2__c != null && oneRT.ucinn_ascendv2__Designation_2_Name__c != null){
            desigD2Reference = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c + String.valueOf(designationDetailCtr));
            ucinn_ascendv2__Designation__c designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_2_Name__c);

            ucinn_ascendv2__Designation_Detail__c oneDD = createDesignationDetail(oneRT, designationDetailCtr, sessionId, opportunityReference, designationReference );

            listOfDesignationDetails.add(oneDD);

            for(ucinn_ascendv2__Installment__c oneInstallment : createInstallments(oneRT,designationDetailCtr,oneDD)){
                listOfInstallments.add(oneInstallment);
            }

            //listOfInstallments.add(createInstallment(oneRT,designationDetailCtr,desigD2Reference));

            designationDetailCtr++;

            // --- Mark Edit 10/6/2017
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(2, oneRT, null, sessionId, opportunityReference, oneDD, 'Pledge');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            //
        }
        if(oneRT.ucinn_ascendv2__Amount_3__c != null && oneRT.ucinn_ascendv2__Designation_3_Name__c != null){

            desigD3Reference = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c + String.valueOf(designationDetailCtr));
            ucinn_ascendv2__Designation__c designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_3_Name__c);

            ucinn_ascendv2__Designation_Detail__c oneDD = createDesignationDetail(oneRT, designationDetailCtr, sessionId, opportunityReference, designationReference );

            listOfDesignationDetails.add(oneDD);

            for(ucinn_ascendv2__Installment__c oneInstallment : createInstallments(oneRT,designationDetailCtr,oneDD)){
                listOfInstallments.add(oneInstallment);
            }

            //listOfInstallments.add(createInstallment(oneRT,designationDetailCtr,desigD3Reference));
            designationDetailCtr++;

            // --- Mark Edit 10/6/2017
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(3, oneRT, null, sessionId, opportunityReference, oneDD, 'Pledge');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            //
        }
        if(oneRT.ucinn_ascendv2__Amount_4__c != null && oneRT.ucinn_ascendv2__Designation_4_Name__c != null){

            desigD4Reference = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c + String.valueOf(designationDetailCtr));
            ucinn_ascendv2__Designation__c designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_4_Name__c);

            ucinn_ascendv2__Designation_Detail__c oneDD = createDesignationDetail(oneRT, designationDetailCtr, sessionId, opportunityReference, designationReference );

            listOfDesignationDetails.add(oneDD);

            for(ucinn_ascendv2__Installment__c oneInstallment : createInstallments(oneRT,designationDetailCtr,oneDD)){
                listOfInstallments.add(oneInstallment);
            }

            //listOfInstallments.add(createInstallment(oneRT,designationDetailCtr,desigD4Reference));
            designationDetailCtr++;

            // --- Mark Edit 10/6/2017
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(4, oneRT, null, sessionId, opportunityReference, oneDD, 'Pledge');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            //
        }
        if(oneRT.ucinn_ascendv2__Amount_5__c != null && oneRT.ucinn_ascendv2__Designation_5_Name__c != null){

            desigD5Reference = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__External_System_ID__c + String.valueOf(designationDetailCtr));
            ucinn_ascendv2__Designation__c designationReference = new ucinn_ascendv2__Designation__c(ucinn_ascendv2__External_System_ID__c = oneRT.ucinn_ascendv2__Designation_5_Name__c);

            ucinn_ascendv2__Designation_Detail__c oneDD = createDesignationDetail(oneRT, designationDetailCtr, sessionId, opportunityReference, designationReference );

            listOfDesignationDetails.add(oneDD);

            for(ucinn_ascendv2__Installment__c oneInstallment : createInstallments(oneRT,designationDetailCtr,oneDD)){
                listOfInstallments.add(oneInstallment);
            }

            //listOfInstallments.add(createInstallment(oneRT,designationDetailCtr,desigD5Reference));
            designationDetailCtr++;

            // --- Mark Edit 10/6/2017
            List<ucinn_ascendv2__Hard_and_Soft_Credit__c> tempListHSC = createHardAndSoftCredit(5, oneRT, null, sessionId, opportunityReference, oneDD, 'Pledge');
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c oneHSC : tempListHSC ){
                listOfHandSCredits.add(oneHSC);
            }
            //
        }


    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Generate unique ID.
    *******************************************************************************/
    public static String generateGUID(){

        String returnValue = '';
        String kHexChars = '0123456789abcdefABCDEF';
        Integer nextByte = 0;

        for (Integer i = 0; i < 16; i++) {
            nextByte = (Math.round(Math.random() * 255) - 128) & 255;

            if(i==6){
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);

             }
             if(i==8){
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
             }
             returnValue += charAt(kHexChars, nextByte >> 4);
             returnValue += charAt(kHexChars, nextByte & 15);
        }
        return returnValue;
    }

     /**
    * Get character in an index of a string.
    *
    * @param: str       String to be processed
    * @param: index     The index at which a character from the String str is accessed.
    * @return:          The character from the String str at position specified by the index
    */
    private static String charAt(String str, Integer index){
        if(str == null){
            return null;
        }
        if(str.length() <= 0){
            return str;
        }
        if(index == str.length()){
            return null;
        }
        return str.substring(index, index+1);
    }
    
    /**
    * Add Manual Review Reason
    *
    * @param: oneRT             Review Transaction record
    * @param: reason            Reason message
    */
    public static void addManualReviewReason(ucinn_ascendv2__Review_Transaction__c oneRT, String reason) {
        if (mapOfManualReviewReasons ==  null) {
            mapOfManualReviewReasons = new Map<String, List<String>>();
        }
        
        if (!mapOfManualReviewReasons.containsKey(oneRT.ucinn_ascendv2__External_System_ID__c)) {
            mapOfManualReviewReasons.put(oneRT.ucinn_ascendv2__External_System_ID__c, new List<String>());
        }
        if (!mapOfManualReviewReasons.get(oneRT.ucinn_ascendv2__External_System_ID__c).contains(reason)) {
            mapOfManualReviewReasons.get(oneRT.ucinn_ascendv2__External_System_ID__c).add(reason);
        }
    }
    
    /**
    * Check to see if there is a matching Pledge, returns matching Opportunity record if found.
    *
    * @param: oneRT             Review Transaction record
    * @return: Opportunity      Returns the matching Pledge opportunity record
    */
    public Opportunity getPledge(ucinn_ascendv2__Review_Transaction__c oneRT) {
        Opportunity oneOpp;
        Id donor;
        if (oneRT.ucinn_ascendv2__Contact__c != null) {
            donor = oneRT.ucinn_ascendv2__Contact__c;
        } else {                                                                           //Assumption - Account is populated if Contact is not.
            donor = oneRT.ucinn_ascendv2__Account__c;
        }
        
        if (oneRT.Pledge_No__c != null) {
            if (mapOfPledgesByExternalID.containsKey(oneRT.Pledge_No__c)) {
                oneOpp = mapOfPledgesByExternalID.get(oneRT.Pledge_No__c);
                                
                if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge Payment') {       //If Pledge Payment, check for designations and appeal
                    List<String> listOfRTDesignations = new List<String>();
                    Map<String, ucinn_ascendv2__Designation_Detail__c> tempMapOfPledgeDDs = new Map<String, ucinn_ascendv2__Designation_Detail__c>();
                    Set<String> tempPledgeDesignationIDs = new Set<String>();
                    Set<String> tempRTDesignationIDs = new Set<String>();
                    Boolean isAppealMatch = true;
                    Boolean isDesignationMatch = false;
                    Boolean isIgnoreDesignationEnabled = true;
                    
                    if (mapOfRTSettings.containsKey('Pledge_Payment_Ignore_Designation')) {
                        isIgnoreDesignationEnabled = mapOfRTSettings.get('Pledge_Payment_Ignore_Designation').Boolean_Value__c;
                    }
                    
                    //[20191029 SC]: Ignore if Designations not supplied
                    if (oneRT.ucinn_ascendv2__Designation_1_Name__c == null
                            && oneRT.ucinn_ascendv2__Designation_2_Name__c == null
                            && oneRT.ucinn_ascendv2__Designation_3_Name__c == null
                            && oneRT.ucinn_ascendv2__Designation_4_Name__c == null
                            && oneRT.ucinn_ascendv2__Designation_5_Name__c == null) {
                        isIgnoreDesignationEnabled = true;
                    }
                    
                    for(ucinn_ascendv2__Designation_Detail__c oneDD : oneOpp.ucinn_ascendv2__Designation_Details_Opportunity__r){
                        tempMapOfPledgeDDs.put(oneDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c, oneDD);
                        tempPledgeDesignationIDs.add(oneDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c);
                    }
                    
                    if (oneRT.ucinn_ascendv2__Designation_1_Name__c != null) {
                        listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_1_Name__c);
                    }
                    if (oneRT.ucinn_ascendv2__Designation_2_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c) {
                        listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_2_Name__c);
                    }
                    if (oneRT.ucinn_ascendv2__Designation_3_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c) {
                        listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_3_Name__c);
                    }
                    if (oneRT.ucinn_ascendv2__Designation_4_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c) {
                        listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_4_Name__c);
                    }
                    if (oneRT.ucinn_ascendv2__Designation_5_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c) {
                        listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_5_Name__c);
                    }
                    
                    tempRTDesignationIDs.addAll(listOfRTDesignations);
                    
                    //Are Pledge's Designations matched RT Designations?
                    for (String eachPledgeDDId: tempPledgeDesignationIDs) {
                        if (tempRTDesignationIDs.contains(eachPledgeDDId)) {
                            isDesignationMatch = true;
                            break;
                        }
                    }

                    /*
                    if(tempPledgeDesignationIDs == tempRTDesignationIDs){
                        isDesignationMatch = true;
                    }
                    */
                    
                    //Is Pledge's Designations' Appeals matched RT Appeal?
                    //Don't need to check if Appeal is not supplied
                    if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c != null) {
                        for(String oneDesignation : listOfRTDesignations){
                            if(tempMapOfPledgeDDs.containsKey(oneDesignation)){
                                ucinn_ascendv2__Designation_Detail__c oneDD = tempMapOfPledgeDDs.get(oneDesignation);
                                if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c != oneDD.ucinn_ascendv2__Campaign__r.ucinn_ascendv2__Motivation_Code__c) {
                                    isAppealMatch = false;
                                }
                            }
                        }
                    }
                    
                    if (!isDesignationMatch && !isIgnoreDesignationEnabled) {
                        addManualReviewReason(oneRT, 'Payment Designation does not match');
                    }
                    
                    if (!isAppealMatch && !isIgnoreDesignationEnabled) {
                        addManualReviewReason(oneRT, 'Payment Appeal does not match');
                    }
                }
            }
        } else if (mapOfActivePledges.containsKey(donor)){                                      //Pledge No. is not provided
            List<Opportunity> listOfActivePledges = mapOfActivePledges.get(donor);
            
            //Loop through all the Opportunities for this donor
            for(Opportunity opp : listOfActivePledges){
                List<String> listOfRTDesignations = new List<String>();
                Map<String, ucinn_ascendv2__Designation_Detail__c> tempMapOfPledgeDDs = new Map<String, ucinn_ascendv2__Designation_Detail__c>();
                Set<String> tempPledgeDesignationIDs = new Set<String>();
                Set<String> tempRTDesignationIDs = new Set<String>();
                Boolean isMatch = false;
                
                for(ucinn_ascendv2__Designation_Detail__c oneDD : opp.ucinn_ascendv2__Designation_Details_Opportunity__r){
                    tempMapOfPledgeDDs.put(oneDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c, oneDD);
                    tempPledgeDesignationIDs.add(oneDD.ucinn_ascendv2__Designation__r.ucinn_ascendv2__External_System_ID__c);
                }
                
                if(oneRT.ucinn_ascendv2__Designation_1_Name__c != null){
                    listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_1_Name__c);
                }
                if(oneRT.ucinn_ascendv2__Designation_2_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c){
                    listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_2_Name__c);
                }
                if(oneRT.ucinn_ascendv2__Designation_3_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c){
                    listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_3_Name__c);
                }
                if(oneRT.ucinn_ascendv2__Designation_4_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c){
                    listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_4_Name__c);
                }
                if(oneRT.ucinn_ascendv2__Designation_5_Name__c != null && oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c){
                    listOfRTDesignations.add(oneRT.ucinn_ascendv2__Designation_5_Name__c);
                }
                
                tempRTDesignationIDs.addAll(listOfRTDesignations);
                
                //Check if Designation from Opportunity Matches Designation from Review Transaction : Assumption - Designations are unique
                if(tempPledgeDesignationIDs == tempRTDesignationIDs){
                    isMatch = true;
                }
                else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
                	addManualReviewReason(oneRT, 'Recurring payment designation does not match with recurring gift');
                    return null;
                }
                
                if((isMatch && !listOfRTDesignations.isEmpty()) || oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
                    // No need to check for external ID, should not go in here if it has external ID
                    if (oneRT.ucinn_ascendv2__Opportunity__c != null && oneRT.ucinn_ascendv2__Opportunity__c == opp.Id) {
                        return opp;
                    } else {
                        oneOpp = opp;
                    }
                }
            }
        }
        
        return oneOpp;
    }
}