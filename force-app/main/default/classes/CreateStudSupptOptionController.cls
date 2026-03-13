/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         17/06/2024
* @description  Class that will create Student Support Options
* @revision     17/06/2024 - Initial Version
*******************************************************************************/
public with sharing class CreateStudSupptOptionController {
    public static string ENQ_TYPE_STUD_SUPPORT = 'Student Support';
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.June.2024
     * @description  Method to fetch the mapping from the List of Values Object
    *******************************************************************************/ 
    @AuraEnabled
    public static List<CreateStudSupptOptionController.SupportOptionWrapper> fetchSupportOptionMappings() {
        CreateStudSupptOptionController.SupportOptionWrapper obj;
        List<CreateStudSupptOptionController.SupportOptionWrapper> supportOptionComb = new List<CreateStudSupptOptionController.SupportOptionWrapper>();
        List<String> mappedValues;
        for(List_of_Values__c val : [SELECT Value__c, System_Code__c 
                                    FROM List_of_Values__c 
                                    WHERE Is_Active__c = true AND Enquiry_Type__c = :ENQ_TYPE_STUD_SUPPORT
                                    AND Type__c = :ENQ_TYPE_STUD_SUPPORT]){
            obj = new CreateStudSupptOptionController.SupportOptionWrapper();
            obj.supportArea = val.System_Code__c;
            obj.supportOption = val.Value__c;
            supportOptionComb.add(obj);
        }
        return supportOptionComb;
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.June.2024
     * @description  Method to save the mapping from the List of Values Object
     * and save fresh records on the Junction object 
    *******************************************************************************/ 
    @AuraEnabled
    public static String saveMappings(String mapping, String recordId) {
        Set<String> s_supportAreaSupportOption = new Set<String>();
        for(String eachMapping : mapping.split(';')){
            s_supportAreaSupportOption.add(eachMapping);
        }
        Map<String, Id> listOfValuesMappings = new Map<String, Id>();
        Map<String, Id> exisitngStudSupptOptionsRecds = new Map<String, Id>();
        CreateStudSupptOptionController.SupportOptionWrapper obj;
        List<CreateStudSupptOptionController.SupportOptionWrapper> supportOptionComb = new List<CreateStudSupptOptionController.SupportOptionWrapper>();
        List<String> mappedValues;
        String existingKey;
        for(List_of_Values__c val : [SELECT Id, Value__c, System_Code__c 
                                    FROM List_of_Values__c 
                                    WHERE Is_Active__c = true AND Enquiry_Type__c = :ENQ_TYPE_STUD_SUPPORT
                                    AND Type__c = :ENQ_TYPE_STUD_SUPPORT]){
            listOfValuesMappings.put(val.System_Code__c + '-' + val.Value__c, val.Id);
        }
        // CHeck for Existing values mapped
        for(Student_Support_Options__c rec : [SELECT List_of_Values__r.Value__c, List_of_Values__r.System_Code__c 
                                              FROM Student_Support_Options__c 
                                              WHERE Outbound_Call__c = :Id.ValueOf(recordId)]){
            exisitngStudSupptOptionsRecds.put(rec.List_of_Values__r.System_Code__c + '-' + rec.List_of_Values__r.Value__c, rec.Id);
        }
        // Remove duplicates
        List<Student_Support_Options__c> newMapping = new List<Student_Support_Options__c>();
        Student_Support_Options__c rec;
        for(String key : s_supportAreaSupportOption){
            if(!exisitngStudSupptOptionsRecds.containsKey(key) && listOfValuesMappings.containsKey(key)){
                rec = new Student_Support_Options__c();
                rec.List_of_Values__c = listOfValuesMappings.get(key);
                rec.Outbound_Call__c = Id.ValueOf(recordId);
                newMapping.add(rec);
            }
        }
        // Insert fresh Mapping
        try{
            insert newMapping;
            return 'Success';
        }catch(Exception ex){
            Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();return ex.getMessage(); 
        }
    }

    public class SupportOptionWrapper{
        @AuraEnabled
        public String supportArea;
        @AuraEnabled
        public String supportOption;
    }
}