/**
 * Bulk Data Processing service class for object Trigger
 * @author Jasmin Joy Rudio
 * @group Bulk Data Processing
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */
public class BDPFieldUpdateService implements IPromise {
    Bulk_Data_Processing__c[] bdpList;
    @TestVisible Map<String, Contact> contactPersonIdMap;
    @TestVisible Map<String, Calendar__c> calendarAlternateNameMap;
    @TestVisible ContactsSelector contactSelector;
    @TestVisible CalendarSelector calendarSelector;

    public IPromise init(){
        //initialize
        this.contactPersonIdMap = new Map<String, Contact>();
        this.calendarAlternateNameMap = new Map<String, Calendar__c>();
        this.contactSelector = new ContactsSelector();
        this.calendarSelector = new CalendarSelector();
		return this;
    }

    public void execute(SObject[] records){
        this.bdpList =  (Bulk_Data_Processing__c[]) records;
        for (Bulk_Data_Processing__c bdp : this.bdpList) {
            //add code here
            if(bdp.Person_ID__c != null) this.contactPersonIdMap.put(bdp.Person_ID__c, null);
            if(bdp.Transfer_Calendar__c != null) this.calendarAlternateNameMap.put(bdp.Transfer_Calendar__c, null);
        }

        getContactsMapByPersonId();
        getCalendarMapByAlternateName();
        updateDefaultFields();
    }

    /**
     * get contact records map by Person ID
     */
    private void getContactsMapByPersonId(){
        for(Contact con: this.contactSelector.selectByPersonId(this.contactPersonIdMap.keySet())){
            this.contactPersonIdMap.put(con.Person_ID_unique__c, con);
        }
    }

    /**
     * get calendar records map by Calendar Name Alternate
     */
    private void getCalendarMapByAlternateName(){        
        for(Calendar__c can: this.calendarSelector.selectByAlternateNameCategory(this.calendarAlternateNameMap.keySet(), BDPConstants.CALENDAR_CATEGORY)){
            this.calendarAlternateNameMap.put(can.Calendar_Name_Alternate__c, can);
        }
    }

    /**
     * set Bulk Processing Data fields before insert/update
     */
    private void updateDefaultFields(){
        for(Bulk_Data_Processing__c bdp: this.bdpList){
            if (bdp.Transfer_Admission_Category__c == null) bdp.Transfer_Admission_Category__c = 'UG-IS';

            if(this.contactPersonIdMap.get(bdp.Person_ID__c) != null){
                bdp.Applicant__c = this.contactPersonIdMap.get(bdp.Person_ID__c).Id;
            } else{
                bdp.addError(BDPConstants.STUDENT_NOT_FOUND);
            }

            if(this.calendarAlternateNameMap.get(bdp.Transfer_Calendar__c) != null){
                bdp.Calendar__c = this.calendarAlternateNameMap.get(bdp.Transfer_Calendar__c).Id;
                bdp.Log__c = null;
            }else{
                bdp.addError(BDPConstants.CALENDAR_NOT_FOUND);
            }    
        }
    }
    

    /**
     * get Bulk Data Processing recordType maps
     */
    public static Map<String, Schema.RecordTypeInfo> recordTypes { get{
        if (recordTypes == null) recordTypes = Schema.SObjectType.Bulk_Data_Processing__c.getRecordTypeInfosByDeveloperName();
        return recordTypes;
    } set;}

