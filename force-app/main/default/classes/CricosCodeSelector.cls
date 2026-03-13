/**
 * @description Selector for CRICOS Code (API name: CRICOS_Code__c) object
 * @group Selectors
 */
public inherited sharing class CricosCodeSelector extends BaseSelector{
    public CricosCodeSelector() {
        super(false);
    }

    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return CRICOS_Code__c.sObjectType;
    }
    

    /**
     * @description Returns a list of CRICOS codes for matching course codes and type
     * @param courseCodes A Set of course codes 
     * @param type The CRICOS code type
     */
    public List<CRICOS_Code__c> selectByCourseVersionKeyAndType(
            Set<String> courseVersionKeys, String cricosCodeType) {
        String queryString = String.format(
            'SELECT {0}, Unit_Set__r.Name FROM {1} WHERE Type__c=:cricosCodeType AND Course_Version_Key__c in: courseVersionKeys', 
            new List<String>{
                    getFieldListString(),
                    getSObjectName()
            }
        );
        return (List<CRICOS_Code__c>) Database.query(queryString);
    }
}