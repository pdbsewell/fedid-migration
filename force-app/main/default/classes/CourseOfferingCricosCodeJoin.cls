/**
 * @description Class to transform Course Offering data so that the course 
 * offering record has CRICOS code (if the CRICOS exists)
 * @group Course Offering
 */
public inherited sharing class CourseOfferingCricosCodeJoin 
        implements CourseOfferingTransform {
    
    private CricosCodeSelector cricosCodeSelector;

    /**
     * @description Constructor to set class dependencies
     * @param CricosCodeSelector The CricosCodeSelector dependency
     */
    public CourseOfferingCricosCodeJoin(CricosCodeSelector cricosCodeSelector) {
        this.cricosCodeSelector = cricosCodeSelector;
    }

    /**
     * @description Applies data transformation to populate the CRICOS code if 
     * a match CRICOS code exists in Salesforce. This method takes the parameter
     *  as a pass by value (not pass by reference).
     * @param courseOfferings List of Course Offering records to be transformed
     */
    public void transform(List<Course_Offering__c> courseOfferings) {

        // we can't be sure course if populated on the course offering record
        // because that gets populated by an Apex trigger
        // to ensure this works - we use course_code + version number to match
        // this will be used to identify the course

        Map<String, Course_Offering__c> courseOfferingsByCourseCode = 
            new Map<String, Course_Offering__c>();
        
        for (Course_Offering__c courseOffering : courseOfferings){
            if (String.isNotBlank(extractCourseCode(courseOffering))) {
                courseOfferingsByCourseCode.put(extractCourseCode(courseOffering), courseOffering);
            }
        }

        // query all related CRICOS Codes
        List<CRICOS_Code__c> relatedCricosCodes = 
            this.cricosCodeSelector.selectByCourseVersionKeyAndType(
                courseOfferingsByCourseCode.keySet(), 'CRICOS'
            );
        Map<String, String> cricosCodeByCourseVersionKey = new Map<String, String>();
        Map<String, String> cricosCodeByCourseVersionKeyAndUnitSet = new Map<String, String>();

        for (CRICOS_Code__c cricosCode : relatedCricosCodes) {
            if (cricosCode.Unit_Set__c == null) {
                cricosCodeByCourseVersionKey.put(cricosCode.Course_Version_Key__c, cricosCode.Name);
            } else {
                cricosCodeByCourseVersionKeyAndUnitSet.put(
                    cricosCode.Course_Version_Key__c + '_' + cricosCode.Unit_Set__r.Name, 
                    cricosCode.Name
                );
            }
        }

        for (Course_Offering__c courseOffering : courseOfferings){
            /*
            If Course Offering Course and Unit Set != Blank, 
            Return CRICOS code with the matching Course + Unit Set
            
            If Course Offering Course and Unit Set != Blank AND CRICOS code 
            record's Unit Set = Blank, return the CRICOS code with the matching Course
            
            If Course Offering Course != Blank and Unit Set = Blank, 
            Return CRICOS code with the matching Course
            */
            if (String.isNotBlank(courseOffering.Unit_Set_Code__c) && 
                    cricosCodeByCourseVersionKeyAndUnitSet.containsKey(
                        extractCourseCodeAndUnitSet(courseOffering))) {
                courseOffering.Cricos_Code__c = 
                    cricosCodeByCourseVersionKeyAndUnitSet.get(
                        extractCourseCodeAndUnitSet(courseOffering)
                    );
            } else {
                if (cricosCodeByCourseVersionKey.containsKey(extractCourseCode(courseOffering))) {
                    courseOffering.Cricos_Code__c = 
                        cricosCodeByCourseVersionKey.get(
                            extractCourseCode(courseOffering)
                        );
                }
            }
        
        }

    }

    private String extractCourseCode(Course_Offering__c courseOffering) {
        String courseCode = '';
        if (String.isNotBlank(courseOffering.Course_Code__c) 
                && courseOffering.Course_Version_Number__c != null) {
            courseCode = courseOffering.Course_Code__c 
                + '_' + Integer.valueOf(courseOffering.Course_Version_Number__c);
        }
        return courseCode;
    }

    private String extractCourseCodeAndUnitSet(Course_Offering__c courseOffering) {
        return extractCourseCode(courseOffering) + '_' 
            + courseOffering.Unit_Set_Code__c;
    }

}