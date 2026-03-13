/**
 * @author : Ibrahim Rumi
 * @description : Support class to build applicant emails for Monash Abroad
 * @group : Abroad Outbound
 * @date : 21/07/2024
 * @rev
 * 
 */
public without sharing class AOEmailBuilder {
    @TestVisible
    private List<AO_Program_Applicant__c> programApplicants = new List<AO_Program_Applicant__c>();

    @TestVisible
    private List<AO_Applicant_Email__c> applicantEmails = new List<AO_Applicant_Email__c>();

    @TestVisible
    private String emailSubject;

    @TestVisible
    private String emailBody;

    /**
     * @description - method to set applicant for the builder class
     */
    public AOEmailBuilder setApplicants(AO_Program_Applicant__c ao){
        this.programApplicants.add(ao);
        return this;
    }

    public AOEmailBuilder setApplicants(list<AO_Program_Applicant__c> aolist){
        this.programApplicants = aolist;
        return this;
    }

    /**
     * @description - method to return applicant emails
     */
    public List<AO_Applicant_Email__c> getApplicantEmails(){
        return this.applicantEmails;
    }

    /**
     * @description - method to set email details using email template name
     */
    public AOEmailBuilder setContentbyTemplateName(String templateName){
        EmailTemplate emailTemp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE name = :templateName LIMIT 1];

        if(emailTemp != null){
            this.emailSubject = emailTemp.subject;
            this.emailBody = emailTemp.HtmlValue;
        }

        return this;
    }

    /**
     * @description - method to set email details statically
     */
    public AOEmailBuilder setStaticContent(String subject, String body){
        this.emailSubject = subject;
        this.emailBody = body;
        return this;
    }


    /**
     * @description - private method to fetch the relevant merge data for the program applicants
     */
    private Map<Id,Map<String,Object>> fetchEmailMergeData(list<AO_Program_Applicant__c> palist){

        Set<Id> contactIds = new Set<Id>();
        Set<Id> programIds = new Set<Id>();
        
        Map<String,Object> mergeData = new Map<String,Object>();
        Map<Id,Map<String,Object>> mergeDataMap = new Map<Id,Map<String,Object>>();
        if(!palist.isEmpty()){
            for(AO_Program_Applicant__c pa: palist){
                contactIds.add(pa.AO_Contact__c);
                programIds.add(pa.AO_Program__c);
            }
            
            Map<Id, Contact> contactsById = new Map<Id, Contact>([
                SELECT id,FirstName,LastName,Name,Email,Monash_Email_Address__c,Person_ID__c FROM Contact WHERE Id IN :contactIds
            ]);
            
            Map<Id, AO_Program__c> programsById = new Map<Id, AO_Program__c>([
                SELECT id, Name,AO_Program_Year__c, Terms__c,AO_Program_Type__c, Business_Unit__c ,Start_Date__c,End_Date__c FROM AO_Program__c WHERE Id IN :programIds
            ]);

            for(AO_Program_Applicant__c pa: palist){
                Contact cont = contactsById.get(pa.AO_Contact__c);
                AO_Program__c prgm = programsById.get(pa.AO_Program__c);
            
                mergeData = this.createEmailMergeData(cont, prgm, pa);

                if(mergeDataMap.get(pa.Id) == null)
                {
                    mergeDataMap.put(pa.Id, mergeData);
                }
            }
        }

        return mergeDataMap;
    }

    /**
     * @description - private method to create the merge data per applicant
     */
    private Map<String,Object> createEmailMergeData(Contact con, AO_Program__c prg, AO_Program_Applicant__c prgApp){
        
        Map<String, Object> mergeData = new Map<String, Object>{
            'Contact' => con.getPopulatedFieldsAsMap(),
            'AO_Program__c' => prg.getPopulatedFieldsAsMap(),
            'AO_Program_Applicant__c' => prgApp.getPopulatedFieldsAsMap()
        };
                    
        return mergeData;
    }

    /**
     * @description - method to build the corresponding applicant email records
     */
    public AOEmailBuilder build(){

        Integer subjectMaxSize = 250;
        Integer bodyMaxSize = 4000;

        if(!this.programApplicants.isEmpty()){
            Map<Id,Map<String,Object>> mergedataMap = this.fetchEmailMergeData(this.programApplicants);

            for(AO_Program_Applicant__c pa: this.programApplicants){
                
                if(mergedataMap.containskey(pa.Id)){
                    Map<String,Object> mergeData = mergedataMap.get(pa.Id);

                    HmlTool.Context templateContext = new HmlTool.Context(mergedata);
                    String body = templateContext.render(this.emailBody, false);
                    String subject = templateContext.render(this.emailSubject, false);
                    
                    if(subject.length() > subjectmaxSize ){
                        subject = subject.substring(0, subjectmaxSize);
                    }
                    
                    if(body.length() > bodyMaxSize ){
                        body = body.substring(0, bodyMaxSize);
                    }

                    Object cont = mergeData.get('Contact');
                    Map<String, Object> contactFields = (Map<String, Object>) cont;
                    String recipientEmailAddress = (String) contactFields.get('Email');

                    AO_Applicant_Email__c ae = new AO_Applicant_Email__c(AO_Program_Applicant__c = pa.Id,
                                                                        AO_Email_Body__c = body, 
                                                                        AO_Email_Subject__c = subject, 
                                                                        AO_Contact__c = pa.AO_Contact__c,
                                                                        AO_Recipient_Email_Address__c = recipientEmailAddress);

                    this.applicantEmails.add(ae);
                }
            }
        }
        return this;
    }

}