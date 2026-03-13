/**
 * @description Test class for OffersDocuSignCreateEnvReqBodyBuild_Test
 */
@isTest(isParallel=true)
public class OffersDocuSignCreateEnvReqBodyBuild_Test {
    
    /**
     * @description Tests the status field of the builder
     * This status is expected to be set to "sent" by default.
     */
    @isTest
    static void shouldSetStatusToSent() {
        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.requestBody;
        System.assertEquals('sent', reqBody.status, 'Expected the status to be set to "sent"');
    }

    /**
     * @description Tests the email subject field for the DocuSign request body
     */
    @isTest
    static void shouldSetEmailSubjectFromBuilder() {
        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Subject Test 123';
        DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).requestBody;
        System.assertEquals('Subject Test 123', reqBody.emailSubject, 'Expected the status to be set to "Subject Test 123"');
    }

    /**
     * @description Tests the email blurb field for the DocuSign request body
     */
    @isTest
    static void shouldSetEmailBlurbFromBuilder() {
        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.emailBlurb = 'Some blurb goes here.';
        DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).requestBody;
        System.assertEquals('Some blurb goes here.', reqBody.emailBlurb, 'Expected the status to be set to "Some blurb goes here."');
    }

    /**
     * @description Tests the document content has been set correctly by the builder
     * Assumes only 1 document will be added
     */
    @isTest
    static void shouldSetDocumentFromBuilder() {
        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentName = 'Test Document 1';
        document.documentId = 1;
        
        // Not a working base64 string as it is not needed for this unit test
        document.documentBody = 'JVBERi0xLjUKJdP0zOEKMSAwIG9iago8PAovVHlwZS9QYWdlCi9SZXNvdXJjZXMKPDwKL0ZvbnQKPDwKL0YxIDIgMCBSCi9GMiAzIDAgUgovRjMgNCAwIFIKL0Y0IDUgMCBSCi9GNSA2IDAgUgo+';
        document.fileExtension = 'pdf';
        
        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addDocument(document).requestBody;

        System.assertEquals(1, reqBody.documents.size(), 'Expected 1 document instead of ' + reqBody.documents.size());
        System.assertEquals('pdf', reqBody.documents[0].fileExtension, 'Expected file extension to be "pdf"');
        System.assertEquals('Test Document 1', reqBody.documents[0].name, 'Expected document name "Test Document 1"');
    }

    /**
     * @description Validates recipient attributes are set correctly by the 
     * builder for a single recipient
     */
    @isTest
    static void shouldAddSingleRecipientUsingBuilder() {
        OffersDocuSignCreateEnvReqBodyBuild.Recipient prospect = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        prospect.email = 'prospect@test.com';
        prospect.routingOrder = 1;
        prospect.recipientId = '1';
        prospect.name = 'John Smith';
        prospect.signHereAnchorString = '/s1/';
        prospect.dateSignedAnchorString = '/d1/';
        prospect.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addRecipient(prospect).requestBody;

        System.assertEquals(1, reqBody.recipients.signers.size(), 'Expected 1 signer.');
        System.assertEquals('prospect@test.com', reqBody.recipients.signers[0].email, 'Expected signer email "prospect@test.com" instead of ' + reqBody.recipients.signers[0].email);
    }

    /**
     * @description Validates recipient attributes are set correctly by the 
     * builder when there are two recipients
     */
    @isTest
    static void shouldAddTwoRecipientsUsingBuilder() {
        OffersDocuSignCreateEnvReqBodyBuild.Recipient prospect = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        prospect.email = 'prospect@test.com';
        prospect.routingOrder = 1;
        prospect.recipientId = '1';
        prospect.name = 'Morty Smith';
        prospect.signHereAnchorString = '/s1/';
        prospect.dateSignedAnchorString = '/d1/';
        prospect.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild.Recipient guardian = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        guardian.email = 'guardian@test.com';
        guardian.routingOrder = 2;
        guardian.recipientId = '2';
        guardian.name = 'Beth Smith';
        guardian.signHereAnchorString = '/s2/';
        guardian.dateSignedAnchorString = '/d2/';
        guardian.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addRecipient(prospect).addRecipient(guardian).requestBody;

        System.assertEquals(2, reqBody.recipients.signers.size(), 'Expected 2 signers.');
        
        // first recipient
        System.assertEquals('prospect@test.com', reqBody.recipients.signers[0].email, 'Expected signer email "prospect@test.com" instead of ' + reqBody.recipients.signers[0].email);
        System.assertEquals('Morty Smith', reqBody.recipients.signers[0].name, 'Expected signer name "Morty Smith" instead of ' + reqBody.recipients.signers[0].name);

        // second recipient
        System.assertEquals('guardian@test.com', reqBody.recipients.signers[1].email, 'Expected signer email "guardian@test.com" instead of ' + reqBody.recipients.signers[1].email);
        System.assertEquals('Beth Smith', reqBody.recipients.signers[1].name, 'Expected signer name "Beth Smith" instead of ' + reqBody.recipients.signers[1].name);

    }

    /**
     * @description Validates anchor tags are set correctly by the 
     * builder for a single recipient
     */
    @isTest
    static void shouldMatchAnchorStringsOnBuilderForSingleRecipient() {
        OffersDocuSignCreateEnvReqBodyBuild.Recipient prospect = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        prospect.email = 'prospect@test.com';
        prospect.routingOrder = 1;
        prospect.recipientId = '1';
        prospect.name = 'John Smith';
        prospect.signHereAnchorString = '/s1/';
        prospect.dateSignedAnchorString = '/d1/';
        prospect.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addRecipient(prospect).requestBody;

        System.assertEquals('/s1/', reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString, 'Expected signer anchor string "/s1/" instead of ' + reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString);
        System.assertEquals('/d1/', reqBody.recipients.signers[0].tabs.dateSignedTabs[0].anchorString, 'Expected date anchor string "/d1/" instead of ' + reqBody.recipients.signers[0].tabs.dateSignedTabs[0].anchorString);

    }

    /**
     * @description Validates anchor tags are set correctly by the 
     * builder where two recipients are added
     */
    @isTest
    static void shouldMatchAnchorStringsOnBuilderForTwoRecipients() {
        OffersDocuSignCreateEnvReqBodyBuild.Recipient prospect = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        prospect.email = 'prospect@test.com';
        prospect.routingOrder = 1;
        prospect.recipientId = '1';
        prospect.name = 'Morty Smith';
        prospect.signHereAnchorString = '/s1/';
        prospect.dateSignedAnchorString = '/d1/';
        prospect.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild.Recipient guardian = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        guardian.email = 'guardian@test.com';
        guardian.routingOrder = 2;
        guardian.recipientId = '2';
        guardian.name = 'Beth Smith';
        guardian.signHereAnchorString = '/s2/';
        guardian.dateSignedAnchorString = '/d2/';
        guardian.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addRecipient(prospect).addRecipient(guardian).requestBody;
        
        System.assertEquals('/s1/', reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString, 'Expected signer anchor string "/s1/" instead of ' + reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString);
        System.assertEquals('/d1/', reqBody.recipients.signers[0].tabs.dateSignedTabs[0].anchorString, 'Expected date anchor string "/d1/" instead of ' + reqBody.recipients.signers[0].tabs.dateSignedTabs[0].anchorString);
        System.assertEquals('/s2/', reqBody.recipients.signers[1].tabs.signHereTabs[0].anchorString, 'Expected signer anchor string "/s2/" instead of ' + reqBody.recipients.signers[1].tabs.signHereTabs[0].anchorString);
        System.assertEquals('/d2/', reqBody.recipients.signers[1].tabs.dateSignedTabs[0].anchorString, 'Expected date anchor string "/d2/" instead of ' + reqBody.recipients.signers[1].tabs.dateSignedTabs[0].anchorString);

    }

    /**
     * @description Ensures exception is thrown if email subject has not been set
     * Email subject is mandatory for the Envelop Create API payload
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
     */
    @isTest
    static void shouldEnsureExceptionWhenEmailSubjectIsNotSet() {
        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        try {
            DocuSignCreateEnvelopsReqBody reqBody = builder.getResult();
            System.assert(false, 'Expecting email subject to be set before using getResult().');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException as email subject was not set.');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception.');
        }
    }
   
    /**
     * @description Ensures status is set to 'sent' prior to
     * retrieving the request body. 
     * (Note: the only possible values should be 'sent' or created,
     * however 'created' is not currently used)
     * status is mandatory for the Envelop Create API payload
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
     */
    @isTest
    static void shouldEnsureStatusIsSetToSentOnGetResult() {
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Test subject';

        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = 'xyz';
        document.documentName = '123';
        document.fileExtension = 'pdf';
        document.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.addDocument(document).setEmailDetails(emailContent).getResult();
        System.assertEquals('sent', reqBody.status, 'Expected "sent" status instead of ' + reqBody.status);
    }

    /**
     * @description Ensures exception is thrown when a no Document was added and
     * the request body was retrieved
     * documents is mandatory for the Envelop Create API payload
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
     */
    @isTest
    static void shouldThrowExceptionWhenNoDocumentBeenAddedOnGetResult() {
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Test subject';
        try {
            OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
            DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).getResult();
            System.assert(false, 'Expected IllegalArgumentException due to null document');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException due to null document');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception');
        }
    }

    /**
     * @description Verifies GetResult contains the correct Document attributes
     */
    @isTest
    static void shouldGetDocumentAttributesCorrectlyOnGetResult() {
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Test subject';

        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = 'xyz';
        document.documentName = '123 Contract';
        document.fileExtension = 'pdf';
        document.documentId = 15;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).addDocument(document).getResult();
        System.assertEquals('123 Contract', reqBody.documents[0].name, 'Expected documentName to be set to "123 Contract" instead of ' + reqBody.documents[0].name);
        System.assertEquals('xyz', reqBody.documents[0].documentBase64, 'Expected documentBase64 to be set to "xyz" instead of ' + reqBody.documents[0].documentBase64);
        System.assertEquals('pdf', reqBody.documents[0].fileExtension, 'Expected fileExtension to be set to "pdf" instead of ' + reqBody.documents[0].fileExtension);
    }

    /**
     * @description Verifies GetResults contains the correct Recipient
     */
    @isTest
    static void shouldGetRecipientAttribCorrectlyOnGetResult() {
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Test subject';

        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = 'xyz';
        document.documentName = '123 Contract';
        document.fileExtension = 'pdf';
        document.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild.Recipient recipient = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        recipient.documentId = 1;
        recipient.dateSignedAnchorString = '/d1/';
        recipient.signHereAnchorString = '/s1/';
        recipient.email = 'test@test.com';
        recipient.recipientId = '0394002';
        recipient.routingOrder = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).addDocument(document).addRecipient(recipient).getResult();
        System.assertEquals('test@test.com', reqBody.recipients.signers[0].email, 'Expected recipient email "test@test.com" instead of ' + reqBody.recipients.signers[0].email);
    }

    /**
     * @description Verifies GetResults contains the correct anchor tags for the recipient
     */
    @isTest
    static void shouldGetAnchorTagsCorrectlyOnGetResult() {
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = 'Test subject';

        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = 'xyz';
        document.documentName = '123 Contract';
        document.fileExtension = 'pdf';
        document.documentId = 1;

        OffersDocuSignCreateEnvReqBodyBuild.Recipient recipient = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        recipient.documentId = 1;
        recipient.dateSignedAnchorString = '/d1/';
        recipient.signHereAnchorString = '/s1/';
        recipient.email = 'test@test.com';
        recipient.recipientId = '0394002';
        recipient.routingOrder = 1;

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder.setEmailDetails(emailContent).addDocument(document).addRecipient(recipient).getResult();
        System.assertEquals('/s1/', reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString, 'Expected sign tab anchor tag "/s1/" instead of ' + reqBody.recipients.signers[0].tabs.signHereTabs[0].anchorString);
    }

    @isTest
    static void shouldSetBrandId() {
        String brandId = 'brand-123-test';
        OffersDocuSignCreateEnvReqBodyBuild builder = 
            new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = 
            builder.setBrandId(brandId).requestBody;
        System.assertEquals(brandId, reqBody.brandId, 
            'Expected brand id to be set correctly');
    }

    @isTest
    static void shouldSetReminders() {

        OffersDocuSignCreateEnvReqBodyBuild.Reminder reminder = 
            new OffersDocuSignCreateEnvReqBodyBuild.Reminder();
        reminder.reminderDelay = 5;
        reminder.reminderEnabled = true;
        reminder.reminderFrequency = 2;

        OffersDocuSignCreateEnvReqBodyBuild builder = 
            new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = 
            builder.setReminder(reminder).requestBody;

        System.assertEquals('5', reqBody.notification.reminders.reminderDelay, 
            'Expected reminder day to match input');

        System.assertEquals('true', reqBody.notification.reminders.reminderEnabled, 
            'Expected reminder enabled to match input');

        System.assertEquals('2', reqBody.notification.reminders.reminderFrequency, 
            'Expected reminder frequency to match input');
    }
}