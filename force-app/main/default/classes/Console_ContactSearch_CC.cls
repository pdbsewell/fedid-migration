/**
 * Custom Controller for use in custom service console component.
 * Specifically, the contact search panel that provides for search, create and link to case
 *
 * @author Carl Vescovi, PwC
 * @revision    22/05/2018 - APRivera - DCXCRM-1754 - MobilePhone Field Encryption on certain roles
 * @revision    22/08/2022 - MJC - Applied mobile phone formatting logic, searching on the mobilephone dup field
 *                               - Replaced applicant email with personal email field
 *                               - Added legal first name to the search to cater for preferred first names  
 */
public with sharing class Console_ContactSearch_CC {
    public Console_ContactSearch_CC(){
    }
    
    /** 
     * custom wrapper class used to pass information to the visualforce page 
     * @param fname contact first name filter
     * @param lname contact last name filter
     * @param personId contact person id filter
     * @param email contact system email field filter
     * @param dob contact date of birth field filter
     * @param monashemail contact monash email field filter
     * @param mobile contact custom monash email field filter
     * @param phone contact standard phone field filter
     */
    
    public class inputWrapper {
        public string fname {get; private set;}
        public string lname {get; private set;}
        public string personId {get; private set;}
        public string email {get;private set;}
        public string dob {get; private set;}
        public string monashemail {get; private set;}
        public string mobile {get; private set;}
        public string phone {get; private set;}
        public inputWrapper(){
            this.fname = '';
            this.lname = '';
            this.personId = '';
            this.email = '';
            this.dob = '';
            this.monashemail = '';
            this.mobile = '';
            this.phone = '';
            
        }
    }
    
    
    /** 
     * custom wrapper to return results into the visualforce page
     * @param tooManyResults a boolean to indicate if search results had to be capped
     * @param results list of contact search results
     */
    
    public class resultsWrapper {
        public boolean tooManyResults {get; private set;}
        public list<contact> results {get;private set;}
        public resultsWrapper(boolean tm, list<contact> cList){
            this.tooManyResults = tm;
            this.results = cList;
        }
    }
    
    /** a helper class for use by test methods, to simplify access to custom classes */
    
    public string testGetResults(string fn, string ln){ // used by test class to access private methods 
        
        inputWrapper wr = new inputWrapper();
        wr.fname = fn;
        wr.lname = ln;
        if(Test.isRunningTest()){ return getResults(wr); } else { return ''; }
    }
    
    /** a helper class for use by test methods, to simplify access to custom classes */
    
    
    public string testAddEnquiry(string fn, string ln, string em){ // used by test class to access private methods 
        
        inputWrapper wr = new inputWrapper();
        wr.fname = fn;
        wr.lname = ln;
        wr.email = em;
        if(Test.isRunningTest()){ return addEnquiry(wr); } else { return ''; }
    }
    
    /** 
     * used to clean inbound text strings, to prevent script injection to dynamic SOQL
     * @param s inbound raw string
     * @return string that has had single quotes escaped
     */
    
    private static string cleanString(String s){
        return (s == null) ? '' : String.escapeSingleQuotes(s);
    }
    
    
    /**
     * remote action to add a contact using filter fields to pre-populate where possible, 
     * then add a new enquiry and finally link it to new contact
     * if all ok, then will return caseId
     * if error, then will return string 'Error: ' + err message to place in feedback panel
     *
     * @param wrapper wrapper class from vf page, containing filter fields
     * @return string containing either a case Id or an error message
     */
    
    @RemoteAction
    public static string addEnquiry(inputWrapper wrapper){
    	
        string fname = cleanString(wrapper.fname).tolowercase().capitalize();
        string lname = cleanString(wrapper.lname).tolowercase().capitalize();
        string em = cleanString(wrapper.email).tolowercase();
        string dobString = cleanString(wrapper.dob);
        date dob = (dobString > '') ? Date.valueOf(dobString) : null;
        string mob = cleanString(wrapper.mobile);
        string ph = cleanString(wrapper.phone);
        
        // if have minimum required to create a contact, do so and then proceed to adding an enquiry to it
        // using user context to insert rather than via services layer to ensure we respect user perms
        case cse = new case();
        SavePoint sp = Database.setSavepoint();
        if(fname > '' && lname > '' && (em > '' || mob > '' || ph > '')){
            contact c = new contact( firstname = fname,
                                     lastname = lname,
                                     email = em,
                                     birthdate = dob,
                                     mobilePhone = mob,
                                     Phone = ph);
            
        	
            try{
                insert c;
            } catch (exception ex){
                logUtilityException.logException('Class', 'Insert Contact', ex, 'Console_ContactSearch_CC', 'Error');
                return 'Error: unable to create a new contact with data provided. Try again, or reset form and continue.';
            }
            // inserted, so create a new enquiry and link contact
            cse.contactId =  c.id;
           
        } 
        try{
             insert cse;
             return (String)cse.id;
        } catch(exception ex){
             Database.rollback(sp); // remove contact just inserted
             return 'Error: unable to create an enquiry. Try again, or use add enquiry button from list view.';
        }
        
    }
    
    
    /**
     * remote action to retrieve contact records that meet filter criteria, 
     * <p>
     * builds a dynamic SOQL string based on the filter criteria passed into the method 
     *
     * @param wrapper wrapper class from vf page, containing filter fields
     * @return string serialised list of contact results
     */
    @RemoteAction
    public static string getResults(inputWrapper wrapper){ // JSON string passed in
        list<contact> results = new list<contact>();
        boolean tooMany = false;
        
        // process inputs to protect for dynamic query eg remove escape characters
        
        string fname = cleanString(wrapper.fname);
        string lname = cleanString(wrapper.lname);
        string personId = cleanString(wrapper.personId);
        string em = cleanString(wrapper.email);
        string dobString = cleanString(wrapper.dob);
        date dob = (dobString > '') ? Date.valueOf(dobString) : null;
        string monemail = cleanString(wrapper.monashemail);
        string mob = cleanString(wrapper.mobile);
        string ph = cleanstring(wrapper.phone);
        
        // build query - include filters
        
        string qry = 'select id,Person_ID__c ,birthdate, monash_email_address__c, firstname,lastname,email,mobilePhone, Masked_Mobile__c,phone from Contact';
        // consider filters
        List<string> filters = new List<string>();
        if(fname > '' && lname == '')  filters.add('firstname like \''+fname+'%\' or first_name__c like \''+fname+'%\'');  // includes legal first name
        if(lname > '' && fname == '')  filters.add('lastname like \''+lname+'%\'');
        if(lname > '' && fname > '') filters.add('((firstname like \''+fname+'%\' or first_name__c like \''+fname+'%\') and lastname like \''+lname+'%\')'); // includes legal first name
        
        if(personId > '') filters.add('Person_ID__c =\''+ personId + '\'');
        
        if(em > '') filters.add('(email like \''+em + '%\' or Personal_Email__c like \'' + em + '%\')');

        
        if(monemail > '') filters.add('monash_email_address__c = \''+monemail+'\'');
        if(mob > '') filters.add('mobilephone_dup__c = \''+ phoneservices.rawFormatPhone(mob) + '\'');
        if(ph > '') filters.add('phone =\'' + ph + '\'');
        
        qry += ' where (';
        for(integer i=0; i<filters.size()-1; i++){
            qry += filters[i] + ' or ';
        }
        qry += filters[filters.size()-1] + ')';
        if(dobString > '') qry += ' and BirthDate =:dob '; // make this a must have if is provided
        if(lname > '') qry += ' order by lastname ASC ';
        qry += ' limit 21';
        
        try{
            results = Database.query(qry);
            if(results.size() > 20){
                tooMany = true;
                results.remove(20);
            }
            
        } catch (exception e){
            Exlog.write('Console_ContactSearch_CC','getResults','dynamic query','query issue. qry ='+qry+', error is '+e.getMessage());
        }
         
        resultsWrapper rw = new resultsWrapper(tooMany, results);
        return Json.serialize(rw);
        
    }
}