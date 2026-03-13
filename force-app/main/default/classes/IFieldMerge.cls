/**
 * @description Interface for comparing Fields
 * @group Engage
 */
public interface IFieldMerge {

    /**
     * @description Returns the DocuSign signing URL
     * @param fieldName The Account field Name
     * @param masterRecord The master record.
     * @param duplicateRecord The duplicate record
     */
    Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord);
}