/*******************************************************************************
* @author       Sethu Venna
* @date         18/03/2025
* @description  invoke callista interface v1/admissions/sms/documents to send scores
* @revision     18/03/2025 - Sethu Venna - Created
*******************************************************************************/
public class ATARSendScoreToCallistaService extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String INTERFACE_NAME = 'IP14_ATAR_Score_Callista_Integration';


    public Contact_Qualification__c contactQualificationRec;

    /**
     * @author      Sethu Venna
     * @description Constructor
     * @param       contactQualificationRec
     * @revision    18/03/2025 - Initial Version
     */
    public ATARSendScoreToCallistaService (
        Contact_Qualification__c contactQualificationRec
    ) 
    {
        this.doInit(INTERFACE_NAME);
        this.contactQualificationRec = contactQualificationRec;
    }

    /**
     * @author      Sethu Venna
     * @description creates request body for the call out
     * @revision    18/03/2025 - Initial Version
     */
    public void createRequestBody()
    { 
        try 
        {
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            Contact conRec = [SELECT Id, Person_ID__c  
                              FROM Contact 
                              WHERE Id = :contactQualificationRec.Contact__c];
            if(conRec.Person_ID__c != null) {
                urlReplaceKeyValuePairs.put('{personId}', conRec.Person_ID__c);
                this.constructEndPoint(urlReplaceKeyValuePairs); 
            
                AtarIntegrationJSONClass reqJSON = new AtarIntegrationJSONClass();
                AtarIntegrationJSONClass.Cls_qualifications quals = new AtarIntegrationJSONClass.Cls_qualifications();
                quals.verificationStatus = contactQualificationRec.Verification_Status__c != null ? 
                                            contactQualificationRec.Verification_Status__c.toUpperCase() : 
                                            contactQualificationRec.Verification_Status__c;
                quals.statusKey = 'UNCOMPLETED';
                if(contactQualificationRec.Year_of_Completion__c != null) {
                    quals.statusKey = 'COMPLETED';
                    quals.conferredYear = Integer.valueOf(contactQualificationRec.Year_of_Completion__c);
                }
                AtarIntegrationJSONClass.Cls_score score = new AtarIntegrationJSONClass.Cls_score();
                score.value = (contactQualificationRec.Score__c != null) ? Decimal.valueOf(contactQualificationRec.Score__c) : 0.0;
                quals.score = score;
                AtarIntegrationJSONClass.Cls_institution institution = new AtarIntegrationJSONClass.Cls_institution();
                if(contactQualificationRec.Institution_Code__c != null) {
                    institution.institutionCode = contactQualificationRec.Institution_Code__c;
                }
                else if(contactQualificationRec.Institution_Name__c != null) {
                    institution.institutionName = contactQualificationRec.Institution_Name__c.toUpperCase();
                } else if (contactQualificationRec.Other_Institution__c != null){
                    institution.institutionName = contactQualificationRec.Other_Institution__c.toUpperCase();
                }
                quals.institution = institution;
                AtarIntegrationJSONClass.Cls_type type = new AtarIntegrationJSONClass.Cls_type();
                type.type = 'Secondary Education';
                Qualification__c qualRec = [SELECT State__c, Callista_Code__c 
                                            FROM Qualification__c 
                                            WHERE Id =: contactQualificationRec.Qualification__c];

                type.state = (qualRec.State__c != null) ? qualRec.State__c : contactQualificationRec.State__c;
                type.smsQualificationCode = qualRec.Callista_Code__c;
                quals.type = type;
                reqJSON.qualifications = quals;
                this.jsonRequest = reqJson;
            }
        }
        catch (Exception ex) 
        {
            Nebula.Logger.error(ex.getMessage(), ex).addtag(ATARIntegrationQueuable.LOG_TAG);
        }
    }

    /**
     * @author      Sethu Venna
     * @description Read the web service call response & update fields on the Contact Document
     *              records after the call out
     * @revision    18/03/2025 - Initial Version
    */
    public void handleResponse()
    {
        try 
        {
            if(jsonRequest != null)
            {
                Nebula.Logger.info('Response from ATARSendScoreToCallistaService: '+String.valueOf(this.httpResponseCode)+' for Contact Qual reccord: '+contactQualificationRec.Id).addtag(ATARIntegrationQueuable.LOG_TAG);
            }
        }
        catch (Exception ex) 
        {
            Nebula.Logger.error(ex.getMessage(), ex).addtag(ATARIntegrationQueuable.LOG_TAG);
        }
    }
}