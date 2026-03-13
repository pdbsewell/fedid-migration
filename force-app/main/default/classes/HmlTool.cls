/**
 * Handlebars template processing tool for Apex.
 * Only supports the following subset of the handlebars language:
 * - merge fields - escaped "{{" and unescaped "{{{"
 *      - {{Key}}, {{{Contact.Field__c}}} {{People.Tom.Name}}
 * - if/else
 *      - {{#if Key}}Text If True{{else}}Text If False{{/if}}
 * - unless
 *      - {{#unless Key}}Text If False{{/unless}}
 * - each
 *      - {{#each People}}Name: {{this.Name}}, {{/each}} (People = Map<String, Object>)
 *      - {{#each Numbers}}{{this}} {{/each}} (Numbers = List<Integer>)
 *
 * Note: "unless" and "each" are not supported in Lightning emails and will prevent them from saving/compiling.
 *
 * @author Tom Gangemi
 * @date 2023-06-09
 * @testclass HmlTool_Test
 * @group Utilities
 **/
public with sharing class HmlTool {

    /**
     * Handle conversion of generic objects to String
     * Currently fixes Dates as String.valueOf() without casting adds a time to string, e.g. "2016-01-01 00:00:00"
     */
    public static String stringVal(Object o) {
        if (o instanceof Date) return String.valueOf((Date)o);
        return String.valueOf(o);
    }
    /**
     * Convert any object to a bool
     * - Numbers are true if > 0
     * - Strings are true if not blank
     * - Everything else is true if not null
     */
    public static Boolean booleanVal(Object o) {
        if (o instanceof Boolean) return (Boolean)o;
        if (o instanceof String) return String.isNotBlank((String)o);
        if (o instanceof Integer) return (Integer)o > 0;
        if (o instanceof Double) return (Double)o > 0;
        if (o instanceof Long) return (Long)o > 0;
        if (o instanceof Decimal) return (Decimal)o > 0;
        return o != null;
    }

    final static Pattern expressionPattern = Pattern.compile('\\{\\{\\{([^\\}]+)\\}\\}\\}|\\{\\{([^\\}]+)\\}\\}');
    final public static String ERR_MISSING_END_BLOCK = 'No matching end block for: ';
    final public static String ERR_UNSUPPORTED_HELPER = 'Unsupported helper: ';

    /**
     * Render a template but instead of returning the rendered template, return a list of errors.
     */
    public static String[] validateTemplate(String template, Map<String,Object> mergeData) {
        Context cont = new Context(mergeData);
        cont.render(template);
        return cont.errors;
    }

    public static String[] validateTemplate(String template) {
        return validateTemplate(template, new Map<String,Object>());
    }

    public class Context {
        public final Map<String, Object> mergeVars;
        public String[] errors = new String[]{};
        private Boolean retainUnmatchedMergeFields = false;

        public Context() {
            this.mergeVars = new Map<String, Object>();
        }

        public Context(Map<String, Object> mergeData) {
            this.mergeVars = mergeData;
        }

        public Context(SObject mergeData) {
            this.mergeVars = mergeData.getPopulatedFieldsAsMap().clone();
        }

        /**
         * Add a merge variable to the template.
         *  - value can be nested maps or lists
         *  - if value is an SObject, it will be converted to a Map<String, Object> using getPopulatedFieldsAsMap()
         *
         * @param key The key to use in the template
         * @param value The value to use in the template
         */
        public void addMergeVar(String key, Object value) {
            mergeVars.put(key, value instanceof SObject ? ((SObject)value).getPopulatedFieldsAsMap() : value);
        }

        public String render(String template) {
            return render(template, this.retainUnmatchedMergeFields);
        }

        /**
         * Render template with the current context.
         * @param template The template to render
         * @param retainUnmatchedMergeFields If true, unmatched merge fields will be retained in the output (helper blocks will still be removed)
         * @return The rendered template
         */
        public String render(String template, Boolean retainUnmatchedMergeFields) {
            Matcher matcher = expressionPattern.matcher(template);
            this.retainUnmatchedMergeFields = retainUnmatchedMergeFields;

            Integer curPos = 0; // use offset to skip over unmatched merge fields
            while (matcher.find(curPos)) {
                // extract the expression and determine if it is triple-stash "{{{" (unescaped) or not
                String expression;
                String rawExpression = matcher.group();
                Boolean isUnescaped = false;
                if (matcher.group(1) != null) {
                    expression = matcher.group(1);
                    isUnescaped = true;
                } else {
                    expression = matcher.group(2);
                }

                if (expression.startsWith('#')) {
                    // Handle helper (conditional or iteration)
                    String helperType = expression.substring(1).split(' ',2)[0]; // if, unless, each
                    String key = expression.substring(helperType.length() + 2); // Object.Value, Value
                    String endBlock = '{{/' + helperType + '}}';

                    Integer startBlockPos = matcher.start();
                    Integer endBlockPos = template.indexOf(endBlock, startBlockPos);
                    if (endBlockPos == -1) {
                        errors.add(ERR_MISSING_END_BLOCK + rawExpression);
                        // remove the expression and continue
                        template = template.substring(0, startBlockPos) + template.substring(matcher.end());
                        curPos = matcher.start();
                        matcher = expressionPattern.matcher(template);
                        continue;
                    }
                    String blockContent = template.substring(matcher.end(), endBlockPos);
                    String newContent;
                    if (helperType == 'if') {
                        newContent = handleIfUnless(false, key, blockContent);
                    } else if (helperType == 'unless') {
                        newContent = handleIfUnless(true, key, blockContent);
                    } else if (helperType == 'each') {
                        newContent = handleEach(key, blockContent);
                    } else {
                        errors.add(ERR_UNSUPPORTED_HELPER + rawExpression);
                    }
                    template = template.substring(0, startBlockPos) + newContent + template.substring(endBlockPos + endBlock.length());
                    curPos = startBlockPos + newContent.length();
                } else {
                    // Handle simple replacement
                    Object val = getValue(expression);
                    String replacement = '';
                    if(val != null) {
                        replacement = stringVal(val);
                        if (!isUnescaped) {
                            replacement = replacement.escapeHtml4();
                        }
                    }
                    if(val != null || !retainUnmatchedMergeFields) {
                        // replace the expression
                        template = template.substring(0, matcher.start()) + replacement + template.substring(matcher.end());
                        curPos = matcher.start();
                    } else {
                        // expression is unmatched and should be retained, continue from the end of the expression
                        curPos = matcher.end();
                    }
                }
                matcher = expressionPattern.matcher(template); // Re-evaluate the updated template
            }
            return template;
        }

        public String handleIfUnless(Boolean isUnless, String key, String blockContent) {
            Boolean value = booleanVal(getValue(key)) ^ isUnless;

            Integer elseIndex = blockContent.indexOf('{{else}}');
            if (elseIndex != -1) {
                // has else block
                String trueContent = blockContent.substring(0, elseIndex);
                String falseContent = blockContent.substring(elseIndex + 8); // Length of '{{else}}' is 8
                return value ? render(trueContent, retainUnmatchedMergeFields) : render(falseContent, retainUnmatchedMergeFields);
            } else {
                return value ? render(blockContent, retainUnmatchedMergeFields) : '' ;
            }
        }

        public String handleEach(String key, String blockContent) {
            List<Object> items = (List<Object>) getValue(key);
            String[] eachPart = new String[0];
            // create a new context for inside the loop, with the current item as 'this'
            Context itemContext = new Context(mergeVars.clone());
            for (Object item : items) {
                itemContext.addMergeVar('this', item);
                eachPart.add(itemContext.render(blockContent, retainUnmatchedMergeFields));
            }
            return String.join(eachPart, '');
        }

        /**
         * Retrieve a given key's value from mergeData
         *
         * @param key can be a nested key, e.g. "Object.Object.Value"
         * @return The value of the key, or null if not found
         */
        public Object getValue(String key) {
            String[] keys = key.split('\\.');
            if(keys.size() > 1) {
                Map<String, Object> nestedMergeVars = mergeVars;
                for(Integer i = 0; i < keys.size() - 1; i++) {
                    nestedMergeVars = (Map<String, Object>) nestedMergeVars.get(keys[i]);
                }
                if(nestedMergeVars != null)
                    return nestedMergeVars.get(keys[keys.size() - 1]);
                else
                    return null;
            }
            return mergeVars.get(key);
        }
    }

}