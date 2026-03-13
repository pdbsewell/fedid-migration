({
	setPicklistOptions : function(component, event, helper, valueLabelMap, picklistAttribute, selectedValue) {
        var options = [];
        for (var key in valueLabelMap) {
            console.log(key);
            options.push({
                class : 'optionClass',
                label : valueLabelMap[key],
                value : key,
                selected : (key == selectedValue)
            });
        }
        
        component.set(picklistAttribute, options);
    }
})