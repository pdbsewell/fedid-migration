/**
 * @author Nick Guia
 * @date MAR.20.2018
 * @description Trigger handler for LeadCourseAssociationTrigger
 * @revision
 * 	APR.11.2018 	Nick Guia 	- modified entire LCA course roll up logic with change in solution
 *  MAY.31.2018 	Nick Guia 	- added update on Lead.Preferred_Course_Unknown__c whenever an LCA is existing for the Lead
 * 	AUG.01.2018 	Nick Guia 	- CommonUtilities.addListToMapByParentId renamed to addListToMapByKey
 *  AUG.15.2018 	Nick Guia 	- Added feature for capturing Course Master
 *	AUG.28.2018 	Nick Guia 	- Added CrossPopulateCourses (interim)
 *	OCT.08.2018 	Nick Guia 	- removed CrossPopulateCourses.
 *								- DCXCRM-1833 removed all references to Course__c and Primary_Course_Associated__c lookup (deleted field)
 *	JAN.31.2019 	Nick Guia 	- Added rollup for number of LCA's in 'insert' context 
 */
public class LeadCourseAssociationTriggerHandler {

	//custom setting value for LCA grouping interval
	private static LCA_Grouping_Interval__c LCA_SETTING;

	/**
	 * @description class that runs the criteria checking for running process
	 *				of updating LCA isLatestPrimary, IsLatestCourseAssociation__c, and
	 *				for rolling up Lead's Primary Course
	 */
	public class ValidateIsLatestPrimaryProcess implements Triggers.Handler {
		public void run() {
			//instantiate custom setting value
			if(LCA_SETTING == null) {
				LCA_SETTING = LCA_Grouping_Interval__c.getInstance();
			}

			//container for invokeIsLatestPrimaryProcess
			Map<Id, Lead_Course_Association__c> getLeadPrimaryCourseMap =
				new Map<Id, Lead_Course_Association__c>();

			//container for getNewPrimary
			Map<Id, Lead_Course_Association__c> rankChangedMap =
				new Map<Id, Lead_Course_Association__c>();

			Set<Id> isLatestPrimaryDeleted = new Set<Id>();
			Set<Id> calculateCourseList = new Set<Id>();

			//filter entry criteria here
			if(!Trigger.isDelete) {
				for(Lead_Course_Association__c lcaNew : (List<Lead_Course_Association__c>) Trigger.new) {
					if(Trigger.isInsert) {
						/** 
						 * INSERT CRITERIA :
						 * 	- if LCA Associated Date is not null
						 */
						if(lcaNew.Associated_Date__c != null) {
							getLeadPrimaryCourseMap.put(lcaNew.Id, lcaNew);
						}
						calculateCourseList.add(lcaNew.Lead__c);
					} else if(Trigger.isUpdate) {
						/** 
						 * UPDATE CRITERIA :
						 * 	- if LCA Associated Date is changed
						 * 	- if Rank changed and IsLatestCourseAssociation__c is true
						 */
						Lead_Course_Association__c lcaOld = 
							(Lead_Course_Association__c) Trigger.oldMap.get(lcaNew.Id); //get old value

						if(CommonUtilities.fieldHasChanged('Associated_Date__c', lcaNew, lcaOld)) {
							getLeadPrimaryCourseMap.put(lcaNew.Id, lcaNew);
						} else if(CommonUtilities.fieldHasChanged('Last_Associated_Rank__c', lcaNew, lcaOld) &&
							lcaNew.IsLatestCourseAssociation__c) 
						{
							rankChangedMap.put(lcaNew.Id, lcaNew);
						}
					}
				}
			} else {
				/** 
				 * DELETE CRITERIA :
				 * 	- if IsLatestPrimary__c is true
				 */
				for(Lead_Course_Association__c lcaOld : (List<Lead_Course_Association__c>) Trigger.old) {
					if(lcaOld.IsLatestPrimary__c) {
						isLatestPrimaryDeleted.add(lcaOld.Lead__c);
					}
					//if an LCA is deleted, recalcualate total number of associated courses
					calculateCourseList.add(lcaOld.Lead__c);
				}
			}

			//RUN PROCESSES
			if(!getLeadPrimaryCourseMap.isEmpty()) {
				invokeIsLatestPrimaryProcess(getLeadPrimaryCourseMap);
			}

			if(!isLatestPrimaryDeleted.isEmpty()) {
				invokeIsLatestPrimaryProcess(isLatestPrimaryDeleted);
			}

			if(!rankChangedMap.isEmpty()) {
				rankChangedGetNewPrimary(rankChangedMap);
			}

			if(!calculateCourseList.isEmpty()) {
				calculateCourses(calculateCourseList);
			}
		}
	}

