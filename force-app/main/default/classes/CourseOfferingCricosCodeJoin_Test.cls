/**
 * @description Test class for CourseOfferingCricosCodeJoin
 */
@isTest(isParallel=true)
public class CourseOfferingCricosCodeJoin_Test {

    private static final CricosCodeSelector CricosCodeSelectorMock = 
        (CricosCodeSelector) Test.createStub(
            CricosCodeSelector.class, new CricosCodeSelectorMock()
        );

    @isTest
    static void shouldNotSetCricosCodeWhenCourseVersionDoesNotExistOnCourseOffering() {
    
        Course_Offering__c courseOffering1 = new Course_Offering__c();

        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);
        
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'S2003';
        courseOffering.Course_Version_Number__c = null;
        courseOffering.Unit_Set_Code__c = null;

        courseOfferings.add(courseOffering);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
        
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals(true, String.isBlank(result.Cricos_Code__c), 
            'Expected no Cricos Code to be set because course version value ' 
            + 'was empty');
        }
        System.assertEquals(false, courseOfferings.isEmpty(), 
            'Expected course offering to be returned with transformed data ' 
            + 'even if no transformation is required'
        );

    }


    @isTest
    static void shouldNotSetCricosCodeWhenThereIsNoMatchForSingleRecord() {
    
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'DNF000001';
        courseOffering.Course_Version_Number__c = 5;
        courseOffering.Unit_Set_Code__c = null;

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals(true, String.isBlank(result.Cricos_Code__c), 
                'Expected no Cricos Code to be set because no matching cricos '
                + 'code exists');
        }
    }

    @isTest
    static void shouldNotSetCricosCodeWhenThereIsNoMatchForSingleRecordAndOfferingHasUnitSet() {
    
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'DNE000008';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Unit_Set_Code__c = 'TSCVV1545X';

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals(true, String.isBlank(result.Cricos_Code__c), 
                'Expected no Cricos Code to be set because no matching cricos '
                + 'code exists');
        }
    }


    @isTest
    static void shouldNotSetCricosCodeWhenThereIsNoMatchForTwoRecords() {
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
        new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering1 = new Course_Offering__c();
        courseOffering1.Course_Code__c = 'DNF000001';
        courseOffering1.Course_Version_Number__c = 5;
        courseOfferings.add(courseOffering1);

        Course_Offering__c courseOffering2 = new Course_Offering__c();
        courseOffering2.Course_Code__c = 'DNF000002';
        courseOffering2.Course_Version_Number__c = 2;
        courseOfferings.add(courseOffering2);

        courseOfferingCricosCodeJoin.transform(courseOfferings);

        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals(true, String.isBlank(result.Cricos_Code__c), 
                'Expected no Cricos Code to be set because no matching cricos '
                + 'code exists');
        }
    }

    /*If Course Offering Course != Blank and Unit Set = Blank, Return CRICOS code with the matching Course*/

    @isTest
    static void shouldMatchCricosCodeWhenCourseOfferingHasNoUnitSetAndCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'S2003';
        courseOffering.Course_Version_Number__c = 5;
        courseOffering.Unit_Set_Code__c = null;

        courseOfferings.add(courseOffering);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals('083405C', result.Cricos_Code__c, 
                'Expected CRICOS code because value exists');
        }
        System.assertEquals(false, courseOfferings.isEmpty(), 
            'Expected course offering to be returned with transformed data'
        );

    }

    @isTest
    static void shouldMatchCricosCodeWhenTwoCourseOfferingsBothHaveNoUnitSetAndCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering1 = new Course_Offering__c();
        courseOffering1.Course_Code__c = 'S2003';
        courseOffering1.Course_Version_Number__c = 5;
        courseOffering1.Unit_Set_Code__c = null;

        courseOfferings.add(courseOffering1);

        Course_Offering__c courseOffering2 = new Course_Offering__c();
        courseOffering2.Course_Code__c = 'A6008';
        courseOffering2.Course_Version_Number__c = 2;
        courseOffering2.Unit_Set_Code__c = null;

        courseOfferings.add(courseOffering2);
 
        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        Boolean courseOffering1CricosMatch = false;
        Boolean courseOffering2CricosMatch = false;

        for (Course_Offering__c result : courseOfferings) {
            if ('083405C'.equals(result.Cricos_Code__c) 
                    && result.Course_Code__c == 'S2003') {
                courseOffering1CricosMatch = true;
            }
            if ('082656C'.equals(result.Cricos_Code__c)
                    && result.Course_Code__c == 'A6008') {
                courseOffering2CricosMatch = true;
            }
        }
        System.assertEquals(true, courseOffering1CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );
        System.assertEquals(true, courseOffering2CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );
    }

    @isTest
    static void shouldMatchOneCricosCodeWhenTwoCourseOfferingsAndOnlyOneMatchCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering1 = new Course_Offering__c();
        courseOffering1.Course_Code__c = 'S2003';
        courseOffering1.Course_Version_Number__c = 5;

        courseOfferings.add(courseOffering1);

        Course_Offering__c courseOffering2 = new Course_Offering__c();
        courseOffering2.Course_Code__c = 'A6008';
        courseOffering2.Course_Version_Number__c = 22;

        courseOfferings.add(courseOffering2);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        Boolean courseOffering1CricosMatch = false;
        Boolean courseOffering2CricosMatch = false;

        for (Course_Offering__c result : courseOfferings) {
            if ('083405C'.equals(result.Cricos_Code__c) 
                    && result.Course_Code__c == 'S2003') {
                courseOffering1CricosMatch = true;
            }
        }
        System.assertEquals(true, courseOffering1CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );
    }

    /*     
    If Course Offering Course and Unit Set != Blank, Return CRICOS code with the matching Course + Unit Set
    */

    @isTest
    static void shouldMatchCricosCodeWhenCourseOfferingHasUnitSetAndCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'A6023';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Unit_Set_Code__c = 'KCUFSOUT01';

        courseOfferings.add(courseOffering);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals('083176M', result.Cricos_Code__c, 
                'Expected CRICOS code because value exists');
        }
        System.assertEquals(false, courseOfferings.isEmpty(), 
            'Expected course offering to be returned with transformed data'
        );

    }

    @isTest
    static void shouldMatchCricosCodeWhenOneCourseOfferingHasUnitSetAndOtherDoesNotAndBothCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'A6023';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Unit_Set_Code__c = 'KCUFSOUT01';

        courseOfferings.add(courseOffering);

        
        Course_Offering__c courseOffering2 = new Course_Offering__c();
        courseOffering2.Course_Code__c = 'A6008';
        courseOffering2.Course_Version_Number__c = 2;

        courseOfferings.add(courseOffering2);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        Boolean courseOffering1CricosMatch = false;
        Boolean courseOffering2CricosMatch = false;

        for (Course_Offering__c result : courseOfferings) {
            if ('083176M'.equals(result.Cricos_Code__c) 
                    && result.Course_Code__c == 'A6023') {
                courseOffering1CricosMatch = true;
            }
            if ('082656C'.equals(result.Cricos_Code__c)
                    && result.Course_Code__c == 'A6008') {
                courseOffering2CricosMatch = true;
            }
        }
        System.assertEquals(true, courseOffering1CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );
        System.assertEquals(true, courseOffering2CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );

    }

    @isTest
    static void shouldMatchCricosCodeWhenBothCourseOfferingHasDifferentUnitSetSameCourseAndBothCricosCodeExists() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'A6023';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Unit_Set_Code__c = 'KCUFSOUT01';

        courseOfferings.add(courseOffering);

        
        Course_Offering__c courseOffering2 = new Course_Offering__c();
        courseOffering2.Course_Code__c = 'A6023';
        courseOffering2.Course_Version_Number__c = 1;
        courseOffering2.Unit_Set_Code__c = 'TRSTEOUT01';
        
        courseOfferings.add(courseOffering2);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        Boolean courseOffering1CricosMatch = false;
        Boolean courseOffering2CricosMatch = false;

        for (Course_Offering__c result : courseOfferings) {
            if ('083176M'.equals(result.Cricos_Code__c) 
                    && result.Course_Code__c == 'A6023') {
                courseOffering1CricosMatch = true;
            }
            if ('078764M'.equals(result.Cricos_Code__c)
                    && result.Course_Code__c == 'A6023') {
                courseOffering2CricosMatch = true;
            }
        }
        System.assertEquals(true, courseOffering1CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );
        System.assertEquals(true, courseOffering2CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );

    }

    /*
    If Course Offering Course and Unit Set != Blank AND CRICOS code record's Unit Set = Blank, return the CRICOS code with the matching Course
    */
    @isTest
    static void shouldMatchCricosCodeWhenCourseOfferingHasUnitSetAndCricosCodeExistsWithoutUnitSet() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = '2087';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Unit_Set_Code__c = 'KCUFSOUT01';

        courseOfferings.add(courseOffering);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        for (Course_Offering__c result : courseOfferings) {
            System.assertEquals('030494B', result.Cricos_Code__c, 
                'Expected CRICOS code because value exists');
        }

    }

    @isTest
    static void shouldMatchCricosCodeWhenCourseOfferingHasUnitSetAndCricosCodeExistsForUnitSetAndNoUnitSet() {
        
        CourseOfferingCricosCodeJoin courseOfferingCricosCodeJoin = 
            new CourseOfferingCricosCodeJoin(CricosCodeSelectorMock);

        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'X7000';
        courseOffering.Course_Version_Number__c = 2;
        courseOffering.Unit_Set_Code__c = 'KCUFSIN09';

        courseOfferings.add(courseOffering);

        courseOfferingCricosCodeJoin.transform(courseOfferings);
    
        Boolean courseOffering1CricosMatch = false;
        for (Course_Offering__c result : courseOfferings) {
            if ('700013Z'.equals(result.Cricos_Code__c) 
                    && result.Course_Code__c == 'X7000') {
                courseOffering1CricosMatch = true;
            }
        }
        System.assertEquals(true, courseOffering1CricosMatch, 
            'Expected CRICOS code match to course offering.'
        );

    }


    private class CricosCodeSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {

            CricosCodeTestDataGenerator cricosCodeTestDataGenerator = new CricosCodeTestDataGenerator();
            
            Map<String, List<CRICOS_Code__c>> cricosCodeByCourseVersionKey = 
                new Map<String, List<CRICOS_Code__c>>();

            cricosCodeByCourseVersionKey.put('B2000_5', 
                new List<CRICOS_Code__c> {cricosCodeTestDataGenerator.generate('056414D', 'B2000_5')});
            cricosCodeByCourseVersionKey.put('S2000_5', 
                new List<CRICOS_Code__c> {cricosCodeTestDataGenerator.generate('017092G', 'S2000_5')});
            cricosCodeByCourseVersionKey.put('S2003_5', 
                new List<CRICOS_Code__c> {cricosCodeTestDataGenerator.generate('083405C', 'S2003_5')});
            cricosCodeByCourseVersionKey.put('A6008_2', 
                new List<CRICOS_Code__c> {cricosCodeTestDataGenerator.generate('082656C', 'A6008_2')});
            cricosCodeByCourseVersionKey.put('2087_1', 
                new List<CRICOS_Code__c> {cricosCodeTestDataGenerator.generate('030494B', '2087_1')});
            cricosCodeByCourseVersionKey.put('A6023_1', 
                new List<CRICOS_Code__c> {
                    cricosCodeTestDataGenerator.generate('078764M', 'A6023_1', 'TRSTEOUT01'),
                    cricosCodeTestDataGenerator.generate('083176M', 'A6023_1', 'KCUFSOUT01'),
                    cricosCodeTestDataGenerator.generate('079049G', 'A6023_1', 'TRIESTE01')
                }
            );
            cricosCodeByCourseVersionKey.put('X7000_2', 
                new List<CRICOS_Code__c> {
                    cricosCodeTestDataGenerator.generate('700013X', 'X7000_2'),
                    cricosCodeTestDataGenerator.generate('700013Z', 'X7000_2', 'KCUFSIN09')
                }
            );

            // List<CRICOS_Code__c> selectByCourseVersionKey(Set<String> courseVersionKeys) {
            if ('selectByCourseVersionKeyAndType'.equals(stubbedMethodName) && !listOfArgs.isEmpty()) {

                List<CRICOS_Code__c> querycourseOfferings = new List<CRICOS_Code__c>();

                // get first parameter,. we're only interested in productIds for unit testing purposes
                Set<String> courseVersionKeys = (Set<String>) listOfArgs[0];
                for (String courseVersionKey : courseVersionKeys) {
                    if (cricosCodeByCourseVersionKey.containsKey(courseVersionKey)) {
                        querycourseOfferings.addAll(cricosCodeByCourseVersionKey.get(courseVersionKey));
                    }
                }
                return querycourseOfferings;
                
            }
            return null;
        }
        
    }

    private class CricosCodeTestDataGenerator {


        /**
         * @description Generates a CRICOS Code record without unit sets
         */
        public CRICOS_Code__c generate(String cricosCodeName, String courseVersionKey) {

            CRICOS_Code__c cricosCode = new CRICOS_Code__c();
            cricosCode.Name = cricosCodeName;
            cricosCode.Type__c = 'CRICOS';
            cricosCode.Course_Version_Key__c = courseVersionKey;
            cricosCode.Notes__c	= 'Test CRICOS record for ' + courseVersionKey;
            cricosCode.Unit_Set__c = null;
            cricosCode.Unit_Set_Version_Key__c = null;
            cricosCode.Unique_Key__c = courseVersionKey + '_CRICOS_' 
                + cricosCodeName;
            return cricosCode;
        }

        /**
         * @description Generates a CRICOS Code record with unit sets
         */
        public CRICOS_Code__c generate(String cricosCodeName, String courseVersionKey, String unitSet) {
            // Need to generate this with Unit Sets, so use json deserialize instead of 
            // creating these records in the database
            String cricosCodeJsonString = '{"attributes":{"type":"CRICOS_Code__c"},"Name":"' 
                + cricosCodeName + '","Course_Version_Key__c":"' + courseVersionKey 
                + '","Type__c":"CRICOS","Unit_Set__c" : "a0B0I00000bu9IfUAI",' 
                + '"Unit_Set__r":{"attributes":{"type":"Course__c"},"Name":"' 
                + unitSet + '"}}';
            return (CRICOS_Code__c) JSON.deserialize(cricosCodeJsonString, CRICOS_Code__c.class);
        }

    }
}