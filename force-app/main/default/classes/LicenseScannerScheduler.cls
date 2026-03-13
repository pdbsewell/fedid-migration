/*******************************************************************************
* @author       Russell Cadapan
* @date         30/04/2020
* @description  Managed Package License Scanner Scheduler
* @revision     1.0
*******************************************************************************/

global class LicenseScannerScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        LicenseScanner scanner = new LicenseScanner(false);
        scanner.scan();
    }
}