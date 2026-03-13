/*
 * @author PwC
 * @description custom controller to facilitate QFlow popping a tab  in service console
 * complete change in Qflow process flow since UniCRM v1, so now no new case popped by default.
 * checks for contact, if exists then pop contact in new primary tab, otherwise pop a contact search panel.
 * in addition, timestamps are now on URL rather than requiring a separate callout - logic adjusted to reflect this.
*/


public with sharing class QFlowContact_CC {
    
    public string cid {get; private set;}
    
    public QFlowContact_CC(){
        // replaces original QFlow logic of case creation then redirect
        // now, we look for a contact match and pop as primary tab, otherwise straight to contact search page
        cid = '';
        string studentId = (ApexPages.currentPage().getParameters().containsKey('StudentId')) ? ApexPages.currentPage().getParameters().get('StudentId') : '';
        
        // now check whether we have an contact to link to since have been passed a student id
        
        if(studentId > ''){
            if(studentId.length()>8) studentId = studentId.left(8); // Qflow appends characters to Id sometimes, so only want to compare to first 8
            try{
                cid = [select id,
                        		firstname,
                        		lastname 
                        		from contact 
                        		where Person_Id__c = :studentId limit 1].id;
                
            } catch (exception e){
                // no match, so will redirect to a search page
            }
        }
        
        
        

    }
    
    
    
}