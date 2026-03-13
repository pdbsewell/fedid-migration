import getFeatureSettings from '@salesforce/apex/ApplicationNavigationController.fetchMyAppFeatureToggle';

// Save the original console functions so you can restore them if needed.
const originalConsoleLog = window.console.log;
const originalConsoleWarn = window.console.warn;
const originalConsoleError = window.console.error;
let _isInitialized = false;

/**
 * Initializes console functions.
 *
 * @param {Object} options - Optional settings.
 * @param {Boolean} options.loggingEnabled - If defined, forces logging on (true) or off (false),
 *   disregarding the custom setting. 
 */
export function initConsoleFunctions({ loggingEnabled } = {}) {
    // If an override is provided, apply it immediately.
    if (loggingEnabled !== undefined) {
        if (loggingEnabled) {
            // Enable logging: restore original console functions.
            resetConsoleFunctions();
        } else {
            console.warn('Console logging is disabled.');
            // Disable logging: override functions with no-ops.
            window.console.log = () => {};
            window.console.warn = () => {};
            window.console.error = () => {};
        }
        _isInitialized = true;
        return;
    }

    // Otherwise, use the custom setting from Apex (if not already initialized).
    if (!_isInitialized) {
        getFeatureSettings()
            .then(result => {
                // If the custom setting indicates that logging should be disabled, override the functions.
                if (result && !result.Console_Logs_Enabled__c) {
                    window.console.log = () => {};
                    window.console.warn = () => {};
                    window.console.error = () => {};
                } else {
                    // Otherwise, restore the original functions.
                    resetConsoleFunctions();
                }
                _isInitialized = true;
            })
            .catch(error => {
                // Use the original console.error to log any error during initialization.
                originalConsoleError('Error retrieving feature settings', error);
            });
    }
}

/**
 * Restores the original console functions.
 */
export function resetConsoleFunctions() {
    window.console.log = originalConsoleLog;
    window.console.warn = originalConsoleWarn;
    window.console.error = originalConsoleError;
    _isInitialized = false;
}