/*******************************************************************************
* @author       Russell Cadapan
* @date         30/04/2020
* @description  Managed Package License Scanner
* @revision     1.0
* 1.1     RANAND      [EPBBS-2803] Change CMD refrence to System Settings MD in retrievePackages method
*******************************************************************************/

public class LicenseScanner {

    // list of managed package info for validation
    @TestVisible
    private List<PackageInfo> managedPackageList;

    // boolean flag to remind all
    private Boolean checkAll = false;
	private String FEATURE_CUSTOM_LICENSE_PACKAGE = 'CUSTOM_LICENSE_PACKAGE';
    /*
    * Method Name: LicenseScanner
    * Description: Constructor to initiate the retrieval of managed packages details
    */
    public LicenseScanner(Boolean checkAll) {
        this.checkAll = checkAll;
        retrievePackages();
    }

    /*
    * Method Name: scan
    * Description: method to scan through the retrieved managed package and validate the license status
    */
    public void scan(){
        List<PackageInfo> packagesForReminder = new List<PackageInfo>();

        if(!managedPackageList.isEmpty()){
            // for every managed package retrieved
            for(PackageInfo pi: managedPackageList){

                // if check all, put all the package info in the list
                if(checkAll){
                    packagesForReminder.add(pi);
                }
                else{
                    // validate if the package is in 14 days before its expiry
                    if(pi.expiryDate.addDays(-10) < Date.Today()){
                        packagesForReminder.add(pi);
                    }
                    // or if the package has consumed all its allowed licenses
                    else if(pi.AllowedLicenses == pi.usedLicenses){
                        packagesForReminder.add(pi);
                    }
                }

            }
        }

        // send the email for reminder
        if(!packagesForReminder.isEmpty()){
            sendEmailForReminder(packagesForReminder);
        }
    }

    /*
    * Method Name: retrievePackages
    * Description: method to query all managed packages and details
    */
    private void retrievePackages(){
        managedPackageList = new List<PackageInfo>();

        if(this.checkAll){
            // query all installed packages whose licenses are managed through the standard configuration
            for(PackageLicense pl: [SELECT Id, NamespacePrefix, Status, ExpirationDate, AllowedLicenses, UsedLicenses FROM PackageLicense]){
                managedPackageList.add(new PackageInfo(pl.NamespacePrefix, Integer.valueOf(pl.AllowedLicenses), Integer.valueOf(pl.UsedLicenses), Date.valueOf(pl.ExpirationDate)));
            }
        }
        else{
            // query all installed packages whose licenses are managed through the standard configuration
            for(PackageLicense pl: [SELECT Id, NamespacePrefix, Status, ExpirationDate, AllowedLicenses, UsedLicenses FROM PackageLicense WHERE Status = 'Active' AND ExpirationDate != NULL AND AllowedLicenses NOT IN (-1, NULL)]){
                managedPackageList.add(new PackageInfo(pl.NamespacePrefix, Integer.valueOf(pl.AllowedLicenses), Integer.valueOf(pl.UsedLicenses), Date.valueOf(pl.ExpirationDate)));
            }
        }

        // query all installed packages whose licenses are managed through custom configuration (should be maintained in the custom metadata: Installed Package with Custom Package License)
        List<System_Settings__mdt> settings = SystemSettingsUtil.getinstance().getByFeature(FEATURE_CUSTOM_LICENSE_PACKAGE);
        SystemSettingWrapper.CustomPackageLicense customPackage;
        if(!settings.isEmpty()){
            for(System_Settings__mdt objSetting : settings){
                customPackage = (SystemSettingWrapper.CustomPackageLicense)SystemSettingWrapper.parse(objSetting, SystemSettingWrapper.CustomPackageLicense.class);
                managedPackageList.add(new PackageInfo(customPackage.namespacePrefix, Integer.valueOf(customPackage.allowedLicense), Integer.valueOf(customPackage.usedLicense), Date.parse(customPackage.expirationDate)));
            }
        }
    }

    /*
    * Method Name: sendEmailForReminder
    * Description: method to send the email to CRM Platform Team if there is at least one package that will expire within 14 days or has consumed all the licenses
    */
    private void sendEmailForReminder(List<PackageInfo> packageInfoList){


        try{

            Id adminAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'unicrm.coreadmin@f.e.monash.edu' LIMIT 1].Id;

            Messaging.singleEmailmessage email =new Messaging.singleEmailmessage();
            email.setsubject(Label.LicenseEmailSubject);
            email.SetPlainTextbody(generateEmailTextBody(packageInfoList));
            email.SetToAddresses(new List<String>{'esol-dt-crmplatform@monash.edu'});
            email.setOrgWideEmailAddressId(adminAddressId);

            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.singleEmailmessage>{email});
            }
        }
        catch(Exception e){
            ExLog.add('LicenseScanner','Messaging','sendEmailForReminder', e);
        }

    }

    /*
    * Method Name: generateEmailTextBody
    * Description: method to generate the email body for reminder
    */
    private String generateEmailTextBody(List<PackageInfo> packageInfoList){
        String body = 'Please be reminded that the following managed package(s) are about to expire or has consumed all the licenses';

        for(PackageInfo pi: packageInfoList){

            body += '\n\n';
            body += 'Namespace: ' + String.valueOf(pi.packageName) + '.\n';
            body += 'Allowed Licenses: ' + String.valueOf(pi.allowedLicenses) + '.\n';
            body += 'Used Licenses: ' + String.valueOf(pi.usedLicenses) + '.\n';
            body += 'Expiration Date: ' + String.valueOf(pi.expiryDate) + '.';

        }

        return body;
    }

    /*
    * Class Name: PackageInfo
    * Description: Object to contain managed package info
    */
    private class PackageInfo{
        public String packageName;
        public Integer allowedLicenses;
        public Integer usedLicenses;
        public Date expiryDate;

        public packageInfo(String packageName, Integer allowedLicenses, Integer usedLicenses, Date expiryDate){
            this.packageName = packageName;
            this.allowedLicenses = allowedLicenses;
            this.usedLicenses = usedLicenses;
            this.expiryDate = expiryDate;
        }
    }
}