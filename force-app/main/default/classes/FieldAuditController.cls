public with sharing class FieldAuditController {
    @AuraEnabled
    public static void logFieldAccess(String recordId, String fieldName, String reason) {
        try {
            nebula.Logger.setScenario('PII Reveal Audit');
            nebula.Logger.info('User revealed private field')
                  .setRecordId(recordId)
                  .addTag('Security')
                  .addTag('PII_Access')
                  .setMessage('Field: ' + fieldName + ' | Reason: ' + reason);
            nebula.Logger.saveLog();
            nebula.Logger.endScenario('PII Reveal Audit');
            
        } catch (Exception e) {
            nebula.Logger.error('PII Audit Logging Failed', e)
                  .setRecordId(recordId);
            
            nebula.Logger.saveLog();
            nebula.Logger.endScenario('PII Reveal Audit');

            throw new AuraHandledException('Security log could not be created. Access denied.');
        }
    }
}