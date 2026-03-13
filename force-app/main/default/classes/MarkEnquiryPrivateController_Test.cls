@isTest(isParallel=true)
private class MarkEnquiryPrivateController_Test {
    @isTest
    private static void markAsPrivateTest_MGRO() {
        Id runningUserId = UserInfo.getUserId();

        Id mgroUserId = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE Assignee.isActive = TRUE AND PermissionSet.Name = 'Monash_Graduate_Research_Office_Staff_PSG'
            LIMIT 1
        ][0]
        .AssigneeId;

        System.runAs(new User(Id = mgroUserId)) {
            // GIVEN - new enquiry with case teams and manual shares
            Case enquiry = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Enquiry MGRO'),
                'MGROTestHelper.CaseDefaults'
            );
            enquiry.OwnerId = mgroUserId;

            TriggerCommon.disableTrigger('Case');
            insert enquiry;

            insert new CaseTeamTemplateRecord(
                TeamTemplateId = [
                    SELECT Id, Name
                    FROM CaseTeamTemplate
                    WHERE Name = 'MGRO'
                ]
                .Id,
                ParentId = enquiry.Id
            );

            CaseShare caseShare = new CaseShare();
            caseShare.CaseId = enquiry.Id;
            caseShare.UserOrGroupId = runningUserId;
            caseShare.RowCause = 'Manual';
            caseShare.CaseAccessLevel = 'Edit';
            insert caseShare;

            // WHEN - enquiry is marked as Private
            Test.startTest();
            MarkEnquiryPrivateController.markEnquiryAsPrivate(enquiry.Id);

            enquiry = [
                SELECT
                    Id,
                    Private_Enquiry__c,
                    (SELECT Id FROM TeamTemplateRecords),
                    (SELECT Id FROM Shares WHERE RowCause = 'Manual')
                FROM Case
                WHERE Subject = 'Enquiry MGRO'
            ];

            // THEN - all case teams / members are removed
            System.assertEquals(true, enquiry.TeamTemplateRecords.size() == 0);

            // THEN - all manual shares are removed
            System.assertEquals(true, enquiry.Shares.size() == 0);

            // THEN - Private Enquiry checkbox is checked
            System.assertEquals(true, enquiry.Private_Enquiry__c);
        }
    }

    @isTest
    private static void markAsPrivateTest_FacultyGraduateResearch() {
        Id runningUserId = UserInfo.getUserId();

        Id facultyGradResUserId = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE
                Assignee.isActive = TRUE
                AND PermissionSet.Name = 'Faculty_Graduate_Research_Staff_PSG'
                AND Assignee.UserRole.Name = 'BusEco - Graduate Research'
            LIMIT 1
        ][0]
        .AssigneeId;

        System.runAs(new User(Id = facultyGradResUserId)) {
            // GIVEN - new enquiry with case teams and manual shares
            Case enquiry = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Enquiry Faculty Grad Research'),
                'FacultyGradResearchTestHelper.CaseDefaults'
            );
            enquiry.OwnerId = facultyGradResUserId;

            TriggerCommon.disableTrigger('Case');
            insert enquiry;

            insert new CaseTeamTemplateRecord(
                TeamTemplateId = [
                    SELECT Id, Name
                    FROM CaseTeamTemplate
                    WHERE Name = 'MGRO'
                ]
                .Id,
                ParentId = enquiry.Id
            );

            CaseShare caseShare = new CaseShare();
            caseShare.CaseId = enquiry.Id;
            caseShare.RowCause = 'Manual';
            caseShare.UserOrGroupId = runningUserId;
            caseShare.CaseAccessLevel = 'Edit';
            insert caseShare;

            // WHEN - enquiry is marked as Private
            Test.startTest();
            MarkEnquiryPrivateController.markEnquiryAsPrivate(enquiry.Id);

            enquiry = [
                SELECT
                    Id,
                    Private_Enquiry__c,
                    (SELECT Id FROM TeamTemplateRecords),
                    (SELECT Id, UserOrGroupId, CaseAccessLevel FROM Shares WHERE RowCause = 'Manual')
                FROM Case
                WHERE Subject = 'Enquiry Faculty Grad Research'
            ];

            // THEN - all case teams are removed
            System.assertEquals(true, enquiry.TeamTemplateRecords.size() == 0);

            // THEN - all manual shares are removed except Faculty
            System.assertEquals(true, enquiry.Shares.size() == 1);
            System.assertEquals(
                true,
                enquiry.Shares[0].UserOrGroupId ==
                [SELECT Id, Type FROM Group WHERE Name = 'BusEco - Graduate Research' AND Type = 'Regular']
                .Id
            );

            // THEN - Private Enquiry checkbox is checked
            System.assertEquals(true, enquiry.Private_Enquiry__c);
        }
    }
}