    /**
     * Static method that updates recordType based on BDP type field
     * @param  bdp Bulk Data Processing record
     * @description currently used in trigger's before insert event handler
     */
    public static void updateRecordType(Bulk_Data_Processing__c bdp){
        if (bdp.Current_Course_Code__c != bdp.Transfer_Course_Code__c || bdp.Current_Unit_Set__c != bdp.Transfer_Unit_Set__c) {
            bdp.Type__c = BDPConstants.COURSE_TRANSFER_TYPE;
            bdp.RecordTypeId = recordTypes.get(BDPConstants.CC_TRANSFER_RECORDTYPE).getRecordTypeId();
        }else if (bdp.Current_Course_Campus__c != bdp.Transfer_Course_Campus__c) {
            bdp.Type__c = BDPConstants.CAMPUS_TRANSFER_TYPE;
            bdp.RecordTypeId = recordTypes.get(BDPConstants.CC_TRANSFER_RECORDTYPE).getRecordTypeId();
        }
        bdp.is_Onshore__c = isAustralianCampus(bdp.Current_Course_Campus__c);
        bdp.Manual_ISCA_Edit__c = bdp.is_Onshore__c == false && bdp.Type__c == BDPConstants.CAMPUS_TRANSFER_TYPE;
    }

    /**
     * Static method that updates Status when Transfer To field was populated
     * @param  bdp Bulk Data Processing record
     * @description currently used in trigger's before update event handler
     */
    public static void updateStatus(Bulk_Data_Processing__c bdp){
        if(bdp.Transfer_To__c != null){
            bdp.Status__c = BDPConstants.READY_STATUS;
        }
    }
    
    /**
     * Static method that splits Credit Duration string into respective SF fields
     * @param  bdp Bulk Data Processing record
     * @description currently used in trigger's before insert event handler
     */    
    public static void splitCreditDuration(Bulk_Data_Processing__c bdp){
        if(bdp.Credit_Duration__c != null){
            String[] creditArray = bdp.Credit_Duration__c.split(' ');
            bdp.Credit_Duration_Value__c = Decimal.valueOf(creditArray[0]);
            bdp.Credit_Duration_Unit__c = (creditArray.size() > 1 ? creditArray[1] : '');
        }
    }

    private static boolean isAustralianCampus(String campusName) {
        // Australian Campus that match the Course Transfer csv file upload
        if (String.isNotEmpty(campusName) &&
            MyApplicationUtilities.ConvertCampusToLocation(campusName.toUpperCase()) == 'Australia') {            
            return true;
        }else {
            return false;
        }
       
    }

    /**
     * Singleton for Offer Settings
     */
    public static Offer_Setting__c offersetting {
        get {
            if (offersetting == null) {
                offersetting = Offer_Setting__c.getOrgDefaults();
            }
            return offersetting;
        }
        set;
    }
    /**
     * Static method that sets the Offer_Template__c & Template_Type__c fields based on the Offer type
     * @param  bdp Bulk Data Processing record
     * @description currently used in trigger's before insert event handler
     */  
    public static void updateOfferTemplate(Bulk_Data_Processing__c bdp){
        if(bdp.Offer_Template__c != null) {
            String templateId;

            switch on bdp.Offer_Template__c {
                when 'Domestic Monash College - Australia' {
                    templateId = offersetting.Domestic_Template_Id__c;
                    bdp.Template_Type__c ='Domestic Monash College Australia';
                }	
                when 'International Coursework - Australia' {
                    templateId = offersetting.Isca_Template_Id__c;
                    bdp.Template_Type__c ='International Coursework Australia';
                }
                when 'International Coursework - Monash Abroad' {
                    templateId = offersetting.Monash_Abroad_Template_Id__c;
                    bdp.Template_Type__c ='International Monash Abroad Australia';
                }
                when 'Domestic Coursework - Australia' {
                    templateId = offersetting.Monash_Abroad_Template_Id__c;
                    bdp.Template_Type__c ='Domestic Coursework Australia';
                    bdp.Signature_Type__c ='Not Applicable';
                }
                when else {
                    // To ensure that existing Template ID is retained, during other field updates in BDP Record
                    templateId = bdp.Offer_Template__c; 
                }
            }
            bdp.Offer_Template__c = templateId;
        } else {
            bdp.Offer_Template__c = '';
            bdp.Template_Type__c = '';
        }
    }
}