/*
 * @description Test class for record creation class
 * @author Martin cadman
 * @date 19 Dec 2019
 */
@isTest(isParallel=true)
public class StudFirst_DocumentDTO_Test {

    @isTest static void testMe() {
        
		StudFirst_DocumentDTO doc = new StudFirst_DocumentDTO();
        doc.externalApplicantId = '78787878';

        // Agent
        doc.Agent = new StudFirst_DocumentDTO.Agent();
        doc.Agent.agentPersonId = Label.CALLISTA_AGENT_PERSON_ID;

        // Document
        doc.document = new StudFirst_DocumentDTO.Document();
        doc.document.type = 'CRM_EMAIL';
        doc.document.filename = 'Email_Test';
		doc.document.contentType = 'text/plain';
        doc.document.comments = 'Enquiry Source: ';
        
        Blob documentBlob = Blob.valueOf('docBody');
        doc.document.binary = EncodingUtil.base64Encode(documentBlob);       

        system.assertEquals(doc.document.binary != null, true, 'We have no blob!');
    }
    
}