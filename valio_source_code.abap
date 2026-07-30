*&---------------------------------------------------------------------*
*& Report Z_VALIO_CODE_REVIEW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_valio_code_review LINE-SIZE 132.

CONSTANTS:
  gc_object_def_type_class  TYPE string VALUE 'CLASS',
  gc_object_def_type_report TYPE string VALUE 'REPORT',
  gc_object_def_type_fm     TYPE string VALUE 'FM'.

TYPES:
  BEGIN OF ts_suggestion,
    object_type              TYPE string,
    object_name              TYPE string,
    source_code_section_name TYPE string,
    suggestion               TYPE string,
    priority                 TYPE string,
    user                     TYPE string,
  END OF ts_suggestion,

  BEGIN OF ts_object_definition,
    object_name TYPE string,
    object_type TYPE string,
  END OF ts_object_definition,

  tt_suggestion        TYPE STANDARD TABLE OF ts_suggestion WITH DEFAULT KEY,
  tt_object_definition TYPE STANDARD TABLE OF ts_object_definition WITH DEFAULT KEY,
  tt_class_name        TYPE STANDARD TABLE OF seoclsname WITH DEFAULT KEY,
  tt_prog_name         TYPE STANDARD TABLE OF progname WITH DEFAULT KEY,
  tt_fm_name           TYPE STANDARD TABLE OF rs38l_fnam WITH DEFAULT KEY,

  BEGIN OF ts_object_source,
    object_name        TYPE string,
    local_section_name TYPE string,
    source_code        TYPE string,
  END OF ts_object_source,

  BEGIN OF ts_object_sections_source,
    object_name TYPE string,
    sections    TYPE string_table,
  END OF ts_object_sections_source,

  BEGIN OF ts_contact,
    object    TYPE seoclsname,
    component TYPE seocmpname,
    contact   TYPE sy-uname,
  END OF ts_contact,

  tt_contact                TYPE STANDARD TABLE OF ts_contact WITH DEFAULT KEY,
  tt_object_source          TYPE STANDARD TABLE OF ts_object_source WITH DEFAULT KEY,
  tt_object_sections_source TYPE STANDARD TABLE OF ts_object_sections_source WITH DEFAULT KEY.


CLASS lcx_utility_base DEFINITION INHERITING FROM cx_static_check ABSTRACT.

  PUBLIC SECTION.
    METHODS:
      constructor IMPORTING !iv_error_text TYPE string
                            !io_previous   TYPE REF TO cx_root OPTIONAL
                            !iv_subrc      TYPE syst_subrc OPTIONAL,

      get_text REDEFINITION.

  PRIVATE SECTION.
    DATA:
      mv_error_text TYPE string,
      mv_subrc      TYPE syst_subrc.
ENDCLASS.


CLASS lcx_utility_base IMPLEMENTATION.


  METHOD constructor.
    super->constructor( previous = io_previous ).
    mv_error_text = iv_error_text.
    mv_subrc = iv_subrc.
  ENDMETHOD.


  METHOD get_text.
    result = mv_error_text.

    IF mv_subrc IS NOT INITIAL.
      result = |{ result }:SUBRC { mv_subrc }|.
    ENDIF.

    IF previous IS BOUND.
      result = |{ result }:( { previous->get_text( ) } )|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcx_ai_helper_error DEFINITION INHERITING FROM lcx_utility_base FINAL.
ENDCLASS.

CLASS lcx_object_extractor_error DEFINITION INHERITING FROM lcx_utility_base FINAL.
ENDCLASS.

CLASS lcx_suggestions_exporter_error DEFINITION INHERITING FROM lcx_utility_base FINAL.
ENDCLASS.

CLASS lcx_source_code_getter_error DEFINITION INHERITING FROM lcx_utility_base FINAL.
ENDCLASS.

CLASS lcx_code_reviewer_error DEFINITION INHERITING FROM lcx_utility_base FINAL.
ENDCLASS.


CLASS lcl_logger DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      warn IMPORTING !iv_message TYPE string.
ENDCLASS.

CLASS lcl_logger IMPLEMENTATION.

  METHOD warn.
    IF sy-batch = abap_true.
      MESSAGE iv_message TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_ai_helper DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS:
      get_master_prompt RETURNING VALUE(rv_master_prompt) TYPE stringval,

      get_default_prompt RETURNING VALUE(rv_default_prompt) TYPE stringval,

      get_final_prompt IMPORTING iv_user_prompt          TYPE stringval
                       RETURNING VALUE(rv_target_prompt) TYPE stringval,

      deserialize_suggestions IMPORTING !iv_object_type      TYPE string
                                        !iv_object_name      TYPE string
                                        !iv_json             TYPE string
                                        !iv_user             TYPE string
                              RETURNING VALUE(rt_suggestion) TYPE tt_suggestion
                              RAISING   lcx_ai_helper_error,

      execute_prompt IMPORTING !iv_prompt         TYPE string
                     RETURNING VALUE(rv_response) TYPE string
                     RAISING   lcx_ai_helper_error.

  PRIVATE SECTION.
    CONSTANTS:
      gc_prompt_begin_of_input     TYPE string VALUE 'Input for the review:',

      gc_msg_inaccessible_llm      TYPE string VALUE 'LLM Agent cannot be accessed',
      gc_msg_agent_not_provided    TYPE string VALUE 'LLM agent is not provided',

      gc_msg_corrupted_json        TYPE string VALUE 'Corrupted JSON',
      gc_msg_no_object_name        TYPE string VALUE 'No object name was provided',
      gc_msg_no_json_string        TYPE string VALUE 'No JSON string was provided',
      gc_msg_unnormalizable_string TYPE string VALUE 'String cannot be normalized',

      gc_fallback_object_type      TYPE string VALUE 'OBJ',
      gc_fallback_user_name        TYPE string VALUE 'UNKNOWN'.

    CLASS-METHODS:
      normalize_format IMPORTING !iv_string                  TYPE string
                       RETURNING VALUE(rv_normalized_string) TYPE string
                       RAISING   lcx_ai_helper_error.
ENDCLASS.

CLASS lcl_ai_helper IMPLEMENTATION.

  METHOD execute_prompt.
**********************************************************************
* Here you should provide a call to LLM.
**********************************************************************

    RAISE EXCEPTION TYPE lcx_ai_helper_error
      EXPORTING
        iv_error_text = gc_msg_agent_not_provided.

