/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-console */
/* eslint-disable vars-on-top */
/**
 * usage: import * as util from 'c/util';
 */
import getQuoteLineList from '@salesforce/apex/OfferLightningEnabledClass.getQuoteLineList';
const timedOutSubStatus = 'Timed out on portal';
const previesReleasedSubStatus = 'Preview Released';
const pendingSignatureSubStatus = 'Pending Signature in DocuSign';
const acceptedStatus = 'Accepted';
const newStatus = 'New';
const publishedStatus = 'Published';
const signedStatus = 'Signed';
const subStatusTriggerConga = 'Details changed';
const subStatusCompleted = 'Details completed';
const gradResearchOppName = '-GRCAND-';
/**
 * usage: util.log(message); 
 */
const log = (message) => {
    console.log(message);
}
/**
 * usage: util.log(object); 
 */
const logJson = (object) =>{
    console.log(JSON.stringify(object));
}

/**
 * usage: util.urlParameter(url);  e.g. url = window.location.href
 */
const urlParameter = (url) =>{
    let urlParams = new URL(url).searchParams;
    return urlParams;
}

/**
 * usage: util.getQuoteLines(offerId); 
 */
const getQuoteLines = (parentId) =>{
 return getQuoteLineList({offerId: parentId})
            .then(result => {
                return result;
            })
            .catch(error => {
                return error;
            });
}

/**
 * usage: util.getQuoteLines(object); 
 */
const isOfferReadOnly = (offerRecord) =>{
    return offerRecord.Sub_Status__c.value === 'Details completed'
        || offerRecord.Sub_Status__c.value === 'Ready for acknowledgement';
}

/**
 * usage: util.disableButton(object); 
 * object being @wire query return
 */
const disableButton = (offerRecord) =>{
    return offerRecord.Sub_Status__c.value === 'Contract Created'
    || offerRecord.Sub_Status__c.value === 'Conga Error'
    || offerRecord.Sub_Status__c.value === 'DocuSign Error'
    || offerRecord.Sub_Status__c.value === 'Pending Signature in DocuSign'
    || offerRecord.Sub_Status__c.value === 'Signed recipient 1'
    || offerRecord.Sub_Status__c.value === 'Signed recipient 2'
    || offerRecord.Sub_Status__c.value === 'APEX Doc. Gen/Save Error'
    || offerRecord.SBQQ__Status__c === 'Signed';
}

/**
 * usage: util.dateFormatted(new Date()); 
 */
const dateFormatted = (date) =>{
    return formatDate(date);
}

/**
 * usage: util.formatDate(new Date()); 
 * return: 01 Jan 2000
 */
function formatDate(date) {
    if(date){
        var monthNames = [
            "Jan", "Feb", "March",
            "April", "May", "June", "July",
            "Aug", "Sept", "Oct",
            "Nov", "Dec"
            ];
    
        var day = date.getUTCDate().toString().padStart(2, "0");
        var monthIndex = date.getUTCMonth();
        var year = date.getUTCFullYear();
        
        return day + ' ' + monthNames[monthIndex] + ' ' + year;
    }
    return '';
}

/**
 * usage: util.longMonthName(new Date()); 
 * return: January
 */
const longMonthName = (date) =>{
    return getLongMonth(date);
}

function getLongMonth(date){
    var monthIndex = date.getMonth();
    var monthNames = [
        "January", "February", "March",
        "April", "May", "June", "July",
        "August", "September", "October",
        "November", "December"
        ];
    return monthNames[monthIndex];
}

/**
 * usage: util.getDaysbetweenDates(new Date(), new Date()); 
 */
const getDaysbetweenDates = (date1, date2) =>{
    return daysBetweenDates(date1, date2);
}

function daysBetweenDates(date1, date2){
    var dt1 = new Date(date1); 
    var dt2 = new Date(date2); 
    
    let utcDate2 = Date.UTC(dt2.getFullYear(), dt2.getMonth(), dt2.getDate());
    let utcDate1 = Date.UTC(dt1.getFullYear(), dt1.getMonth(), dt1.getDate());

    var Difference_In_Days = ((utcDate2 - utcDate1) /(1000 * 60 * 60 * 24));
    return Difference_In_Days;
}
/**
 * usage: util.formattedCurrency(double); 
 */
const formattedCurrency = (curr) =>{
    if(curr != null){
        return curr.toLocaleString(undefined, {maximumFractionDigits:2});
    }
    return '';
}

/**
 * usage: util.replaceAllString(string, stringToReplace, replacementValue); 
 */
const replaceAllString = (content, str, filedValue) =>{
    if(filedValue){
        return content.split(str).join(filedValue);
    }
    return content.split(str).join('');
}
  
