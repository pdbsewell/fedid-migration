/*
 * @author:			    JPadda jpad0005
 * @description:	    Controller class for MarkEnquiryPrivate
 */
public with sharing class MarkEnquiryPrivateController {
    /*
     * @author:			JPadda jpad0005
     * @date:			05-12-2023
     * @description:	Updates the Private Enquiry checkbox, removes Case Teams & Manual Sharing
     *                  For Faculty Graduate Research Enquiries, reruns the Sharing Flow
     */
    @AuraEnabled
    public static void markEnquiryAsPrivate(Id enquiryId) {
        Case enquiry = [
            SELECT
                Id,
                RecordTypeId,
                (SELECT Id FROM TeamMembers),
                (SELECT Id FROM TeamTemplateRecords),
                (SELECT Id FROM Shares WHERE RowCause = 'Manual')
            FROM Case
            WHERE Id = :enquiryId
            LIMIT 1
        ];

        try {
            // Delete Case Team / Members associated with the Enquiry
            delete enquiry.TeamMembers;
            delete enquiry.TeamTemplateRecords;

            // Delete Manual Sharing rules
            delete enquiry.Shares;

            // Change the owner to be the running user
            enquiry.OwnerId = UserInfo.getUserId();

            // Set Private Enquiry flag to true
            enquiry.Private_Enquiry__c = true;

            update enquiry;

            // Faculty Graduate Research Enquiries
            if (enquiry.RecordTypeId == CaseUtilities.facultyGradResearchRecordTypeId) {
                // Call the Enquiry Sharing Flow to update sharing for Faculty
                Map<String, Object> flowInputs = new Map<String, Object>();
                flowInputs.put('CaseId', enquiry.Id);

                Flow.Interview.Enquiry_Sharing_Faculty_Graduate_Research flow = new Flow.Interview.Enquiry_Sharing_Faculty_Graduate_Research(
                    flowInputs
                );
                flow.start();
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}