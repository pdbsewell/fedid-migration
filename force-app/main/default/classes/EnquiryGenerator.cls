/**
 * @author                      Kristian Vegerano
 * @description                 Class for initiating enquiry creation enquiries org-wide
 * @History                     
 *      AUG.08.2018     Kristian Vegerano   -   Created
 */
public class EnquiryGenerator {
    
    /* Generator variables */
    private EnquiryFactory enqFactory;
    
    //Constructor for general enquiries without needing a contact
    public EnquiryGenerator(EnquiryUtil.EnquiryPurpose purpose){
        //Initialize details for the factory
        this.enqFactory = new EnquiryFactory(purpose);
    }
    
    //Constructor for enquiries related to a contact
    public EnquiryGenerator(EnquiryUtil.EnquiryPurpose purpose, Contact relatedContact){
        //Initialize details for the factory
        this.enqFactory = new EnquiryFactory(purpose, relatedContact);
    }
    
    //Constructor for enquiries related to leads
    public EnquiryGenerator(EnquiryUtil.EnquiryPurpose purpose, Contact relatedContact, Lead relatedLead){
        //Initialize details for the factory
        this.enqFactory = new EnquiryFactory(purpose, relatedContact, relatedLead);
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Method for generating an enquiry from a contact
     *  @param          EnquiryPurpose purpose - enum to define what type of enquiry should be created
     */
    public Case generateEnquiry(String subject, String description){
        //Initialize enquiry factory
        
        //Initialize enquiry
        Case enquiry = enqFactory.createEnquiry();
        
        //Assign the subject to the generated enquiry
        enquiry.subject = subject;
        
        //Assign the subject to the generated enquiry
        enquiry.description = description;
        
        //Run processes for the generated enquiry
        //enquiry.runAssignmentRules();
        
        return enquiry;
    }
}