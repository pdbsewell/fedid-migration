/*******************************************************************************
* @author:      Shalini Mendu
* @date:        24.June.2020
* @description: ASNF-3-Controller class for ASN form to retrieve and update the Student's choice
* @revision: 
*               pvic0002 - ASNF-58 Added Datetime to capture timezone
*               rcad0001 - EPCP-1103 Added Teaching Period sorting logic + code clean up
*******************************************************************************/
public without sharing class ASNController {

    private static List<ASN_Teaching_Periods__mdt> TEACHING_PERIOD_LIST {
        get{
            if(TEACHING_PERIOD_LIST == null){
                TEACHING_PERIOD_LIST = [SELECT Teaching_Period__c, Group_CI_Sequence_Numbers__c, Location__c FROM ASN_Teaching_Periods__mdt];
            }
            return TEACHING_PERIOD_LIST;
        }
        set;
    }

    private static Map<String, List<String>> TEACHING_PERIOD_MAP{
        get{
            if(TEACHING_PERIOD_MAP == null){
                TEACHING_PERIOD_MAP = new Map<String, List<String>>();

                // generate the teaching period and its ci sequence numbers map
                for(ASN_Teaching_Periods__mdt mdt: TEACHING_PERIOD_LIST) {
                    List<String> ciSequenceNumbers = String.valueOf(mdt.Group_CI_Sequence_Numbers__c).split(',');
                    if (!TEACHING_PERIOD_MAP.containsKey(mdt.Teaching_Period__c)) {

                        TEACHING_PERIOD_MAP.put(mdt.Teaching_Period__c, ciSequenceNumbers);
                    }
                    else{
                        TEACHING_PERIOD_MAP.get(mdt.Teaching_Period__c).addAll(ciSequenceNumbers);
                    }
                }
            }
            return TEACHING_PERIOD_MAP;
        }
        set;
    }

    private static List<String> COURSE_CODE_EXCLUDED{
        get{
            return String.valueOf(Label.ASN_Exclude_Course_Code).split(',');
        }
        set;
    }

    @TestVisible
    private static Boolean TIMESTAMP_SWITCH{
        get{
            if(TIMESTAMP_SWITCH == null){
                TIMESTAMP_SWITCH = Boolean.valueOf(Label.ASN_Timestamp_Switch);
            }
            return TIMESTAMP_SWITCH; 
        }
        set;
    }

    private static Map<String, String> TEACHING_PERIOD_LOCATION_MAP{
        get{
            if(TEACHING_PERIOD_LOCATION_MAP == null){
                TEACHING_PERIOD_LOCATION_MAP = new Map<String, String>();
                for(ASN_Teaching_Periods__mdt mdt: TEACHING_PERIOD_LIST) {
                    TEACHING_PERIOD_LOCATION_MAP.put(mdt.Teaching_Period__c, mdt.Location__c);
                }
            }

            return TEACHING_PERIOD_LOCATION_MAP;
        }
        set;
    }

    /*******************************************************************************
    * @description  Method returns a list of TeachingPeriod wrapper after
                    matching with the Unit Attempts against the ASN_Teaching_Periods__mdt
    * @Param  String  personId - To query UnitAttempt
    * @Return List<TeachingPeriod> - List of TeachingPeriod matching with the UnitAttempt
                                     CI Sequence number of the Student.
    ******************************************************************************/
    @AuraEnabled
    public static List<TeachingPeriod> retrieveStudentTeachingPeriods(String conId) {

        Map<String, TeachingPeriod> mapTP = new  Map<String, TeachingPeriod>();


        List<Unit_Attempt__c> unitAttempList = [SELECT Id, Course_Code__c, Person_ID__c, Updated_At__c, LastModifiedDate, Course_Attempt__r.Course__r.Sub_Level__c, Status__c, CI_Sequence_Number__c, Unit_Code__c, Unit_Mode__c, Mark__c,ASN_Response_Datetime__c, Achieved_Credit_Points__c,Title__c, ASN_Response__c, ASN_Response_Date__c, Grade__c, Teaching_Calendar__r.Description__c, Teaching_Calendar__r.Type__c, Course_Attempt__r.Location__c
        FROM Unit_Attempt__c
        WHERE Deleted_In_Source__c = false
        AND  COURSE_CODE__c NOT IN: COURSE_CODE_EXCLUDED
        AND Student__c =: conId
        AND Status__c != 'Duplicate'
        AND ASN_Exclude__c = false
        ORDER BY Teaching_Calendar__r.Year__c DESC, Teaching_Calendar__r.Description__c DESC];

        if(!unitAttempList.isEmpty()){
            for(Unit_Attempt__c ua: unitAttempList){
                Boolean isEligible = false;

                String teachingPeriodName = ua.Teaching_Calendar__r.Description__c;

                for(String mdt: TEACHING_PERIOD_MAP.keySet()) {
                    List<String> ciSequenceNumbers = TEACHING_PERIOD_MAP.get(mdt);

                    if (ciSequenceNumbers.contains(ua.CI_Sequence_Number__c)) {

                        // obtain the potential location where the ci sequence is specifically eligible
                        List<String> teachingPeriodLocations = new List<String>();

                        String locationString = TEACHING_PERIOD_LOCATION_MAP.containsKey(mdt) ? TEACHING_PERIOD_LOCATION_MAP.get(mdt) : '' ;
                        if(String.isNotBlank(locationString)){
                            for(String s: locationString.split(',')){
                                teachingPeriodLocations.add(s.toLowerCase().trim());
                            }
                        }

                        if((!teachingPeriodLocations.isEmpty() && ua.Course_Attempt__r.Location__c != null && teachingPeriodLocations.contains(String.valueOf(ua.Course_Attempt__r.Location__c).toLowerCase().trim())) // if a ci sequence number is eligible for specific location(s)
                            || teachingPeriodLocations.isEmpty() // OR, if a ci sequence number is eligible for any location
                            ){
                            isEligible = true;
                        }

                        if (ciSequenceNumbers.size() > 1) {
                            teachingPeriodName = mdt;
                        }
                    }
                }

                if(isEligible){
                    TeachingPeriod tp = new TeachingPeriod(teachingPeriodName);
                    tp.unitAttemptList = new List<TeachingPeriod.UnitAttempt>();

                    if(mapTP.containsKey(teachingPeriodName)) {
                        tp = mapTP.get(teachingPeriodName);
                    }

                    TeachingPeriod.UnitAttempt uaNew = new TeachingPeriod.UnitAttempt();
                    if(ua.Teaching_Calendar__r != null) {
                        tp.teachingPeriodType = ua.Teaching_Calendar__r.Type__c;
                    }

                    uaNew.convertToSFR = false;
                    uaNew.withDraw = false;
                    uaNew.cISequenceNumber = ua.CI_Sequence_Number__c;
                    uaNew.unitCode = ua.Unit_Code__c;
                    uaNew.unitAttemptId = ua.Id;
                    uaNew.acvdCreditPoints = ua.Achieved_Credit_Points__c == null ? 0 : Integer.valueOf(ua.Achieved_Credit_Points__c);
                    uaNew.UnitMode = ua.Unit_Mode__c;
                    uaNew.unitTitle = ua.Title__c;
                    uaNew.mark = Integer.valueOf(ua.Mark__c);
                    uaNew.grade = ua.Grade__c;
                    uaNew.status = String.valueOf(ua.Status__c).toLowerCase();
					uaNew.studentResponseDate = ua.ASN_Response_Date__c;
					uaNew.courseLevel = ua.Course_Attempt__r.Course__r.Sub_Level__c == null? '' : String.valueOf(ua.Course_Attempt__r.Course__r.Sub_Level__c).toLowerCase();
                    uaNew.lastUpdatedDate = TIMESTAMP_SWITCH ? ua.Updated_At__c : ua.LastModifiedDate;
                    uaNew.location = ua.Course_Attempt__r.Location__c == null ? '' : String.valueOf(ua.Course_Attempt__r.Location__c).toLowerCase();
                    uaNew.courseCode = ua.Course_Code__c == null ? '' : String.valueOf(ua.Course_Code__c).toLowerCase();

                    if(String.isNotBlank(ua.ASN_Response__c)) {
                        if(ua.ASN_Response__c == 'SFR') {
                            uaNew.convertToSFR = true;
                        } else if(ua.ASN_Response__c == 'WDN') {
                            uaNew.withDraw = true;
                        }
                    }

                    // calculate most recent updated unit attempte
                    if(tp.latestUpdatedUA != null){
                        if(uaNew.lastUpdatedDate > tp.latestUpdatedUA){
                            tp.latestUpdatedUA = uaNew.lastUpdatedDate;
                        }
                    }
                    else{
                        tp.latestUpdatedUA = uaNew.lastUpdatedDate;
                    }

                    //Use teaching Period public method
                    tp.validateTimeLimitRule(uaNew); 
                    tp.addUnitAttempt(uaNew);
                    mapTP.put(teachingPeriodName, tp);
                }
            }
        }

        return mapTP.values();
    }
    /*******************************************************************************
    * @description  Method to update the UnitAttempts for a student to mark the selection.
    * @Param  TeachingPeriod  tp - Wrapper class from the UI
    * @Return Boolean - True when it is successfully able to update the backend,
                       False on failure
    ******************************************************************************/
    @AuraEnabled
    public static Boolean updateUnitAttempts(TeachingPeriod teachingPeriod, Contact conRecord) {
        List<Unit_Attempt__c> forUpdate = new List<Unit_Attempt__c>();

        System.debug('!!@@##: submit:teachingPeriod:'+JSON.serializePretty(teachingPeriod));
        Savepoint sp = Database.setSavepoint();
        List<Id> unitAttemptIdList = new List<Id>();
        try {
            for(TeachingPeriod.UnitAttempt ua:teachingPeriod.unitAttemptList) {
                unitAttemptIdList.add(ua.unitAttemptId);
                if(teachingPeriod.studentUpdated == true) {
                    Unit_Attempt__c uaRecord = new Unit_Attempt__c();
                    uaRecord.Id = ua.unitAttemptId;
                    //ASNF-58
                    uaRecord.ASN_Response_Date__c = System.today();
                    uaRecord.ASN_Response_Datetime__c = Datetime.now();
                    if(ua.withDraw == true) {
                        uaRecord.ASN_Response__c = 'WDN';
                    }
                    if(ua.convertToSFR == true) {
                        uaRecord.ASN_Response__c = 'SFR';
                    }
                    forUpdate.add(uaRecord);
                }
            }
            if(forUpdate.isEmpty() == false) {
                //Commenting out for testing
                update forUpdate;
                //Place SingleEmail method call here
                //SingleEMail Message
                sendConfirmationEmail(teachingPeriod.unitAttemptList, teachingPeriod.teachingPeriodName, conRecord);
            }
        } catch(Exception ex) {
            LogUtilityException.logException(ex);
            Database.rollback(sp);
            return false;
        }
        return true;
    }

    /*******************************************************************************
    * @description  Method to check Encumbrance for the student
    * @Param conId - Id of the Contact
    * @Return Boolean - True when there are encumberance records matching the criteria
    ******************************************************************************/
    @AuraEnabled
    public static Boolean checkEncumbrance(Id conId)
    {
        String enchklbl = Label.ASN_Encumbrance_Check;
        List<String> effTypeList = new List<String>();
        if(String.isNotBlank(enchklbl))
        {
            effTypeList =  enchklbl.split(',');
        }

        List<Encumbrance__c> enList = [SELECT id from Encumbrance__c where eff_type__c in :effTypeList
				        and isactive__c = true
				        and deleted_in_source__c = false
				        and contact__c = :conId];
        return enList.size()>0;
    }


    /*******************************************************************************
    * @description  Method to send email to the student
    * @Param unitAttemptIdList - List<TeachingPeriod.UnitAttempt> , tpName - String
    * @Return void
    ******************************************************************************/
    private static void sendConfirmationEmail(List<TeachingPeriod.UnitAttempt> unitAttemptIdList, String tpName, Contact con) {
        String replyTo = Label.ASN_ReplyTo;

        List<OrgWideEmailAddress> orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address =:replyTo LIMIT 1];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setPlainTextBody('Plain Text body');
        String[] htmlPart1Args = new String[] { con.FirstName+' '+con.LastName, tpName};
        String cLPart1 = Label.ASN_Email_HTMLPart1;
        String htmlPart1 = String.format( cLPart1, htmlPart1Args);

        String htmlPart2 = '';
        for(TeachingPeriod.UnitAttempt ua: unitAttemptIdList)
        {
            String clPart2 = Label.ASN_Email_HTMLPart2;
            String[] htmlPart2Args = new String[] {ua.unitCode, ua.unitTitle, String.valueOf(ua.acvdCreditPoints), String.valueOf(ua.mark), ua.grade, ua.newoutcome};
            htmlPart2 += String.format( clPart2, htmlPart2Args);
        }
        String htmlPart3 =  Label.ASN_Email_HTMLPart3;
        message.setHtmlBody( htmlPart1 + htmlPart2 + htmlPart3);
        message.setSubject(Label.ASN_Email_Subject);
        message.setToAddresses(new List<String> {con.Email});
        message.setTargetObjectId(con.Id);

        if(orgWideAddress != null && !orgWideAddress.isEmpty()) {
            message.setOrgWideEmailAddressId(orgWideAddress.get(0).Id);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});
    }

    /*******************************************************************************
    * @description Method to retrieve the Contact related to the logged in User
    * @Return Contact - Contact that is returned from the query
    ******************************************************************************/
    @AuraEnabled
    public static Contact retrieveUserContact(Id userId)
    {
        List<User> userRec = [SELECT Id, ContactId, Email, Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Person_ID__c FROM User WHERE Id = :userId];
        Contact con;
        if(userRec != null && !userRec.isEmpty()) {
            User usr = userRec.get(0);
            if(usr.ContactId != null) {
                con = usr.Contact;
            }
        }
        return con;
    }
}