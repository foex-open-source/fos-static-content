function render
    ( p_region              apex_plugin.t_region
    , p_plugin              apex_plugin.t_plugin
    , p_is_printer_friendly boolean
    )
return apex_plugin.t_region_render_result
as
    l_return apex_plugin.t_region_render_result;

    -- required settings
    l_region_id        varchar2(4000) := p_region.static_id;
    l_wrapper_id       varchar2(4000) := l_region_id || '_FOS_WRAPPER';

    l_raw_content      p_region.attribute_01%type := p_region.attribute_01;
    l_escape           boolean := p_region.attribute_02 = 'Y';

begin

    if apex_application.g_debug then
        apex_plugin_util.debug_region
            ( p_plugin => p_plugin
            , p_region => p_region
            );
    end if;

    -- a wrapper is needed to properly identify and replace the content in case of a refresh
    htp.p('<div id="' || apex_escape.html_attribute(l_wrapper_id) || '">');

    sys.htp.p(apex_plugin_util.replace_substitutions
        ( p_value  => l_raw_content
        , p_escape => l_escape
        )
    );

    --closing the wrapper
    sys.htp.p('</div>');

    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write('regionId', l_region_id);
    apex_json.write('regionWrapperId', l_wrapper_id);
    apex_json.write('rawContent', l_raw_content);
    apex_json.write('escape', l_escape);
    apex_json.close_object;

    -- initialization code for the region widget. needed to handle the refresh event
    apex_javascript.add_onload_code('FOS.region.staticContent.init(this, ' || apex_json.get_clob_output || ');');

    apex_json.free_output;

    return l_return;
end;

