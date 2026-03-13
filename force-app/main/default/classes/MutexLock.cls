/**
 * @File Name          : MutexLock.cls
 * @Description        : MutexLock class that holds the MutexLockable interface and execution logic
 * @Author             : Nick Guia
 * @Group              : Commons
 */
public class MutexLock {

    //static job types
    public static final String JOB_TYPE_FUTURE = 'Future';
    public static final String JOB_TYPE_SHARING_RECALCULATION = 'SharingRecalculation';
    public static final String JOB_TYPE_SCHEDULED_APEX = 'ScheduledApex';
    public static final String JOB_TYPE_BATCH_APEX = 'BatchApex';
    public static final String JOB_TYPE_BATCH_APEX_WORKER = 'BatchApexWorker';
    public static final String JOB_TYPE_TEST_REQUEST = 'TestRequest';
    public static final String JOB_TYPE_TEST_WORKER = 'TestWorker';
    public static final String JOB_TYPE_APEX_TOKEN = 'ApexToken';
    public static final String JOB_TYPE_QUEUEABLE = 'Queueable';

    //async jobs statuses that indicates "not done"
    public static final List<String> RUNNING_JOBS_STATUS = new List<String> {
        'Holding', 'Queued', 'Preparing', 'Processing'
    };

    //async jobs statuses that indicates "done"
    public static final List<String> FINISHED_JOB_STATUS = new List<String> {
        'Aborted', 'Completed', 'Failed'
    };

    /**
    * @description invoke mutex lockable methods
    **/
    public static void execute(IMutexLockable mutex) {
        mutex.start();
        if(mutex.acquire()) {
            mutex.execute();
        }
    }

    public interface IMutexLockable {
        /**
        * @description for loading any configurations, init logic
        **/
        IMutexLockable getInstance();
        /**
        * @description for loading any configurations, init logic
        **/
        void start();
        /**
        * @description acquire mutex lock record
        **/
        Boolean acquire();
        /**
        * @description run logic
        **/
        void execute();
        /**
        * @description callback method for async processes
        **/
        void callBack();
        /**
        * @description release lock from mutex record
        **/
        void release();
        /**
        * @description fetch any records that require processing
        **/
        List<SObject> getRecords();
    }

    public class MutexLockException extends Exception {}
}