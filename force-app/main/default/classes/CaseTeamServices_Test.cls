@isTest(isParallel=true)
private class CaseTeamServices_Test {

    @isTest
    private static void testRunCaseTeamCreationRules_positive() {
        Id mgroUserId = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE Assignee.isActive = TRUE AND PermissionSet.Name = 'Monash_Graduate_Research_Office_Staff_PSG'
            LIMIT 1
        ][0].AssigneeId;

        System.runAs(new User(Id=mgroUserId)) {
            // GIVEN - new enquiry
            Case case1 = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Case 1'),
                'MGROTestHelper.CaseDefaults'
            );
            Case case2 = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Case 2'),
                'MGROTestHelper.CaseDefaults'
            );

            TriggerCommon.disableTrigger('Case');
            insert new List<Case>{ case1, case2 };

            // WHEN - task created under enquiry is assigned to a mgro queue 
            Task admissionsTask = (Task) TestDataFactory.createSObject(new Task());
            admissionsTask.WhatId = case1.Id;
            admissionsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Admissions'].Id;

            Task bookingsTask = (Task) TestDataFactory.createSObject(new Task());
            bookingsTask.WhatId = case2.Id;

            Test.startTest();
            insert new List<Task>{ admissionsTask, bookingsTask };

            case1 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 1'
            ];

            // THEN - case team mgro is added since it is assigned to mgro queue 
            System.assertEquals(true, case1.TeamTemplateRecords.size() == 1);
            System.assertEquals('MGRO', case1.TeamTemplateRecords[0].TeamTemplate.Name);

            // GIVEN - new enquiry
            case2 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 2'
            ];

            // WHEN - no case team added initially since not assigned to a queue
            System.assertEquals(true, case2.TeamTemplateRecords.size() == 0);

            bookingsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Bookings'].Id;
            update bookingsTask;
            Test.stopTest();

            case2 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 2'
            ];

            // THEN - case team mgro is added when changed to mgro queue
            System.assertEquals(true, case2.TeamTemplateRecords.size() == 1);
            System.assertEquals('MGRO', case2.TeamTemplateRecords[0].TeamTemplate.Name);
        }
    }

    @isTest
    private static void testRunCaseTeamCreationRules_negative() {
        Id mgroUserId = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE Assignee.isActive = TRUE AND PermissionSet.Name = 'Monash_Graduate_Research_Office_Staff_PSG'
            LIMIT 1
        ][0].AssigneeId;

        System.runAs(new User(Id=mgroUserId)) {
            // GIVEN - enquiry with case team mgro added
            Case case1 = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Case 1'),
                'MGROTestHelper.CaseDefaults'
            );

            TriggerCommon.disableTrigger('Case');
            insert case1;

            Task admissionsTask = (Task) TestDataFactory.createSObject(new Task());
            admissionsTask.WhatId = case1.Id;
            admissionsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Admissions'].Id;

            Test.startTest();
            insert admissionsTask;

            case1 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 1'
            ];
            System.assertEquals(true, case1.TeamTemplateRecords.size() == 1);

            // WHEN - task owner is changed to a user
            admissionsTask.OwnerId = mgroUserId;
            update admissionsTask;

            // WHEN - task owner is changed back to a queue
            admissionsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Admissions'].Id;
            update admissionsTask;
            Test.stopTest();

            case1 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 1'
            ];

            // THEN - case team mgro is not added again - silent failure for duplicate rows
            System.assertEquals(true, case1.TeamTemplateRecords.size() == 1);
            System.assertEquals('MGRO', case1.TeamTemplateRecords[0].TeamTemplate.Name);
        }
    }
}