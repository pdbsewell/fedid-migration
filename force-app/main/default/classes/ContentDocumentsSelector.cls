/**
 * @author      Mathew Jose
 * @description Selector class for CPQ Quote line object processes
 * @group       Selectors
 * @revision    11/11/2019 - Mathew Jose - Created
 */
public inherited sharing class ContentDocumentsSelector extends BaseSelector {
    /**
     * Constructors
     */
    public ContentDocumentsSelector() {
        super(false);
    }
    
    public ContentDocumentsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Mathew Jose
     * @description Returns the object type
     * @revision    11/12/2019 - Mathew Jose - Created
     */
    public Schema.SObjectType getSObjectType() {
        return ContentDocument.sObjectType;
    }
    
    /**
     * @author      Mathew Jose
     * @description Query Content Document by ids
     * @revision    11/12/2019 - Mathew Jose - Created
     */
    public List<ContentDocument> selectById(Set<Id> idSet) {
        // Cannot use the BaseSelector stuff because Content Document does not 
        // have a name field for ordering
        return (ContentDocument[]) Database.query(
            String.format('SELECT {0} FROM {1} WHERE id in :idSet', 
                new List<String>{getFieldListString(), getSObjectName()}));
    }

}