/**
 * @author Nick Guia
 * @date 19-10-2020
 * @group Event Management
 * @description Test class for BTAudienceTypeAnalyser.
 **/
@IsTest(isParallel=true)
private class BTAudienceTypeAnalyser_Test {

    /**
     * @description test by providing 2 audience types.
     * Prospective Student should be the winning affiliation
     */
    @isTest
    static void shouldReturnWinningAffiliation() {
        //given

        //provide 2 audience types
        String audType = String.join(new List<String>{
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT,
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY
        }, ';');

        String winningAff;

        Test.startTest();

        //when
        winningAff = new BTAudienceTypeAnalyser(audType)
            .runAnalyser()
            .getAffiliationString();

        Test.stopTest();

        //then
        System.assert(String.isNotBlank(winningAff), 'Unexpected value for winning Affiliation');
        System.assertEquals(BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT, winningAff, 
            'Unexpected value for winning Affiliation');
    }

    /**
     * @description test by providing more than 2 audience types.
     * There should be no winning affiliation
     */
    @isTest
    static void shouldReturnWinningAffiliationUndefined() {
        //given

        //provide more than 2 audience types
        String audType = String.join(new List<String>{
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT,
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY,
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_APPLICANT,
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_ALUMNI
        }, ';');

        String winningAff;

        Test.startTest();

        //when
        winningAff = new BTAudienceTypeAnalyser(audType)
            .runAnalyser()
            .getAffiliationString();

        Test.stopTest();

        //then
        System.assert(String.isBlank(winningAff), 'Unexpected value for winning Affiliation');
    }

    /**
     * @description test by providing a single audience.
     * This should be the winning value
     */
    @isTest
    static void shouldReturnWinningAffiliationSingle() {
        //given
        String winningAff;

        Test.startTest();

        //when

        //provide a single audience
        winningAff = new BTAudienceTypeAnalyser(BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY)
            .runAnalyser()
            .getAffiliationString();

        Test.stopTest();

        //then
        System.assert(String.isNotBlank(winningAff), 'Unexpected value for winning Affiliation');
        System.assertEquals(BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY, winningAff, 
            'Unexpected value for winning Affiliation');
    }
    /**
     * @description test by providing 2 audience types.
     * Industry should be the winning affiliation
     */
    @isTest
    static void shouldReturnWinningAffiliationAsIndustry() {
        //given

        //provide 2 audience types
        String audType = String.join(new List<String>{
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_ALUMNI,
            BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY
        }, ';');

        String winningAff;

        Test.startTest();

        //when
        winningAff = new BTAudienceTypeAnalyser(audType)
            .runAnalyser()
            .getAffiliationString();

        Test.stopTest();

        //then
        System.assert(String.isNotBlank(winningAff), 'Winning Affiliation is available');
        System.assertEquals(BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY, winningAff, 
            'Industry is a winning affiliation');
    }
}