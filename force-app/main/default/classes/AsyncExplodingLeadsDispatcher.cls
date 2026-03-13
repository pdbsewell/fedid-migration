/**
 * @author Nick Guia
 * @group Lead Management
 * @description : Dispatcher class for Asynchronous Exploding Leads using Mutex locks
 * @revision 
 *  JAN.07.2020     Nick Guia   - updated getUnprocessedRecords from dynamic query of sps to a static query 
 **/
public without sharing class AsyncExplodingLeadsDispatcher implements MutexLock.IMutexLockable {
    @TestVisible
    private static final String CONFIG_NAME = 'Exploding_Leads';
    @TestVisible
    private static AsyncExplodingLeadsDispatcher instance;
    @TestVisible
    private App_Mutex_Config__mdt config;
    @TestVisible
    private Mutex__c mutexRec;
    @TestVisible
    private List<Staged_Prospective_Student__c> spsList;
    @TestVisible
    private Integer batchSize;
    @TestVisible
    private Boolean isAcquire = false;
    @TestVisible
    private ExplodingLeadsSelector selector;

    private AsyncExplodingLeadsDispatcher() {
    }
    /**
     * @description method for getting the single running instance of this dispatcher within the thread.
     * @return AsyncExplodingLeadsDispatcher
     */
    public static MutexLock.IMutexLockable getInstance() {
        if(instance == null) {
            instance = new AsyncExplodingLeadsDispatcher();
        }
        return instance;
    }
    /**
     * @description initialie logic, get config data
     */
    public void start() {
        this.spsList = new List<Staged_Prospective_Student__c>();
        if(this.config == null) {
            getConfig();
        }
    }
    /**
     * @description acquire lock record from Mutex object
     * @return Boolean : indicates whether we are able to acquire a mutex lock instance
     */
    public Boolean acquire() {
        try {
            //check first if we already acquired a mutex worker
            if(this.mutexRec == NULL) {
                //if none, try to acquire an unlocked worker
                Mutex__c mutexRec = [SELECT Id
                                    FROM Mutex__c
                                    WHERE Name = :CONFIG_NAME
                                    AND is_Locked__c = FALSE
                                    LIMIT 1 
                                    FOR UPDATE];
                mutexRec.is_Locked__c = TRUE;
                this.mutexRec = mutexRec;
                this.isAcquire = true;
                update mutexRec;
            }
        } catch(Exception e) {
            this.isAcquire = false;
        }
        return this.isAcquire;
    }
    /**
     * @description if a mutex lock instance is acquired, and configuration metadata isn't muted,
     *   fetch any unprocessed SPS records. If unprocessed records exist, enqueue the job.
     *   Otherwise, release the acquired lock
     */
    public void execute() {
        //if lock is acquired and mutex config isn't muted
        if(this.isAcquire && !this.config.is_Muted__c) {
            this.selector = new ExplodingLeadsSelector();
            this.spsList = this.selector.getUnprocessedRecords(this.batchSize);
            
            //check if there are records to process before queueing
            if(!this.spsList.isEmpty()) {
                QueueExplodeLead qExLead = new QueueExplodeLead(this);
                System.enqueueJob(qExLead);
            } else {
                //release the lock
                release();
            }
        }
    }
    /**
     * @description callback method from the async job. This tries to re-execute
     *   enqueueing job if there are more unprocessed SPS records found.
     */
    public void callBack() {
        //try to execute once more if there are more records to process
        execute();
    }
    /**
     * @description release the acquired lock by updating the mutex record
     *   stored in this instance
     */
    public void release() {
        if(this.mutexRec != null && this.mutexRec.is_Locked__c) {
            this.mutexRec.is_Locked__c = FALSE;
            update this.mutexRec;
        }
    }
    /**
     * @description get unprocessed SPS records
     */
    public List<SObject> getRecords() {
        return this.spsList;
    }

    /**
     * @description get configuration data from App_Mutex_Config__mdt custom metadata
     */
    @TestVisible
    private void getConfig() {
        this.config = [SELECT QualifiedApiName, Batch_Size__c, is_Muted__c
                    FROM App_Mutex_Config__mdt
                    WHERE QualifiedApiName = :CONFIG_NAME
                    LIMIT 1];

        //parse decimal configs
        this.batchSize = Integer.valueOf(this.config.Batch_Size__c);
    }
}