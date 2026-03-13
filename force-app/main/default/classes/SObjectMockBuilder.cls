/**
 * @description A generalized builder for creating sobject records for the 
 * purposes of unit testing without dml operations.
 * Although this could be used for production code, this class creates sObjects 
 * with JSON deseralization for the ability to create sObjects without dml 
 * operations, such as creating records with formula fields without the need to 
 * insert the parent record into the database at all. As such, it is not 
 * advised to use this for creating records for non-unit testing uses.
 * @group Unit Test
 */
public class SObjectMockBuilder {

    private System.Type sObjectClass;
    private List<String> jsonFieldValues = new List<String>();

    /**
     * @description Constructor for setting the object type of the sobject 
     * record
     * @param sObjectClass The Systen.Type of the sobject to be created
     * @example new SObjectMockBuilder(Account.class);
     */
    public SObjectMockBuilder(System.Type sObjectClass) {
        this.sObjectClass = sObjectClass;
    }

    /**
     * @description Sets the field and value of the sobject record
     * @param fieldName The Schema.sObjectField field name
     * @param fieldValue The field value as a string
     * @return Returns the current instance
     */
    public SObjectMockBuilder with(Schema.sObjectField fieldName, String fieldValue) {
        jsonFieldValues.add('"' + String.valueOf(fieldName) + '":"' + fieldValue + '"');
        return this;
    }

    /**
     * @description Sets the field and value of the sobject record
     * @param fieldName The Schema.sObjectField field name
     * @param fieldValue The field value as a Id
     * @return Returns the current instance
     */
    public SObjectMockBuilder with(Schema.sObjectField fieldName, Id fieldValue) {
        jsonFieldValues.add('"' + String.valueOf(fieldName) + '":"' + Id.valueOf(fieldValue) + '"');
        return this;
    }

    /**
     * @description Sets the field and value of the sobject record
     * @param fieldName The Schema.sObjectField field name
     * @param fieldValue The field value as a boolean
     * @return Returns the current instance
     */
    public SObjectMockBuilder with(Schema.sObjectField fieldName, boolean fieldValue) {
        jsonFieldValues.add('"' + String.valueOf(fieldName) + '":' + String.valueOf(fieldValue));
        return this;
    }

    /**
     * @description Sets the field and value of the sobject record
     * @param fieldName The Schema.sObjectField field name
     * @param fieldValue The field value as a Integer
     * @return Returns the current instance
     */
    public SObjectMockBuilder with(Schema.sObjectField fieldName, Integer fieldValue) {
        jsonFieldValues.add('"' + String.valueOf(fieldName) + '":"' + String.valueOf(fieldValue) + '"');
        return this;
    }

    /**
     * @description Sets the parent relationship record for cross object field access
     * This does not set the Id value for the lookup field on the object, if 
     * an id value is required, then it should be set separately with the 
     * with(Schema.sObjectField fieldName, Id fieldValue) method
     * @param fieldName The Schema.sObjectField field name
     * @param parentRecord The sobject parent record
     */
    public SObjectMockBuilder withParentRelationship(Schema.sObjectField fieldName, SObject parentRecord) {
        String relationshipFieldName = fieldName.getDescribe().getRelationshipName();
        String parentRecordJson = JSON.serialize(parentRecord);
        jsonFieldValues.add('"' + String.valueOf(relationshipFieldName) + '":' + String.valueOf(parentRecordJson));
        return this;
    }

    /**
     * @description Creates the sObject record
     * @return Returns the record as an sobject. Depending on how this is used, 
     * it is likely the code calling this will need to cast the sobject record 
     * created to the specific sobject type
     */
    public SObject create() {
        String sobjectJsonString = '{"attributes" : {"type" : "' + sObjectClass.toString() + '"}';
        
        if (!jsonFieldValues.isEmpty()) {
            sobjectJsonString += ',';
            for (Integer i = 0; i < jsonFieldValues.size(); i++) {
                sobjectJsonString += jsonFieldValues[i];

                // Add comma if it is not the last field to add
                if (i != jsonFieldValues.size() - 1) {
                    sobjectJsonString += ',';
                }
            }
        }

        String sObjectJsonRecord = sobjectJsonString + '}';

        return (Sobject) JSON.deserialize(sObjectJsonRecord, sObjectClass);
    }
}