({
    copyJsObjectProperties : function(source, target) {
        if (typeof source == "object" && typeof target == "object") {
            for (var property in source) {
                if (source.hasOwnProperty(property)) {
                    target[property] = source[property];
                }
            }
        }
    }
})