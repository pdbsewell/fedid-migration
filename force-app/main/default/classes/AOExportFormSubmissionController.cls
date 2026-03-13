/**
 * @author : [Babyshark]
 * @description : Report and Export Form Submission Data for Admins/Faculty
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
public with sharing class AOExportFormSubmissionController {
    /**
     * @description - Provide Programs details based upon year 
     * @revision    
     */
    @AuraEnabled(cacheable=true)
    public static List<AO_Program__c> getPrograms(String year){
        return [SELECT Id, Name FROM AO_Program__c WHERE AO_Program_Year__c=:year];
    }
    /**
     * @description - Query and Return Forms associated to Programs selected
     * @revision    
     */
    @AuraEnabled(cacheable=true)
    public static List<AO_Program_Form_Map__c> getAssociatedForms(String programId){
        return [SELECT Id, Name, AO_Form__c, AO_Form__r.AO_Form_Display_Name__c FROM AO_Program_Form_Map__c WHERE AO_Program__c =: programId];
    }
    /**
     * @description - Wrapper for custom datatable to deisplay all the fields stored as JSON
     * @revision    
     */
    public class CustomDT{
        @AuraEnabled public String keyField= 'Id';
        @AuraEnabled public List<Map<String,Object>> data = new List<Map<String,Object>>();
        @AuraEnabled public List<Column> columns = new List<Column>{};
        @AuraEnabled public String error;
        //Wrapper for Unique key field on data row
        public CustomDT setKeyField(String keyField){
            this.keyField = keyField;
            return this;
        }
        //Wrapper for individual columns of datatable
        public CustomDT addColumn(Column col){
            this.columns.add(col);
            return this;
        }
        //Adds new row in data table
        public CustomDT addRow(Map<String,Object> row){
            this.data.add(row);
            return this;
        }
        //Populates Data in individual rows of datatable
        public CustomDT setData(List<Map<String,Object>> data){
            this.data = data;
            return this;
        }
    }
    //Wrapper for individual Column and their properties
    public class Column{
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Integer initialWidth;
        @AuraEnabled public boolean sortable;
        
        public Column(String label, String fieldName){
            this.label = label;
            this.fieldName =  fieldName;
            this.initialWidth = 130;
            this.sortable = true;
        }
        public Column(String label, String fieldName, String type){
            this.label = label;
            this.fieldName =  fieldName;
            this.type = type;
            this.initialWidth = 130;
            this.sortable = true;
        }
    }
    /**
     * @description - Search Submission based upon below params. It performs below actions
     * 1.   Split year, program, form, status and dates from search key inout parameter
     * 2.   Construct a query based upon above filters on Form Submission record
     * 3.   Returns all the necessary Submission record in a custom datatable format 
     * @param - searchKey(Map of String, Object)
     * @revision    
     */
    @AuraEnabled
    public static CustomDT searchSubmissions(String searchKey){//(Id programId, Id formId){//, Date fromDate, Date toDate){
        try {
            Map<String,Object> searchWrap = (Map<String,Object>) JSON.deserializeUntyped(searchKey);
            String selectedYear = String.valueOf(searchWrap.get('selectedYear'));
            String programId = String.valueOf(searchWrap.get('programId'));
            String formId = String.valueOf(searchWrap.get('formId'));
            String status = String.valueOf(searchWrap.get('status'));
            Date fromDate = searchWrap.get('fromDate')!= null ? Date.valueOf(String.valueOf(searchWrap.get('fromDate'))) : null;
            Date toDate = searchWrap.get('toDate')!= null ? Date.valueOf(String.valueOf(searchWrap.get('toDate'))) : null;

            String whereClause = 'WHERE AO_Program_Form_Map__r.AO_Program__c =:programId AND AO_Program_Form_Map__r.AO_Form__c=:formId';
            
            if(String.isNotBlank(status)){
                whereClause += ' AND AO_Program_Applicant__r.AO_Application_Status__c =:status';
            }
            if(fromDate != null){
                whereClause += ' AND AO_Submitted_Date__c >= :fromDate';
            }
            if(toDate != null){
                whereClause += ' AND AO_Submitted_Date__c <= :toDate';
            }
            //Construct Query on Form Submission from input provided in parameters
            String query = 'SELECT Id, Name, AO_Program_Applicant__r.AO_Application_Status__c, AO_Response_Json__c FROM AO_Form_Submission__c ' + whereClause + ' Order By LastModifiedDate DESC';
            CustomDT newDt = new CustomDT();
            Set<String> uniqueColumns = new Set<String>();
            newDt.setKeyField('Id');
            newDt.addColumn(new Column('Link', 'Link', 'url'));
            newDt.addColumn(new Column('Name', 'Name')); 
            newDt.addColumn(new Column('Id','Id'));
            newDt.addColumn(new Column('Application Status','Application Status'));
            List<AO_Form_Submission__c> formSubs = new List<AO_Form_Submission__c>();
            
            formSubs = Database.query(query);//[SELECT Id, Name, AO_Response_Json__c FROM AO_Form_Submission__c Order By LastModifiedDate DESC];
            if(!formSubs.isEmpty()){
                for(AO_Form_Submission__c aoSub : formSubs){
                    Map<string,Object> objRow =  new Map<string,Object>();
                    if(String.isNotBlank(aoSub.AO_Response_Json__c)){
                        //Deserialise the Form Submission Objet repsonse in List of Object format
                        List<Object> individualResponseList = (List<Object>) JSON.deserializeUntyped(aoSub.AO_Response_Json__c);
                        for(Object obj : individualResponseList){
                            //Populates the additional rows from calculated fields
                            objRow.put('Id', aoSub.Id);
                            objRow.put('Link', URL.getOrgDomainURL().toExternalForm() + '/' + aoSub.Id);
                            objRow.put('Name', aoSub.Name);
                            objRow.put('Application Status', aoSub.AO_Program_Applicant__r.AO_Application_Status__c);
                            Map<String, Object> answer = (Map<String, Object>) obj;
                            if(!answer.isEmpty()){
                                String elemType = (String)answer.get('type');
                                //Construct columns for datatable based upon returned submissions
                                if(!uniqueColumns.contains(String.valueOf(answer.get('label')))){
                                    uniqueColumns.add(String.valueOf(answer.get('label')));
                                    
                                    if(elemType == 'email') {
                                        newDt.addColumn(new Column(String.valueOf(answer.get('label')), String.valueOf(answer.get('label')), 'email'));  
                                    }
                                    else if(elemType == 'checkbox') {
                                        newDt.addColumn(new Column(String.valueOf(answer.get('label')), String.valueOf(answer.get('label')), 'boolean'));   
                                    }else{
                                        newDt.addColumn(new Column(String.valueOf(answer.get('label')), String.valueOf(answer.get('label'))));
                                    }
                                }
                                //In case of file upload, display file name rather that object type
                                if(elemType == 'file upload') {
                                    List<Object> files = (List<Object>)answer.get('value');
                                    String[] fileNames = new String[0];
                                    if(files!= null && !files.isEmpty()){
                                        for(Object file :files) {
                                            Map<String,Object> fileMap = (Map<String,Object>)file;
                                            fileNames.add((String)fileMap.get('name'));
                                        }
                                        objRow.put(String.valueOf(answer.get('label')), String.join(fileNames, ' | '));
                                    }
                                }else{
                                    //Otherwise display the value stored against field
                                    String valueForLabel = String.valueOf(answer.get('value'));
                                    if(objRow.containsKey(String.valueOf(answer.get('label'))) && String.IsNotBlank(String.valueOf(objRow.get(String.valueOf(answer.get('label')))))){
                                        if(String.isNotBlank(valueForLabel)){
                                            valueForLabel += ';' + objRow.get(String.valueOf(answer.get('label')));
                                        }else{
                                            valueForLabel = (String)objRow.get(String.valueOf(answer.get('label')));
                                        }
                                    }
                                    valueForLabel = valueForLabel == null ? valueForLabel : valueForLabel.replaceAll(',',';');
                                    objRow.put(String.valueOf(answer.get('label')), valueForLabel);
                                }
                            }
                        }
                        //Add above constrtucted individual rows to datatable
                        newDt.addRow(objRow);
                    }
                    
                }
                
            }
            else{
                //No Submission found based upon input provided
                newDt.error ='No Submissions found for selected Form';
            }
            return newDt;
            
        } catch (Exception e) {
            nebula.logger.exception(e.getMessage(), e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}