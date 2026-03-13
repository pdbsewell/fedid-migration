/**
 * @description Selector class for Content Version object
 * @group       Selectors
 */
public inherited sharing class ContentVersionSelector extends BaseSelector {

    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return ContentVersion.sObjectType;
    }

    /**
     * @description Queries Id, VersionData (fileBody in base64) and title 
     * in ContentVersion
     * @param Id of the ContentVersion to query
     * @return Returns Content Version with basic file details
     */
    public ContentVersion selectContentVersionById(String id) {
        return [SELECT Id, VersionData, FileExtension, Title FROM ContentVersion WHERE Id = :id];
    }

}