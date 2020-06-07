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
prompt --application/shared_components/plugins/dynamic_action/com_fos_clientside_condition
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(37441962356114799)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'COM.FOS.CLIENTSIDE_CONDITION'
,p_display_name=>'FOS - Client-side Condition'
,p_category=>'EXECUTE'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/script.min.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function render',
'    ( p_dynamic_action apex_plugin.t_dynamic_action',
'    , p_plugin         apex_plugin.t_plugin',
'    )',
'return apex_plugin.t_dynamic_action_render_result',
'as',
'    l_result apex_plugin.t_dynamic_action_render_result;',
'    ',
'    l_type                  p_dynamic_action.attribute_01%type := p_dynamic_action.attribute_01;',
'    l_item                  p_dynamic_action.attribute_02%type := p_dynamic_action.attribute_02;',
'    l_value                 p_dynamic_action.attribute_03%type := p_dynamic_action.attribute_03;',
'    l_javascript_expression p_dynamic_action.attribute_04%type := p_dynamic_action.attribute_04;',
'    l_else_event_name       p_dynamic_action.attribute_06%type := p_dynamic_action.attribute_06;',
'begin',
'    ',
'    if apex_application.g_debug then',
'        apex_plugin_util.debug_dynamic_action',
'            ( p_plugin         => p_plugin',
'            , p_dynamic_action => p_dynamic_action ',
'            );',
'    end if;',
'',
'    apex_json.initialize_clob_output;',
'    apex_json.open_object;',
'    ',
'    apex_json.write(''type'' , l_type);',
'    ',
'    if l_type = ''JAVASCRIPT_EXPRESSION'' then',
'        apex_json.write_raw',
'            ( p_name  => ''conditionFunction''',
'            , p_value => ''function(){return ('' || l_javascript_expression || '');}''',
'            );',
'    else',
'        apex_json.write(''item'' , l_item);',
'        apex_json.write(''value'', l_value);',
'    end if;',
'',
'    apex_json.write(''elseEventName'', l_else_event_name);',
'',
'    apex_json.close_object;',
'    ',
'    l_result.javascript_function := ''function(){FOS.utils.clientsideCondition(this, '' || apex_json.get_clob_output || '');}'';',
'    ',
'    apex_json.free_output;',
'',
'    return l_result;',
'end;'))
,p_api_version=>2
,p_render_function=>'render'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_help_text=>'Specify a client-side condition to control whether the execution of actions continues or stops. If the condition evaluates to True, then the rest of True or False actions are executed, if the condition evaluates to False, the execution stops.'
,p_version_identifier=>'20.1.0'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'@fos-export',
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>75
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37504322492994203)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'JAVASCRIPT_EXPRESSION'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Specify a client-side condition type to control whether or not to proceed with the remaining actions.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37505036807996840)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>10
,p_display_value=>'Item = Value'
,p_return_value=>'EQUALS'
,p_help_text=>'Checks if the value of the selected Item is equal to the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37505379050998525)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>20
,p_display_value=>'Item != Value'
,p_return_value=>'NOT_EQUALS'
,p_help_text=>'Checks if the value of the selected Item is not equal to the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37505868315000005)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>30
,p_display_value=>'Item > Value'
,p_return_value=>'GREATER_THAN'
,p_help_text=>'Checks if the value of the selected Item is greater than the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37506187179001183)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>40
,p_display_value=>'Item >= Value'
,p_return_value=>'GREATER_THAN_OR_EQUAL'
,p_help_text=>'Checks if the value of the selected Item is greater than or equal to the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37506634373003831)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>50
,p_display_value=>'Item < Value'
,p_return_value=>'LESS_THAN'
,p_help_text=>'Checks if the value of the selected Item is less than the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37507049016004933)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>60
,p_display_value=>'Item <= Value'
,p_return_value=>'LESS_THAN_OR_EQUAL'
,p_help_text=>'Checks if the value of the selected Item is less than or equal to the Value specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37507379545006078)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>70
,p_display_value=>'Item is null'
,p_return_value=>'NULL'
,p_help_text=>'Checks if the selected Item is empty.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37507869166007183)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>80
,p_display_value=>'Item is not null'
,p_return_value=>'NOT_NULL'
,p_help_text=>'Checks if the selected Item is not empty.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37508190443010112)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>90
,p_display_value=>'Item is in list'
,p_return_value=>'IN_LIST'
,p_help_text=>'Checks if the value of the selected Item is in the List specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37508641338014090)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>100
,p_display_value=>'Item is not in list'
,p_return_value=>'NOT_IN_LIST'
,p_help_text=>'Checks if the value of the selected Item is not in the List specified.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37509064796015977)
,p_plugin_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_display_sequence=>110
,p_display_value=>'JavaScript Expression'
,p_return_value=>'JAVASCRIPT_EXPRESSION'
,p_help_text=>'Evaluates the JavaScript Expression specified.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37516627480233283)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Item'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'EQUALS,NOT_EQUALS,GREATER_THAN,GREATER_THAN_OR_EQUAL,LESS_THAN,LESS_THAN_OR_EQUAL,NULL,NOT_NULL,IN_LIST,NOT_IN_LIST'
,p_help_text=>'Enter the page item used in this condition. You can type in the name or pick from the list of available items.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37516934287267651)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Value'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>true
,p_depending_on_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'EQUALS,NOT_EQUALS,GREATER_THAN,GREATER_THAN_OR_EQUAL,LESS_THAN,LESS_THAN_OR_EQUAL,NULL,NOT_NULL,IN_LIST,NOT_IN_LIST'
,p_help_text=>'Enter the value for this condition.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37517743817430748)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'JavaScript Expression'
,p_attribute_type=>'JAVASCRIPT'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(37504322492994203)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'JAVASCRIPT_EXPRESSION'
,p_help_text=>'<p>A JavaScript expression that evaluates to <code>true</code> or <code>false</code>.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37544429503653997)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Trigger Else Event'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'</p>Select "Yes" to trigger a custom event when the condition evaluates to False. This acts as an ELSE handler i.e. you can create a new dynamic action that listens to a custom event to perform alternate actions.</p>',
'',
'<p><strong>Note:</strong> the event will be triggered against the HTML document''s body tag. So in the "When" section in Page Designer use the selection type: "jQuery Selector" and for the jQuery Selector attribute use the value: "body"</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37545143143657431)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'Event Name'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(37544429503653997)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>'Enter the name of the custom event.'
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E464F53203D2077696E646F772E464F53202020202020202020202020207C7C207B7D3B0A77696E646F772E464F532E7574696C73203D2077696E646F772E464F532E7574696C73207C7C207B7D3B0A0A464F532E7574696C732E636C69';
wwv_flow_api.g_varchar2_table(2) := '656E7473696465436F6E646974696F6E203D2066756E6374696F6E20286461436F6E746578742C20636F6E66696729207B0A0A09617065782E64656275672E696E666F2827464F53202D204578656375746520504C2F53514C20436F646520272C20636F';
wwv_flow_api.g_varchar2_table(3) := '6E666967293B0A0A0976617220636F6E74696E7565457865637574696F6E203D20747275653B0A0A09696628636F6E6669672E74797065203D3D20274A4156415343524950545F45585052455353494F4E27297B0A09092F2F2063616C6C696E67207468';
wwv_flow_api.g_varchar2_table(4) := '652066756E6374696F6E207769746820746865206F726967696E616C202274686973220A0909636F6E74696E7565457865637574696F6E203D20636F6E6669672E636F6E646974696F6E46756E6374696F6E2E63616C6C286461436F6E74657874293B0A';
wwv_flow_api.g_varchar2_table(5) := '097D20656C7365207B0A09092F2F207765207573652074686520696E7465726E616C20415045582066756E6374696F6E20666F7220616C6C204974656D203D2C20213D2C203E2C20696E206C6973742C2065746320636F6E646974696F6E730A0909636F';
wwv_flow_api.g_varchar2_table(6) := '6E74696E7565457865637574696F6E203D20617065782E64612E74657374436F6E646974696F6E28636F6E6669672E6974656D2C20636F6E6669672E747970652C20636F6E6669672E76616C7565293B0A097D0A0A0969662028636F6E74696E75654578';
wwv_flow_api.g_varchar2_table(7) := '65637574696F6E29207B0A0909617065782E64656275672E6C6F67282754686520636C69656E742D7369646520636F6E646974696F6E20776173206576616C756174656420746F20547275652E2050726F63656564696E67207769746820657865637574';
wwv_flow_api.g_varchar2_table(8) := '696F6E206F6620616374696F6E732E27293B0A097D20656C7365207B0A0909617065782E64656275672E6C6F67282754686520636C69656E742D7369646520636F6E646974696F6E20776173206576616C756174656420746F2046616C73652E2053746F';
wwv_flow_api.g_varchar2_table(9) := '7070696E6720657865637574696F6E206F6620616374696F6E732E27293B0A0A0909696628617065782E64612E63616E63656C297B0A0909092F2F206173206F662032302E310A090909617065782E64612E63616E63656C28293B0A09097D20656C7365';
wwv_flow_api.g_varchar2_table(10) := '207B0A090909617065782E6576656E742E6743616E63656C466C6167203D20747275653B0A090909617065782E64612E6743616E63656C416374696F6E73203D20747275653B0A09097D0A0A090969662028636F6E6669672E656C73654576656E744E61';
wwv_flow_api.g_varchar2_table(11) := '6D6529207B0A090909617065782E64656275672E6C6F67282754726967676572696E672022656C736522206576656E742E27293B0A090909617065782E6576656E742E747269676765722827626F6479272C20636F6E6669672E656C73654576656E744E';
wwv_flow_api.g_varchar2_table(12) := '616D652C206461436F6E746578742E64617461293B0A09097D0A097D0A7D3B0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(8542951619780085)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_file_name=>'js/script.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E464F533D77696E646F772E464F537C7C7B7D2C77696E646F772E464F532E7574696C733D77696E646F772E464F532E7574696C737C7C7B7D2C464F532E7574696C732E636C69656E7473696465436F6E646974696F6E3D66756E637469';
wwv_flow_api.g_varchar2_table(2) := '6F6E28652C6E297B617065782E64656275672E696E666F2822464F53202D204578656375746520504C2F53514C20436F646520222C6E293B28224A4156415343524950545F45585052455353494F4E223D3D6E2E747970653F6E2E636F6E646974696F6E';
wwv_flow_api.g_varchar2_table(3) := '46756E6374696F6E2E63616C6C2865293A617065782E64612E74657374436F6E646974696F6E286E2E6974656D2C6E2E747970652C6E2E76616C756529293F617065782E64656275672E6C6F67282254686520636C69656E742D7369646520636F6E6469';
wwv_flow_api.g_varchar2_table(4) := '74696F6E20776173206576616C756174656420746F20547275652E2050726F63656564696E67207769746820657865637574696F6E206F6620616374696F6E732E22293A28617065782E64656275672E6C6F67282254686520636C69656E742D73696465';
wwv_flow_api.g_varchar2_table(5) := '20636F6E646974696F6E20776173206576616C756174656420746F2046616C73652E2053746F7070696E6720657865637574696F6E206F6620616374696F6E732E22292C617065782E64612E63616E63656C3F617065782E64612E63616E63656C28293A';
wwv_flow_api.g_varchar2_table(6) := '28617065782E6576656E742E6743616E63656C466C61673D21302C617065782E64612E6743616E63656C416374696F6E733D2130292C6E2E656C73654576656E744E616D65262628617065782E64656275672E6C6F67282754726967676572696E672022';
wwv_flow_api.g_varchar2_table(7) := '656C736522206576656E742E27292C617065782E6576656E742E747269676765722822626F6479222C6E2E656C73654576656E744E616D652C652E646174612929297D3B0A2F2F2320736F757263654D617070696E6755524C3D7363726970742E6A732E';
wwv_flow_api.g_varchar2_table(8) := '6D6170';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(8543756111780468)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_file_name=>'js/script.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227363726970742E6A73225D2C226E616D6573223A5B2277696E646F77222C22464F53222C227574696C73222C22636C69656E7473696465436F6E646974696F6E222C226461436F6E746578';
wwv_flow_api.g_varchar2_table(2) := '74222C22636F6E666967222C2261706578222C226465627567222C22696E666F222C2274797065222C22636F6E646974696F6E46756E6374696F6E222C2263616C6C222C226461222C2274657374436F6E646974696F6E222C226974656D222C2276616C';
wwv_flow_api.g_varchar2_table(3) := '7565222C226C6F67222C2263616E63656C222C226576656E74222C226743616E63656C466C6167222C226743616E63656C416374696F6E73222C22656C73654576656E744E616D65222C2274726967676572222C2264617461225D2C226D617070696E67';
wwv_flow_api.g_varchar2_table(4) := '73223A2241414141412C4F41414F432C4941414D442C4F41414F432C4B41416D422C4741437643442C4F41414F432C49414149432C4D414151462C4F41414F432C49414149432C4F4141532C4741457643442C49414149432C4D41414D432C6F42414173';
wwv_flow_api.g_varchar2_table(5) := '422C53414155432C45414157432C4741457044432C4B41414B432C4D41414D432C4B41414B2C364241413842482C49414935422C7942414166412C4541414F492C4B4145574A2C4541414F4B2C6B4241416B42432C4B41414B502C4741473942452C4B41';
wwv_flow_api.g_varchar2_table(6) := '414B4D2C47414147432C63414163522C4541414F532C4B41414D542C4541414F492C4B41414D4A2C4541414F552C5141493345542C4B41414B432C4D41414D532C494141492C3246414566562C4B41414B432C4D41414D532C494141492C6F4641455A56';
wwv_flow_api.g_varchar2_table(7) := '2C4B41414B4D2C474141474B2C4F414556582C4B41414B4D2C474141474B2C55414552582C4B41414B592C4D41414D432C614141632C4541437A42622C4B41414B4D2C47414147512C6742414169422C4741477442662C4541414F67422C674241435666';
wwv_flow_api.g_varchar2_table(8) := '2C4B41414B432C4D41414D532C494141492C3442414366562C4B41414B592C4D41414D492C514141512C4F4141516A422C4541414F67422C634141656A422C454141556D42222C2266696C65223A227363726970742E6A73227D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(8544184516780468)
,p_plugin_id=>wwv_flow_api.id(37441962356114799)
,p_file_name=>'js/script.js.map'
,p_mime_type=>'application/json'
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


