/**
 * @author Nick Guia
 * @group Enquiry Management
 * @description Utility class for Case Object to centralise utility methods and static variables
 * @revision    FEB.11.2020 - APRivera - Refactored
 *              JUL.03.2020 - APRivera - cover the scenario where role doesn't have children role
 *              AUG.31.2020 - KL - added method mumRecordTypeId for SFTG-1377 to enable MUM's Enquiry Managentment use cases
 *              JUL.25.2022 - RANAND - Delete references of unsused BH Stop Status Metadata
 */
public class CaseUtilities {

    public static final String CASE_OBJECT = 'Case';

    public static final String ORIGIN_WEB = 'Web';
    public static final String ORIGIN_PHONE = 'Phone';
    public static final String ORIGIN_BACK_OFFICE_GENERAL = 'Back Office - General';
    public static final String ORIGIN_FACE_TO_FACE = 'Face to Face';
    public static final String ORIGIN_KEY_AGENT = 'adm-keyagent@monash.edu';
    public static final String ORIGIN_WEB_RDR = 'Web - Research Deferral Request';
    public static final String CASE_RECORDTYPENAME_SCHOOLENQUIRY = 'School Enquiry';
    public static final String ORIGIN_WEB_MONPLAN = 'Web - MonPlan';

    public static final String CASE_TYPE_KEY_AGENT_INTERNATIONAL = 'Key Agent - International';

    public static final String DO_NOT_CHANGE = '-- Do not change --';
    public static final String DO_NOT_EXCLUDE = '-- Do not exclude --';

    public static final Set<String> setSolvedStatus = new Set<String>{'Solved', 'Referred Off-System', 'Referred by Phone'};
    public static final Set<String> setOpenStatus = new Set<String>{'Open', 'Awaiting Customer Feedback', 'Pending Investigation'};
    
    public static Id hrRecordTypeId{
        get{
            if(hrRecordTypeId == null){
                hrRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HR').getRecordTypeId();
            }
            return hrRecordTypeId;
        }
        set;
    }

    public static Id pdRecordTypeId{
        get{
            if(pdRecordTypeId == null){
                pdRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Development').getRecordTypeId();
            }
            return pdRecordTypeId;
        }
        set;
    }

    public static Id mumRecordTypeId{
        get{
            if(mumRecordTypeId == null){
                mumRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MUM_Admissions').getRecordTypeId();
            }
            return mumRecordTypeId;
        }
        set;
    }
	
	public static Id entprseRecordTypeId{
        get{
            if(entprseRecordTypeId == null){
                entprseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
            }
            return entprseRecordTypeId;
        }
        set;
    }

    public static Id outboundCallRecordTypeId{
        get{
            if(outboundCallRecordTypeId == null){
                outboundCallRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId();
            }
            return outboundCallRecordTypeId;
        }
        set;
    }

    public static Id facultyGradResearchRecordTypeId{
        get{
            if(facultyGradResearchRecordTypeId == null){
                facultyGradResearchRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();
            }
            return facultyGradResearchRecordTypeId;
        }
        set;
    }



    public static Map<Id, String> mapCaseRecordTypeById{
        get{
            if(mapCaseRecordTypeById == null){
                mapCaseRecordTypeById = new Map<Id, String>();
                for(RecordTypes_Allowed_on_CaseTrigger__c rt : RecordTypes_Allowed_on_CaseTrigger__c.getall().values()){
                    mapCaseRecordTypeById.put(Schema.SObjectType.Case.getRecordTypeInfosByName().get(rt.Name).getRecordTypeId(), rt.Name);
                }
            }
            return mapCaseRecordTypeById;
        }
        set;
    }

    public static Boolean isAllowedRecordType(Id recordTypeId){
        Boolean isAllowedRecordTypeId = false;
        for(RecordTypes_Allowed_on_CaseTrigger__c rt : RecordTypes_Allowed_on_CaseTrigger__c.getAll().values()){
            if(mapCaseRecordTypeById.containsKey(recordTypeId)){
                isAllowedRecordTypeId = true;
            }
        }
        mapCaseRecordTypeById = null;
        return isAllowedRecordTypeId;
    }