**********************************************************************
* Here you should provide a call to LLM.
**********************************************************************
  ENDMETHOD.

  METHOD get_master_prompt.

    rv_master_prompt = |Goal: Perform a detailed code review of an ABAP class and return structured findings.|
                    && |{ cl_abap_char_utilities=>newline }Context: You are an expert ABAP developer with deep knowledge of SAP best practices, performance optimization, maintainability.|
                    && |{ cl_abap_char_utilities=>newline }Output Format:|
                    && |{ cl_abap_char_utilities=>newline } - Return ONLY a valid JSON array.|
                    && |{ cl_abap_char_utilities=>newline } - Each element must follow this structure:|
                    && |{ cl_abap_char_utilities=>newline }   \{|
                    && |{ cl_abap_char_utilities=>newline }     "source_code_section_name": "<source_code_section_name_or_global_if_not_applicable>",|
                    && |{ cl_abap_char_utilities=>newline }     "suggestion": "<short, precise recommendation>",|
                    && |{ cl_abap_char_utilities=>newline }     "priority": "<HIGH\|MEDIUM\|LOW>"|
                    && |{ cl_abap_char_utilities=>newline }   \}|
                    && |{ cl_abap_char_utilities=>newline } - JSON must always start with [ symbol and end with ] symbol|
                    && |{ cl_abap_char_utilities=>newline } - Ensure the JSON is valid and properly formatted.|
                    && |{ cl_abap_char_utilities=>newline } - If no issues are found, return an empty JSON array: [].|
                    && |{ cl_abap_char_utilities=>newline } - Do not explain suggestions outside the JSON.|
                    && |{ cl_abap_char_utilities=>newline } - Avoid duplicate or overlapping suggestions.|
                    && |{ cl_abap_char_utilities=>newline } - Points max length 50 words.|
                    && |{ cl_abap_char_utilities=>newline }Instructions:|.
  ENDMETHOD.


  METHOD get_default_prompt.

    " Default prompt
    rv_default_prompt = | - Analyze the provided ABAP class code thoroughly.|
                     && |{ cl_abap_char_utilities=>newline } - Identify concrete issues, bugs, risks, and improvements.|
                     && |{ cl_abap_char_utilities=>newline } - Do not stop at surface-level issues;|
                     && |{ cl_abap_char_utilities=>newline } analyze underlying risks and edge cases.|
                     && |{ cl_abap_char_utilities=>newline } - The output should not be huge|
                     && |{ cl_abap_char_utilities=>newline } - Focus on:|
                     && |{ cl_abap_char_utilities=>newline }  - Syntax and logical errors|
                     && |{ cl_abap_char_utilities=>newline }  - Performance issues like needless database access, inefficient loops|
                     && |{ cl_abap_char_utilities=>newline }  - Clean code violations (readability, naming, modularization)|
                     && |{ cl_abap_char_utilities=>newline }  - SAP best practices and conventions|
                     && |{ cl_abap_char_utilities=>newline } - Generate as many potential issues as possible,|
                     && |{ cl_abap_char_utilities=>newline }   but avoid trivial or redundant points.|
                     && |{ cl_abap_char_utilities=>newline } - Each point must be concise, actionable, and specific.|
                     && |{ cl_abap_char_utilities=>newline } - Do not include any text outside the JSON output.|
                     && |{ cl_abap_char_utilities=>newline } - Use "GLOBAL" as source_code_section_name |
                     && |{ cl_abap_char_utilities=>newline }   if the issue is not tied to a specific method.|
                     && |{ cl_abap_char_utilities=>newline } - For GLOBAL be ultra precise|
                     && |{ cl_abap_char_utilities=>newline } - Do not use complex words for explanations|
                     && |{ cl_abap_char_utilities=>newline } - Be precise and specific. Point exactly to the weak places|
                     && |{ cl_abap_char_utilities=>newline } - Generic points are prohibited|
                     && |{ cl_abap_char_utilities=>newline } - You must add clear examples to the output|.
  ENDMETHOD.


  METHOD get_final_prompt.

    DATA(lv_master_prompt) = lcl_ai_helper=>get_master_prompt( ).

    rv_target_prompt = COND #( WHEN iv_user_prompt IS NOT INITIAL
                               THEN |{ lv_master_prompt }{ iv_user_prompt }{ cl_abap_char_utilities=>newline }{ gc_prompt_begin_of_input }{ cl_abap_char_utilities=>newline } |
                               ELSE |{ lv_master_prompt }{ cl_abap_char_utilities=>newline }{ gc_prompt_begin_of_input }{ cl_abap_char_utilities=>newline } | ).
  ENDMETHOD.


  METHOD deserialize_suggestions.

    IF iv_object_name IS INITIAL.
      RAISE EXCEPTION TYPE lcx_ai_helper_error
        EXPORTING
          iv_error_text = gc_msg_no_object_name.
    ENDIF.

    IF iv_json IS INITIAL.
      RAISE EXCEPTION TYPE lcx_ai_helper_error
        EXPORTING
          iv_error_text = gc_msg_no_json_string.
    ENDIF.

    DATA(lv_json) = normalize_format( iv_json ).

    IF /ui5/cl_json_util=>is_wellformed( lv_json ) = abap_false.
      RAISE EXCEPTION TYPE lcx_ai_helper_error
        EXPORTING
          iv_error_text = gc_msg_corrupted_json.
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json = lv_json
                               CHANGING  data = rt_suggestion ).

    IF rt_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_object_type) = COND #( WHEN iv_object_type IS NOT INITIAL THEN iv_object_type ELSE gc_fallback_object_type ).
    DATA(lv_user) = COND #( WHEN iv_user IS NOT INITIAL THEN iv_user ELSE gc_fallback_user_name ).

    LOOP AT rt_suggestion ASSIGNING FIELD-SYMBOL(<ls_suggestion>).
      <ls_suggestion>-object_type = lv_object_type.
      <ls_suggestion>-object_name = to_upper( iv_object_name ).
      <ls_suggestion>-source_code_section_name = to_upper( <ls_suggestion>-source_code_section_name ).
      <ls_suggestion>-user = lv_user.
    ENDLOOP.
  ENDMETHOD.


  METHOD normalize_format.

    CONSTANTS:
      lc_occurrence_last             TYPE i VALUE -1,
      lc_inclusive_length_adjustment TYPE i VALUE 1,

      lc_json_array_begin            VALUE '[',
      lc_json_array_end              VALUE ']'.

    IF iv_string IS INITIAL.
      RAISE EXCEPTION TYPE lcx_ai_helper_error
        EXPORTING
          iv_error_text = gc_msg_unnormalizable_string.
    ENDIF.

    DATA(lv_truncate_from) = find_any_of( val = iv_string sub = lc_json_array_begin ).
    DATA(lv_truncate_to)   = find_any_of( val = iv_string sub = lc_json_array_end occ = lc_occurrence_last ).

    IF lv_truncate_from < 0
    OR lv_truncate_to < 0
    OR lv_truncate_to - lv_truncate_from < 0.
      RAISE EXCEPTION TYPE lcx_ai_helper_error
        EXPORTING
          iv_error_text = gc_msg_unnormalizable_string.
    ENDIF.

    rv_normalized_string = substring( val = iv_string
                                      off = lv_truncate_from
                                      len = lv_truncate_to - lv_truncate_from + lc_inclusive_length_adjustment ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_object_extractor DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES:
      tt_user TYPE STANDARD TABLE OF syuname WITH DEFAULT KEY.

    METHODS:
      get_objects_by_packages IMPORTING !it_package_name TYPE string_table
                              RETURNING VALUE(rt_object) TYPE tt_object_definition
                              RAISING   lcx_object_extractor_error,

      get_objects_by_names IMPORTING !it_object_name  TYPE string_table
                           RETURNING VALUE(rt_object) TYPE tt_object_definition
                           RAISING   lcx_object_extractor_error,

      get_objects_by_tr_requests IMPORTING !iv_fl_current_objects_only TYPE abap_bool
                                           !iv_fl_current_user_only    TYPE abap_bool
                                           !it_tr_request_header       TYPE trwbo_request_headers
                                           !it_user                    TYPE tt_user
                                 RETURNING VALUE(rt_object)            TYPE tt_object_definition
                                 RAISING   lcx_object_extractor_error.

  PRIVATE SECTION.
    CONSTANTS:
      gc_request_functions_all      TYPE string VALUE 'CDEFGKMOPQRSTWX',
      gc_status_modifiable_released TYPE string VALUE 'DLP ',
      gc_objects_type_class_include TYPE string VALUE 'CINC',
      gc_objects_type_class         TYPE string VALUE 'CLAS',
      gc_objects_type_func          TYPE string VALUE 'FUNC',
      gc_objects_type_program       TYPE string VALUE 'PROG',
      gc_objects_type_fm            TYPE string VALUE 'FUGR',
      gc_function_group_prefix      TYPE string VALUE 'SAPL',
      gc_pgmid_complete_object      TYPE pgmid  VALUE 'R3TR',
      gc_program_type_include       TYPE string VALUE 'I',
      gc_trfunction_workbench       TYPE string VALUE 'K',

      gc_msg_search_objects_error   TYPE string VALUE 'Search objects error',
      gc_msg_no_packages            TYPE string VALUE 'No packages were provided',
      gc_msg_no_objects             TYPE string VALUE 'No objects were provided',
      gc_msg_no_user_request        TYPE string VALUE 'No user or request was provided',
      gc_msg_tr_request_read_error  TYPE string VALUE 'Cannot read transport request headers',
      gc_msg_invalid_format         TYPE string VALUE 'Invalid object name format'.

    METHODS:
      get_tr_request_headers IMPORTING !is_selection        TYPE trwbo_selection OPTIONAL
                                       !iv_username_pattern TYPE syst_uname OPTIONAL
                             RETURNING VALUE(rt_tr_request) TYPE trwbo_request_headers,

      get_objects_by_tr_request_hdrs IMPORTING !it_tr_request_header    TYPE trwbo_request_headers
                                               !iv_fl_current_user_only TYPE abap_bool OPTIONAL
                                     RETURNING VALUE(rt_object)         TYPE tt_object_definition,

      get_modules_in_function_group IMPORTING !it_function_group_name   TYPE string_table
                                    RETURNING VALUE(rt_function_module) TYPE tt_object_definition,

      delete_includes IMPORTING !it_prog_name TYPE tt_prog_name
                      CHANGING  !ct_object    TYPE tt_object_definition,

      adjust_objects_table IMPORTING !it_object       TYPE tt_object_definition
                           RETURNING VALUE(rt_object) TYPE tt_object_definition.
ENDCLASS.



CLASS lcl_object_extractor IMPLEMENTATION.


  METHOD get_objects_by_packages.

    DATA: lt_package_name       TYPE STANDARD TABLE OF devclass,
          lt_search_object_type TYPE RANGE OF trobjtype.

    lt_package_name = VALUE #( FOR <lv_package_name> IN it_package_name WHERE ( table_line IS NOT INITIAL )
                                                                              ( CONV #( <lv_package_name> ) ) ).

    IF lt_package_name IS INITIAL.
      RAISE EXCEPTION TYPE lcx_object_extractor_error
        EXPORTING
          iv_error_text = gc_msg_no_packages.
    ENDIF.

    lt_search_object_type = VALUE #( ( option = 'EQ' sign = 'I' low = gc_objects_type_class )
                                     ( option = 'EQ' sign = 'I' low = gc_objects_type_program  )
                                     ( option = 'EQ' sign = 'I' low = gc_objects_type_fm ) ) .

    SELECT obj_name,
           object
      FROM tadir                                       "#EC CI_GENBUFF.
      FOR ALL ENTRIES IN @lt_package_name
        WHERE devclass = @lt_package_name-table_line
             AND pgmid = @gc_pgmid_complete_object
             AND object IN @lt_search_object_type
    INTO TABLE @DATA(lt_object).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    RETURN adjust_objects_table( it_object = VALUE #( FOR <ls_obj> IN lt_object ( object_name = <ls_obj>-obj_name
                                                                                  object_type = <ls_obj>-object ) ) ).
  ENDMETHOD.


  METHOD get_objects_by_names.

    DATA: lt_wb_request       TYPE if_ris_quick_search=>ty_t_workbench_requests,
          lo_ris_quick_search TYPE REF TO if_ris_quick_search,
          lt_search_result    TYPE cl_wb_browser_util=>tt_sewb_quicksearch_value_help,
          lt_prog_name        TYPE STANDARD TABLE OF progname.

    DATA(lt_object_name) = VALUE string_table( FOR <ls_object_name> IN it_object_name WHERE ( table_line IS NOT INITIAL )
                                                                                            ( <ls_object_name> ) ).

    IF lt_object_name IS INITIAL.
      RAISE EXCEPTION TYPE lcx_object_extractor_error
        EXPORTING
          iv_error_text = gc_msg_no_objects.
    ENDIF.

    lo_ris_quick_search = NEW cl_ris_quick_search( ).
    LOOP AT lt_object_name ASSIGNING FIELD-SYMBOL(<ls_obj_name>).
      CLEAR: lt_wb_request,
             lt_search_result.

      TRY.
          lo_ris_quick_search->execute( EXPORTING i_query        = <ls_obj_name>
                                                  i_object_types = VALUE #( ( CONV #( gc_objects_type_class ) )
                                                                            ( CONV #( gc_objects_type_class_include ) )
                                                                            ( CONV #( gc_objects_type_fm ) )
                                                                            ( CONV #( gc_objects_type_func ) )
                                                                            ( CONV #( gc_objects_type_program ) ) )
                                        IMPORTING e_wb_requests  = lt_wb_request ).

          cl_wb_browser_util=>map_wb_requests_to_value_help( EXPORTING i_wb_requests = lt_wb_request
                                                             IMPORTING e_value_helps = lt_search_result ).
        CATCH cx_ris_exception INTO DATA(lx_ris).
          RAISE EXCEPTION TYPE lcx_object_extractor_error
            EXPORTING
              iv_error_text = |{ gc_msg_search_objects_error }: { <ls_obj_name> }|
              io_previous   = lx_ris.
      ENDTRY.

      LOOP AT lt_search_result ASSIGNING FIELD-SYMBOL(<ls_res>).

        APPEND CONV #( <ls_res>-obj_name ) TO lt_prog_name.

        APPEND VALUE #( object_name = <ls_res>-obj_name
                        object_type = SWITCH #( <ls_res>-object WHEN gc_objects_type_class OR gc_objects_type_class_include
                                                                THEN gc_object_def_type_class
                                                                WHEN gc_objects_type_fm OR gc_objects_type_func
                                                                THEN gc_object_def_type_fm
                                                                WHEN gc_objects_type_program
                                                                THEN gc_object_def_type_report ) ) TO rt_object.
      ENDLOOP.

    ENDLOOP.

    delete_includes( EXPORTING it_prog_name = lt_prog_name
                     CHANGING ct_object = rt_object ).
  ENDMETHOD.


  METHOD get_objects_by_tr_requests.

    DATA lt_tr_request TYPE trwbo_request_headers.

    IF it_user IS INITIAL
    AND it_tr_request_header IS INITIAL.
      RAISE EXCEPTION TYPE lcx_object_extractor_error
        EXPORTING
          iv_error_text = gc_msg_no_user_request.
    ENDIF.

    IF iv_fl_current_objects_only = abap_true.
      lt_tr_request = get_tr_request_headers( iv_username_pattern = sy-uname ).
    ELSE.
      lt_tr_request = it_tr_request_header.
      LOOP AT it_user ASSIGNING FIELD-SYMBOL(<ls_user>).
        APPEND LINES OF get_tr_request_headers( iv_username_pattern = <ls_user> ) TO lt_tr_request.
      ENDLOOP.
    ENDIF.

    SORT lt_tr_request BY trkorr.
    DELETE ADJACENT DUPLICATES FROM lt_tr_request COMPARING trkorr.

    RETURN get_objects_by_tr_request_hdrs( it_tr_request_header = lt_tr_request
                                           iv_fl_current_user_only = iv_fl_current_user_only ).
  ENDMETHOD.


  METHOD get_objects_by_tr_request_hdrs.

    DATA: lt_request           TYPE trwbo_requests,
          lt_all_request       TYPE trwbo_requests,
          lt_object_definition TYPE tt_object_definition.

    IF it_tr_request_header IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_tr_request_header ASSIGNING FIELD-SYMBOL(<ls_tr_req_header>) .
      CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
        EXPORTING
          iv_trkorr     = <ls_tr_req_header>-trkorr
        IMPORTING
          et_requests   = lt_request
        EXCEPTIONS
          invalid_input = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
        lcl_logger=>warn( |{ gc_msg_tr_request_read_error }: { <ls_tr_req_header>-trkorr }| ).
        CONTINUE.
      ENDIF.

      APPEND LINES OF lt_request TO lt_all_request.
    ENDLOOP.

    IF iv_fl_current_user_only = abap_true.
      DELETE lt_all_request WHERE h-as4user <> sy-uname.
    ENDIF.

    LOOP AT lt_all_request ASSIGNING FIELD-SYMBOL(<ls_request_detail>).

      LOOP AT <ls_request_detail>-objects ASSIGNING FIELD-SYMBOL(<ls_object>).
        SPLIT <ls_object>-obj_name AT '=' INTO TABLE DATA(lt_split).

        IF lt_split IS INITIAL.
          lcl_logger=>warn( |{ gc_msg_invalid_format }: { <ls_object>-obj_name }| ).
          CONTINUE.
        ENDIF.

        APPEND VALUE #( object_name = VALUE #( lt_split[ 1 ] OPTIONAL )
                        object_type = <ls_object>-object ) TO lt_object_definition.
      ENDLOOP.
    ENDLOOP.

    RETURN adjust_objects_table( lt_object_definition ).
  ENDMETHOD.


  METHOD adjust_objects_table.

    DATA:
      ls_object_definition   TYPE ts_object_definition,
      lt_function_group_name TYPE string_table,
      lt_prog_name           TYPE STANDARD TABLE OF progname.

    IF it_object IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_object ASSIGNING FIELD-SYMBOL(<ls_object>).
      ls_object_definition-object_name = <ls_object>-object_name.

      CASE <ls_object>-object_type.

        WHEN gc_objects_type_class_include OR gc_objects_type_class.
          ls_object_definition-object_type = gc_object_def_type_class.

        WHEN gc_objects_type_func.
          ls_object_definition-object_type = gc_object_def_type_fm.

        WHEN gc_objects_type_program.
          ls_object_definition-object_type = gc_object_def_type_report.
          " Add to lt_prog_name to check if it is include and delete in that case
          APPEND ls_object_definition-object_name TO lt_prog_name.

        WHEN gc_objects_type_fm.
          "Add to lt_function_group_name to find function modules in groups
          APPEND |{ gc_function_group_prefix }{ ls_object_definition-object_name }| TO lt_function_group_name.
          "Skip to not add function group
          CONTINUE.

        WHEN OTHERS.
          CONTINUE.
      ENDCASE.

      APPEND ls_object_definition TO rt_object.
    ENDLOOP.

    APPEND LINES OF get_modules_in_function_group( lt_function_group_name ) TO rt_object.

    SORT rt_object BY object_name.
    DELETE ADJACENT DUPLICATES FROM rt_object COMPARING ALL FIELDS.

    delete_includes( EXPORTING it_prog_name = lt_prog_name
                     CHANGING ct_object = rt_object ).
  ENDMETHOD.


  METHOD get_modules_in_function_group.

    DATA lt_function_group_name TYPE STANDARD TABLE OF pname.

    lt_function_group_name = VALUE #( FOR <ls_fg> IN it_function_group_name WHERE ( table_line IS NOT INITIAL )
                                                                                  ( CONV #( to_upper( <ls_fg> ) ) ) ).

    IF lt_function_group_name IS INITIAL.
      RETURN.
    ENDIF.

    " select function modules names that belong to function group
    SELECT funcname
      FROM tfdir                                       "#EC CI_GENBUFF.
      FOR ALL ENTRIES IN @lt_function_group_name
           WHERE pname = @lt_function_group_name-table_line
    INTO TABLE @DATA(lt_function_module_name).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    APPEND LINES OF VALUE tt_object_definition( FOR <ls_fm> IN lt_function_module_name ( object_name = <ls_fm>-funcname
                                                                                         object_type = gc_object_def_type_fm ) ) TO rt_function_module.
  ENDMETHOD.


  METHOD delete_includes.

    DATA(lt_prog_name) = VALUE tt_prog_name( FOR <ls_prog_name> IN it_prog_name WHERE ( table_line IS NOT INITIAL )
                                                                                      ( <ls_prog_name> ) ).

    IF lt_prog_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT name
      FROM progdir
      FOR ALL ENTRIES IN @lt_prog_name
            WHERE name = @lt_prog_name-table_line
              AND subc = @gc_program_type_include
    INTO TABLE @DATA(lt_inc_name).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT lt_inc_name ASSIGNING FIELD-SYMBOL(<ls_inc_name>).
      DELETE ct_object WHERE object_name = <ls_inc_name>-name.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_tr_request_headers.

    DATA(lv_username_pattern) = sy-uname.

    " All types of requests
    DATA(ls_selection) = VALUE trwbo_selection( reqfunctions = gc_request_functions_all
                                                reqstatus    = gc_status_modifiable_released ).
    IF is_selection IS SUPPLIED.
      ls_selection = is_selection.
    ENDIF.

    IF iv_username_pattern IS SUPPLIED.
      lv_username_pattern = iv_username_pattern.
    ENDIF.

    CALL FUNCTION 'TRINT_SELECT_REQUESTS'
      EXPORTING
        is_selection        = ls_selection
        iv_username_pattern = lv_username_pattern
      IMPORTING
        et_requests         = rt_tr_request.

    DELETE rt_tr_request WHERE trfunction <> gc_trfunction_workbench.
  ENDMETHOD.


ENDCLASS.


CLASS lcl_suggestions_exporter DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS:
      export_in_excel IMPORTING !it_suggestion TYPE tt_suggestion
                      RAISING   lcx_suggestions_exporter_error,

      export_to_server IMPORTING !iv_file_path  TYPE string
                                 !it_suggestion TYPE tt_suggestion
                       RAISING   lcx_suggestions_exporter_error,

      display_in_demo_output IMPORTING !it_suggestion TYPE tt_suggestion,

      display_in_alv IMPORTING !it_suggestion TYPE tt_suggestion
                     RAISING   lcx_suggestions_exporter_error.

  PRIVATE SECTION.

    CONSTANTS:
      gc_msg_xlsx_creation_error     TYPE string VALUE 'XLSX creation error',
      gc_msg_export_err_gui_download TYPE string VALUE 'Exporting with gui download error',
      gc_msg_export_err_open_dataset TYPE string VALUE 'Exporting with open dataset error',
      gc_msg_invalid_path            TYPE string VALUE 'Invalid path was provided for current platform',
      gc_msg_table_not_bound         TYPE string VALUE 'ALV table not bound',
      gc_msg_alv_format_error        TYPE string VALUE 'ALV table format error',
      gc_msg_alv_display_error       TYPE string VALUE 'Error while generating SALV Grid Display',
      gc_msg_save_dialog_error       TYPE string VALUE 'Error occurred in save file dialog',
      gc_msg_empty_file_path         TYPE string VALUE 'Empty file path',

      gc_priority_high               TYPE string VALUE 'HIGH',
      gc_priority_medium             TYPE string VALUE 'MEDIUM',
      gc_priority_low                TYPE string VALUE 'LOW',

      " constants for calculating sorting key according to priority
      gc_sort_priority_high          TYPE string VALUE '1',
      gc_sort_priority_medium        TYPE string VALUE '2',
      gc_sort_priority_low           TYPE string VALUE '3',
      gc_sort_priority_default       TYPE string VALUE '4',

      gc_column_name_color           TYPE lvc_fname VALUE 'COLOR',
      gc_column_name_sorting_key     TYPE lvc_fname VALUE 'SORTING_KEY',
      gc_column_name_object_type     TYPE lvc_fname VALUE 'OBJECT_TYPE',
      gc_column_name_object_name     TYPE lvc_fname VALUE 'OBJECT_NAME',
      gc_column_name_code_section    TYPE lvc_fname VALUE 'SOURCE_CODE_SECTION_NAME',
      gc_column_name_suggestion      TYPE lvc_fname VALUE 'SUGGESTION',
      gc_column_name_priority        TYPE lvc_fname VALUE 'PRIORITY',
      gc_column_name_user            TYPE lvc_fname VALUE 'USER',

      gc_column_text_object_type     TYPE string VALUE 'Type',
      gc_column_text_object_name     TYPE string VALUE 'Object',
      gc_column_text_code_section    TYPE string VALUE 'Code section name',
      gc_column_text_suggestion      TYPE string VALUE 'Comment',
      gc_column_text_priority        TYPE string VALUE 'Priority',
      gc_column_text_user            TYPE string VALUE 'User',

      gc_method_name_global          TYPE string VALUE 'GLOBAL',
      gc_file_extension_xlsx         TYPE string VALUE 'XLSX',
      gc_file_type_bin               TYPE char10 VALUE 'BIN',

      gc_default_file_name           TYPE string VALUE 'Code review',
      gc_default_intense_value       TYPE i VALUE 1,

      gc_color_code_red              TYPE i VALUE 6,
      gc_color_code_orange           TYPE i VALUE 7,
      gc_color_code_yellow           TYPE i VALUE 3.

    TYPES:
      BEGIN OF ts_suggestion_with_tech_info,
        object_type              TYPE string,
        object_name              TYPE string,
        source_code_section_name TYPE string,
        suggestion               TYPE string,
        priority                 TYPE string,
        user                     TYPE string,
        sorting_key              TYPE string,
        color                    TYPE lvc_t_scol,
      END OF ts_suggestion_with_tech_info,

      tt_suggestion_with_tech_info TYPE STANDARD TABLE OF ts_suggestion_with_tech_info WITH DEFAULT KEY.

    METHODS:
      create_xlsx_from_itab IMPORTING !it_fieldcat      TYPE lvc_t_fcat OPTIONAL
                                      !it_sort          TYPE lvc_t_sort OPTIONAL
                                      !it_filt          TYPE lvc_t_filt OPTIONAL
                                      !is_layout        TYPE lvc_s_layo OPTIONAL
                                      !it_hyperlink     TYPE lvc_t_hype OPTIONAL
                            CHANGING  !it_data          TYPE STANDARD TABLE
                            RETURNING VALUE(rv_xstring) TYPE xstring
                            RAISING   lcx_suggestions_exporter_error,

      export_with_gui_download IMPORTING !iv_file_path TYPE string
                                         !iv_file_data TYPE xstring
                               RAISING   lcx_suggestions_exporter_error,

      export_with_open_dataset IMPORTING !iv_file_path TYPE string
                                         !iv_file_data TYPE xstring
                               RAISING   lcx_suggestions_exporter_error,

      populate_technical_info IMPORTING !it_suggestion                      TYPE tt_suggestion
                              RETURNING VALUE(rt_suggestion_with_tech_info) TYPE tt_suggestion_with_tech_info,

      calculate_sorting_key IMPORTING !is_suggestion TYPE ts_suggestion
                            RETURNING VALUE(rv_key)  TYPE string,

      calculate_color IMPORTING !is_suggestion TYPE ts_suggestion
                      RETURNING VALUE(rv_code) TYPE lvc_s_scol,

      beautify_salv_table IMPORTING !io_salv_table TYPE REF TO cl_salv_table
                          RAISING   lcx_suggestions_exporter_error,

      get_default_file_name RETURNING VALUE(rv_file_name) TYPE string.

ENDCLASS.



CLASS lcl_suggestions_exporter IMPLEMENTATION.


  METHOD create_xlsx_from_itab.

    FIELD-SYMBOLS: <ls_tab> TYPE STANDARD TABLE.

    DATA(lt_data) = REF #( it_data ).

    IF it_fieldcat IS INITIAL.
      ASSIGN lt_data->* TO <ls_tab>.
      TRY.
          cl_salv_table=>factory( EXPORTING list_display = abap_false
                                  IMPORTING r_salv_table = DATA(salv_table)
                                  CHANGING  t_table      = <ls_tab> ).

          beautify_salv_table( salv_table ).

          DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog( r_columns      = salv_table->get_columns( )
                                                                             r_aggregations = salv_table->get_aggregations( ) ).
        CATCH cx_salv_msg INTO DATA(lx_salv).
          RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
            EXPORTING
              iv_error_text = gc_msg_xlsx_creation_error
              io_previous   = lx_salv.
      ENDTRY.
    ELSE.
      lt_fcat = it_fieldcat.
    ENDIF.

    TRY.
        cl_salv_bs_lex=>export_from_result_data_table( EXPORTING is_format            = if_salv_bs_lex_format=>mc_format_xlsx
                                                                 ir_result_data_table = cl_salv_ex_util=>factory_result_data_table(
                                                                 r_data               = lt_data
                                                                 s_layout             = is_layout
                                                                 t_fieldcatalog       = lt_fcat
                                                                 t_sort               = it_sort
                                                                 t_filter             = it_filt
                                                                 t_hyperlinks         = it_hyperlink )
                                                       IMPORTING er_result_file       = rv_xstring ).
      CATCH cx_salv_unexpected_param_value INTO DATA(lx_salv_param).
        RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
          EXPORTING
            iv_error_text = gc_msg_xlsx_creation_error
            io_previous   = lx_salv_param.
    ENDTRY.
  ENDMETHOD.


  METHOD export_with_gui_download.

    IF iv_file_path IS INITIAL.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = gc_msg_empty_file_path.
    ENDIF.

    DATA(it_raw_string) = cl_bcs_convert=>xstring_to_solix( iv_file_data ).

    cl_gui_frontend_services=>gui_download( EXPORTING filename     = iv_file_path
                                                      filetype     = gc_file_type_bin
                                                      bin_filesize = xstrlen( iv_file_data )
                                            CHANGING  data_tab     = it_raw_string
                                            EXCEPTIONS access_denied    = 1
                                                       file_write_error = 2
                                                       no_batch         = 3
                                                       gui_refuse_filetransfer = 4
                                                       OTHERS           = 5 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = | { gc_msg_export_err_gui_download }: { iv_file_path }|
          iv_subrc      = sy-subrc.
    ENDIF.
  ENDMETHOD.


  METHOD export_with_open_dataset.

    DATA lv_msg TYPE string.

    IF iv_file_path IS INITIAL.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = gc_msg_empty_file_path.
    ENDIF.

    TRY.

        cl_fs_path=>create( iv_file_path ).

      CATCH cx_fs_path_error INTO DATA(lx_path_error).
        RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
          EXPORTING
            iv_error_text = gc_msg_invalid_path
            io_previous   = lx_path_error.
    ENDTRY.

    OPEN DATASET iv_file_path FOR OUTPUT IN BINARY MODE MESSAGE lv_msg.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = |{ gc_msg_export_err_open_dataset }: { iv_file_path }: { lv_msg }|
          iv_subrc      = sy-subrc.
    ENDIF.

    TRANSFER iv_file_data TO iv_file_path.
    IF sy-subrc <> 0.
      CLOSE DATASET iv_file_path.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = |{ gc_msg_export_err_open_dataset }: { iv_file_path }|
          iv_subrc      = sy-subrc.
    ENDIF.

    CLOSE DATASET iv_file_path.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = |{ gc_msg_export_err_open_dataset }: { iv_file_path }|
          iv_subrc      = sy-subrc.
    ENDIF.
  ENDMETHOD.


  METHOD calculate_color.

    IF is_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    rv_code = SWITCH lvc_s_scol( is_suggestion-priority
                                WHEN gc_priority_high   THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_red    int = gc_default_intense_value ) )
                                WHEN gc_priority_medium THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_orange int = gc_default_intense_value ) )
                                WHEN gc_priority_low    THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_yellow int = gc_default_intense_value ) )
                                ELSE VALUE #( ) ).
  ENDMETHOD.


  METHOD calculate_sorting_key.

    IF is_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_suggestion) = is_suggestion.
    CONDENSE: lv_suggestion-object_name NO-GAPS, lv_suggestion-source_code_section_name NO-GAPS.

    rv_key = |{ lv_suggestion-object_name }|
             && |{ SWITCH stringval( is_suggestion-priority WHEN gc_priority_high   THEN gc_sort_priority_high
                                                            WHEN gc_priority_medium THEN gc_sort_priority_medium
                                                            WHEN gc_priority_low    THEN gc_sort_priority_low
                                                                                    ELSE gc_sort_priority_default ) }|
             && |{ SWITCH stringval( is_suggestion-source_code_section_name WHEN gc_method_name_global THEN gc_sort_priority_high
                                                                                                       ELSE lv_suggestion-source_code_section_name ) }|.
  ENDMETHOD.


  METHOD populate_technical_info.

    IF it_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    rt_suggestion_with_tech_info = VALUE #( FOR <ls_suggestion> IN it_suggestion
                                            WHERE ( table_line IS NOT INITIAL )
                                                  ( object_type              = <ls_suggestion>-object_type
                                                    object_name              = <ls_suggestion>-object_name
                                                    source_code_section_name = <ls_suggestion>-source_code_section_name
                                                    suggestion               = <ls_suggestion>-suggestion
                                                    priority                 = <ls_suggestion>-priority
                                                    user                     = <ls_suggestion>-user
                                                    sorting_key              = calculate_sorting_key( <ls_suggestion> )
                                                    color                    = VALUE #( ( calculate_color( <ls_suggestion> ) ) ) ) ).
  ENDMETHOD.


  METHOD beautify_salv_table.

    TYPES: BEGIN OF ts_column_config,
             column_name TYPE lvc_fname,
             text        TYPE string,
           END OF ts_column_config.

    DATA: lt_column_config TYPE STANDARD TABLE OF ts_column_config,
          lo_column        TYPE REF TO cl_salv_column.


    IF io_salv_table IS NOT BOUND.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = gc_msg_table_not_bound.
    ENDIF.

    lt_column_config = VALUE #(
              ( column_name = gc_column_name_object_type  text = gc_column_text_object_type )
              ( column_name = gc_column_name_object_name  text = gc_column_text_object_name )
              ( column_name = gc_column_name_code_section text = gc_column_text_code_section )
              ( column_name = gc_column_name_suggestion  text = gc_column_text_suggestion )
              ( column_name = gc_column_name_priority    text = gc_column_text_priority )
              ( column_name = gc_column_name_user        text = gc_column_text_user )
            ).

    TRY.
        DATA(lo_columns) = io_salv_table->get_columns( ).
        lo_columns->set_color_column( gc_column_name_color ).
        lo_columns->get_column( gc_column_name_sorting_key )->set_visible( if_salv_c_bool_sap=>false ).

        LOOP AT lt_column_config ASSIGNING FIELD-SYMBOL(<ls_column_config>).
          lo_column = lo_columns->get_column( <ls_column_config>-column_name ).
          lo_column->set_short_text( CONV scrtext_s( <ls_column_config>-text ) ).
          lo_column->set_medium_text( CONV scrtext_m( <ls_column_config>-text ) ).
          lo_column->set_long_text( CONV scrtext_l( <ls_column_config>-text ) ).
        ENDLOOP.

        io_salv_table->get_functions( )->set_all( abap_true ).
        lo_columns->set_optimize( abap_true ).

      CATCH cx_salv_data_error cx_salv_not_found INTO DATA(lx_salv).
        RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
          EXPORTING
            iv_error_text = gc_msg_alv_format_error
            io_previous   = lx_salv.
    ENDTRY.
  ENDMETHOD.


  METHOD display_in_alv.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    TRY.
        cl_salv_table=>factory( EXPORTING list_display = abap_false
                                IMPORTING r_salv_table = DATA(salv_table)
                                CHANGING  t_table      = lt_suggestion_with_tech_info ).
      CATCH cx_salv_msg INTO DATA(lx_salv).
        RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
          EXPORTING
            iv_error_text = gc_msg_alv_display_error
            io_previous   = lx_salv.
    ENDTRY.

    beautify_salv_table( salv_table ).

    salv_table->display( ).
  ENDMETHOD.


  METHOD export_in_excel.

    DATA: lv_full_path   TYPE string,
          lv_path        TYPE string,
          lv_filename    TYPE string,
          lv_user_action TYPE i.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        default_extension         = gc_file_extension_xlsx
        default_file_name         = get_default_file_name( )
      CHANGING
        filename                  = lv_filename
        path                      = lv_path
        fullpath                  = lv_full_path
        user_action               = lv_user_action
      EXCEPTIONS
        cntl_error                = 1
        error_no_gui              = 2
        not_supported_by_gui      = 3
        invalid_default_file_name = 4
        OTHERS                    = 5 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = |{ gc_msg_save_dialog_error }: { lv_full_path }|
          iv_subrc      = sy-subrc.
    ENDIF.

    IF lv_user_action = cl_gui_frontend_services=>action_cancel.
      RETURN.
    ENDIF.

    export_with_gui_download( iv_file_path = lv_full_path
                              iv_file_data = create_xlsx_from_itab( CHANGING it_data = lt_suggestion_with_tech_info ) ).
  ENDMETHOD.


  METHOD export_to_server.

    IF iv_file_path IS INITIAL.
      RAISE EXCEPTION TYPE lcx_suggestions_exporter_error
        EXPORTING
          iv_error_text = |{ gc_msg_empty_file_path }: { iv_file_path }|.
    ENDIF.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    export_with_open_dataset( iv_file_path = iv_file_path
                              iv_file_data = create_xlsx_from_itab( CHANGING it_data = lt_suggestion_with_tech_info ) ).
  ENDMETHOD.


  METHOD display_in_demo_output.
    cl_demo_output=>display( it_suggestion ).
  ENDMETHOD.

  METHOD get_default_file_name.
    RETURN |{ gc_default_file_name } { sy-datum }-{ sy-uzeit }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_abap_source_code_getter DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS:
      get_reports_source_code IMPORTING !it_report_name         TYPE string_table
                              RETURNING VALUE(rt_report_source) TYPE tt_object_source,

      get_func_modules_source_code IMPORTING !it_fm_name         TYPE string_table
                                   RETURNING VALUE(rt_fm_source) TYPE tt_object_source,

      get_classes_source_code IMPORTING !it_class_name         TYPE string_table
                              RETURNING VALUE(rt_class_source) TYPE tt_object_source,

      get_classes_methods_src_code IMPORTING !it_class_name                 TYPE string_table
                                   RETURNING VALUE(rt_class_methods_source) TYPE tt_object_sections_source,

      get_reports_sections_src_code IMPORTING !it_report_name                  TYPE string_table
                                    RETURNING VALUE(rt_report_sections_source) TYPE tt_object_sections_source.

    CLASS-METHODS:
      get_report_contacts IMPORTING !it_report_name          TYPE tt_prog_name
                          RETURNING VALUE(rt_report_contact) TYPE tt_contact,

      get_function_module_contacts IMPORTING !it_fm_name                       TYPE tt_fm_name
                                   RETURNING VALUE(rt_function_module_contact) TYPE tt_contact,

      get_class_method_contacts IMPORTING !it_class_name                 TYPE tt_class_name
                                RETURNING VALUE(rt_class_method_contact) TYPE tt_contact.

  PRIVATE SECTION.
    CONSTANTS:
      gc_msg_max_iterations_exceeded TYPE string VALUE 'Max iterations count were exceeded',
      gc_msg_get_by_cifkey_error     TYPE string VALUE 'Unable to get object by cif key',
      gc_msg_ref_not_bound           TYPE string VALUE 'Failed to instantiate OO object reference',
      gc_msg_not_a_class             TYPE string VALUE 'Object is not a class',
      gc_msg_fm_src_retrieval_error  TYPE string VALUE 'Unable to get function module source',
      gc_msg_reading_src_error       TYPE string VALUE 'Error occurred while reading source code',

      text_separator                 TYPE abap_char1 VALUE cl_abap_char_utilities=>newline,
      gc_class_pool                  TYPE string VALUE 'CLASS-POOL',
      gc_comment_pattern             TYPE string VALUE '*"',
      gc_kw_public_section           TYPE string VALUE 'PUBLIC SECTION',
      gc_kw_class                    TYPE string VALUE 'CLASS',
      gc_kw_endclass                 TYPE string VALUE 'ENDCLASS',
      gc_kw_definition               TYPE string VALUE 'DEFINITION',
      gc_kw_implementation           TYPE string VALUE 'IMPLEMENTATION',
      gc_kw_method                   TYPE string VALUE 'METHOD',
      gc_kw_endmethod                TYPE string VALUE 'ENDMETHOD',
      gc_kw_include                  TYPE string VALUE 'INCLUDE',
      gc_kw_form                     TYPE string VALUE 'FORM',
      gc_kw_endform                  TYPE string VALUE 'ENDFORM',

      gc_include_marker_start        TYPE string VALUE '>>> STARTINCLUDE',
      gc_include_marker_end          TYPE string VALUE '<<< ENDINCLUDE',
      gc_include_marker_expanded     TYPE string VALUE 'EXPANDED',
      gc_include_marker_not_found    TYPE string VALUE 'NOT FOUND',
      gc_progdir_active_objects      TYPE r3state VALUE 'A',
      gc_active_objects              TYPE i VALUE 1.

    METHODS:
      get_class_src_code IMPORTING !iv_class_name              TYPE string
                         RETURNING VALUE(rv_class_source_code) TYPE string
                         RAISING   lcx_source_code_getter_error,

      get_report_src_code IMPORTING !iv_report_name              TYPE string
                          RETURNING VALUE(rv_report_source_code) TYPE string
                          RAISING   lcx_source_code_getter_error,

      get_local_classes_src_code IMPORTING !iv_class_name             TYPE string
                                 RETURNING VALUE(rt_class_definition) TYPE tt_object_source
                                 RAISING   lcx_source_code_getter_error,

      get_class_methods_src_code IMPORTING !iv_class_name                   TYPE string
                                 RETURNING VALUE(rt_class_methods_src_code) TYPE string_table
                                 RAISING   lcx_source_code_getter_error,

      get_report_sections_src_code IMPORTING !iv_report_name                    TYPE string
                                   RETURNING VALUE(rt_report_sections_src_code) TYPE string_table
                                   RAISING   lcx_source_code_getter_error,

      get_class_pool_src_code IMPORTING !it_source                     TYPE seop_source_string
                                        !iv_class_name                 TYPE string
                              EXPORTING !ev_class_pool_begin_src_code  TYPE string
                                        !ev_class_pool_bridge_src_code TYPE string
                                        !ev_class_pool_ending_src_code TYPE string,

      convert_source_code_to_string IMPORTING !it_source              TYPE seop_source_string
                                    RETURNING VALUE(rv_source_string) TYPE string,

      get_public_section_src_code IMPORTING !it_include                 TYPE seop_source_string
                                  EXPORTING !ev_class_definition_header TYPE string
                                            !ev_public_section          TYPE string,

      get_global_cl_methods_src_code IMPORTING !it_include              TYPE seop_methods_w_include
                                     RETURNING VALUE(rt_methods_source) TYPE string_table,

      get_local_cls_methods_src_code IMPORTING !io_class_naming         TYPE REF TO if_oo_class_incl_naming
                                     RETURNING VALUE(rt_methods_source) TYPE string_table,

      extract_local_cls_by_name IMPORTING !iv_class_name         TYPE string
                                          !iv_source             TYPE string
                                RETURNING VALUE(rv_class_source) TYPE string.
