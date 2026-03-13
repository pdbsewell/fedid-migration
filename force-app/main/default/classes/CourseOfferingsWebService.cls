/**
* @description       : Rest API return list of course offerings.
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 06-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
* @last modified by  : SMendu - 26-04-2024 - Updated for populating noOfRecords
**/
@RestResource(urlMapping='/v2/CourseOfferingsWebService/*')
global with sharing class CourseOfferingsWebService {
    
    /**
    * @description Get Offered Course
    * @author rajesh.punjabi@monash.edu | 06-02-2024 
    **/
    @HttpGet
    global static void getOfferedCourses() {
        
        RestRequest oRestRequest = RestContext.request;
        
        CourseOfferingsWSRequest.Courserequest oCORequest = new CourseOfferingsWSRequest.Courserequest();
        CourseOfferingsResponseWrapper CORespoWrapper = new CourseOfferingsResponseWrapper();
        
        try{

            oCORequest = (CourseOfferingsWSRequest.Courserequest) JSON.deserialize(JSON.serialize(oRestRequest.params), CourseOfferingsWSRequest.Courserequest.class);
            List<Course_Offering__c> lstCourseOffering = new List<Course_Offering__c>();
            List<Course_Offering__c> totalCourseOfferingsNum = new List<Course_Offering__c>();
            
            //.. Validate inputs
            String sMissingParam = '';
            
            oCORequest.pageSize = (String.isBlank(oCORequest.pageSize)? '2000' : oCORequest.pageSize);
            oCORequest.pageOffset = (String.isBlank(oCORequest.pageOffset)? '0' : oCORequest.pageOffset);
            
            sMissingParam += (String.isBlank(oCORequest.courseYear)? 'courseYear' : '');
            sMissingParam += (String.isBlank(oCORequest.campusCountry)? 'campusCountry' : '');
            
            if(!String.isBlank(sMissingParam)){
                CORespoWrapper.success = 'false';
                CORespoWrapper.description = 'Required Parameter(s) {'+sMissingParam+'} is/are missing';
                CORespoWrapper.error = 'Missing Parameter(s)';
                CORespoWrapper.courses = null;
            }
            else{
            	lstCourseOffering = CourseOfferingsService.getCourseOfferings(oCORequest, true);     
                totalCourseOfferingsNum = CourseOfferingsService.getCourseOfferings(oCORequest, false);       
            }
            if(lstCourseOffering.size() > 0 && String.isBlank(sMissingParam)){
                CORespoWrapper.success = 'true';
                CORespoWrapper.description = '';
                CORespoWrapper.error = '';
                CORespoWrapper.courses = lstCourseOffering;
				CORespoWrapper.noOfRecords = totalCourseOfferingsNum.size();  
                CORespoWrapper.pageSize = oCORequest.pageSize;
                CORespoWrapper.pageOffset = oCORequest.pageOffset;
            }
            else if(lstCourseOffering.size() < 1 && String.isBlank(sMissingParam)){
                CORespoWrapper.success = 'true';
                CORespoWrapper.description = 'No record found.';
                CORespoWrapper.error = '';
                CORespoWrapper.courses = null;
                CORespoWrapper.noOfRecords = totalCourseOfferingsNum.size();  
                CORespoWrapper.pageSize = oCORequest.pageSize;
                CORespoWrapper.pageOffset = oCORequest.pageOffset;
            }                                                                              
            
            //Set return type to JSON
            RestContext.response.addHeader('Content-Type', 'application/json');
            
            //Return FAQ data
            String responseJSON = JSON.serializePretty(CORespoWrapper);
            
            //Set return type to JSON
            RestContext.response.responseBody = Blob.valueOf(responseJSON);
        }
        catch(Exception ex){
            CORespoWrapper.error = 'Course Offerings Exception';
            CORespoWrapper.description = ex.getMessage();
            CORespoWrapper.success = 'false';
            CORespoWrapper.courses = null;
            Nebula.Logger.error('Exception Error'+ex.getMessage()+ex.getLineNumber());
            Nebula.Logger.saveLog();
        }
    }
}