    public static List<Case_to_Contact_Field_Mapping__mdt> lstCastToContactMappings{
        get{
            if(lstCastToContactMappings == null){
                lstCastToContactMappings = [SELECT Id, Case_API_name__c, Contact_Field_API_name__c
                FROM Case_to_Contact_Field_Mapping__mdt LIMIT 400];
            }
            return lstCastToContactMappings;
        }
        set;
    }

    public static Set<String> stopStatusSet{
        get{
            if(stopStatusSet == null){
                stopStatusSet = new Set<String>();
                for (Case_Stop_Status__mdt stopStatus : [SELECT MasterLabel FROM Case_Stop_Status__mdt]) {
                    stopStatusSet.add(stopStatus.MasterLabel);
                }
            }
            return stopStatusSet;
        }
        set;
    }

    public static Set<String> closedStatusSet{
        get{
            if(closedStatusSet == null){
                closedStatusSet = new Set<String>();
                for(CaseStatus status : [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true]) {
                    closedStatusSet.add(status.MasterLabel);
                }
            }
            return closedStatusSet;
        }
        set;
    }

    public static Map<String, Id> mapRecordTypeIdByName{
        get{
            if(mapRecordTypeIdByName == null){
                mapRecordTypeIdByName = new Map<String, Id>();
                for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType='Case']){
                    mapRecordTypeIdByName.put(rt.Name, rt.Id);
                }
            }
            return mapRecordTypeIdByName;
        }
        set;
    }

    public static BusinessHours defaultHours{
        get{
            if(defaultHours == null){
                defaultHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE];
            }
            return defaultHours;
        }
        set;
    }

    public static Id businessHoursId{
        get{
            if(businessHoursId == null){
                businessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE].Id;
            }
            return businessHoursId;
        }
        set;
    }


    public static Map<String, MC_Enquiry_Origin_Category__mdt> mapEnquiryOriginCategoriesByLabel{
        get{
            if(mapEnquiryOriginCategoriesByLabel == null){
                mapEnquiryOriginCategoriesByLabel = new Map<String, MC_Enquiry_Origin_Category__mdt>();
            }
            return mapEnquiryOriginCategoriesByLabel;
        }
        set;
    }

    public static Map<String, String> mapEnquiryOriginCategoriesByLabelString{
        get{
            if(mapEnquiryOriginCategoriesByLabelString == null){
                mapEnquiryOriginCategoriesByLabelString = new Map<String, String>();
            }
            return mapEnquiryOriginCategoriesByLabelString;
        }
        set;
    }

    public static Map<String, String> getMapEnquiryOriginCategoriesByLabel(Set<String> setCaseOrigin){
        Map<String, String> mapRecords = new Map<String, String>();
        Set<String> setStringCaseOrigin = new Set<String>();

        if(mapEnquiryOriginCategoriesByLabelString != null){
            for(String strCaseOrigin : setCaseOrigin){
                if(!mapEnquiryOriginCategoriesByLabelString.containsKey(strCaseOrigin)){
                    setStringCaseOrigin.add(strCaseOrigin);
                }else{
                    mapRecords = mapEnquiryOriginCategoriesByLabelString.clone();
                }
            }
        }
        if(!setStringCaseOrigin.isEmpty()){
            for (MC_Enquiry_Origin_Category__mdt mdt : [SELECT MasterLabel, Category__c FROM MC_Enquiry_Origin_Category__mdt
            WHERE MasterLabel IN: setStringCaseOrigin]) {
                mapRecords.put(mdt.MasterLabel, mdt.Category__c);
                mapEnquiryOriginCategoriesByLabelString.put(mdt.MasterLabel, mdt.Category__c);
            }
        }
        return mapRecords;
    }

    public static Set<String> setFacultyEmailAddresses{
        get{
            if(setFacultyEmailAddresses == null){
                setFacultyEmailAddresses = new Set<String>();
                for(Off_System_Email_Address__mdt addr : [SELECT Label, Email_Address__c FROM Off_System_Email_Address__mdt
                ORDER BY Label ASC LIMIT 200]) {
                    setFacultyEmailAddresses.add(addr.Email_Address__c);
                }
            }
            return setFacultyEmailAddresses;
        }
        set;
    }

    public static Environment_Settings__c environmentSettings{
        get{
            if(environmentSettings == null){
                environmentSettings = Environment_Settings__c.getOrgDefaults();
            }
            return environmentSettings;
        }
        set;
    }

    /**
     * utility to confirm if field has changed
     * @param fieldName name of field to check for change
     * @param newObj sObject that the field is on
     * @param oldObj sObject that the field is on
     */
    public static Boolean fieldHasChanged(String fieldName, SObject newObj, SObject oldObj){
        try {
            return (newObj.get(fieldName) != oldObj.get(fieldName)) ? true : false;
        } catch (exception e){
            return false; // if passed a null array
        }
    }

    /**
     * @author      Kristian Vegerano
     * @date        FEB.16.2018
     * @description retrieve map with the key being the role name and value as set of string under the role listed on the key
     */
    public static Map<String, Set<String>> retrieveRoleHierarchyChildren(){
        //Initialize Variables
        Map<Id, UserRole> roleMap = new Map<Id, UserRole>();
        Map<String, UserRole> roleNameMap = new Map<String, UserRole>();
        Map<String, Set<String>> roleHierarchyChildrenMap = new Map<String, Set<String>>();

        //Retrieve roles
        for(UserRole loopRole : [SELECT Id, Name, ParentRoleId
        FROM UserRole]){
            //Assign to role map
            roleMap.put(loopRole.Id, loopRole);
            //Assign to role map
            roleNameMap.put(loopRole.Name, loopRole);
        }

        //Assign to map of parent and set of children
        for(UserRole loopRole : roleMap.values()){
            //Check if the role has a parent
            if(loopRole.ParentRoleId != null){
                //Assign to map of parent role and set of children roles
                if(!roleHierarchyChildrenMap.containsKey(roleMap.get(loopRole.ParentRoleId).Name)){
                    roleHierarchyChildrenMap.put(roleMap.get(loopRole.ParentRoleId).Name, new Set<String>{roleMap.get(loopRole.ParentRoleId).Name});
                }
                roleHierarchyChildrenMap.get(roleMap.get(loopRole.ParentRoleId).Name).add(loopRole.Name);
            }else{ // cover scenario of roles without child roles
                roleHierarchyChildrenMap.put(loopRole.Name, new Set<String>{loopRole.Name});
            }
        }

        //Get child roles from hierarchy
        roleHierarchyChildrenMap = retrieveRoleHierarchyChildren(3, roleHierarchyChildrenMap);

        return roleHierarchyChildrenMap;
    }

    /**
     * @author      Kristian Vegerano
     * @date        FEB.16.2018
     * @description Assign grandchildren role to grandparent roles depending on the parameter number of iteration - higher the number of iterations, the deeper the level of hierarchy retrieved
     */
    public static Map<String, Set<String>> retrieveRoleHierarchyChildren(Integer numberOfIteration, Map<String, Set<String>> roleHierarchyChildrenMap){
        for(Integer counter = 0; counter < numberOfIteration; counter++){
            //1st level - Parent
            for(String loopParentRoleName : roleHierarchyChildrenMap.keySet()){
                //2nd level - Child
                for(String loopChildRoleName : roleHierarchyChildrenMap.get(loopParentRoleName)){
                    //Roll up results to parent
                    if(roleHierarchyChildrenMap.containsKey(loopChildRoleName)){
                        roleHierarchyChildrenMap.get(loopParentRoleName).addAll(roleHierarchyChildrenMap.get(loopChildRoleName));
                    }
                }
            }
        }

        return roleHierarchyChildrenMap;
    }

    /**
     * @author      Angelo Rivera
     * @date        JUN.14.2019
     * @description retrieves map of users
     */
    public static Map<Id, User> retrieveCaseOwner(Set<Id> setUserOwnerIds){
        Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, UserRoleId, UserRole.Name
        FROM User
        WHERE Id IN :setUserOwnerIds]);
        return ownerMap;
    }

    /**
     * @author      Angelo Rivera
     * @date        JUN.14.2019
     * @description retrieves map of queue
     */
    public static void retrieveQueueMap(Map<Id, Group> queueMap, Map<String, Group> queueNameMap){
        for(Group loopGroup : [SELECT Id, Name FROM Group WHERE Type = 'Queue']){
            queueMap.put(loopGroup.Id, loopGroup);
            queueNameMap.put(loopGroup.Name, loopGroup);
        }
    }
}