	/**
	 * @description runs when LCA's Last Associated Rank is updated. This
	 *				method runs a re-assessment of the new is Latest Primary LCA.
	 * @param newLcaMap : map of LCAs that passed the entry criteria
	 */
	private static void rankChangedGetNewPrimary(Map<Id, Lead_Course_Association__c> newLcaMap) {

		//container of DML changes
		List<Lead> leadUpdateList = 
			new List<Lead>();

		List<Lead_Course_Association__c> lcaUpdateList = 
			new List<Lead_Course_Association__c>();

		//Create a map of LCA and it's parent Lead IDs
		Map<String, List<Lead_Course_Association__c>> lcaByLeadIdMap = 
			(Map<String, List<Lead_Course_Association__c>>) CommonUtilities.addListToMapByKey(newLcaMap.values(), 'Lead__c');

		/**
		 * Get all LCAs related to this Lead whose
 		 * 	- is Latest Course Association is true
 		 *	- not in trigger context, just so that we could capture the delta
		 */
		List<Lead> leadList = [SELECT Id, Last_Course_Associated_Date__c, Primary_Course_Master_Associated__c,
								(SELECT Id, IsLatestCourseAssociation__c, CreatedDate, Course_Master__c,
								 		IsLatestPrimary__c, Last_Associated_Rank__c, Lead__c
								 FROM Lead_Courses_Association__r
								 WHERE IsLatestCourseAssociation__c = true
								 AND Id NOT IN :newLcaMap.keySet())
								FROM Lead
								WHERE Id IN :lcaByLeadIdMap.keySet()];
		for(Lead ld : leadList) {

			//now we merge the existing LCAs in this contact with the delta LCAs
			List<Lead_Course_Association__c> deltaLCA = ld.Lead_Courses_Association__r;
			if(lcaByLeadIdMap.containsKey(ld.Id)) deltaLCA.addAll(lcaByLeadIdMap.get(ld.Id));

			//create a new instance of the deltaLCAs to avoid read-only errors
			deltaLCA = createNewLCAInstances(deltaLCA);

			//after we determine the latest batch of LCA, find the isLatestPrimary
			invokeUpdateIsLatestPrimary(ld, deltaLCA);

			lcaUpdateList.addAll(deltaLCA);
			leadUpdateList.add(ld);
		}

		//commit records
		commitUpdates(lcaUpdateList, leadUpdateList);
	}

	/**
	 * @description runs the process of rolling up the is Latest Primary
	 *				LCA's Course to it's parent Lead.
	 * @param newLcaMap : map of LCAs that passed the entry criteria
	 * @overload
	 */
	private static void invokeIsLatestPrimaryProcess(Map<Id, Lead_Course_Association__c> newLcaMap) {

		//container of DML changes
		List<Lead> leadUpdateList = 
			new List<Lead>();

		List<Lead_Course_Association__c> lcaUpdateList = 
			new List<Lead_Course_Association__c>();

		//Create a map of LCA and it's parent Lead IDs
		Map<String, List<Lead_Course_Association__c>> lcaByLeadIdMap = 
			(Map<String, List<Lead_Course_Association__c>>) CommonUtilities.addListToMapByKey(newLcaMap.values(), 'Lead__c');

		//Get all LCAs related to this Lead except those included in Trigger context
		List<Lead> leadList = [SELECT Id, Last_Course_Associated_Date__c, Preferred_Course_Unknown__c, 
								Primary_Course_Master_Associated__c,
								(SELECT Id, Associated_Date__c, IsLatestCourseAssociation__c, Course_Master__c,
								 		IsLatestPrimary__c, Last_Associated_Rank__c, Lead__c, CreatedDate
								 FROM Lead_Courses_Association__r
								 WHERE Id NOT IN :newLcaMap.keySet())
								FROM Lead
								WHERE Id IN :lcaByLeadIdMap.keySet()];

		//process each Lead
		for(Lead ld : leadList) {

			//now we merge the existing LCAs in this Lead with the delta LCAs
			List<Lead_Course_Association__c> deltaLCA = ld.Lead_Courses_Association__r;
			if(lcaByLeadIdMap.containsKey(ld.Id)) deltaLCA.addAll(lcaByLeadIdMap.get(ld.Id));

			//create a new instance of the deltaLCAs to avoid read-only errors
			deltaLCA = createNewLCAInstances(deltaLCA);

			//run the isLatestPrimary process
			isLatestPrimaryProcess(ld, deltaLCA);

			//NAG 31/05/2018 -add updating Preferred_Course_Unknown__c to false
			ld.Preferred_Course_Unknown__c = false;

			//store changes
			lcaUpdateList.addAll(deltaLCA);
			leadUpdateList.add(ld);
		}

		commitUpdates(lcaUpdateList, leadUpdateList);
	}

