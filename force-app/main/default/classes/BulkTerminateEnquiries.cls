/**
 * @author Inderpal Dhanoa
 * @date 20.Nov.2023
 * @description Class for Monash Connect to initiate terminate Bulk GeneSys Enquiries.
 * @group Monash Connect
 * @Modifications Log
 *  NOV.20.2023     Inderpal D   - Initial Version MCT-323
 */
public class BulkTerminateEnquiries {
    
    @InvocableMethod(label='Initiate Bulk Update' description='Common method to bulk update Enquiries')
    public static void bulkUpdateEnquiries(List<List<String>> input){
        List<Id> l_linkedEnq = new List<Id>();
        // Assign the Owner Id
        List<String> wrapperInp = input[0];
        Id i_ownerId = Id.valueof(wrapperInp[0]);

        for(String inp : wrapperInp){
            l_linkedEnq.add(Id.valueof(inp));
        }

        BatchTerminateGenesysEnquiries obj_freshTermination = new BatchTerminateGenesysEnquiries(l_linkedEnq, i_ownerId);
        Database.executeBatch(obj_freshTermination, 1);
    }
}