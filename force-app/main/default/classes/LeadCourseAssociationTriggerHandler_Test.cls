/**
 * @author Nick Guia
 * @date MAR.20.2018
 * @description Test class for LeadCourseAssociationTriggerHandler
 * @revision
 *	APR.11.2018 	Nick Guia 		- Modified test scenarios to cater change in solution
 *	OCT.09.2018		Nick Guia 		- Removed all reference to Course__c field in LCA (deleted)
 *									- Test scenarios pointed to Course Masters rather than Course
 *  AUG.08.2025		Sachin Shetty	- Lead trigger disabled on certain LCA inserts and updates 
 */
@isTest (isParallel=true)
private class LeadCourseAssociationTriggerHandler_Test {

	@testSetup static void init() {
		//create lead record
		Lead leadRec = TestHelper.createLeads(1)[0];
		leadRec.Preferred_Course_Unknown__c	= true;
		insert leadRec;
		Assert.isNotNull(leadRec.Id, 'Lead record should be created');

		/**
		 * create course - course trigger would create Course Masters
		 * based on unique course code
		 */
		List<Course__c> courseList = new List<Course__c>();
		Integer i = 1;
		for(Course__c crs : TestHelper.createCourses(5)) {
			crs.Name = '' + i;
			/**
			 * course must be of type Course-All or Short Course in order
			 * for it to generate a corresponding Course Master record
			 */
			crs.Type__c = Label.Course_Type_Course_All; 
			i++;
			courseList.add(crs);
		}

		insert courseList;

		LCA_Grouping_Interval__c lcaSetting = new LCA_Grouping_Interval__c();
        lcaSetting.Time_Interval_In_Seconds__c = 3600;
        insert lcaSetting;
	}

	/**
	 * @description Test scenario: Insert first batch of LCA's :
	 *				- Max of LCA Associated Date should be stamped against
	 *				  Lead's last course associated date.
	 *				- if LCA's Associated Date is within 1 hour (custom setting)
	 *				  of Lead's last course associated date, flag
	 *				  is Latest Course Association = true
	 *				- Find all LCA whose is Latest Course Association is true,
	 *				  get the greatest rank, and assign it's course to
	 *				  Lead's Primary Course Associated
	 */
    @IsTest
	static void test_insertNewLCA() {

        // GIVEN : Data for new LCAs are prepared
		Integer LCA_NUM = 5; //number of LCA's to be created

		//query Course Masters
		Course_Master__c cm1;
		Course_Master__c cm2;
		Course_Master__c cm3;
		Course_Master__c cm4;
		Course_Master__c cm5;
		//assign course to different variables for assertion
		List<Course_Master__c> cmList = new List<Course_Master__c>();
		for(Course_Master__c iCM : [SELECT Id, Name FROM Course_Master__c]) {
			if(iCM.Name == '1') cm1 = iCM;
			if(iCM.Name == '2') cm2 = iCM;
			if(iCM.Name == '3') cm3 = iCM;
			if(iCM.Name == '4') cm4 = iCM;
			if(iCM.Name == '5') cm5 = iCM;
			cmList.add(iCM);
		}
		//query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//generate LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1LCA;
		Integer ctr = 0;
        DateTime dt = System.now();
		for(Lead_Course_Association__c lca : TestHelper.createLCA(null, leadRec.Id, LCA_NUM)) {
			lca.Associated_Date__c = dt;
			lca.Course_Master__c = cmList[ctr].Id;
			lca.Last_Associated_Rank__c = ctr + 1;
			ctr++;

			//store rank 1 LCA for assertion
			if(lca.Last_Associated_Rank__c == 1) rank1LCA = lca;
			lcaList.add(lca);
		}

        // WHEN : LCAs are  created
		Test.startTest();
 			TriggerCommon.disableTrigger('Lead');
            	insert lcaList;
            TriggerCommon.enableTrigger('Lead');
		Test.stopTest();

		//check if the LCA was flagged as the latest course association
		lcaList = [SELECT Id, IsLatestPrimary__c, IsLatestCourseAssociation__c
 				   FROM Lead_Course_Association__c];

 		//all LCA's in this batch should be have is latest course association = true
		for(Lead_Course_Association__c lca : lcaList) {
			Assert.isTrue(lca.IsLatestCourseAssociation__c, 'All LCAs should have latest course association = true');
		}

		//THEN : check if rank 1 LCA's course is Lead's Primary Course Associated
		leadRec = [SELECT Id, Primary_Course_Master_Associated__c, Preferred_Course_Unknown__c,
					Number_of_Associated_Courses__c
				  FROM Lead
				  WHERE Id = :leadRec.Id LIMIT 1];
		Assert.areEqual(leadRec.Primary_Course_Master_Associated__c, rank1LCA.Course_Master__c, 'Rank 1 LCAs course should be the the same as the primary course on the lead');
		Assert.isFalse(leadRec.Preferred_Course_Unknown__c, 'Preferred Course Unknown on Lead should be False');
		Assert.areEqual(LCA_NUM, leadRec.Number_of_Associated_Courses__c, 'Number of LCAs associated with the lead should match');
	}

