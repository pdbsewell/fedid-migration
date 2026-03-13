/**
 * @description Utility class for session management
 * @author      Kai-Fan Hsieh
 * @since       19/08/2024
 */
public with sharing class SessionUtils {
    /**
   * @description Retrieves the current user's session ID.
   * @return A string representing the session ID of the current user.
   */
    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
    public static String PARTITION {
        get {
            if (partition == null) {
                partition = 'MONASH'; // Default Platform Cache Partition
            }
            return partition;
        }
        set {
            partition = value;
        }
    }

    /**
     * Stores a value in Session Cache
     * @param key - Unique key for the cache entry
     * @param value - Value to store in cache (String format)
     * @param ttlSeconds - Time-to-live in seconds (optional)
     * @return Boolean - True if successfully stored, False otherwise
     */
    public static Boolean setCacheValue(String key, String value, Integer ttlSeconds) {
        try {
            Cache.SessionPartition partition = Cache.Session.getPartition(PARTITION);
            if (partition != null) {
                partition.put(key, value, ttlSeconds);
                return true;
            }
        } catch (Exception e) {
            Nebula.logger.error('Error setting cache: ' + e.getMessage()).addTag('MY.App OTP');
        }
        return false;
    }
    
    /**
     * Retrieves a value from Session Cache
     * @param key - Unique key for the cache entry
     * @return String - Cached value or null if not found
     */
    public static String getCacheValue(String key) {
        try {
            Cache.SessionPartition partition = Cache.Session.getPartition(PARTITION);
            if (partition != null) {
                return (String) partition.get(key);
            }
        } catch (Exception e) {
            Nebula.logger.error('Error retrieving cache: ' + e.getMessage()).addTag('MY.App OTP');
        }
        return null;
    }
    
    /**
     * Clears a specific key from Session Cache
     * @param key - Unique key for the cache entry
     */
    public static void clearCacheValue(String key) {
        try {
            Cache.SessionPartition partition = Cache.Session.getPartition(PARTITION);
            if (partition != null) {
                partition.remove(key);
            }
        } catch (Exception e) {
            Nebula.logger.error('Error clearing cache: ' + e.getMessage()).addTag('MY.App OTP');
        }   
    }
}