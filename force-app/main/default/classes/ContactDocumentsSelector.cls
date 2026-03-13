/**
 * @author      Sethu Venna
 * @description Selector class for contact documnet object processes
 * @group       Selectors
 * @revision    05/10/2024 - Initial Version
 */
public inherited sharing class ContactDocumentsSelector extends BaseSelector {
    /**
     * @author      Sethu Venna
     * @description Constructor
     * @revision    05/10/2024 - Initial Version
     */
	public ContactDocumentsSelector() {
	    super();
	}
	
    /**
     * @author      Sethu Venna
     * @description Constructor
     * @param       newOverrideObjectPermissions
     * @revision    05/10/2024 - Initial Version
     */
    public ContactDocumentsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Sethu Venna
     * @description Returns the object type
     * @return      Schema.SObjectType
     * @revision    05/10/2024 - Initial Version
     */
	public Schema.SObjectType getSObjectType() {
		return Contact_Document__c.sObjectType;
	}
    
    /**
     * @author      Sethu Venna
     * @description Query contact documents by ids
     * @return      List<Contact_Document__c>
     * @param       idSet of Contact Document Ids
     * @revision    05/10/2024 - Initial Version
     */
    public List<Contact_Document__c> selectByIdWithRelatedApplicationDetails(Set<Id> idSet) {

        String relatedFieldsString = String.join(
            new List<String>{
                'Application__r.Callista_Applicant_Id__c',
                'Document_Checklist__r.Document_Type__c',
                'Application__r.Parent_Application__r.Callista_Applicant_Id__c',
                'Application__r.Type_of_Study__c',
                'Application__r.Graduate_Research_Application_Type__c'
            }
            , ','
        );

        String queryString = String.format('SELECT {0}, {1} FROM {2} WHERE Id IN :idSet ORDER BY {3}', 
            new List<String> {
                getFieldListString(),
                relatedFieldsString,
                getSObjectName(),
                getOrderBy()
            }
        );
        
        return (List<Contact_Document__c>) Database.query(queryString);
	}

    /**
     * @author      Sethu Venna
     * @description Query contact documents by ids
     * @return      List<Contact_Document__c>
     * @param       idSet of Contact Document Ids
     * @revision    05/10/2024 - Initial Version
     */
    public List<Contact_Document__c> selectByApplicationIdWithEmptyCallistaDocId(Set<Id> idSet) {

        String queryString = String.format('SELECT {0} FROM {1} WHERE Application__c IN :idSet AND Callista_Document_Id__c = null ORDER BY {2}', 
            new List<String> {
                getFieldListString(),
                getSObjectName(),
                getOrderBy()
            }
        );
        
        return (List<Contact_Document__c>) Database.query(queryString);
	}
}