ENDCLASS.



CLASS lcl_abap_source_code_getter IMPLEMENTATION.


  METHOD get_reports_source_code.

    IF it_report_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_report_name ASSIGNING FIELD-SYMBOL(<ls_report_name>) WHERE table_line IS NOT INITIAL.
      TRY.
          APPEND VALUE #( object_name = <ls_report_name>
                          source_code = get_report_src_code( <ls_report_name> ) ) TO rt_report_source.
        CATCH lcx_source_code_getter_error INTO DATA(lx_source_code_getter_error).
          lcl_logger=>warn( |{ lx_source_code_getter_error->get_text( ) }| ).
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_report_src_code.

    CONSTANTS lc_iterations_max TYPE i VALUE 1000.

    DATA: lv_name              TYPE char30,
          lt_src               TYPE string_table,
          lv_include_name      TYPE char30,
          lt_include_src       TYPE string_table,
          lt_include_expanded  TYPE STANDARD TABLE OF char30,
          lv_include_expansion TYPE string,
          ls_match             TYPE match_result,
          ls_submatch          TYPE submatch_result,
          lv_current_iteration TYPE i.

    IF iv_report_name IS INITIAL.
      RETURN.
    ENDIF.

    lv_name = CONV #( iv_report_name ).

    READ REPORT lv_name INTO lt_src.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_reading_src_error }: { iv_report_name }|
          iv_subrc      = sy-subrc.
    ENDIF.
    rv_report_source_code = concat_lines_of( table = lt_src
                                             sep = text_separator ).

    IF rv_report_source_code IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_pcre_regex) = cl_abap_regex=>create_pcre( pattern = |(?im)^\\s*?{ gc_kw_include }\\s+(\\w\{1,30\})\\s*?\\.| ).

    DO.
      IF lv_current_iteration > lc_iterations_max.
        RAISE EXCEPTION TYPE lcx_source_code_getter_error
          EXPORTING
            iv_error_text = |{ gc_msg_max_iterations_exceeded }: { iv_report_name }|.
      ENDIF.

      CLEAR ls_match.
      FIND FIRST OCCURRENCE OF REGEX lo_pcre_regex
      IN rv_report_source_code
      RESULTS ls_match.
      IF ls_match IS INITIAL.
        EXIT.
      ENDIF.

      ls_submatch = VALUE #( ls_match-submatches[ 1 ] OPTIONAL ).
      IF ls_submatch IS INITIAL.
        EXIT.
      ENDIF.

      lv_include_name = substring( val = rv_report_source_code
                                   off = ls_submatch-offset
                                   len = ls_submatch-length ).

      IF line_exists( lt_include_expanded[ table_line = lv_include_name ] ).
        lv_include_expansion = |"{ gc_kw_include } { lv_include_name } { gc_include_marker_expanded }|.
      ELSE.

        CLEAR lt_include_src.
        READ REPORT lv_include_name INTO lt_include_src.
        IF sy-subrc <> 0.
          lv_include_expansion = |"{ gc_kw_include } { lv_include_name } { gc_include_marker_not_found }|.
        ELSE.
          lv_include_expansion = |" { gc_include_marker_start } { lv_include_name }{ text_separator }| &&
                |{ concat_lines_of( table = lt_include_src sep = text_separator ) }{ text_separator }| &&
                                   |" { gc_include_marker_end } { lv_include_name }{ text_separator }|.
        ENDIF.
      ENDIF.

      REPLACE SECTION OFFSET ls_match-offset
      LENGTH ls_match-length
      OF rv_report_source_code
      WITH lv_include_expansion.

      APPEND lv_include_name TO lt_include_expanded.

      lv_current_iteration += 1.
    ENDDO.
  ENDMETHOD.


  METHOD get_func_modules_source_code.

    DATA: lv_include TYPE rs38l-include,
          lt_src     TYPE string_table,
          lv_program TYPE pname.

    IF it_fm_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_fm_name) = VALUE tt_fm_name( FOR <ls_fm> IN it_fm_name ( CONV #( <ls_fm> ) ) ).

    SELECT funcname,
           pname,
           include
      FROM tfdir
      FOR ALL ENTRIES IN @lt_fm_name
        WHERE funcname = @lt_fm_name-table_line
    INTO TABLE @DATA(lt_fg_detail).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT lt_fg_detail ASSIGNING FIELD-SYMBOL(<ls_fg_details>).

      lv_program = <ls_fg_details>-pname.

      CALL FUNCTION 'FUNCTION_INCLUDE_CONCATENATE'
        EXPORTING
          include_number   = <ls_fg_details>-include
        IMPORTING
          include          = lv_include
        CHANGING
          program          = lv_program
        EXCEPTIONS
          not_enough_input = 1
          no_function_pool = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
        lcl_logger=>warn( |{ gc_msg_fm_src_retrieval_error }: { <ls_fg_details>-funcname }: { sy-subrc }| ).
        CONTINUE.
      ENDIF.

      CLEAR lt_src.
      READ REPORT lv_include INTO lt_src.
      IF sy-subrc <> 0.
        lcl_logger=>warn( |{ gc_msg_fm_src_retrieval_error }: { <ls_fg_details>-funcname }: { sy-subrc }| ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( object_name = <ls_fg_details>-funcname
                      source_code = concat_lines_of( table = lt_src
                                                     sep = text_separator ) ) TO rt_fm_source.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_classes_methods_src_code.

    IF it_class_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_class_name ASSIGNING FIELD-SYMBOL(<ls_cls_name>) WHERE table_line IS NOT INITIAL.
      TRY.
          APPEND VALUE #( object_name = <ls_cls_name>
                          sections = get_class_methods_src_code( <ls_cls_name> ) ) TO rt_class_methods_source.
        CATCH lcx_source_code_getter_error INTO DATA(lx_source_code_getter_error).
          lcl_logger=>warn( |{ lx_source_code_getter_error->get_text( ) }| ).
          CONTINUE.
      ENDTRY.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_reports_sections_src_code.

    IF it_report_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_report_name ASSIGNING FIELD-SYMBOL(<ls_report_name>) WHERE table_line IS NOT INITIAL.
      TRY.
          APPEND VALUE #( object_name = <ls_report_name>
                          sections = get_report_sections_src_code( <ls_report_name> ) ) TO rt_report_sections_source.
        CATCH lcx_source_code_getter_error INTO DATA(lx_source_code_getter_error).
          lcl_logger=>warn( |{ lx_source_code_getter_error->get_text( ) }| ).
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_classes_source_code.

    DATA: lv_source_code            TYPE string,
          lt_local_classes_src_code TYPE tt_object_source.

    IF it_class_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_class_name ASSIGNING FIELD-SYMBOL(<ls_class_name>) WHERE table_line IS NOT INITIAL.
      CLEAR: lv_source_code,
             lt_local_classes_src_code.

      TRY.
          lv_source_code = get_class_src_code( <ls_class_name> ).
          lt_local_classes_src_code = get_local_classes_src_code( <ls_class_name> ).
          IF lv_source_code IS INITIAL.
            CONTINUE.
          ENDIF.

          APPEND VALUE #( object_name = <ls_class_name>
                          source_code = lv_source_code ) TO rt_class_source.

          APPEND LINES OF lt_local_classes_src_code TO rt_class_source.
        CATCH lcx_source_code_getter_error INTO DATA(lx_source_code_getter_error).
          lcl_logger=>warn( |{ lx_source_code_getter_error->get_text( ) }| ).
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_methods_src_code.

    DATA: lo_class_naming TYPE REF TO if_oo_class_incl_naming.

    IF iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    cl_oo_include_naming=>get_instance_by_cifkey(
      EXPORTING
        cifkey         = VALUE #( clsname = to_upper( iv_class_name ) )
      RECEIVING
        cifref         = DATA(lo_include_naming)
      EXCEPTIONS
        no_objecttype  = 1
        internal_error = 2
        OTHERS         = 3 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_get_by_cifkey_error }: { iv_class_name }|
          iv_subrc      = sy-subrc.
    ENDIF.

    IF lo_include_naming IS NOT BOUND.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_ref_not_bound }: { iv_class_name }|.
    ENDIF.

    TRY.
        lo_class_naming ?= lo_include_naming.
      CATCH cx_sy_move_cast_error INTO DATA(lx_cast_error).
        RAISE EXCEPTION TYPE lcx_source_code_getter_error
          EXPORTING
            iv_error_text = |{ gc_msg_not_a_class }: { iv_class_name }|
            io_previous   = lx_cast_error.
    ENDTRY.

    DATA(lt_local_cls_method) = get_local_cls_methods_src_code( lo_class_naming ).

    rt_class_methods_src_code = get_global_cl_methods_src_code( lo_class_naming->get_all_method_includes( ) ).

    APPEND LINES OF lt_local_cls_method TO rt_class_methods_src_code.
  ENDMETHOD.


  METHOD get_report_sections_src_code.

    IF iv_report_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_report_src) = get_report_src_code( iv_report_name ).

    FIND ALL OCCURRENCES OF PCRE |(?ims)\\s*({ gc_kw_form }\|{ gc_kw_method })\\s+(\\w\{1,30\})\\s*\\..*?({ gc_kw_endform }\|{ gc_kw_endmethod })\\s*\\.|
    IN lv_report_src
    IGNORING CASE
    RESULTS DATA(lt_match).

    IF lt_match IS INITIAL.
      RETURN.
    ENDIF.

    rt_report_sections_src_code = VALUE #( FOR <ls_match> IN lt_match ( substring( val = lv_report_src
                                                                                   off = <ls_match>-offset
                                                                                   len = <ls_match>-length ) ) ).
  ENDMETHOD.


  METHOD get_class_pool_src_code.

    CLEAR: ev_class_pool_begin_src_code,
           ev_class_pool_bridge_src_code,
           ev_class_pool_ending_src_code.

    DATA lv_class_pool_section_pointer TYPE sytabix.

    IF it_source IS INITIAL
    OR iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<ls_src_line>).
      IF <ls_src_line> CS gc_class_pool.
        ev_class_pool_begin_src_code = |{ ev_class_pool_begin_src_code }{ <ls_src_line> }{ text_separator }|.
        lv_class_pool_section_pointer = sy-tabix.
        EXIT.
      ENDIF.
    ENDLOOP.

    DATA(lv_section_delimiter) = |{ gc_kw_class } { to_upper( iv_class_name ) } { gc_kw_implementation }|.

    LOOP AT it_source ASSIGNING <ls_src_line> FROM lv_class_pool_section_pointer.
      IF <ls_src_line> CS gc_kw_endclass.
        ev_class_pool_bridge_src_code = |{ ev_class_pool_bridge_src_code }{ <ls_src_line> }{ text_separator }|.
      ENDIF.

      IF <ls_src_line> CS lv_section_delimiter.
        ev_class_pool_bridge_src_code = |{ ev_class_pool_bridge_src_code }{ <ls_src_line> }{ text_separator }|.
        lv_class_pool_section_pointer = sy-tabix.
        EXIT.
      ENDIF.
    ENDLOOP.

    LOOP AT it_source ASSIGNING <ls_src_line> FROM lv_class_pool_section_pointer.
      IF <ls_src_line> CS gc_kw_endclass.
        ev_class_pool_ending_src_code = |{ ev_class_pool_ending_src_code }{ <ls_src_line> }{ text_separator }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_src_code.

    DATA: lo_class_naming TYPE REF TO if_oo_class_incl_naming,
          lt_source       TYPE seop_source_string.

    IF iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    cl_oo_include_naming=>get_instance_by_cifkey(
      EXPORTING
        cifkey         = VALUE #( clsname = to_upper( iv_class_name ) )
      RECEIVING
        cifref         = DATA(lo_include_naming)
      EXCEPTIONS
        no_objecttype  = 1
        internal_error = 2
        OTHERS         = 3 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_get_by_cifkey_error }: { iv_class_name }|
          iv_subrc      = sy-subrc.
    ENDIF.

    IF lo_include_naming IS NOT BOUND.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_ref_not_bound }: { iv_class_name }|.
    ENDIF.

    TRY.
        lo_class_naming ?= lo_include_naming.
      CATCH cx_sy_move_cast_error INTO DATA(lx_cast_error).
        RAISE EXCEPTION TYPE lcx_source_code_getter_error
          EXPORTING
            iv_error_text = |{ gc_msg_not_a_class }: { iv_class_name }|
            io_previous   = lx_cast_error.
    ENDTRY.