	/**
	 * @description Method overload. process to be ran when the current isLatestPrimary LCA
	 *				has been deleted.
	 * @param leadIdSet : set of Lead IDs whose new primary is to be re-evaluated
	 * @overload
	 */
	private static void invokeIsLatestPrimaryProcess(Set<Id> leadIdSet) {
		//container of DML changes
		List<Lead> leadUpdateList = 
			new List<Lead>();

		List<Lead_Course_Association__c> lcaUpdateList = 
			new List<Lead_Course_Association__c>();

		//Get all LCAs related to this Lead whose is Latest Course Association is true
		List<Lead> leadList = [SELECT Id, Last_Course_Associated_Date__c, Primary_Course_Master_Associated__c,
								(SELECT Id, IsLatestCourseAssociation__c, CreatedDate, Course_Master__c,
								 		IsLatestPrimary__c, Last_Associated_Rank__c, Lead__c, Associated_Date__c
								 FROM Lead_Courses_Association__r
								 WHERE IsLatestCourseAssociation__c = true)
								FROM Lead
								WHERE Id IN :leadIdSet];
        for(Lead ld : leadList) {
			List<Lead_Course_Association__c> lcaList = ld.Lead_Courses_Association__r;
			//run the isLatestPrimary process
			isLatestPrimaryProcess(ld, lcaList);
			//ld.Number_of_Associated_Courses__c = lcaList.size();

			//store changes
			lcaUpdateList.addAll(lcaList);
			leadUpdateList.add(ld);
		}

		//commit records
		commitUpdates(lcaUpdateList, leadUpdateList);
	}

	/**
	 * @description Method for rolling up total nunber of Associated Courses
	 * 				with the Lead. This is to customise the rollup summary field
	 *				as Leads can't be master to a master-detail relationship.
	 */
	public static void calculateCourses(Set<Id> leadIdSet) {
		List<Lead> leadList = [SELECT Id, (SELECT Id FROM Lead_Courses_Association__r)
								FROM Lead
								WHERE Id IN :leadIdSet];
		for(Lead iLead : leadList) {
			iLead.Number_of_Associated_Courses__c = iLead.Lead_Courses_Association__r.size();
		}
		update leadList;
	}

	/**
	 * @description reusable method for determining the is latest primary process
	 */
	private static void isLatestPrimaryProcess(Lead ld, List<Lead_Course_Association__c> lcaList) {
		/**
		 * STEP 1: get the max associated date from all the LCAs
		 * 		   associated to this Lead
		 */
		ld.Last_Course_Associated_Date__c = getLatestAssociatedDate(lcaList);
        
		/**
		 * STEP 2: if LCAs Associated Date is within the time interval specified 
		 * 		   in the custom setting, update to true. Otherwise, false
		 */
		updateIsLatestCourseAssociation(lcaList, ld.Last_Course_Associated_Date__c);

		/**
		 * STEP 3: after we determine the latest batch of LCA, find the isLatestPrimary
		 */
		invokeUpdateIsLatestPrimary(ld, lcaList);
	}

	/**
	 * @description reusable method for updating is latest primary
	 */
	private static void invokeUpdateIsLatestPrimary(Lead ld, List<Lead_Course_Association__c> lcaList) {
		Lead_Course_Association__c latestPrimary = updateIsLatestPrimary(lcaList);
		if(latestPrimary != null) {
			ld.Primary_Course_Master_Associated__c = latestPrimary.Course_Master__c;
		} else {
			ld.Primary_Course_Master_Associated__c = null;
		}
	}

	/**
	 * @description get the max associated date assigned to all LCAs
	 * 				under the Lead
	 * @param lcaList : all child LCAs of the Lead 
	 * @return the max DateTime value of Associated Date from the LCA list
	 */
	private static DateTime getLatestAssociatedDate(List<Lead_Course_Association__c> lcaList) {
		DateTime maxDT;
		for(Lead_Course_Association__c iLCA : lcaList) {
			if(iLCA.Associated_Date__c != null) {
				if(maxDT == null) {
					maxDT = iLCA.Associated_Date__c;
				} else {
					maxDT = (iLCA.Associated_Date__c > maxDT) ? iLCA.Associated_Date__c : maxDT;
				}
			}
		}
		return maxDT;
	}

