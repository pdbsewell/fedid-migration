/**
 * @author      Shalini Mendu
 * @description Class for generating GCO auto offers
 * @revision    02/11/2024 - Created
 */
global class  GCOAutoGenerateOffer {
    // Initialize  values
    @TestVisible private static   OpportunitiesSelector opptySelector;
    @TestVisible private static   Dao myDao;
    @TestVisible private static  Application_Course_Preference__c acp;
    @TestVisible private static  Opportunity  opp;
    @TestVisible private static  Contact contact;
    private static String WET_SIGNATURE_TYPE = 'Wet Signature';
    private static String CONGA_TEMPLATE_TYPE = 'International Coursework Australia';
    private static String COND_OFFER_TYPE = 'COND-OFFER';
    // static initializer
    static {
    
        opptySelector = new OpportunitiesSelector();
        myDao = new SObjectDao();
    }

   /**
     * @author      Shalini Mendu
     * @description Invocable method to be called from a flow tht triggers GCO offer generation
     * @param       String acpIds
     */    
    @InvocableMethod(label='Auto generate offer' description='Auto generate GCO offer' category='ACP')
    public static void sendApplication(List<String> acpIds) 
    {
        SavePoint savePointDML = Database.setSavepoint();
        try{
            String acpId = acpIds.get(0);
            Application_Course_Preference__c acp = [select id,Course_Product_Id__c,name,Application__r.Agent__c,Application__r.Id,Application__c, Applicant__c,Course_Start_Date_Updated__c,Course_Code__c,Credit_Adjusted_Course_Duration_Type__c,Course_Offering__c,Offer_Response_Date__c,Revised_End_Date__c,Agreed_Start_Date__c, Course_Title__c, Outcome_Status_LOV__r.System_Code__c from Application_Course_Preference__c where Id= :acpId];
            execute(acp);
        }catch(Exception ex){
            Nebula.logger.exception('Failed generating GCO offer for ACP:'+ acp.Name+ ex.getMessage(), ex);
            Nebula.logger.error(ex.getMessage(), acp.Name);
            throw ex;
        }finally{
          Nebula.logger.saveLog();
        }   
    }
       
   /**
     * @author      Shalini Mendu
     * @description execute method to help generate GCO offer
     * @param       Application_Course_Preference__c acp
     */
    public static void execute(Application_Course_Preference__c acp)
    {
        contact c = [select id,First_Name__c,Last_Name__c,AccountId from contact where id=:acp.Applicant__c];
        Course_Offering__c co = [select id,Override_Duration__c,Course_Duration__c from Course_Offering__c where id=:acp.Course_Offering__c];
        contact = c;
        //create opportunity
        OfferWizardWrapper wrapper  = setOfferWrapper(contact, acp);

        myDao.upsertRecords(new Opportunity[]{wrapper.opptyRecord});

        //set init acp & course offering into wrapper
        wrapper.selectedACPList = new Application_Course_Preference__c[]{acp};
        wrapper.courseOfferingByAcpId = new Map<String,Course_Offering__c>{acp.Id =>co};


        //create opportunity line item for destination acp    
        myDao.insertRecords(new OpportunityLineItemService.OppLineItemCreator(wrapper).execute());
       
        Opportunity[] opps = opptySelector.selectByIdWithOpportunityLines(new Set<ID>{wrapper.opptyRecord.Id});
        generateQuote( opps);
        TriggerCommon.disableTrigger('Opportunity');
        myDao.updateRecords(opps); 
        TriggerCommon.enableTrigger('Opportunity');
    }


     /**
     * @author      Shalini Mendu
     * @description Construct OfferWizardWrapper 
     * @param       Contact ,Application_Course_Preference__c acp
     * @return   offer wrapper
     */
    @TestVisible private static OfferWizardWrapper setOfferWrapper(Contact student, Application_Course_Preference__c acp)
    {
            
        Opportunity oppRecord = new Opportunity();
        //Get org defaults of Offer Setting cs
        Offer_Setting__c offerSetting = Offer_Setting__c.getOrgDefaults();
        //Retrieve GCO Template from Offer Setting cs
        Id templateId = offerSetting.GCO_Template_Id__c;
        //Return if the fields are null
        if (acp.Agreed_Start_Date__c == null || acp.Revised_End_Date__c == null) {
            throw new IllegalArgumentException('ACP Start & End Dates cannot be blank.');
        }
        
        //Populate OfferWizardWrapper with appropriate values
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.updatedACPs = new Map<Id, Application_Course_Preference__c>([select id,Credit_Adjusted_Course_Duration__c,Agreed_Start_Date__c,Revised_End_Date__c,Credit_Adjusted_Course_Duration_Type__c from Application_Course_Preference__c where id=:acp.Id]);
        wrapper.opptyRecord = OpportunityService.createInternationalOfferOpp(student,acp);
        wrapper.opptyRecord.Bulk_Gen__c = false;
        wrapper.opptyRecord.Signature_Type__c = WET_SIGNATURE_TYPE;
        wrapper.opptyRecord.Offer_Template__c = templateId;
        wrapper.opptyRecord.Destination_ACP__c = acp.Id;
        wrapper.opptyRecord.Destination_Course_Name__c = acp.Course_Title__c;
        wrapper.opptyRecord.Offer_Type__c = COND_OFFER_TYPE;
        wrapper.opptyRecord.Template_Type__c = CONGA_TEMPLATE_TYPE;
        wrapper.opptyRecord.currencyISOCode = Constants.AUD_CURRENCY;
        OpportunityService.OverrideDates visaDates = OpportunityService.calculateOfferVisaDates(acp.Agreed_Start_Date__c,acp.Revised_End_Date__c);
        wrapper.opptyRecord.Visa_Start_Date__c = visaDates.startDate;
        wrapper.opptyRecord.Visa_End_Date__c = visaDates.endDate;
        wrapper.opptyRecord.CloseDate = acp.Offer_Response_Date__c;
        return wrapper;
    }

     /**
     * @author      Shalini Mendu
     * @description Assign the appropriate fields to trigger GCO offer generation 
     * @param       Opportunity[] opps
     */
    @TestVisible private static void generateQuote(Opportunity[] opps){
        //start quote gen
        Boolean result = true;
        if (result){    //quote created successfully
             opps[0].stagename = 'Processing Offer';
             opps[0].NextStep = 'Generate Offer';
        }else{  //error
            //what should be the opportunity stage or next step ? How to report the error ? 
            opps[0].StageName = 'Specialist Review';
            opps[0].NextStep = 'Quote Generation Failed!';
        }
    }


             
}