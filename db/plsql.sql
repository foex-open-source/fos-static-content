function render
    ( p_dynamic_action apex_plugin.t_dynamic_action
    , p_plugin         apex_plugin.t_plugin
    )
return apex_plugin.t_dynamic_action_render_result
as
    l_result apex_plugin.t_dynamic_action_render_result;

    l_type                  p_dynamic_action.attribute_01%type := p_dynamic_action.attribute_01;
    l_item                  p_dynamic_action.attribute_02%type := p_dynamic_action.attribute_02;
    l_value                 p_dynamic_action.attribute_03%type := p_dynamic_action.attribute_03;
    l_javascript_expression p_dynamic_action.attribute_04%type := p_dynamic_action.attribute_04;
    l_else_event_name       p_dynamic_action.attribute_06%type := p_dynamic_action.attribute_06;
begin

    if apex_application.g_debug then
        apex_plugin_util.debug_dynamic_action
            ( p_plugin         => p_plugin
            , p_dynamic_action => p_dynamic_action
            );
    end if;

    apex_json.initialize_clob_output;
    apex_json.open_object;

    apex_json.write('type' , l_type);

    if l_type = 'JAVASCRIPT_EXPRESSION' then
        apex_json.write_raw
            ( p_name  => 'conditionFunction'
            , p_value => 'function(){return (' || l_javascript_expression || ');}'
            );
    else
        apex_json.write('item' , l_item);
        apex_json.write('value', l_value);
    end if;

    apex_json.write('elseEventName', l_else_event_name);

    apex_json.close_object;

    l_result.javascript_function := 'function(){FOS.utils.clientsideCondition(this, ' || apex_json.get_clob_output || ');}';

    apex_json.free_output;

    return l_result;
end;

