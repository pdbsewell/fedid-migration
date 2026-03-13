/**
 * @author      Mathew Jose
 * @description Selector class for CPQ Quote line object processes
 * @group       Selectors
 * @revision    11/11/2019 - Mathew Jose - Created
 */
public inherited sharing class ContentDocumentLinksSelector extends BaseSelector {
    /**
     * Constructors
     */
    public ContentDocumentLinksSelector() {
        super(false);
    }
    
    public ContentDocumentLinksSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Mathew Jose
     * @description Returns the object type
     * @revision    11/12/2019 - Mathew Jose - Created
     */
    public Schema.SObjectType getSObjectType() {
        return ContentDocumentLink.sObjectType;
    }
    /**
     * @author      Mathew Jose
     * @description Query Content Document by ids including versions and links
     * @revision    11/12/2019 - Mathew Jose - Created
     */
    public Map<Id, ContentDocumentLink> selectByIdWithEntityType(Set<Id> contentDocLinkIdSet) { 
        return new Map<Id,ContentDocumentLink>((List<ContentDocumentLink>) Database.query('SELECT Id,LinkedEntityId,ShareType,Visibility,ContentDocumentId,LinkedEntity.type,ContentDocument.LatestPublishedVersionId,ContentDocument.title FROM '+getSObjectName()+' WHERE Id in :contentDocLinkIdSet')); 
    }
}