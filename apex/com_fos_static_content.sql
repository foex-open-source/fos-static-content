prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_190200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2019.10.04'
,p_release=>'19.2.0.00.18'
,p_default_workspace_id=>1620873114056663
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'FOS_MASTER_WS'
);
end;
/

prompt APPLICATION 102 - FOS Dev
--
-- Application Export:
--   Application:     102
--   Name:            FOS Dev
--   Exported By:     FOS_MASTER_WS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 34175298479606152
--     PLUGIN: 2657630155025963
--     PLUGIN: 35822631205839510
--     PLUGIN: 14934236679644451
--   Manifest End
--   Version:         19.2.0.00.18
--   Instance ID:     250144500186934
--

begin
  -- replace components
  wwv_flow_api.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_fos_static_content
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(14934236679644451)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.FOS.STATIC_CONTENT'
,p_display_name=>'FOS - Static Content'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/script#MIN#.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function render',
'    ( p_region              apex_plugin.t_region',
'    , p_plugin              apex_plugin.t_plugin',
'    , p_is_printer_friendly boolean',
'    )',
'return apex_plugin.t_region_render_result',
'as',
'    l_return apex_plugin.t_region_render_result;',
'',
'    -- required settings',
'    l_region_id        varchar2(4000) := p_region.static_id;',
'    l_wrapper_id       varchar2(4000) := l_region_id || ''_FOS_WRAPPER'';',
'',
'    l_raw_content      p_region.attribute_01%type := p_region.attribute_01;',
'    l_escape           boolean := p_region.attribute_02 = ''Y'';',
'   ',
'begin',
'',
'    if apex_application.g_debug then',
'        apex_plugin_util.debug_region',
'            ( p_plugin => p_plugin',
'            , p_region => p_region',
'            );',
'    end if;',
'',
'    -- a wrapper is needed to properly identify and replace the content in case of a refresh',
'    htp.p(''<div id="'' || apex_escape.html_attribute(l_wrapper_id) || ''">'');',
'',
'    sys.htp.p(apex_plugin_util.replace_substitutions',
'        ( p_value  => l_raw_content',
'        , p_escape => l_escape',
'        )',
'    );',
'',
'    --closing the wrapper',
'    sys.htp.p(''</div>'');',
'    ',
'    apex_json.initialize_clob_output;',
'',
'    apex_json.open_object;',
'    apex_json.write(''regionId'', l_region_id);',
'    apex_json.write(''regionWrapperId'', l_wrapper_id);',
'    apex_json.write(''rawContent'', l_raw_content);',
'    apex_json.write(''escape'', l_escape);',
'    apex_json.close_object;',
'    ',
'    -- initialization code for the region widget. needed to handle the refresh event',
'    apex_javascript.add_onload_code(''FOS.region.staticContent.init(this, '' || apex_json.get_clob_output || '');'');',
'    ',
'    apex_json.free_output;',
'',
'    return l_return;',
'end;'))
,p_api_version=>2
,p_render_function=>'render'
,p_substitute_attributes=>false
,p_subscribe_plugin_settings=>true
,p_help_text=>'<p>This region type differs from the native "Static Content" region in that it is refreshable.</p>'
,p_version_identifier=>'20.1.0'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'@fos-export',
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>84
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(14934465811644455)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Text'
,p_attribute_type=>'HTML'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'<p>Enter the text source for this component.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(14949404962846770)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Escape Item Values'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Escape any special characters contained in the values of referenced items.</p>',
'<p>For more control, this setting can be turned off, and individul items can be escaped via the <code>&P1_ITEM!HTML.</code> syntax.</p>'))
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E464F53203D2077696E646F772E464F53207C7C207B7D3B0A464F532E726567696F6E203D20464F532E726567696F6E207C7C207B7D3B0A464F532E726567696F6E2E737461746963436F6E74656E74203D20464F532E726567696F6E2E';
wwv_flow_api.g_varchar2_table(2) := '737461746963436F6E74656E74207C7C207B7D3B0A0A2F2A0A202A20496E697469616C697A6174696F6E2066756E6374696F6E20666F72207468652064796E616D696320636F6E74656E7420726567696F6E2E0A202A20546869732066756E6374696F6E';
wwv_flow_api.g_varchar2_table(3) := '206D7573742062652072756E20666F722074686520726567696F6E20746F2073756273637269626520746F207468652072656672657368206576656E740A202A204578706563747320617320706172616D6574657220616E206F626A6563742077697468';
wwv_flow_api.g_varchar2_table(4) := '2074686520666F6C6C6F77696E6720617474726962757465733A0A202A0A202A2040706172616D207B4F626A6563747D20206461436F6E7465787420202020202020202020202020202054686520636F6E74657874204F626A6563742070617373656420';
wwv_flow_api.g_varchar2_table(5) := '6279204150455820746F2064796E616D696320616374696F6E730A202A2040706172616D207B4F626A6563747D2020636F6E666967202020202020202020202020202020202020436F6E66696775726174696F6E206F626A65637420686F6C64696E6720';
wwv_flow_api.g_varchar2_table(6) := '616C6C20617474726962757465730A202A2040706172616D207B737472696E677D2020636F6E6669672E726567696F6E4964202020202020202020546865206D61696E20726567696F6E2049442E2054686520726567696F6E206F6E2077686963682022';
wwv_flow_api.g_varchar2_table(7) := '72656672657368222063616E206265207472696767657265640A202A2040706172616D207B737472696E677D2020636F6E6669672E726567696F6E57726170706572496420204944206F66207772617070657220656C656D656E742E2054686520636F6E';
wwv_flow_api.g_varchar2_table(8) := '74656E7473206F66207468697320656C656D656E742077696C6C206265207265706C61636564207769746820746865206E657720636F6E74656E740A202A2040706172616D207B737472696E677D2020636F6E6669672E726177436F6E74656E74202020';
wwv_flow_api.g_varchar2_table(9) := '202020205468652072617720636F6E74656E7420737472696E670A202A2040706172616D207B626F6F6C65616E7D20636F6E6669672E65736361706520202020202020202020205768657468657220746F20657363617065207468652076616C75657320';
wwv_flow_api.g_varchar2_table(10) := '6F66207265666572656E636564206974656D730A2A2F0A0A464F532E726567696F6E2E737461746963436F6E74656E742E696E6974203D2066756E6374696F6E286461436F6E746578742C20636F6E666967297B0A0A20202020617065782E6465627567';
wwv_flow_api.g_varchar2_table(11) := '2E696E666F2827464F53202D2053746174696320436F6E74656E74272C20636F6E666967293B0A0A2020202076617220656C656D24203D202428272327202B20636F6E6669672E726567696F6E577261707065724964293B0A2020202076617220726177';
wwv_flow_api.g_varchar2_table(12) := '436F6E74656E74203D20636F6E6669672E726177436F6E74656E743B0A2020202076617220657363617065203D20636F6E6669672E6573636170653B0A0A202020202F2F20696D706C656D656E74696E672074686520617065782E726567696F6E20696E';
wwv_flow_api.g_varchar2_table(13) := '7465726661636520696E206F7264657220746F20726573706F6E6420746F2072656672657368206576656E74730A20202020617065782E726567696F6E2E63726561746528636F6E6669672E726567696F6E49642C207B0A202020202020202074797065';
wwv_flow_api.g_varchar2_table(14) := '3A2027666F732D726567696F6E2D7374617469632D636F6E74656E742D636F6E74656E74272C0A2020202020202020726566726573683A2066756E6374696F6E28297B0A202020202020202020202020656C656D242E68746D6C28617065782E7574696C';
wwv_flow_api.g_varchar2_table(15) := '2E6170706C7954656D706C61746528726177436F6E74656E742C207B0A2020202020202020202020202020202064656661756C7445736361706546696C7465723A20657363617065203F202748544D4C27203A2027524157270A20202020202020202020';
wwv_flow_api.g_varchar2_table(16) := '20207D29293B0A20202020202020207D0A202020207D293B0A7D3B0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14940628687644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227363726970742E6A73225D2C226E616D6573223A5B2277696E646F77222C22464F53222C22726567696F6E222C22737461746963436F6E74656E74222C22696E6974222C226461436F6E74';
wwv_flow_api.g_varchar2_table(2) := '657874222C22636F6E666967222C2261706578222C226465627567222C22696E666F222C22656C656D24222C2224222C22726567696F6E577261707065724964222C22726177436F6E74656E74222C22657363617065222C22637265617465222C227265';
wwv_flow_api.g_varchar2_table(3) := '67696F6E4964222C2274797065222C2272656672657368222C2268746D6C222C227574696C222C226170706C7954656D706C617465222C2264656661756C7445736361706546696C746572225D2C226D617070696E6773223A2241414141412C4F41414F';
wwv_flow_api.g_varchar2_table(4) := '432C4941414D442C4F41414F432C4B41414F2C4741433342412C49414149432C4F414153442C49414149432C514141552C4741433342442C49414149432C4F41414F432C6341416742462C49414149432C4F41414F432C65414169422C4741657644462C';
wwv_flow_api.g_varchar2_table(5) := '49414149432C4F41414F432C63414163432C4B41414F2C53414153432C45414157432C4741456844432C4B41414B432C4D41414D432C4B41414B2C754241417742482C47414578432C49414149492C45414151432C454141452C4941414D4C2C4541414F';
wwv_flow_api.g_varchar2_table(6) := '4D2C694241437642432C45414161502C4541414F4F2C5741437042432C45414153522C4541414F512C4F41477042502C4B41414B4C2C4F41414F612C4F41414F542C4541414F552C534141552C4341436843432C4B41414D2C6F4341434E432C51414153';
wwv_flow_api.g_varchar2_table(7) := '2C5741434C522C4541414D532C4B41414B5A2C4B41414B612C4B41414B432C63414163522C454141592C4341433343532C6F4241417142522C454141532C4F414153222C2266696C65223A227363726970742E6A73227D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14941071112644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.js.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E464F533D77696E646F772E464F537C7C7B7D2C464F532E726567696F6E3D464F532E726567696F6E7C7C7B7D2C464F532E726567696F6E2E737461746963436F6E74656E743D464F532E726567696F6E2E737461746963436F6E74656E';
wwv_flow_api.g_varchar2_table(2) := '747C7C7B7D2C464F532E726567696F6E2E737461746963436F6E74656E742E696E69743D66756E6374696F6E28742C65297B617065782E64656275672E696E666F2822464F53202D2053746174696320436F6E74656E74222C65293B766172206E3D2428';
wwv_flow_api.g_varchar2_table(3) := '2223222B652E726567696F6E577261707065724964292C693D652E726177436F6E74656E742C6F3D652E6573636170653B617065782E726567696F6E2E63726561746528652E726567696F6E49642C7B747970653A22666F732D726567696F6E2D737461';
wwv_flow_api.g_varchar2_table(4) := '7469632D636F6E74656E742D636F6E74656E74222C726566726573683A66756E6374696F6E28297B6E2E68746D6C28617065782E7574696C2E6170706C7954656D706C61746528692C7B64656661756C7445736361706546696C7465723A6F3F2248544D';
wwv_flow_api.g_varchar2_table(5) := '4C223A22524157227D29297D7D297D3B0A2F2F2320736F757263654D617070696E6755524C3D7363726970742E6A732E6D6170';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14941461739644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done


