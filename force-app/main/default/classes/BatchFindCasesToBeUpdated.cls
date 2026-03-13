global class BatchFindCasesToBeUpdated implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    public String query;
    public String csv = 'Id,CaseNumber,Status,RecordType,LastmodifiedDate,LastEmailMessageDate,LastCaseStatusChange\n'; 
    global database.querylocator start(Database.BatchableContext BC)
    {
        try {
            return Database.getQueryLocator(query);
        }
        catch(Exception e) {  
            return null;         
        }
    }    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try {
            List<case> caseList=(List<case>)scope;
            for(Case c: caseList)
            {
                if(c.emailmessages.size()==0) {
                    continue;
                }
                else if(c.emailmessages.size()>0 && c.Histories.size()==0) {
                    csv += c.id + ',' + c.CaseNumber.escapeCsv() + ',' + c.Status + ',' + c.recordtype.developername + ',' + c.lastmodifieddate + ',' + c.emailmessages[0].MessageDate + ',' + '' + '\n';       
                }
                else if(c.emailmessages.size()>0 && c.Histories.size()>0){
                    if(c.emailmessages[0].MessageDate>c.Histories[0].createdDate) {
                        csv += c.id + ',' + c.CaseNumber.escapeCsv() + ',' + c.Status.escapeCsv() + ',' + c.recordtype.developername.escapeCsv() + ',' + c.lastmodifieddate + ',' + c.emailmessages[0].MessageDate + ',' + c.Histories[0].createdDate + '\n';                               
                    }
                }
            }
        }
        catch (Exception e) {
        }
    }   
    global void finish(Database.BatchableContext BC) {
        ContentVersion file = new ContentVersion(       
        title = 'case.csv',       
        versionData = Blob.valueOf( csv ),        
        pathOnClient = '/case.csv'      
        );              
        insert file; 
        System.debug('File generated is ' +  file );
    }
    global void execute(SchedulableContext sc) {
        BatchFindCasesToBeUpdated  batchObj = new  BatchFindCasesToBeUpdated (); 
        batchObj.query='select id,casenumber,status,lastmodifieddate,case.recordtype.developername,(SELECT CaseId,Field,createdDate,id FROM Histories where field=\'Status\' order by createdDate desc limit 1),(select id,MessageDate,Incoming from emailmessages where Incoming=true order by MessageDate desc limit 1) from case where status in (\'Solved\',\'Awaiting Customer Feedback\',\'Pending Investigation\',\'Referred Off-System\',\'Referred by Phone\') and case.recordtype.developername=\'Monash_Connect_Enquiry\'';
        ID batchprocessidOpp = Database.executeBatch(batchObj,100);
    }
}