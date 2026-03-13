/*
 *    DescribeUtility : This class holds useful methods for accessing system describes / tooling api
 *    @group Utilities
 */
public class DescribeUtility {
    
    //Map of relationship describes
    private static Map<String, Map<String, Map<String, String>>> childRelationshipMap;
    public static Map<String, Map<String, String>> getChildRelationshipMap(String defineChildRelationshipsObject){
        
        //Initialize childRelationshipMap map
        if(childRelationshipMap == null){
            childRelationshipMap = new Map<String, Map<String, Map<String, String>>>();
        }
        
        //Initialize map of sobject : map of child relationship names
        if(!childRelationshipMap.containsKey(defineChildRelationshipsObject)){
            childRelationshipMap.put(defineChildRelationshipsObject, DescribeUtility.retrieveChildRelationships(defineChildRelationshipsObject));
        }
        
        return childRelationshipMap.get(defineChildRelationshipsObject);
    }
    
    /*
     *  Method that retrieves all child relationships of a given object.
     *  Useful for getting the lookup field's child relationship name
     * 
     *  @author     Kristian Vegerano
     *  @param      String defineChildRelationshipsObject - Object API name from where to get relationship names
     *  @returns    Map of child api name | child field pointed to the parent api name | value: child relationship name
     *  @reference  Example child relationship item: 
     *              Schema.ChildRelationship[ getChildSObject=Application_Qualification_Provided__c;
     *              getField=Application__c;
     *              getJunctionIdListNames=();
     *              getRelationshipName=Application_Qualifications__r;
     *              isCascadeDelete=true;
     *              isDeprecatedAndHidden=false;
     *              isRestrictedDelete=false; ]
     */
    private static Map<String, Map<String, String>> retrieveChildRelationships(String defineChildRelationshipsObject){
        //Initialize Map
        Map<String, Map<String, String>> childRelationshipMap = new Map<String, Map<String, String>>();
        //Iterate through each child relationships of the given OBJECT
        for(Schema.ChildRelationship loopRelationship : Schema.getGlobalDescribe().get(defineChildRelationshipsObject).getDescribe().getChildRelationships()){
            //Add child object api name
            if(!childRelationshipMap.containsKey(loopRelationship.getChildSObject().getDescribe().getName())){
                childRelationshipMap.put(loopRelationship.getChildSObject().getDescribe().getName(), new Map<String, String>());
            }
            
            //Add child field pointed to the parent api name
            childRelationshipMap.get(loopRelationship.getChildSObject().getDescribe().getName()).put(loopRelationship.getField().getDescribe().getName(), loopRelationship.getRelationshipName());
        }
        
        return childRelationshipMap;
    }
    
    //Describe field's data type
    public static Schema.DisplayType getFieldDataType(String objectName, String fieldName){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
    }
}