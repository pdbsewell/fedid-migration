/**
 * Custom Controller for use in custom service console component.
 * Specifically, the component that prompts user for presets information
 *
 * @author Carl Vescovi, PwC
 */
public with sharing class Console_MyInformation_CCv2 {

    public user usr {get; private set;}
    public boolean inputRequired {get; private set;}
    public user newUser {get;set;}
    
    /** custom controller instantiation */
    public Console_MyInformation_CCv2(){
    	usr = UserServices.contextUser;                           
    	inputRequired = (usr.My_Information_LastUpdate__c < date.today() || usr.My_Information_LastUpdate__c == null);
        newUser = new User(id = usr.id, My_Information_LastUpdate__c = date.today());
        if(!inputRequired){
            newUser = usr;
        }
        
        //Set not set as default
        if(newUser.Enquiry_Role__c == null){
            newUser.Enquiry_Role__c = '- Not Set -';
        }
    }
    
    // this is called to save selections
    /** stores location, queue and role inputs entered via custom console component vf page */
    public PageReference storeInputs(){
        if(newUser.Location__c > '' 
           && newUser.Queue__c > ''
           && newUser.Enquiry_Role__c > '' ){
            newUser.My_Information_LastUpdate__c = date.today();
               UserServices.updateUsers(new List<user>{ newUser });
            inputRequired = false;
        }
        
        return null;
    }
    
    /** retrieves list of location options for user 
     * @return list of locations
     */
    public List<SelectOption> locations{
        get{
            List<SelectOption> options = new List<SelectOption>();
        	Schema.DescribeFieldResult fieldResult = User.Location__c.getDescribe();
   			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        	for( Schema.PicklistEntry f : ple) options.add(new selectOption(f.getvalue(), f.getLabel()));
            return options;
		}
    }
    
    /** retrieves list of queue options for user 
     * @return list of queues
     */
    public List<SelectOption> queues{
        get{
            List<SelectOption> options = new List<SelectOption>();
        	Schema.DescribeFieldResult fieldResult = User.Queue__c.getDescribe();
   			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        	for( Schema.PicklistEntry f : ple) options.add(new selectOption(f.getvalue(), f.getLabel()));
            return options;
		}
    }
    
    /** retrieves list of role options for user 
     * @return list of roles
     */
    public List<SelectOption> enquiryRoles{
        get{
            List<SelectOption> options = new List<SelectOption>();
        	Schema.DescribeFieldResult fieldResult = User.Enquiry_Role__c.getDescribe();
   			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        	for( Schema.PicklistEntry f : ple) options.add(new selectOption(f.getvalue(), f.getLabel()));
            return options;
		}
    }
}