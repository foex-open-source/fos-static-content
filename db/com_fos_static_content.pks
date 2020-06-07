create or replace package com_fos_static_content
as

    function render
        ( p_region              apex_plugin.t_region
        , p_plugin              apex_plugin.t_plugin
        , p_is_printer_friendly boolean
        )
    return apex_plugin.t_region_render_result;

end;
/


