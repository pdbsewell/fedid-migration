/*******************************************************************************
* @author       Ryan Wilson
* @date         30.Jan.2017         
* @description  Scheduler class for CalabrioCallUpdatesBatch
* @revision     
*******************************************************************************/
global class CalabrioCallUpdatesSC implements Schedulable {
	global void execute(SchedulableContext sc) {
		CalabrioCallUpdatesBatch batchClass = new CalabrioCallUpdatesBatch();
		database.executebatch(batchClass, 100);
	}
}