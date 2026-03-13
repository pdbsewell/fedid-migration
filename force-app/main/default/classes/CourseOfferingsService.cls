/**
* @description       : Service Class for Rest API
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 06-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
* @last modified by  : SMendu - 30-04-2024 - Updated for excluding Malaysia courses for Australia campus
**/
public with sharing class CourseOfferingsService {
    
    /**
    * @description Process Get course offering request 
    * @author rajesh.punjabi@monash.edu | 06-02-2024 
    **/
    public static List<Course_Offering__c> getCourseOfferings(CourseOfferingsWSRequest.Courserequest oRequest, Boolean applyLimit){
        
        String COURSE_OFFERING_FIELDS = 'Id, Course_Offering_UID__c, Academic_Year__c, Course_Code__c, Course_title__c, Course_Version_Number__c, Location_Code__c,Attendance_Mode__c, Attendance_Mode_Description__c, Attendance_Type__c, Attendance_Type_Description__c,Admission_Category__c, Citizenship_Type__c, fee_category__c, Type_of_place_code__c, Type_of_Place_Description__c, Active__c, Start_Date__c, Academic_CI_Sequence_Number__c, Academic_Calendar_Type__c, Calendar_Name_Alternate__c, Admission_CI_Sequence_Number__c, Admission_Calendar_Type__c, Admission_Calendar_Description__c, Course_Type__c, Course_Type_Group__c, Location_Description__c, Faculty__c, Name, Unique_Code__c, Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c';
        
        try{
            Set<String> fieldset = new Set<String> (COURSE_OFFERING_FIELDS.split(','));
            
            String sWhereClause = ' Academic_Year__c =' +oRequest.courseYear;        
            
            if(oRequest.campusCountry == 'Malaysia'){
                sWhereClause += ' AND Location_Code__c = \'MALAYSIA\'';
            }            
            
            //To filter out MALAYSIAN courses for  Australia campusCountry - Without this clause, Malaysia courses will be 
            //returned as APNG/Malaysia share the same sharing settings
            if(oRequest.campusCountry == 'Australia'){
            	sWhereClause += ' AND ( NOT Location_Code__c = \'MALAYSIA\')';
            } 
            
            if(oRequest.courseName != null){
                sWhereClause += ' AND Course_Title__c LIKE \'%'+ oRequest.courseName + '%\'';
            }

            if(oRequest.citizenshipTypeCodes != null){
                List<String> citizenshipTypes = oRequest.citizenshipTypeCodes.split(',');
                String citizenshipWhere = '(';
                if(citizenshipTypes.size()>1)
                {
                    for(String cit: citizenshipTypes)
                    {
                        citizenshipWhere += '\''+cit+'\',';
                    }
                    citizenshipWhere = citizenshipWhere.removeEnd(',');

                }else{
                    citizenshipWhere += '\''+citizenshipTypes[0]+'\'';
                } 
                citizenshipWhere += ')';
                sWhereClause += ' AND Citizenship_Type__c IN ' + citizenshipWhere ;
            }
            
            if(oRequest.courseCode != null){
                sWhereClause += ' AND Course_Code__c = \''+ oRequest.courseCode + '\'';
            }
            
            String sQuery = DynamicSoqlBuilder.getInstance()
                .validateFields(false)
                .showSOQLStatement(true)
                .setEnforced(false)
                .querySObject(String.escapeSingleQuotes('Course_Offering__c'))
                .queryFields(fieldset)
                .getQuery(sWhereClause);
            
            sQuery += ' ORDER BY Course_Code__c, Type_of_Place_Description__c, Unit_Set_Code__c, Admission_Calendar_Description__c';
            if(applyLimit)
            {
                sQuery += ' LIMIT ' + oRequest.pageSize;  
                sQuery += ' OFFSET ' + oRequest.pageOffset;
            }
            System.debug('sQuery'+sQuery);
            System.debug('sWhereClause'+sWhereClause);

            List<Course_Offering__c> lstCourseOffering = Database.query(sQuery);
            
            return lstCourseOffering;   
        }
        catch(Exception ex){
            Nebula.Logger.error('Exception Error'+ex.getMessage());
            Nebula.Logger.saveLog();

            return new List<Course_Offering__c>{};
        }
    }
    
    /**
    * @description Convert String to Query Params.
    * @author rajesh.punjabi@monash.edu | 13-02-2024 
    * @param lstString 
    * @return String 
    **/
    public static String convertListToQueryParam(List<String> lstString){
        String sReturnParam;
        
        for(String sValue: lstString){
            sReturnParam = '\'' + sValue + '\',';
        }
        
        return sReturnParam.removeEnd(',');
    }
    
    /**
    * @description Generate HASH for UID
    * @author rajesh.punjabi@monash.edu | 06-03-2024 
    * @param lstCourseOfferingHashRequest 
    * @return List<String> 
    * revision 1 - bgreenland 15-04-2024 corrected issue with bulkification
    **/
    
    @InvocableMethod (label='Generate Hash Course Offerings' description='Returns the response message success/failed.')
    public static List<String> generateHash(List<List<CourseOfferingHashRequest>> lstCourseOfferingHashRequest){
        List<String> lstResponse = new List<String>();
        List<Course_Offering__c> lstCourseOffering = new List<Course_Offering__c>();

        for(List<CourseOfferingHashRequest> lstCourseOfferingHashRequestIds :lstCourseOfferingHashRequest ){
            for(CourseOfferingHashRequest oCO: lstCourseOfferingHashRequestIds){
                Course_Offering__c oCourrseOffer = new Course_Offering__c(); 
                oCourrseOffer.Id = oCO.strId;
                oCourrseOffer.Course_Offering_UID__c  = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(oCO.strMixUniqueId)));
                lstCourseOffering.add(oCourrseOffer);
                lstResponse.add('success');
            }
        }
        
        TriggerCommon.disableTrigger('Course_Offering__c');
        update lstCourseOffering;
        TriggerCommon.enableTrigger('Course_Offering__c');
        return lstResponse;
    }
    

}