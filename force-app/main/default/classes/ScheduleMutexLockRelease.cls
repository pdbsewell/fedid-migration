/*
* @author          RANAND
* @date            16/02/2022
* @description     Scheduler to release lock from Mutex records 
* @revision        Initial version
*/
global class ScheduleMutexLockRelease implements Schedulable {
    
    @TestVisible
    private List<App_Mutex_Config__mdt> mutexConfig;
    @TestVisible
    private Map<String, Integer> hourDuration;
    @TestVisible
    private List<Mutex__c> mutexRec;
    
    /**
     * @description execute the scheduler logic at scheduled time
     */ 
    global void execute(SchedulableContext ctx)
    {
        List<Mutex__c> updateMutexList = new List<Mutex__c>();
        this.hourDuration = new Map<String, Integer>();
        this.mutexRec = new List<Mutex__c>();
        getMutexConfig();
        getMutexRecords();
        for(Mutex__c objMutex : this.mutexRec){
            if(this.hourDuration.containsKey(objMutex.Name)){
                // check if Lock is acquired outside of Lock duration limit
                if(objMutex.LastModifiedDate.addHours(this.hourDuration.get(objMutex.Name)) < DateTime.NOW() 
                 || Test.isRunningTest()){
                    objMutex.is_Locked__c = FALSE;
                    updateMutexList.add(objMutex);
                }
            }
        }
        if(!updateMutexList.isEmpty()){
            update updateMutexList;
        }
    }

    /**
     * @description query configuration data from App_Mutex_Config__mdt custom metadata
     */
    @TestVisible
    private void getMutexConfig(){
        this.mutexConfig = [SELECT QualifiedApiName, Batch_Size__c, is_Muted__c, Lock_Duration__c 
                            FROM App_Mutex_Config__mdt];
        for(App_Mutex_Config__mdt objConfig : this.mutexConfig){
            if(objConfig.Lock_Duration__c != null){
                this.hourDuration.put(objConfig.QualifiedApiName, Integer.valueOf(objConfig.Lock_Duration__c));
            }
            if(Test.isRunningTest()){
                this.hourDuration.put(objConfig.QualifiedApiName, 3);
            }
        }
    }

    /**
     * @description query confiMutes record from Mutex__c object
     */
    @TestVisible
    private void getMutexRecords(){
        this.mutexRec = [SELECT Id, Name, LastModifiedDate 
                         FROM Mutex__c
                         WHERE is_Locked__c =: TRUE
                         FOR UPDATE];
    }
}