	/**
	 * @description Test scenario: Insert new batch of LCA against a Lead with existing LCA’s:
	 * 				- Max of new and old LCA Associated Date should be stamped 
	 * 				  against  Lead's last course associated date.
	 * 				- if LCA's Associated Date is within 1 hour (custom setting) of 
	 * 				  Lead's last course associated date, flag s Latest Course Association = true, 
	 * 				  otherwise update to false
	 * 				- Find all LCA whose is Latest Course Association is true, get the greatest rank, 
	 * 				  and assign its course to Lead's Primary Course Associated.
	 */
    @IsTest
	static void test_insertNewLCA_with_existing() {

        // GIVEN : Data for new LCAs are prepared
		//query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//query Course Masters
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];

		//generate initial set of LCA's
		List<Lead_Course_Association__c> oldLcaList = new List<Lead_Course_Association__c>();
		Integer ctr = 1;
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = System.now().addDays(-1); //assign yesterday's date
			oldLcaList.add(lca);
			
			ctr++;
		}
        
		//insert first batch of LCA
		TriggerCommon.disableTrigger('Lead');
		insert oldLcaList;
        TriggerCommon.enableTrigger('Lead');
		Map<Id, Lead_Course_Association__c> oldLCAMap = new Map<Id, Lead_Course_Association__c>(oldLcaList);

		//now, we insert the second batch of LCA
		List<Lead_Course_Association__c> newLcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1LCA = new Lead_Course_Association__c();
		ctr = 1;
        DateTime dt = System.now();
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = dt; //assign today's date
			newLcaList.add(lca);

			//store rank 1 lca for assertion
			if(lca.Last_Associated_Rank__c == 1) rank1LCA = lca;

			ctr++;
		}

		Map<Id, Lead_Course_Association__c> newLCAMap;

        // WHEN : insert second batch of LCA
		Test.startTest();
         	TriggerCommon.disableTrigger('Lead');
            	insert newLcaList;
            TriggerCommon.enableTrigger('Lead');

 			//collect new LCA IDs
 			newLCAMap = new Map<Id, Lead_Course_Association__c>(newLcaList);
		Test.stopTest();

		//check if the LCA was flagged as the latest course association
		newLcaList = [SELECT Id, IsLatestPrimary__c, IsLatestCourseAssociation__c, Last_Associated_Rank__c
 				   	  FROM Lead_Course_Association__c
 				   	  WHERE Id IN: newLCAMap.keySet()];

 		//THEN : All LCA's in this batch should be have is latest course association = true
		for(Lead_Course_Association__c lca : newLcaList) {
			//this batch of LCA should all have IsLatestCourseAssociation__c = true
			Assert.isTrue(lca.IsLatestCourseAssociation__c, 'IsLatestCourseAssociation__c on all the LCAs should be True');
			//the greatest rank in this batch should be tagged as is latest primary
			if(lca.Last_Associated_Rank__c == 1) {
				Assert.isTrue(lca.IsLatestPrimary__c, 'The LCA with Last_Associated_Rank__c == 1 should be the latest primary');
			}
		}

		//now we check if the old is latest course associations were toggled to false
		oldLcaList = [SELECT Id, IsLatestPrimary__c, IsLatestCourseAssociation__c, Last_Associated_Rank__c
 				   	  FROM Lead_Course_Association__c
 				   	  WHERE Id IN: oldLCAMap.keySet()];
 		for(Lead_Course_Association__c lca : oldLcaList) {
			//this batch of LCA should all haveIsLatestCourseAssociation__c = false
			Assert.isFalse(lca.IsLatestCourseAssociation__c, 'This batch of LCAs should all haveIsLatestCourseAssociation__c as false');
			//the greatest rank in this batch should be tagged as is latest primary = false
			if(lca.Last_Associated_Rank__c == 1) {
				Assert.isFalse(lca.IsLatestPrimary__c, 'The greatest rank in this batch should be tagged as is latest primary = false');
			}
		}

		//check if rank 1 LCA's course is Lead's Primary Course Associated
		leadRec = [SELECT Id, Primary_Course_Master_Associated__c, Preferred_Course_Unknown__c,
					Number_of_Associated_Courses__c
				  FROM Lead
				  WHERE Id = :leadRec.Id LIMIT 1];
		Assert.areEqual(leadRec.Primary_Course_Master_Associated__c, rank1LCA.Course_Master__c, 'Rank 1 LCAs course should be the the same as the primary course on the lead');
		Assert.isFalse(leadRec.Preferred_Course_Unknown__c, 'Preferred Course Unknown on Lead should be False');

		//get total LCA's for this Lead:
		Integer totalLCA = oldLcaList.size() + newLcaList.size();
		Assert.areEqual(totalLCA, leadRec.Number_of_Associated_Courses__c, 'Total number of LCAs associated with the lead should match the Number_of_Associated_Courses');
	}

	/**
	 * @description Test scenario: More than 1 greatest rank
	 *				- if there are duplicate greatest rank on the latest LCA batch,
	 *				  determine primary course from the LCA with latest Created Date
	 */
    @IsTest
	static void test_duplicate_greatest_rank() {
		// GIVEN : Prep data for creating LCAs
        //query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//query Courses 
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
		//generate initial set of LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Integer ctr = 1;
        DateTime dt = System.now();
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = dt;
			lcaList.add(lca);
			
			ctr++;
		}

		//create duplicate rank 1 LCA - assign any course except the first one 
		//which was already assigned to the first rank 1 LCA
		Lead_Course_Association__c lca = TestHelper.createLCA(cmList[3].Id, leadRec.Id, 1)[0];
		lca.Last_Associated_Rank__c = 1;
		lca.Associated_Date__c = System.now();
		lcaList.add(lca);

		//get total LCA's for this Lead:
		Integer totalLCA = lcaList.size();

        // WHEN : LCAs are created
		Test.startTest();
 			insert lcaList;
		Test.stopTest();

		//get the LCA with latest CreatedDate
		lcaList = [SELECT Id, IsLatestPrimary__c, CreatedDate, Course_Master__c
			   	  FROM Lead_Course_Association__c
			   	  WHERE Last_Associated_Rank__c = 1];

 		lca = null;
		for(Lead_Course_Association__c lcaLoop : lcaList) {
			if(lca == null) {
				lca = lcaLoop;
			} else {
				//check created date
				if(lcaLoop.CreatedDate > lca.CreatedDate) lca = lcaLoop;
			}
		}

		//THEN : check if latest lca's course was assigned to Lead
		leadRec = [SELECT Id, Primary_Course_Master_Associated__c, Number_of_Associated_Courses__c
				  FROM Lead
				  WHERE Id = :leadRec.Id LIMIT 1];
		Assert.areEqual(leadRec.Primary_Course_Master_Associated__c, lca.Course_Master__c, 'Latest LCAs course should be assigned to Lead');
		Assert.areEqual(totalLCA, leadRec.Number_of_Associated_Courses__c, 'Total number of LCAs associated with the lead should match the Number_of_Associated_Courses');
	}

	/**
	 * @description Test scenario: if Associated Date of LCA is within the
	 *					defined time interval grouping in custom setting,
	 *					set is latest course association to true
	 */
    @IsTest
	static void test_LCA_grouping_interval() {
		// GIVEN : Prep data for creating LCAs
        //query Lead
		Lead leadRec = [SELECT Id, Last_Course_Associated_Date__c FROM Lead LIMIT 1];
		//query Courses 
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
		//generate initial set of LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1Lca;
		Integer ctr = 1;
        DateTime dt = System.now();
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = dt;
			lcaList.add(lca);

			if(ctr == 1) rank1Lca = lca;
			ctr++;
		}

        // WHEN : LCAs are created
		Test.startTest();
			//test insert
 			insert lcaList;

 			//test update
 			rank1Lca.Associated_Date__c = System.now().addDays(-1);
 			update rank1Lca;

		Test.stopTest();

		//get custom setting value
		LCA_Grouping_Interval__c lcaSetting = LCA_Grouping_Interval__c.getInstance();

		leadRec = [SELECT Id, Last_Course_Associated_Date__c 
				FROM Lead 
				WHERE Id = :leadRec.Id
				LIMIT 1];

		//THEN : get the latest field values of LCAs
		for(Lead_Course_Association__c lcaLoop : [SELECT Id, IsLatestPrimary__c, Associated_Date__c, 
													IsLatestCourseAssociation__c
				   	  							  FROM Lead_Course_Association__c])
		{
			//now, with new values, check if lca's associated date is within 
			//the time interval defined in the custom setting

			//get millisec value of date times
			Long lcadt = lcaLoop.Associated_Date__c.getTime(); 
			Long leaddt = leadRec.Last_Course_Associated_Date__c.getTime();

			//get difference, get absolute value, then convert to seconds
			Long diff = (Math.abs(lcadt - leaddt)) / 1000;

			if(diff <= lcaSetting.Time_Interval_In_Seconds__c) {
				//if within time interval grouping, it should be tagged as latest course association
				Assert.isTrue(lcaLoop.IsLatestCourseAssociation__c, 'If within time interval grouping, it should be tagged as latest course association');
			} else {
				//otherwise, should be false
				Assert.isFalse(lcaLoop.IsLatestCourseAssociation__c, 'If not within time interval grouping, it should not be tagged as latest course association' );
			}
		}
	}

	/**
	 * @description Test scenario: if Rank is updated on LCA,
	 *					- trigger logic should re-evaluate is latest course association
	 *					  and is latest primary
	 */
    @IsTest
	static void test_update_lca_rank() {
        // GIVEN : Prep data for creating and updating LCAs
		//query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//query Courses 
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
		//generate initial set of LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1Lca;
		Lead_Course_Association__c rank2Lca;
		Integer ctr = 1;
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lcaList.add(lca);

			if(ctr == 1) rank1Lca = lca;
			if(ctr == 2) rank2Lca = lca;
			
			ctr++;
		}

		//insert first batch of LCA
		insert lcaList;

		Test.setCreatedDate(rank2Lca.Id, System.now().addMinutes(-5));

        // WHEN : LCAs are updated
		Test.startTest();
			
 			//now we update the rank 1 LCA
 			rank1Lca.Last_Associated_Rank__c = 2;
 			update rank1Lca;

		Test.stopTest();

		//THEN : there should now be multiple rank 2 LCA's we should
		//get the one with latest created date
		Lead_Course_Association__c lca;
		for(Lead_Course_Association__c lcaLoop : [SELECT Id, IsLatestPrimary__c, CreatedDate
			   	  							FROM Lead_Course_Association__c
			   	  							WHERE Last_Associated_Rank__c = 2])
		{
			if(lca == null) {
				lca = lcaLoop;
			} else {
				//check created date
				if(lcaLoop.CreatedDate > lca.CreatedDate) lca = lcaLoop;
			}
		}

		//the latest one should now be the new is latest primary
		Assert.isTrue(lca.IsLatestPrimary__c, 'The latest one should now be the primary');
	}

	/**
	 * @description Test scenario: if Associated Date is updated on LCA,
	 *					- trigger logic should re-evaluate is latest course association,
	 *					  is latest primary, and lead's primary course associated
	 */
    @IsTest
	static void test_update_lca_associatedDate() {
        // GIVEN : Prep data for creating and updating LCAs
		//query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//query Courses 
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
		//generate initial set of LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1Lca;
		Lead_Course_Association__c rank2Lca;
		Integer ctr = 1;
        DateTime dt = System.now();
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = dt;
			lcaList.add(lca);

			if(ctr == 1) rank1Lca = lca;
			if(ctr == 2) rank2Lca = lca;
			
			ctr++;
		}

        // WHEN : LCAs are updated
		Test.startTest();
            TriggerCommon.disableTrigger('Lead');
            	insert lcaList;
            TriggerCommon.enableTrigger('Lead');

 			//now we update the rank 1 LCA
 			rank1Lca.Associated_Date__c = System.now().addDays(-1);
 			update rank1Lca;

		Test.stopTest();

		//get lead's latest field values
		leadRec = [SELECT Id, Primary_Course_Master_Associated__c, Last_Course_Associated_Date__c
			  FROM Lead
			  WHERE Id = :leadRec.Id LIMIT 1];

		//get custom setting value
		LCA_Grouping_Interval__c lcaSetting = LCA_Grouping_Interval__c.getInstance();

		//get the latest field values of rank 1 and 2 LCA
		for(Lead_Course_Association__c lcaLoop : [SELECT Id, IsLatestPrimary__c, Associated_Date__c, 
													IsLatestCourseAssociation__c, Course_Master__c
				   	  							  FROM Lead_Course_Association__c
				   	  							  WHERE Id = :rank1Lca.Id
				   	  							  OR Id = :rank2Lca.Id])
		{
			if(lcaLoop.Id == rank1LCA.Id) rank1LCA = lcaLoop;
			if(lcaLoop.Id == rank2LCA.Id) rank2LCA = lcaLoop;
		}

        // THEN 
		//now, with new values, check if lca's associated date is within 
		//the time interval defined in the custom setting

		//get millisec value of date times
		Long lcadt = rank1LCA.Associated_Date__c.getTime(); 
		Long leaddt = leadRec.Last_Course_Associated_Date__c.getTime();

		//get difference, get absolute value, then convert to seconds
		Long diff = (Math.abs(lcadt - leaddt)) / 1000;

		if(diff <= lcaSetting.Time_Interval_In_Seconds__c) {
			//if within time interval grouping, it should be tagged as latest course association
			Assert.isTrue(rank1LCA.IsLatestCourseAssociation__c, 'If within time interval grouping, it should be tagged as latest course association');
			//rank 1 is latest primary should still be true
			Assert.isTrue(rank1LCA.IsLatestPrimary__c, 'Rank 1 should still be the latest primary');
		} else {
			//otherwise, should be false
			Assert.isFalse(rank1LCA.IsLatestCourseAssociation__c, 'If not within time interval grouping, it should not be tagged as latest course association');
			//rank 1 is latest primary should be updated to false
			Assert.isFalse(rank1LCA.IsLatestPrimary__c, 'If not within time interval grouping, rank 1 is latest primary should be updated to false');
		}

		/**
		 * assuming that rank 2 is now the latest associated date based on test data :
		 * 	- it should now be the Lead's Last_Course_Associated_Date__c
		 *	- it should now be the new is latest primary
		 *	- course associated to it should roll up to lead
		 */
		if(rank2LCA.Associated_Date__c > rank1LCA.Associated_Date__c) {
			Assert.areEqual(rank2LCA.Associated_Date__c, leadRec.Last_Course_Associated_Date__c, 'If rank2 LCA has the latest associated date, then it should reflect on the Lead');
			Assert.isTrue(rank2LCA.IsLatestPrimary__c, 'If rank2 LCA has the latest associated date, then it should be the primary');
			Assert.areEqual(rank2LCA.Course_Master__c, leadRec.Primary_Course_Master_Associated__c, 'If rank2 LCA has the latest associated date, then the course should match with that on the Lead');
		}
	}

	/**
	 * @description Test scenario: the isLatestPrimary LCA is deleted,
	 *					re-evaluate to get the new isLatestPrimary
	 */
    @IsTest
	static void test_delete_isLatestPrimary() {
        // GIVEN : Prep data for creating and updating LCAs
		//query Lead
		Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
		//query Courses 
		List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
		//generate initial set of LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		Lead_Course_Association__c rank1Lca;
		Lead_Course_Association__c rank2Lca;
		Integer ctr = 1;
        DateTime dt = System.now();
		for(Course_Master__c iCM : cmList) {
			Lead_Course_Association__c lca = TestHelper.createLCA(iCM.Id, leadRec.Id, 1)[0]; 
			lca.Last_Associated_Rank__c = ctr;
			lca.Associated_Date__c = dt;
			lcaList.add(lca);

			if(ctr == 1) rank1Lca = lca;
			if(ctr == 2) rank2Lca = lca;
			
			ctr++;
		}

        TriggerCommon.disableTrigger('Lead');
		insert lcaList;
        TriggerCommon.enableTrigger('Lead');

        // WHEN : An LCA is deleted 
		Test.startTest();
 			delete rank1Lca;
		Test.stopTest();

		//get the latest field values of rank 2 LCA
		rank2Lca = [SELECT Id, IsLatestPrimary__c, Associated_Date__c, 
						IsLatestCourseAssociation__c, Course_Master__c
					FROM Lead_Course_Association__c
						WHERE Id = :rank2Lca.Id
					LIMIT 1];
        
        // THEN : The primary LCA and number of associated LCAs on the Lead should be updated
		Assert.isTrue(rank2LCA.IsLatestPrimary__c, 'The next ranked LCA should become primary');

		leadRec = [SELECT Id, Number_of_Associated_Courses__c, 
					(SELECT Id FROM Lead_Courses_Association__r)
					FROM Lead 
					WHERE Id = :leadRec.Id 
					LIMIT 1];
        
        Assert.areEqual(leadRec.Number_of_Associated_Courses__c, 
							leadRec.Lead_Courses_Association__r.size(),
                       'The Number_of_Associated_Courses__c on Lead should match the number of associated LCAs');
	}
}