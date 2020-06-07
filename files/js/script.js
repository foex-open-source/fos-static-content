window.FOS = window.FOS             || {};
window.FOS.utils = window.FOS.utils || {};

FOS.utils.clientsideCondition = function (daContext, config) {

	apex.debug.info('FOS - Execute PL/SQL Code ', config);

	var continueExecution = true;

	if(config.type == 'JAVASCRIPT_EXPRESSION'){
		// calling the function with the original "this"
		continueExecution = config.conditionFunction.call(daContext);
	} else {
		// we use the internal APEX function for all Item =, !=, >, in list, etc conditions
		continueExecution = apex.da.testCondition(config.item, config.type, config.value);
	}

	if (continueExecution) {
		apex.debug.log('The client-side condition was evaluated to True. Proceeding with execution of actions.');
	} else {
		apex.debug.log('The client-side condition was evaluated to False. Stopping execution of actions.');

		if(apex.da.cancel){
			// as of 20.1
			apex.da.cancel();
		} else {
			apex.event.gCancelFlag = true;
			apex.da.gCancelActions = true;
		}

		if (config.elseEventName) {
			apex.debug.log('Triggering "else" event.');
			apex.event.trigger('body', config.elseEventName, daContext.data);
		}
	}
};


