/**
 * @author      Mac Domingo
 * @description Selector class for Salutation object processes
 * @group       Selectors
 * @revision    14/07/2023 - Mac Domingo - Created
 */
public inherited sharing class SalutationSelector {
    /**
     * Constructors
     */
    public SalutationSelector() {
       
    }
    
    /**
     * @author      Mac Domingo
     * @description This method returns a list of Salutation records 
     * @param idSet - contactIds that needs deduping
     * @return return List of Salutation records
     */
    public List<ucinn_ascendv2__Salutation__c> selectByConstituentId (Set<Id> idSet){
        List<ucinn_ascendv2__Salutation__c> salutationList = new List<ucinn_ascendv2__Salutation__c>();
        String wClause = 'ucinn_ascendv2__Contact__c IN :idSet'; // filter by Contact        
        String soqlStr = DynamicSoqlBuilder.getInstance()
                            .showSOQLStatement(true)
                            .setEnforced(false)
                            .querySObject('ucinn_ascendv2__Salutation__c')
                            .validateFields(false)
                            .queryFields(new Set<String>{'ucinn_ascendv2__Addressee_Line_1__c', 'ucinn_ascendv2__Addressee_Line_2__c', 'ucinn_ascendv2__Contact_2__c', 'ucinn_ascendv2__Contact__c', 'ucinn_ascendv2__Inside_Salutation__c', 'ucinn_ascendv2__Salutation_Author__c', 'ucinn_ascendv2__Salutation_Record_Type_Formula__c', 'ucinn_ascendv2__Salutation_Type__c', 'LastModifiedDate'})
                            .getQuery(wClause);

        salutationList = Database.query(soqlStr);
        return salutationList;
    }

}