/**
 * usage: util.splitPhoneNumber('+61435815010');
 * @returns {object} An object containing the country code, local number, formatted versions, and country name.
 * @param {string} fullNumber - The full phone number to split.
 * @param {string} preferredCountryName - The preferred country name to prioritize in matching.
 * @param {string} codeField - The field name for the country code in the country list.
 * @param {string} nameField - The field name for the country name in the country list.
 * @example
 * const countryList = [
 *   { NumericPhoneCode__c: '+61', Country__c: 'Australia' },
 *   { NumericPhoneCode__c: '+1', Country__c: 'United States' },
 *   { NumericPhoneCode__c: '+44', Country__c: 'United Kingdom' }
 * ];
 * const splitter = createPhoneSplitter(countryList);
 * const result = splitter('+61435815010');
 * console.log(result); // { countryCode: '+61', localNumber: '435815010', formattedFull: '(+61) 0435 815 010', countryName: 'Australia' }
 */
const createPhoneSplitter = (countryList, codeField = 'NumericPhoneCode__c', nameField = 'ShortName__c') => {
    const codeMap = countryList
      .filter(c => c[codeField])
      .map(c => {
        const rawCode = c[codeField].toString().replace(/^\+/, '').trim();
        return {
          rawCode,
          countryCode: `+${rawCode}`,
          countryCodeDisplay: `(+${rawCode})`,
          countryName: c[nameField] || ''
        };
      })
      .sort((a, b) => b.rawCode.length - a.rawCode.length); // longest code match first
  
    const formatLocalNumber = (num) => {
      const digits = num.replace(/[^\d]/g, '');
      if (digits.length === 10) return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
      if (digits.length === 9) return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
      if (digits.length === 8) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
      return digits; // fallback to raw if length doesn't match known patterns
    };
  
    return function splitPhoneNumber(fullNumber, preferredCountryName = null) {
      if (!fullNumber || typeof fullNumber !== 'string') {
        return {
          countryCode: null,
          rawCountryCode: null,
          countryCodeDisplay: null,
          localNumber: null,
          formattedLocalNumber: null,
          formattedFull: null,
          countryName: null,
          matches: []
        };
      }
  
      const clean = fullNumber.replace(/[^\d]/g, '');
      const matchingCountries = codeMap.filter(entry => clean.startsWith(entry.rawCode));
  
      let match = matchingCountries[0];
      if (preferredCountryName) {
          const preferred = matchingCountries.find(entry => entry.countryName.toLowerCase() === preferredCountryName.toLowerCase());
          if (preferred) {
              match = preferred;
          }
      }
  
      if (match) {
        const local = clean.slice(match.rawCode.length);
        const formattedLocal = formatLocalNumber(local);
        return {
          countryCode: match.countryCode,
          rawCountryCode: match.rawCode,
          countryCodeDisplay: match.countryCodeDisplay,
          localNumber: local,
          formattedLocalNumber: formattedLocal,
          formattedFull: `${match.countryCodeDisplay} ${formattedLocal}`,
          countryName: match.countryName,
          matches: matchingCountries
        };
      }
  
      // If no country match found
      const fallbackFormatted = formatLocalNumber(clean);
      return {
        countryCode: null,
        rawCountryCode: null,
        countryCodeDisplay: null,
        localNumber: clean,
        formattedLocalNumber: fallbackFormatted,
        formattedFull: fallbackFormatted,
        countryName: null,
        matches: []
      };
    };
};
/**
 * Starts a countdown timer.
 * @param {number} durationSeconds - Total duration in seconds.
 * @param {function} onTick - Callback fired every tick with remaining time.
 * @returns {object} handle with stop() method to clear the timer.
 *
 * Example:
 * const timer = startTimer(30, ({ seconds, formattedTime }) => {
 *   console.log('Remaining:', seconds, formattedTime);
 * });
 * timer.stop(); // when needed
 */
const startTimer= (durationSeconds, onTick)=> {
    let intervalId = null;
    const start = Date.now();
    const totalMs = durationSeconds * 1000;

    function format(ms) {
        const hours = Math.floor((ms % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((ms % (1000 * 60)) / 1000);
        const milliseconds = Math.floor(ms % 1000);
        return `${hours}:${minutes}:${seconds}:${milliseconds}`;
    }

    intervalId = setInterval(() => {
        const elapsed = Date.now() - start;
        const remaining = Math.max(totalMs - elapsed, 0);
        const seconds = Math.floor(remaining / 1000);
        const formattedTime = format(remaining);

        if (typeof onTick === 'function') {
            onTick({ seconds, formattedTime });
        }

        if (remaining <= 0) {
            clearInterval(intervalId);
        }
    }, 100);

    return {
        stop: () => {
            if (intervalId) {
                clearInterval(intervalId);
                intervalId = null;
            }
        }
    };
}
  
export {
    log, logJson, urlParameter, getQuoteLines, dateFormatted, isOfferReadOnly,
        subStatusTriggerConga, longMonthName, getDaysbetweenDates, formattedCurrency,
    replaceAllString, timedOutSubStatus, previesReleasedSubStatus, pendingSignatureSubStatus,
        acceptedStatus, newStatus, publishedStatus, signedStatus, subStatusCompleted, disableButton, 
    gradResearchOppName, createPhoneSplitter, startTimer
}