* Build full class source code by sequentially reading and merging all generated includes of the class pool.

    " Class pool
    READ REPORT lo_class_naming->class_pool INTO lt_source.
    get_class_pool_src_code( EXPORTING it_source                     = lt_source
                                       iv_class_name                 = iv_class_name
                             IMPORTING ev_class_pool_begin_src_code  = DATA(lv_class_pool_begin_src_code)
                                       ev_class_pool_bridge_src_code = DATA(lv_class_pool_bridge_src_code)
                                       ev_class_pool_ending_src_code = DATA(lv_class_pool_ending_src_code) ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_class_pool_begin_src_code }{ text_separator }|.

    " Locals old
    READ REPORT lo_class_naming->locals_old INTO lt_source.
    DATA(lv_partial_src_code) = convert_source_code_to_string( lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Macros
    READ REPORT lo_class_naming->macros INTO lt_source.
    lv_partial_src_code = convert_source_code_to_string( lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Public Section
    READ REPORT lo_class_naming->public_section INTO lt_source.
    get_public_section_src_code( EXPORTING it_include                 = lt_source
                                 IMPORTING ev_class_definition_header = DATA(class_def_header_src_code)
                                           ev_public_section          = lv_partial_src_code ).

    rv_class_source_code = |{ rv_class_source_code }{ class_def_header_src_code }{ text_separator }| &&
                           |{ lv_partial_src_code }{ text_separator }|.

    " Protected Section
    READ REPORT lo_class_naming->protected_section INTO lt_source.
    lv_partial_src_code = convert_source_code_to_string( lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Private Section
    READ REPORT lo_class_naming->private_section INTO lt_source.
    lv_partial_src_code = convert_source_code_to_string( lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }| &&
                           |{ lv_class_pool_bridge_src_code }{ text_separator }|.

    " Additional global class methods
    DATA(lv_methods_src_code) = get_global_cl_methods_src_code( lo_class_naming->get_all_method_includes( ) ).
    lv_partial_src_code = concat_lines_of( table = lv_methods_src_code
                                           sep = text_separator ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator } | &&
                           |{ lv_class_pool_ending_src_code }{ text_separator }|.
  ENDMETHOD.


  METHOD get_public_section_src_code.

    CLEAR: ev_class_definition_header,
           ev_public_section.

    IF it_include IS INITIAL.
      RETURN.
    ENDIF.

    DATA(is_public_section) = abap_false.

    LOOP AT it_include ASSIGNING FIELD-SYMBOL(<ls_src_line>)
         WHERE table_line IS NOT INITIAL
           AND table_line NS gc_comment_pattern.

      IF is_public_section = abap_false AND <ls_src_line> CP |*{ gc_kw_public_section }*|.
        is_public_section = abap_true.
      ENDIF.

      IF is_public_section = abap_true.
        ev_public_section = |{ ev_public_section }{ <ls_src_line> }{ text_separator }|.
      ELSE.
        ev_class_definition_header = |{ ev_class_definition_header }{ <ls_src_line> }{ text_separator }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD extract_local_cls_by_name.

    IF iv_class_name IS INITIAL
    OR iv_source IS INITIAL.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF PCRE |{ gc_kw_class }\\s+{ iv_class_name }\\s+{ gc_kw_definition }[\\s\\S]*?{ gc_kw_endclass }|
    IN iv_source
    IGNORING CASE
    RESULTS DATA(lv_match).

    IF lv_match IS INITIAL.
      RETURN.
    ENDIF.

    rv_class_source = |{ iv_source+lv_match-offset(lv_match-length) }|.

    CLEAR lv_match.
    FIND FIRST OCCURRENCE OF PCRE |{ gc_kw_class }\\s+{ iv_class_name }\\s+{ gc_kw_implementation }[\\s\\S]*?{ gc_kw_endclass }|
    IN iv_source
    IGNORING CASE
    RESULTS lv_match.

    IF lv_match IS INITIAL.
      RETURN.
    ENDIF.

    rv_class_source = |{ rv_class_source }{ text_separator }{ iv_source+lv_match-offset(lv_match-length) }|.
  ENDMETHOD.


  METHOD get_global_cl_methods_src_code.

    DATA: lt_source          TYPE seop_source_string.

    IF it_include IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_include ASSIGNING FIELD-SYMBOL(<ls_include>).
      CLEAR lt_source.
      READ REPORT <ls_include>-incname INTO lt_source.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF lt_source IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND concat_lines_of( table = lt_source sep = text_separator ) TO rt_methods_source.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_local_classes_src_code.

    DATA: lt_local_class_name TYPE string_table,
          lo_class_naming     TYPE REF TO if_oo_class_incl_naming,
          lt_source           TYPE seop_source_string,
          ls_submatch         TYPE submatch_result.

    IF iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    cl_oo_include_naming=>get_instance_by_cifkey(
      EXPORTING
        cifkey         = VALUE #( clsname = to_upper( iv_class_name ) )
      RECEIVING
        cifref         = DATA(lo_include_naming)
      EXCEPTIONS
        no_objecttype  = 1
        internal_error = 2
        OTHERS         = 3 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_get_by_cifkey_error }: { iv_class_name }|
          iv_subrc      = sy-subrc.
    ENDIF.

    IF lo_include_naming IS NOT BOUND.
      RAISE EXCEPTION TYPE lcx_source_code_getter_error
        EXPORTING
          iv_error_text = |{ gc_msg_ref_not_bound }: { iv_class_name }|.
    ENDIF.

    TRY.
        lo_class_naming ?= lo_include_naming.
      CATCH cx_sy_move_cast_error INTO DATA(lx_cast_error).
        RAISE EXCEPTION TYPE lcx_source_code_getter_error
          EXPORTING
            iv_error_text = |{ gc_msg_not_a_class }: { iv_class_name }|
            io_previous   = lx_cast_error.
    ENDTRY.

    READ REPORT lo_class_naming->locals_def INTO lt_source.
    DATA(lv_local_def_src) = convert_source_code_to_string( lt_source ).

    CLEAR lt_source.
    READ REPORT lo_class_naming->locals_imp INTO lt_source.
    DATA(lv_local_imp_src) = convert_source_code_to_string( lt_source ).

    IF lv_local_def_src IS INITIAL
    AND lv_local_imp_src IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_local_src) = |{ lv_local_def_src }{ text_separator }{ lv_local_imp_src }|.

    FIND ALL OCCURRENCES OF PCRE |{ gc_kw_class }\\s+(\\w\{1,30\})\\s+{ gc_kw_definition }|
    IN lv_local_src
    IGNORING CASE
    RESULTS DATA(lt_match).

    LOOP AT lt_match ASSIGNING FIELD-SYMBOL(<ls_match>).
      ls_submatch = VALUE #( <ls_match>-submatches[ 1 ] OPTIONAL ).

      IF ls_submatch IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND substring( val = lv_local_src
                        off = ls_submatch-offset
                        len = ls_submatch-length ) TO lt_local_class_name.
    ENDLOOP.

    LOOP AT lt_local_class_name ASSIGNING FIELD-SYMBOL(<ls_cls_name>) WHERE table_line IS NOT INITIAL.
      APPEND VALUE #( object_name        = iv_class_name
                      local_section_name = <ls_cls_name>
                      source_code        = extract_local_cls_by_name( iv_class_name = <ls_cls_name>
                                                                      iv_source     = lv_local_src ) ) TO rt_class_definition.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_local_cls_methods_src_code.

    IF io_class_naming IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA lt_source TYPE seop_source_string.

    READ REPORT io_class_naming->locals_imp INTO lt_source.
    DATA(lv_local_imp_src_code) = convert_source_code_to_string( lt_source ).

    FIND ALL OCCURRENCES OF PCRE |{ gc_kw_method }\\s+\\w\{1,30\}[\\s\\S]*?{ gc_kw_endmethod }|
    IN lv_local_imp_src_code
    IGNORING CASE
    RESULTS DATA(lt_match).

    LOOP AT lt_match ASSIGNING FIELD-SYMBOL(<ls_match>) WHERE table_line IS NOT INITIAL.
      APPEND lv_local_imp_src_code+<ls_match>-offset(<ls_match>-length) TO rt_methods_source.
    ENDLOOP.
  ENDMETHOD.


  METHOD convert_source_code_to_string.

    IF it_source IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<ls_src_line>)
         WHERE table_line IS NOT INITIAL
           AND table_line NS gc_comment_pattern.

      rv_source_string = |{ rv_source_string }{ <ls_src_line> }{ text_separator }|.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_report_contacts.

    IF it_report_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT name,
           cnam,
           unam
      FROM progdir
      FOR ALL ENTRIES IN @it_report_name
            WHERE name = @it_report_name-table_line
    INTO TABLE @DATA(lt_report_detail).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rt_report_contact = VALUE #( FOR <ls_detail> IN lt_report_detail
                               ( object = <ls_detail>-name
                                 contact = COND #( WHEN <ls_detail>-unam IS NOT INITIAL
                                                   THEN <ls_detail>-unam
                                                   ELSE <ls_detail>-cnam ) ) ).
  ENDMETHOD.


  METHOD get_function_module_contacts.

    IF it_fm_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT funcname,
           pname
      FROM tfdir
    FOR ALL ENTRIES IN @it_fm_name
      WHERE funcname = @it_fm_name-table_line
    INTO TABLE @DATA(lt_fm_name_group).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lt_prog_name) = VALUE tt_prog_name( FOR <lv_pname> IN lt_fm_name_group ( <lv_pname>-pname ) ).
    SORT lt_prog_name.
    DELETE ADJACENT DUPLICATES FROM lt_prog_name.

    IF lt_prog_name IS NOT INITIAL.
      SELECT name,
             cnam,
             unam
        FROM progdir
      FOR ALL ENTRIES IN @lt_prog_name
            WHERE name = @lt_prog_name-table_line
             AND state = @gc_progdir_active_objects
      INTO TABLE @DATA(lt_fm_detail).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDIF.

    rt_function_module_contact = VALUE #( FOR <ls_tfdir> IN lt_fm_name_group
                                          LET ls_detail = VALUE #( lt_fm_detail[ name = <ls_tfdir>-pname ] OPTIONAL ) IN
                                          ( object  = <ls_tfdir>-funcname
                                            contact = COND #( WHEN ls_detail-unam IS NOT INITIAL
                                                              THEN ls_detail-unam
                                                              ELSE ls_detail-cnam ) ) ).
  ENDMETHOD.


  METHOD get_class_method_contacts.

    IF it_class_name IS INITIAL.
      RETURN.
    ENDIF.

    " Get classes details
    SELECT clsname,
           author,
           changedby
      FROM seoclassdf
      FOR ALL ENTRIES IN @it_class_name
         WHERE clsname = @it_class_name-table_line
           AND version = @gc_active_objects
    INTO TABLE @DATA(lt_class_detail).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Get classes methods details
    SELECT clsname,
           cmpname,
           author,
           changedby
      FROM seocompodf
      FOR ALL ENTRIES IN @it_class_name
         WHERE clsname = @it_class_name-table_line
    INTO TABLE @DATA(lt_class_methods_detail).

    lt_class_methods_detail = CORRESPONDING #( BASE ( lt_class_methods_detail ) lt_class_detail ).

    rt_class_method_contact = VALUE #( FOR <ls_detail> IN lt_class_methods_detail
                                     ( object = <ls_detail>-clsname
                                       component = <ls_detail>-cmpname
                                       contact = COND #( WHEN <ls_detail>-changedby IS NOT INITIAL
                                                         THEN <ls_detail>-changedby
                                                         ELSE <ls_detail>-author ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_code_reviewer DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS:
      gc_msg_object_processing_err  TYPE string VALUE 'Error occurred while processing object',
      gc_msg_section_processing_err TYPE string VALUE 'Error occurred while processing section',
      gc_msg_no_responsible_persons TYPE string VALUE 'No responsible persons were found',
      gc_msg_no_input_objects       TYPE string VALUE 'No objects to review',
      gc_msg_no_prompt              TYPE string VALUE 'No prompt was provided',
      gc_msg_no_objects             TYPE string VALUE 'No objects to review were found',
      gc_msg_no_source_code         TYPE string VALUE 'No source code to review'.

    METHODS:
      get_suggestions_for_objects IMPORTING !it_object           TYPE tt_object_definition
                                            !iv_prompt           TYPE string
                                            !iv_detailed         TYPE abap_bool
                                  RETURNING VALUE(rt_suggestion) TYPE tt_suggestion
                                  RAISING   lcx_code_reviewer_error.

  PRIVATE SECTION.
    METHODS:
      determine_responsible_persons,

      categorize_objects,

      retrieve_source_code IMPORTING !iv_detailed    TYPE abap_bool,

      review_objects IMPORTING !iv_prompt           TYPE string
                     RETURNING VALUE(rt_suggestion) TYPE tt_suggestion.

    DATA:
      mt_class                    TYPE string_table,
      mt_fm                       TYPE string_table,
      mt_report                   TYPE string_table,

      mt_object_src_code          TYPE tt_object_source,
      mt_object_sections_src_code TYPE tt_object_sections_source,

      mt_object_contact           TYPE tt_contact,
      mt_object                   TYPE tt_object_definition.

ENDCLASS.



CLASS lcl_code_reviewer IMPLEMENTATION.


  METHOD get_suggestions_for_objects.

    IF it_object IS INITIAL.
      RAISE EXCEPTION TYPE lcx_code_reviewer_error
        EXPORTING
          iv_error_text = gc_msg_no_input_objects.
    ENDIF.
    IF iv_prompt IS INITIAL.
      RAISE EXCEPTION TYPE lcx_code_reviewer_error
        EXPORTING
          iv_error_text = gc_msg_no_prompt.
    ENDIF.

    CLEAR: mt_class,
           mt_fm,
           mt_report,
           mt_object_src_code,
           mt_object_sections_src_code,
           mt_object_contact.

    mt_object = it_object.

    categorize_objects( ).
    IF mt_class IS INITIAL
    AND mt_fm IS INITIAL
    AND mt_report IS INITIAL.
      RAISE EXCEPTION TYPE lcx_code_reviewer_error
        EXPORTING
          iv_error_text = gc_msg_no_objects.
    ENDIF.

    determine_responsible_persons( ).
    IF mt_object_contact IS INITIAL.
      lcl_logger=>warn( gc_msg_no_responsible_persons ).
    ENDIF.

    retrieve_source_code( iv_detailed ).
    IF mt_object_src_code IS INITIAL.
      RAISE EXCEPTION TYPE lcx_code_reviewer_error
        EXPORTING
          iv_error_text = gc_msg_no_source_code.
    ENDIF.

    rt_suggestion = review_objects( iv_prompt ).
  ENDMETHOD.


  METHOD review_objects.

    DATA:
      lv_prompt     TYPE string,
      lt_suggestion TYPE tt_suggestion,
      lv_name       TYPE string.

    IF iv_prompt IS INITIAL.
      RETURN.
    ENDIF.

    IF mt_object_src_code IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_target_prompt) = lcl_ai_helper=>get_final_prompt( iv_prompt ).

    " Review objects
    LOOP AT mt_object_src_code ASSIGNING FIELD-SYMBOL(<ls_report_src_code>).
      lv_prompt = |{ lv_target_prompt }{ <ls_report_src_code>-source_code }|.
      TRY.
          lt_suggestion = lcl_ai_helper=>deserialize_suggestions(
                            iv_object_name = |{ <ls_report_src_code>-object_name } { <ls_report_src_code>-local_section_name }|
                            iv_object_type = VALUE #( mt_object[ object_name = <ls_report_src_code>-object_name ]-object_type OPTIONAL )
                            iv_user        = VALUE #( mt_object_contact[ object = CONV #( <ls_report_src_code>-object_name ) ]-contact OPTIONAL )
                            iv_json        = lcl_ai_helper=>execute_prompt( lv_prompt ) ).
        CATCH lcx_ai_helper_error INTO DATA(lx_ai_helper_error).
          lcl_logger=>warn( |{ gc_msg_object_processing_err }: { <ls_report_src_code>-object_name }: { lx_ai_helper_error->get_text( ) }| ).
          CONTINUE.
      ENDTRY.

      APPEND LINES OF lt_suggestion TO rt_suggestion.
    ENDLOOP.

    " Review objects sections
    LOOP AT mt_object_sections_src_code ASSIGNING FIELD-SYMBOL(<ls_object_sections_src_code>).
      LOOP AT <ls_object_sections_src_code>-sections ASSIGNING FIELD-SYMBOL(<ls_section>).

        lv_prompt = |{ lv_target_prompt }{ <ls_section> }|.

        lv_name = VALUE #( mt_object_contact[
                           object = CONV #( <ls_object_sections_src_code>-object_name )
                           component = CONV #( <ls_section> ) ]-contact OPTIONAL ).
        IF lv_name IS INITIAL.
          lv_name = VALUE #( mt_object_contact[ object = CONV #( <ls_object_sections_src_code>-object_name ) ]-contact OPTIONAL ).
        ENDIF.

        TRY.
            lt_suggestion = lcl_ai_helper=>deserialize_suggestions(
              iv_object_type = VALUE #( mt_object[ object_name = <ls_object_sections_src_code>-object_name ]-object_type OPTIONAL )
              iv_object_name = <ls_object_sections_src_code>-object_name
              iv_user        = lv_name
              iv_json        = lcl_ai_helper=>execute_prompt( lv_prompt ) ).
          CATCH lcx_ai_helper_error INTO lx_ai_helper_error.
            lcl_logger=>warn( |{ gc_msg_section_processing_err }: { <ls_object_sections_src_code>-object_name }: { lx_ai_helper_error->get_text( ) }| ).
            CONTINUE.
        ENDTRY.

        APPEND LINES OF lt_suggestion TO rt_suggestion.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD determine_responsible_persons.

    IF mt_class IS NOT INITIAL.
      APPEND LINES OF  lcl_abap_source_code_getter=>get_class_method_contacts( CONV #( mt_class ) ) TO mt_object_contact.
    ENDIF.

    IF mt_fm IS NOT INITIAL.
      APPEND LINES OF lcl_abap_source_code_getter=>get_function_module_contacts( CONV #( mt_fm ) ) TO mt_object_contact.
    ENDIF.

    IF mt_report IS NOT INITIAL.
      APPEND LINES OF lcl_abap_source_code_getter=>get_report_contacts( CONV #( mt_report ) ) TO mt_object_contact.
    ENDIF.
  ENDMETHOD.


  METHOD categorize_objects.

    IF mt_object IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT mt_object ASSIGNING FIELD-SYMBOL(<ls_object>).
      CASE <ls_object>-object_type.
        WHEN gc_object_def_type_class.
          APPEND <ls_object>-object_name TO mt_class.
        WHEN gc_object_def_type_fm.
          APPEND <ls_object>-object_name TO mt_fm.
        WHEN gc_object_def_type_report.
          APPEND <ls_object>-object_name TO mt_report.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD retrieve_source_code.

    DATA(lo_class_src_code_getter) = NEW lcl_abap_source_code_getter( ).

    APPEND LINES OF lo_class_src_code_getter->get_classes_source_code( mt_class ) TO mt_object_src_code.
    APPEND LINES OF lo_class_src_code_getter->get_func_modules_source_code( mt_fm ) TO mt_object_src_code.
    APPEND LINES OF lo_class_src_code_getter->get_reports_source_code( mt_report ) TO mt_object_src_code.

    IF mt_object_src_code IS INITIAL.
      RETURN.
    ENDIF.

    " Detailed mode includes quick + method-by-method review
    IF iv_detailed = abap_true.
      APPEND LINES OF lo_class_src_code_getter->get_classes_methods_src_code( mt_class ) TO mt_object_sections_src_code.
      APPEND LINES OF lo_class_src_code_getter->get_reports_sections_src_code( mt_report ) TO mt_object_sections_src_code.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


**********************************************************************
*** Selection Screen
**********************************************************************

TYPE-POOLS sscr.
TABLES sscrfields.

TYPES:
  BEGIN OF ts_selection_option,
    transport_request TYPE tr_trkorr,
    user              TYPE sy-uname,
    object_name       TYPE char30,
    package_name      TYPE char30,
  END OF ts_selection_option.

DATA:
  so_selection_options       TYPE ts_selection_option.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT (50) hdr_txt MODIF ID m1.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF SCREEN 200 AS SUBSCREEN.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT (50) trtbtxt MODIF ID m2.
  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS: so_tr   FOR so_selection_options-transport_request NO INTERVALS,
                  so_user FOR so_selection_options NO INTERVALS MATCHCODE OBJECT sci_user.

  SELECTION-SCREEN SKIP.

  PARAMETERS: p_cobj  AS CHECKBOX USER-COMMAND flag,
              p_cuser AS CHECKBOX USER-COMMAND flag.
SELECTION-SCREEN END OF SCREEN 200.

SELECTION-SCREEN BEGIN OF SCREEN 300 AS SUBSCREEN.
  SELECT-OPTIONS so_obj FOR so_selection_options-object_name NO INTERVALS.
SELECTION-SCREEN END OF SCREEN 300.

SELECTION-SCREEN BEGIN OF SCREEN 400 AS SUBSCREEN.
  SELECT-OPTIONS so_pkg FOR so_selection_options-package_name NO INTERVALS MATCHCODE OBJECT devclass.
SELECTION-SCREEN END OF SCREEN 400.

PARAMETERS: p_acttab TYPE sy-ucomm NO-DISPLAY.

SELECTION-SCREEN: BEGIN OF TABBED BLOCK tb_block FOR 7 LINES,
TAB (40) tr_tab USER-COMMAND push1,
TAB (40) obj_tab USER-COMMAND push2,
TAB (40) pkg_tab USER-COMMAND push3,
END OF BLOCK tb_block.

SELECTION-SCREEN BEGIN OF BLOCK disp_block WITH FRAME TITLE disp.

  PARAMETERS: p_quick  RADIOBUTTON GROUP grp1 DEFAULT 'X',
              p_detail RADIOBUTTON GROUP grp1.

  SELECTION-SCREEN SKIP.

  SELECTION-SCREEN PUSHBUTTON /1(20) pe_btn_t USER-COMMAND txt.

  PARAMETERS p_prompt TYPE stringval LOWER CASE NO-DISPLAY.

SELECTION-SCREEN END OF BLOCK disp_block.

SELECTION-SCREEN BEGIN OF BLOCK exp_block WITH FRAME TITLE exp.

  PARAMETERS: p_alv    RADIOBUTTON GROUP grp2 DEFAULT 'X' USER-COMMAND rad2,
              p_text   RADIOBUTTON GROUP grp2,
              p_excel  RADIOBUTTON GROUP grp2,
              p_xl_srv RADIOBUTTON GROUP grp2.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_path TYPE string MODIF ID pid LOWER CASE.

SELECTION-SCREEN END OF BLOCK exp_block.


CLASS lcl_report_helper DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES:
        rt_object TYPE RANGE OF char30.

    CONSTANTS:
      gc_screen_number_main          TYPE syst_dynnr VALUE '1000',
      gc_tab_number_transport        TYPE syst_dynnr VALUE '0200',
      gc_tab_number_objects          TYPE syst_dynnr VALUE '0300',
      gc_tab_number_packages         TYPE syst_dynnr VALUE '0400',

      gc_txt_label_so_tr             TYPE string VALUE 'Request ID(s)',
      gc_txt_label_so_user           TYPE string VALUE 'User Name(s)',
      gc_txt_label_p_cobj            TYPE string VALUE 'Process my Transport Requests',
      gc_txt_label_p_cuser           TYPE string VALUE 'Process my Objects',
      gc_txt_label_so_obj            TYPE string VALUE 'Objects',
      gc_txt_label_so_pkg            TYPE string VALUE 'Packages',
      gc_txt_label_p_quick           TYPE string VALUE 'Quick Review',
      gc_txt_label_p_detail          TYPE string VALUE 'Detailed Review',
      gc_txt_label_p_alv             TYPE string VALUE 'Display in ALV',
      gc_txt_label_p_text            TYPE string VALUE 'Display in Text',
      gc_txt_label_p_excel           TYPE string VALUE 'Excel export',
      gc_txt_label_p_xl_srv          TYPE string VALUE 'Excel export to server',
      gc_txt_label_p_path            TYPE string VALUE 'File Path',

      gc_program_title               TYPE string VALUE 'Automatic AI Code Reviews',
      gc_tab_name_by_transports      TYPE string VALUE 'By Transports',
      gc_tab_name_by_objects         TYPE string VALUE 'By Objects',
      gc_tab_name_by_packages        TYPE string VALUE 'By Packages',
      gc_export_block_title          TYPE string VALUE 'Output Options',
      gc_display_block_title         TYPE string VALUE 'AI processing method',
      gc_prompt_editor_title         TYPE string VALUE 'Prompt editor',
      gc_info_button_text            TYPE string VALUE 'User Manual',
      gc_prompt_editor_button_text   TYPE string VALUE 'Prompt Editor',
      gc_transport_tab_title         TYPE string VALUE 'Get Transports by:',
      gc_objects_search_help_title   TYPE string VALUE 'Available objects',

      gc_uc_transports_tab           TYPE syucomm VALUE 'PUSH1',
      gc_uc_objects_tab              TYPE syucomm VALUE 'PUSH2',
      gc_uc_packages_tab             TYPE syucomm VALUE 'PUSH3',
      gc_uc_program_description      TYPE syucomm VALUE 'FC01',
      gc_uc_execute                  TYPE syucomm VALUE 'ONLI',
      gc_uc_prompt_edit              TYPE syucomm VALUE 'TXT',

      gc_p_name_objects              TYPE c LENGTH 8 VALUE 'P_COBJ',
      gc_p_name_user                 TYPE c LENGTH 8 VALUE 'P_CUSER',
      gc_p_name_path                 TYPE c LENGTH 8 VALUE 'P_PATH',
      gc_p_path_modif_id             TYPE c LENGTH 8 VALUE 'PID',
      gc_so_name_objects             TYPE c LENGTH 8 VALUE 'SO_OBJ',
      gc_so_name_packages            TYPE c LENGTH 8 VALUE 'SO_PKG',
      gc_so_name_tr                  TYPE c LENGTH 8 VALUE 'SO_TR',
      gc_so_name_usr                 TYPE c LENGTH 8 VALUE 'SO_USER',
      gc_so_obj_low                  TYPE screen-name VALUE 'SO_OBJ-LOW',
      gc_so_obj_high                 TYPE screen-name VALUE 'SO_OBJ-HIGH',
      gc_so_tr_low                   TYPE screen-name VALUE 'SO_TR-LOW',
      gc_so_tr_high                  TYPE screen-name VALUE 'SO_TR-HIGH',
      gc_so_user_low                 TYPE screen-name VALUE 'SO_USER-LOW',
      gc_so_user_high                TYPE screen-name VALUE 'SO_USER-HIGH',

      gc_msg_transport_not_specified TYPE string VALUE 'Transports or users must be specified',
      gc_msg_user_and_tr_selected    TYPE string VALUE 'You cannot specify Requests by Users and Transports Requests together',
      gc_msg_t_request_not_specified TYPE string VALUE 'Transport Requests must be specified',
      gc_msg_empty_select_option     TYPE string VALUE 'Empty select option',
      gc_msg_not_found               TYPE string VALUE 'Nothing has been found',
      gc_msg_no_suggestions          TYPE string VALUE 'No suggestions can be provided',
      gc_msg_extraction_objects_err  TYPE string VALUE 'Unable to get objects to review',
      gc_msg_exporting_error         TYPE string VALUE 'Unable to export',
      gc_msg_screen_field_read_err   TYPE string VALUE 'Unable to read screen field value',

      gc_default_search_pattern      TYPE string VALUE '*',

      gc_screen_true                 TYPE c VALUE '1',
      gc_screen_false                TYPE c VALUE '0'.

    CLASS-METHODS:
      initialize,

      process_at_selection_screen,

      process_at_sel_screen_output,

      process_start_of_selection,

      get_selection_option_input IMPORTING !iv_selection_option_name TYPE screen-name
                                 RETURNING VALUE(rv_input)           TYPE string,

      get_available_objects IMPORTING !iv_search_pattern         TYPE string
                            RETURNING VALUE(rt_range_of_objects) TYPE rt_object,

      setup_text_labels,

      setup_select_opts_restrictions.

  PRIVATE SECTION.

    CLASS-METHODS:
      get_program_description RETURNING VALUE(rv_description) TYPE string.

ENDCLASS.



CLASS lcl_report_helper IMPLEMENTATION.


  METHOD initialize.

    hdr_txt = gc_program_title.
    tr_tab  = gc_tab_name_by_transports.
    obj_tab = gc_tab_name_by_objects.
    pkg_tab = gc_tab_name_by_packages.
    exp     = gc_export_block_title.
    disp    = gc_display_block_title.
    trtbtxt = gc_transport_tab_title.
    pe_btn_t = gc_prompt_editor_button_text.

    tb_block-prog = sy-repid.

    tb_block-dynnr = gc_tab_number_transport.

    setup_select_opts_restrictions( ).

    IF p_prompt IS INITIAL.
      p_prompt = lcl_ai_helper=>get_default_prompt( ).
    ENDIF.

  ENDMETHOD.


  METHOD process_at_selection_screen.

    CASE sscrfields-ucomm.

      WHEN gc_uc_program_description.

        IF sy-dynnr = gc_screen_number_main.
          cl_demo_output=>display_html( get_program_description( ) ).
        ENDIF.

      WHEN gc_uc_transports_tab.

        p_acttab = tb_block-activetab.
        tb_block-activetab = gc_uc_transports_tab.
        tb_block-dynnr = gc_tab_number_transport.

      WHEN gc_uc_objects_tab.

        p_acttab = tb_block-activetab.
        tb_block-activetab = gc_uc_objects_tab.
        tb_block-dynnr = gc_tab_number_objects.

      WHEN gc_uc_packages_tab.

        p_acttab = tb_block-activetab.
        tb_block-activetab = gc_uc_packages_tab.
        tb_block-dynnr = gc_tab_number_packages.

      WHEN gc_uc_execute.

        IF tb_block-dynnr = gc_tab_number_transport.
          IF p_cobj  = abap_false AND
             p_cuser = abap_false AND
             so_tr   IS INITIAL   AND
             so_user IS INITIAL.
            MESSAGE gc_msg_transport_not_specified TYPE 'E'.
            SET CURSOR FIELD gc_p_name_objects.
          ENDIF.

          IF so_user IS NOT INITIAL AND
             so_tr IS NOT INITIAL.
            MESSAGE gc_msg_user_and_tr_selected TYPE 'E'.
            SET CURSOR FIELD gc_p_name_objects.
          ENDIF.

          IF p_cuser = abap_true AND
             p_cobj  = abap_false AND
             so_tr IS INITIAL.
            MESSAGE gc_msg_t_request_not_specified TYPE 'E'.
            SET CURSOR FIELD gc_p_name_user.
          ENDIF.
        ENDIF.

        IF tb_block-dynnr = gc_tab_number_objects.
          IF so_obj IS INITIAL.
            MESSAGE gc_msg_empty_select_option TYPE 'E'.
            SET CURSOR FIELD gc_so_name_objects.
          ENDIF.
        ENDIF.

        IF tb_block-dynnr = gc_tab_number_packages.
          IF so_pkg IS INITIAL.
            MESSAGE gc_msg_empty_select_option TYPE 'E'.
            SET CURSOR FIELD gc_so_name_packages.
          ENDIF.
        ENDIF.

      WHEN gc_uc_prompt_edit.

        IF sy-dynnr = gc_screen_number_main.
          DATA lt_note TYPE STANDARD TABLE OF stringval.

          SPLIT p_prompt AT cl_abap_char_utilities=>newline INTO TABLE lt_note.

          CALL FUNCTION 'TERM_CONTROL_EDIT'
            EXPORTING
              titel          = gc_prompt_editor_title
            TABLES
              textlines      = lt_note
            EXCEPTIONS
              user_cancelled = 1
              OTHERS         = 2.
          IF sy-subrc = 0.
            CLEAR p_prompt.
            LOOP AT lt_note ASSIGNING FIELD-SYMBOL(<ls_note>).
              p_prompt = COND #( WHEN sy-tabix = 1
                                 THEN |{ <ls_note> }|
                                 ELSE |{ p_prompt }{ cl_abap_char_utilities=>newline }{ <ls_note> }| ).
            ENDLOOP.
          ENDIF.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD process_at_sel_screen_output.

    IF p_acttab IS NOT INITIAL.
      tb_block-activetab = p_acttab.

      CASE p_acttab.
        WHEN gc_uc_transports_tab.
          tb_block-dynnr = gc_tab_number_transport.
        WHEN gc_uc_objects_tab.
          tb_block-dynnr = gc_tab_number_objects.
        WHEN gc_uc_packages_tab.
          tb_block-dynnr = gc_tab_number_packages.
      ENDCASE.
    ELSE.
      tb_block-activetab = gc_uc_transports_tab.
      tb_block-dynnr     = gc_tab_number_transport.
    ENDIF.

    LOOP AT SCREEN .
      IF screen-name = gc_so_tr_low   OR
         screen-name = gc_so_tr_high  OR
         screen-name = gc_so_user_low OR
         screen-name = gc_so_user_high.
        screen-input = COND #( WHEN p_cobj = abap_true THEN 0 ELSE 1 ).
        MODIFY SCREEN.
      ENDIF.
      IF screen-name   = gc_p_name_path OR
         screen-group1 = gc_p_path_modif_id.
        IF p_xl_srv = 'X'.
          screen-active    = gc_screen_true.
          screen-invisible = gc_screen_false.
        ELSE.
          screen-active    = gc_screen_false.
          screen-invisible = gc_screen_true.
        ENDIF.
        MODIFY SCREEN.
        IF screen-name = gc_so_obj_high.
          screen-active = gc_screen_false.
          screen-invisible = gc_screen_true.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD process_start_of_selection.

    DATA lt_object         TYPE tt_object_definition.
* Get review objects from data sources

    DATA(lo_object_extractor) = NEW lcl_object_extractor( ).

    TRY.
        CASE tb_block-dynnr.

          WHEN gc_tab_number_transport.
            lt_object = lo_object_extractor->get_objects_by_tr_requests(
                          iv_fl_current_objects_only = p_cobj
                          iv_fl_current_user_only    = p_cuser
                          it_tr_request_header       = VALUE #( FOR <ls_req> IN so_tr[]
                                                                ( trkorr = <ls_req>-low ) )
                          it_user                    = VALUE #( FOR <ls_usr> IN so_user[]
                                                                ( CONV #( <ls_usr>-low ) ) ) ).
          WHEN gc_tab_number_objects.
            lt_object = lo_object_extractor->get_objects_by_names( VALUE #( FOR <lv_obj_name> IN so_obj[]
                                                                          ( CONV #( <lv_obj_name>-low ) ) ) ).

          WHEN gc_tab_number_packages.
            lt_object = lo_object_extractor->get_objects_by_packages( VALUE #(  FOR <lv_pkg_name> IN so_pkg[]
                                                                             ( CONV #( <lv_pkg_name>-low ) ) ) ).
          WHEN OTHERS.
            RETURN.
        ENDCASE.

      CATCH lcx_object_extractor_error INTO DATA(lx_object_extractor_error).
        lcl_logger=>warn( lx_object_extractor_error->get_text( ) ).
        MESSAGE gc_msg_extraction_objects_err TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    TRY.
        DATA(lt_all_suggestion) = NEW lcl_code_reviewer(
                                   )->get_suggestions_for_objects( it_object = lt_object
                                                                   iv_detailed = p_detail
                                                                   iv_prompt = p_prompt ).
      CATCH lcx_code_reviewer_error INTO DATA(lx_code_reviewer_error).
        MESSAGE lx_code_reviewer_error->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    IF lt_all_suggestion IS INITIAL.
      MESSAGE gc_msg_no_suggestions TYPE 'S'.
      RETURN.
    ENDIF.

* Export options

    DATA(lo_suggestion_helper) = NEW lcl_suggestions_exporter( ).

    TRY.
        IF p_excel = abap_true.
          lo_suggestion_helper->export_in_excel( lt_all_suggestion ).
          RETURN.
        ENDIF.

        IF p_alv = abap_true.
          lo_suggestion_helper->display_in_alv( lt_all_suggestion ).
          RETURN.
        ENDIF.

        IF p_text = abap_true.
          lo_suggestion_helper->display_in_demo_output( lt_all_suggestion ).
          RETURN.
        ENDIF.

        IF p_xl_srv = abap_true.
          lo_suggestion_helper->export_to_server( iv_file_path  = p_path
                                                  it_suggestion = lt_all_suggestion ).
        ENDIF.

      CATCH lcx_suggestions_exporter_error INTO DATA(lx_suggestions_exporter_error).
        lcl_logger=>warn( lx_suggestions_exporter_error->get_text( ) ).
        MESSAGE gc_msg_exporting_error TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD get_program_description.
    RETURN
        |<h1>AI Code Review Tool – User Documentation</h1>| &&
        || &&
        |<h2>Overview</h2>| &&
        || &&
        |<p>This program is an AI-powered tool for automatic ABAP code review.| &&
        |It helps developers find weak or questionable places in their code before a transport release. | &&
        |You can use it as an additional quality step in your workflow or as a self-review tool before presenting your code to colleagues.| &&
        |The idea is simple: fix the main problems before they reach someone else and minimize the time spent on repeated reviews.</p>| &&
        |<p>The tool can work with any reasoning LLM you have access to.</p>| &&
        || &&
        |<h2>Supported Objects</h2>| &&
        || &&
        |<p>At the moment the program supports ABAP classes, function modules and reports.</p>| &&
        || &&
        |<h2>Selecting Objects for Review</h2>| &&
        || &&
        |<p>You can select objects for review either by transport IDs, by object names or by packages.</p>| &&
        || &&
        |<p>There are two ways to find relevant transports on the selection screen. | &&
        |You can enter transport IDs directly, or you can enter a user name to retrieve transports associated with that person.</p>| &&
        || &&
        |<p>Additionally, there is a checkbox called "Process only my transport requests."| &&
        |When checked, the transport IDs and user name fields are ignored, and the program returns results only for active requests where you are involved. | &&
        |Please note: if you do not also check "Get only my objects," the program will return objects from all persons involved in the request. | &&
        |If you do check it, only objects from your own tasks will be included.</p>| &&
        || &&
        |<h2>AI Processing Modes</h2>| &&
        || &&
        |<p>The program offers two processing modes:</p>| &&
        || &&
        |<p><b>Quick mode</b> processes entire objects at once. | &&
        |The context window stays large, which means results may be less precise in some cases. | &&
        |For example, reviewing a class in quick mode means the entire class definition and implementation are sent together.</p>| &&
        || &&
        |<p><b>Detailed mode</b> combines full-object processing with a method-by-method review. | &&
        |Each class method is processed individually, keeping the context window as small as possible.| &&
        |This produces more precise and accurate results but requires more tokens and processing time.</p>| &&
        || &&
        |<h2>Custom Prompts</h2>| &&
        || &&
        |<p>You can specify your own review prompt by clicking the prompt edit button.| &&
        |Prompts can be saved as variant options, so you do not need to re-enter them each time you run the report.| &&
        |This is useful when you want to focus on specific aspects — for example, checking for performance issues or verifying how well the code follows SOLID principles.| &&
        |You can define multiple scenarios according to your needs.</p>| &&
        || &&
        |<h2>Output Options</h2>| &&
        || &&
        |<p>The program supports three output formats: ALV, text and Excel.</p>| &&
        || &&
        |<p>Excel files can be saved directly to your PC or exported to a server. | &&
        |If you choose server export, you must specify the server path where the file should be saved. | &&
        |Server export is particularly useful when running the program in background mode for a large number of objects.</p>| &&
        || &&
        |<h2>Initial Setup</h2>| &&
        || &&
        |<p>To use the tool, you need access to any reasoning LLM API. | &&
        |Before running the report, one method must be implemented in the code (the location is marked). | &&
        |Your implementation should call any reasoning LLM with a single string as input and return a single string as output.</p>| &&
        || &&
        |<p>The program was designed to work without ABAP Git, so installation is straightforward. | &&
        |You can copy and paste the program code into local objects in your system and start using it.</p>|.
  ENDMETHOD.


  METHOD get_selection_option_input.

    DATA lt_sel_screen_field TYPE TABLE OF dynpread.

    IF iv_selection_option_name IS INITIAL.
      RETURN.
    ENDIF.

    APPEND VALUE #( fieldname = iv_selection_option_name ) TO lt_sel_screen_field.

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname     = sy-cprog
        dynumb     = sy-dynnr
      TABLES
        dynpfields = lt_sel_screen_field
      EXCEPTIONS
        OTHERS     = 1.
    IF sy-subrc <> 0.
      lcl_logger=>warn( |{ gc_msg_screen_field_read_err }: { iv_selection_option_name }| ).
      RETURN.
    ENDIF.

    RETURN VALUE #( lt_sel_screen_field[ fieldname = iv_selection_option_name ]-fieldvalue OPTIONAL ).
  ENDMETHOD.


  METHOD get_available_objects.

    DATA: lt_result    TYPE tt_object_definition,
          lv_cancelled TYPE abap_bool.

    DATA(lv_search_pattern) = iv_search_pattern.
    IF lv_search_pattern IS INITIAL.
      lv_search_pattern = gc_default_search_pattern.
    ENDIF.

    TRY.
        DATA(lt_value) = NEW lcl_object_extractor(
                          )->get_objects_by_names( it_object_name = VALUE string_table( ( |{ lv_search_pattern }| ) ) ).
      CATCH lcx_object_extractor_error INTO DATA(lx_object_extractor_error).
        lcl_logger=>warn( lx_object_extractor_error->get_text( ) ).
    ENDTRY.

    IF lt_value IS INITIAL.
      MESSAGE gc_msg_not_found TYPE 'I'.
      RETURN.
    ENDIF.

    DATA(lo_value_help) = cl_reca_gui_f4_popup=>factory_grid( id_title   = gc_objects_search_help_title
                                                              it_f4value = lt_value ).

    lo_value_help->set_multi( abap_false ).
    lo_value_help->set_classic_layout( if_classic_layout = abap_true ).

    lo_value_help->display( IMPORTING et_result    = lt_result
                                      ef_cancelled = lv_cancelled ).

    IF lv_cancelled = abap_true.
      RETURN.
    ENDIF.

    RETURN VALUE rt_object( FOR <lv_obj_name> IN lt_result ( sign   = 'I'
                                                             option = 'EQ'
                                                             low    = <lv_obj_name>-object_name ) ).
  ENDMETHOD.


  METHOD setup_text_labels.
    %_so_tr_%_app_%-text    = gc_txt_label_so_tr.
    %_so_user_%_app_%-text  = gc_txt_label_so_user.
    %_so_pkg_%_app_%-text   = gc_txt_label_so_pkg.
    %_p_cobj_%_app_%-text   = gc_txt_label_p_cobj.
    %_p_cuser_%_app_%-text  = gc_txt_label_p_cuser.
    %_so_obj_%_app_%-text   = gc_txt_label_so_obj.
    %_p_quick_%_app_%-text  = gc_txt_label_p_quick.
    %_p_detail_%_app_%-text = gc_txt_label_p_detail.
    %_p_alv_%_app_%-text    = gc_txt_label_p_alv.
    %_p_text_%_app_%-text   = gc_txt_label_p_text.
    %_p_excel_%_app_%-text  = gc_txt_label_p_excel.
    %_p_xl_srv_%_app_%-text = gc_txt_label_p_xl_srv.
    %_p_path_%_app_%-text   = gc_txt_label_p_path.
  ENDMETHOD.


  METHOD setup_select_opts_restrictions.

    "Make Select Single Values only available option
    DATA(ls_restriction) = VALUE sscr_restrict( opt_list_tab = VALUE #( ( name       = gc_so_name_objects
                                                                  options-eq = abap_true
                                                                  options-cp = abap_true )
                                                                 ( name = gc_so_name_packages
                                                                   options-eq = abap_true )
                                                                 ( name = gc_so_name_tr
                                                                   options-eq = abap_true )
                                                                 ( name = gc_so_name_usr
                                                                   options-eq = abap_true ) )
                                        ass_tab      = VALUE #( ( kind = 'S'
                                                                  name = gc_so_name_objects
                                                                  sg_main = 'I'
                                                                  op_main = gc_so_name_objects )
                                                                ( kind = 'S'
                                                                  name = gc_so_name_packages
                                                                  sg_main = 'I'
                                                                  op_main = gc_so_name_packages )
                                                                ( kind = 'S'
                                                                  name = gc_so_name_tr
                                                                  sg_main = 'I'
                                                                  op_main = gc_so_name_tr )
                                                                ( kind = 'S'
                                                                  name = gc_so_name_usr
                                                                  sg_main = 'I'
                                                                  op_main = gc_so_name_usr ) ) ).

    CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
      EXPORTING
        restriction = ls_restriction.
  ENDMETHOD.


ENDCLASS.

INITIALIZATION.

  CONCATENATE icon_information lcl_report_helper=>gc_info_button_text INTO sscrfields-functxt_01 SEPARATED BY space.
  SELECTION-SCREEN FUNCTION KEY 1.

  lcl_report_helper=>initialize( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_obj-low.

  DATA(lv_search_pattern) = lcl_report_helper=>get_selection_option_input( lcl_report_helper=>gc_so_obj_low ).

  DATA(lt_search_result) = lcl_report_helper=>get_available_objects( lv_search_pattern ).
  so_obj = VALUE #( lt_search_result[ 1 ] OPTIONAL ).

AT SELECTION-SCREEN.

  lcl_report_helper=>process_at_selection_screen( ).

AT SELECTION-SCREEN OUTPUT.

  lcl_report_helper=>setup_text_labels( ).

  lcl_report_helper=>process_at_sel_screen_output( ).

START-OF-SELECTION.

  lcl_report_helper=>process_start_of_selection( ).
