@isTest
public class CopadoResultTriggerService_Test {
    
    public static copado__Result__c resultObj;
    private static final String JOB_STEP_NAME = CopadoResultTriggerService.JOB_STEP_NAME;
    private static final String TYPE_TEST = 'Test';
    private static final String STATUS_SUCCESS = 'Success';
    
    private static final String SAMPLE_XML_CONTENT = '<?xml version="1.0" encoding="utf-8"?> <CxXMLResults  DeepLink="https://codereview.monash.edu/CxWebClient/ViewerMain.aspx?scanid=1006596&amp;projectid=201"> <Query categories="PCI" name="FLS_Update_Partial" > <Result DeepLink="https://codereview.monash.edu/CxWebClient/ViewerMain.aspx?scanid=1006596&amp;projectid=201&amp;pathid=2" SeverityIndex="2" > <Path> <PathNode> <FileName>force-app/main/default/classes/AccountOperations.cls</FileName> <Line>5</Line> </PathNode> </Path> </Result> </Query> </CxXMLResults>';
    
    @testSetup static void setupData(){
        copado__User_Story__c userStoryObj = new copado__User_Story__c();
        insert userStoryObj;
        copado__Org__c org = new copado__Org__c();
        insert org;
        copado__Git_Org_Commit__c orgCommit = new copado__Git_Org_Commit__c(copado__Org__c = org.Id);
        insert orgCommit;
        copado__User_Story_Commit__c  userStoryCmtObj = new copado__User_Story_Commit__c(copado__User_Story__c = userStoryObj.Id, copado__Snapshot_Commit__c = orgCommit.Id);
        insert userStoryCmtObj;
        copado__JobExecution__c jobexecution = new copado__JobExecution__c(copado__UserStoryCommit__c = userStoryCmtObj.Id);
        insert jobexecution;
        copado__JobStep__c jobstep = new copado__JobStep__c(Name = JOB_STEP_NAME, copado__JobExecution__c = jobexecution.Id, copado__Type__c = TYPE_TEST);
        insert jobstep;
        resultObj = new copado__Result__c(copado__JobStep__c = jobstep.Id, copado__Job_Type__c = TYPE_TEST);
        insert resultObj;
        ContentVersion contentVersion = new ContentVersion(
            Title='File Name',
            PathOnClient='sample.xml',
            VersionData=Blob.valueOf(SAMPLE_XML_CONTENT),
            Origin='H'
        );
        insert contentVersion;
        ContentDocumentLink cdl=new ContentDocumentLink();
        cdl.LinkedEntityId=resultObj.Id;
        cdl.contentdocumentid = [select contentdocumentid from contentversion where id =: contentVersion.id].contentdocumentid;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';  
        Insert cdl;
    }
    @isTest
    public static void testProcessCheckmarxResult(){
        resultObj = getResultRecord();
        resultObj.copado__Status__c = STATUS_SUCCESS;
        update resultObj;
    }
    
    private static copado__Result__c getResultRecord(){
        return [SELECT Id, copado__Status__c FROM copado__Result__c LIMIT 1];
    }
}