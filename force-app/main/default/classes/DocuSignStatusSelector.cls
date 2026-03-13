/**
 * @description Selector for the DocuSign Status object 
 * (dsfs__DocuSign_Status__c)
 * @group Selectors
 */
public inherited sharing class DocuSignStatusSelector extends BaseSelector {

    public DocuSignStatusSelector() {
        super(false);
    }
    
    public DocuSignStatusSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return dsfs__DocuSign_Status__c.sObjectType;
    }

    /**
     * @description Query DocuSign Status by ids
     * @return      List of DocuSign Status records
     */
    public List<dsfs__DocuSign_Status__c> selectById(Set<Id> docuSignStatusIds) {
        return (List<dsfs__DocuSign_Status__c>) selectSObjectsById(docuSignStatusIds);
    }

    public List<dsfs__DocuSign_Status__c> selectByIdAndEnvelopStatus(Set<Id> docuSignStatusIds, String status) {
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE Id IN :docuSignStatusIds AND dsfs__Envelope_Status__c = :status ORDER BY {2}', 
            new List<String>{
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<dsfs__DocuSign_Status__c>) Database.query(queryString);
    }
}