	/**
	 * @description Groups the LCAs into batches through the
	 * 				'is Latest Course Association' check box.
	 *				This is being determined by the time interval defined
	 *				in the custom setting. If LCA's associated date is within
	 *				the time interval from Lead's Latest Associated Date, set
	 *				the LCA as is Latest Course Association
	 * @param lcaList : child LCAs of Lead
	 *		  leadLastDate : max associated date from Lead
	 */
	private static void updateIsLatestCourseAssociation(List<Lead_Course_Association__c> lcaList, 
													   DateTime leadLastDate) 
	{

		for(Lead_Course_Association__c iLCA : lcaList) {
			//reset IsLatestCourseAssociation__c
			iLCA.IsLatestCourseAssociation__c = false;

			if(iLCA.Associated_Date__c != null) {
				Long diff = CommonUtilities.getDateTimeDifference(leadLastDate, iLCA.Associated_Date__c);
				if(diff <= LCA_SETTING.Time_Interval_In_Seconds__c) {
					iLCA.IsLatestCourseAssociation__c = true;
				}
			}
		}
	}

	/**
	 * @description Determines the new is Latest Primary LCA of a Lead. It's Course should be
	 * 				marked as Lead's 'Primary Course Associated'. Business Logic below:
	 *				- greatest rank within the set of 'is Latest Course Association' LCAs
	 *				- if there are multiple greatest ranks, latest-greatest. Determine by CreatedDate
	 * @param lcaList : List of Lead's child LCAs
	 * @return the 'is Latest Primary' LCA
	 */
	private static Lead_Course_Association__c updateIsLatestPrimary(List<Lead_Course_Association__c> lcaList) {
		//map of LCAs by it rank with possibility of having multiple ranks
		Map<Decimal, List<Lead_Course_Association__c>> lcaMapByRank =
			new Map<Decimal, List<Lead_Course_Association__c>>();

		Decimal maxRank;

		for(Lead_Course_Association__c iLCA : lcaList) {

			//reset all isLatestPrimary to false
			iLCA.IsLatestPrimary__c = false;

			//determine is latest primary of latest batch
			if(iLCA.IsLatestCourseAssociation__c) {
				if(iLCA.Last_Associated_Rank__c != null) {
					//store values by rank
					List<Lead_Course_Association__c> lcaListByRank = lcaMapByRank.get(iLCA.Last_Associated_Rank__c);
					if(lcaListByRank == null) lcaListByRank = new List<Lead_Course_Association__c>();
					lcaListByRank.add(iLCA);
					lcaMapByRank.put(iLCA.Last_Associated_Rank__c, lcaListByRank);

					//get max rank value
					if(maxRank == null) {
						maxRank = iLCA.Last_Associated_Rank__c;
					} else {
						maxRank = (iLCA.Last_Associated_Rank__c < maxRank) ? iLCA.Last_Associated_Rank__c : maxRank;
					}
				}
			}
		}

		//tick LCA's isLatestPrimary
		Lead_Course_Association__c latestLCA;
		if(maxRank != null) {
			for(Lead_Course_Association__c iLCA : lcaMapByRank.get(maxRank)) {
				if(latestLCA == null) {
					latestLCA = iLCA;
				} else {
					//convert CreatedDates to Long to compare with millisecs difference
					Long ilcaDT = iLCA.CreatedDate.getTime();
					Long latestLCADT = latestLCA.CreatedDate.getTime();
					
					latestLCA = (ilcaDT > latestLCADT) ? iLCA : latestLCA;
				}
			}
			if(latestLCA != null) latestLCA.IsLatestPrimary__c = true;
		} else {
			//no max rank detected - potential null values
			System.debug(LoggingLevel.ERROR, 'LAST ASSOCIATED RANK NOT SPECIFIED'); //NOPMD
		}

		return latestLCA;
	}

	/**
	 * @description method to create new instances of LCAs included in the list.
	 * 				Given the chances that we might do updates on LCAs that are included
	 *				in the "after event" trigger context, we need to create a new instance 
	 *				of it or it will error out as "read-only" otherwise.
	 * @param lcaList : lead of LCAs
	 * @return new instance of all LCAs included in the list. IDs will be retained
	 */
	private static List<Lead_Course_Association__c> createNewLCAInstances(List<Lead_Course_Association__c> lcaList) {
		List<Lead_Course_Association__c> newInstanceList = new List<Lead_Course_Association__c>();
		for(Lead_Course_Association__c lca : lcaList) {
			Lead_Course_Association__c newLcaInstance = lca.clone(true, true, true, true);
			newInstanceList.add(newLcaInstance);
		}

		return newInstanceList;
	}

	/**
	 * @description commit changes
	 */
	private static void commitUpdates(List<Lead_Course_Association__c> lcaUpdateList,
									  List<Lead> leadUpdateList) 
	{
		if(!lcaUpdateList.isEmpty()) update lcaUpdateList;
		if(!leadUpdateList.isEmpty()) update leadUpdateList;
	}
}