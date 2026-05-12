*&---------------------------------------------------------------------*
*& Report Z_VALIO_CODE_REVIEW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_valio_code_review LINE-SIZE 132.

TYPES:
  BEGIN OF ts_suggestion,
    class_name TYPE string,
    method     TYPE string,
    suggestion TYPE string,
    priority   TYPE string,
    user       TYPE string,
  END OF ts_suggestion,
  tt_suggestion TYPE STANDARD TABLE OF ts_suggestion WITH DEFAULT KEY,
  tt_class_name TYPE STANDARD TABLE OF seoclsname WITH DEFAULT KEY.

CLASS lcl_ai_helper DEFINITION FINAL.

  PUBLIC SECTION.
    CONSTANTS:
      gc_msg_empty_parameter    TYPE string VALUE 'Input parameter is initial',
      gc_msg_deserialize_error  TYPE string VALUE 'Unable to deserialize',
      gc_msg_inaccessable_llm   TYPE string VALUE 'LLM Agent cannot be accessed',
      gc_msg_agent_not_provided TYPE string VALUE 'LLM agent is not provided',

      gc_prompt_begin_of_input  TYPE string VALUE 'Input for the review:'.

    CLASS-METHODS:
      get_master_prompt RETURNING VALUE(rv_master_prompt) TYPE stringval,

      get_default_prompt RETURNING VALUE(rv_default_prompt) TYPE stringval,

      get_final_prompt IMPORTING iv_user_prompt          TYPE stringval
                       RETURNING VALUE(rv_target_prompt) TYPE stringval,

      deserialize_suggestions IMPORTING !iv_class_name       TYPE string
                                        !iv_json             TYPE string
                                        !iv_user             TYPE string
                              RETURNING VALUE(rt_suggestion) TYPE tt_suggestion,

      execute_prompt IMPORTING !iv_prompt         TYPE string
                     RETURNING VALUE(rv_response) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS:
      normalize_format IMPORTING !iv_string                  TYPE string
                       RETURNING VALUE(rv_normalized_string) TYPE string.
ENDCLASS.

CLASS lcl_ai_helper IMPLEMENTATION.

  METHOD execute_prompt.
**********************************************************************
* Here you should provide a call to LLM.
**********************************************************************

    MESSAGE gc_msg_agent_not_provided TYPE 'E'.

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
                    && |{ cl_abap_char_utilities=>newline }     "method": "<method_name_or_global_if_not_applicable>",|
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
                     && |{ cl_abap_char_utilities=>newline } but avoid trivial or redundant points.|
                     && |{ cl_abap_char_utilities=>newline } - Each point must be concise, actionable, and specific.|
                     && |{ cl_abap_char_utilities=>newline } - Do not include any text outside the JSON output.|
                     && |{ cl_abap_char_utilities=>newline } - Use "GLOBAL" as method if the issue is not tied to a specific method.|
                     && |{ cl_abap_char_utilities=>newline } - For GLOBAL be ultra precise|
                     && |{ cl_abap_char_utilities=>newline } - Do not use complex words for explanations|
                     && |{ cl_abap_char_utilities=>newline } - Be precise and specific. Point exacly to the weak places|
                     && |{ cl_abap_char_utilities=>newline } - Generic points are prohibited|
                     && |{ cl_abap_char_utilities=>newline } - You must add clear examples to the output|.
  ENDMETHOD.


  METHOD get_final_prompt.

    rv_target_prompt = COND #( WHEN iv_user_prompt IS NOT INITIAL
                               THEN |{ lcl_ai_helper=>get_master_prompt( ) }{ iv_user_prompt }{ cl_abap_char_utilities=>newline }{ gc_prompt_begin_of_input }{ cl_abap_char_utilities=>newline } |
                               ELSE |{ lcl_ai_helper=>get_master_prompt( ) }{ cl_abap_char_utilities=>newline }{ gc_prompt_begin_of_input }{ cl_abap_char_utilities=>newline } | ).
  ENDMETHOD.


  METHOD deserialize_suggestions.

    IF iv_class_name IS INITIAL.
      MESSAGE gc_msg_empty_parameter TYPE 'E'.
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json = normalize_format( iv_string = iv_json )
                               CHANGING  data = rt_suggestion ).

    IF rt_suggestion IS INITIAL.
      MESSAGE gc_msg_deserialize_error TYPE 'E'.
    ENDIF.

    LOOP AT rt_suggestion ASSIGNING FIELD-SYMBOL(<fs_suggestion>).
      <fs_suggestion>-class_name = to_upper( iv_class_name ).
      <fs_suggestion>-user       = iv_user.
      <fs_suggestion>-method     = to_upper( <fs_suggestion>-method ).
    ENDLOOP.
  ENDMETHOD.


  METHOD normalize_format.

    CONSTANTS:
      lc_occurrence_last             TYPE i VALUE -1,
      lc_inclusive_length_adjustment TYPE i VALUE 1,

      lc_json_array_begin            VALUE '[',
      lc_json_array_end              VALUE ']'.

    IF iv_string IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_truncate_from) = find_any_of( val = iv_string sub = lc_json_array_begin ).
    DATA(lv_truncate_to)   = find_any_of( val = iv_string sub = lc_json_array_end occ = lc_occurrence_last ).

    IF lv_truncate_to < 0.
      " Incorrect string -> Skip it
      RETURN.
    ENDIF.

    rv_normalized_string = substring( val = iv_string
                                      off = lv_truncate_from
                                      len = lv_truncate_to - lv_truncate_from + lc_inclusive_length_adjustment ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_transport_extractor DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES:
      tt_user         TYPE STANDARD TABLE OF syuname WITH DEFAULT KEY.

    METHODS:
      get_class_from_tr_request IMPORTING !iv_fl_current_objects_only TYPE abap_bool
                                          !iv_fl_current_user_only    TYPE abap_bool
                                          !it_tr_requests_headers     TYPE trwbo_request_headers
                                          !it_user                    TYPE tt_user
                                RETURNING VALUE(rt_class)             TYPE tt_class_name.

  PRIVATE SECTION.
    CONSTANTS:
      gc_request_functions_all      TYPE string VALUE 'CDEFGKMOPQRSTWX',
      gc_objects_type_class_include TYPE string VALUE 'CINC',
      gc_objects_type_class         TYPE string VALUE 'CLAS',
      gc_status_modifiable_released TYPE string VALUE 'DLP ',
      gc_trfunction_workbench       TYPE string VALUE 'K'.

    METHODS:
      get_tr_request_headers IMPORTING !is_selection        TYPE trwbo_selection OPTIONAL
                                       !iv_username_pattern TYPE syst_uname OPTIONAL
                             RETURNING VALUE(rt_tr_request) TYPE trwbo_request_headers,

      get_classes_from_tr_requests IMPORTING !it_tr_requests_headers  TYPE trwbo_request_headers
                                             !iv_fl_current_user_only TYPE abap_bool OPTIONAL
                                   RETURNING VALUE(rt_class)          TYPE tt_class_name.
ENDCLASS.

CLASS lcl_transport_extractor IMPLEMENTATION.

  METHOD get_class_from_tr_request.

    DATA lt_tr_requests TYPE trwbo_request_headers.

    IF iv_fl_current_objects_only = abap_true.
      lt_tr_requests = get_tr_request_headers( iv_username_pattern = sy-uname ).
    ELSE.
      lt_tr_requests = it_tr_requests_headers.
      LOOP AT it_user ASSIGNING FIELD-SYMBOL(<ls_user>).
        APPEND LINES OF get_tr_request_headers( iv_username_pattern = <ls_user> ) TO lt_tr_requests.
      ENDLOOP.
    ENDIF.
    SORT lt_tr_requests BY trkorr.
    DELETE ADJACENT DUPLICATES FROM lt_tr_requests COMPARING trkorr.

    RETURN get_classes_from_tr_requests( it_tr_requests_headers = lt_tr_requests
                                         iv_fl_current_user_only = iv_fl_current_user_only ).
  ENDMETHOD.


  METHOD get_classes_from_tr_requests.

    DATA: lt_requests     TYPE trwbo_requests,
          lt_all_requests TYPE trwbo_requests.

    LOOP AT it_tr_requests_headers ASSIGNING FIELD-SYMBOL(<fs_tr_req_header>).
      CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
        EXPORTING
          iv_trkorr     = <fs_tr_req_header>-trkorr
        IMPORTING
          et_requests   = lt_requests
        EXCEPTIONS
          invalid_input = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND LINES OF lt_requests TO lt_all_requests.
    ENDLOOP.

    IF iv_fl_current_user_only = abap_true.
      DELETE lt_all_requests WHERE h-as4user <> sy-uname.
    ENDIF.

    LOOP AT lt_all_requests ASSIGNING FIELD-SYMBOL(<ls_request_details>).

      LOOP AT <ls_request_details>-objects ASSIGNING FIELD-SYMBOL(<ls_object>)
        WHERE object  = gc_objects_type_class_include
        OR object = gc_objects_type_class.

        SPLIT <ls_object>-obj_name AT '=' INTO TABLE DATA(lv_1) .
        rt_class = VALUE #( BASE rt_class ( CONV #( VALUE #( lv_1[ 1 ] OPTIONAL ) ) ) ).
      ENDLOOP.
    ENDLOOP.

    SORT rt_class.
    DELETE ADJACENT DUPLICATES FROM rt_class.
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

    CONSTANTS:
      gc_msg_save_dialog_fail        TYPE string VALUE 'Fail occured in save file dialog',
      gc_msg_failed_to_open_dataset  TYPE string VALUE 'Failed to open dataset',
      gc_msg_failed_to_transfer      TYPE string VALUE 'Failed to transfer with dataset',
      gc_msg_failed_to_close_dataset TYPE string VALUE 'Failed to close dataset',
      gc_msg_supplied_initial_param  TYPE string VALUE 'Parameter was supplied but its value is initial',
      gc_msg_empty_parameter         TYPE string VALUE 'Input parameter is initial',
      gc_msg_empty_file_path         TYPE string VALUE 'Empty file path'.

    METHODS:
      export_in_excel IMPORTING !it_suggestion TYPE tt_suggestion,

      export_to_server IMPORTING !iv_file_path  TYPE string
                                 !it_suggestion TYPE tt_suggestion,

      display_in_demo_output IMPORTING !it_suggestion TYPE tt_suggestion,

      display_in_alv IMPORTING !it_suggestion TYPE tt_suggestion.

  PRIVATE SECTION.

    CONSTANTS:
      gc_file_type_bin           TYPE char10 VALUE 'BIN',
      gc_priority_high           TYPE string VALUE 'HIGH',
      gc_priority_medium         TYPE string VALUE 'MEDIUM',
      gc_priority_low            TYPE string VALUE 'LOW',

      gc_sort_priority_high      TYPE string VALUE '1',
      gc_sort_priority_medium    TYPE string VALUE '2',
      gc_sort_priority_low       TYPE string VALUE '3',
      gc_sort_priority_default   TYPE string VALUE '4',

      gc_column_name_color       TYPE lvc_fname VALUE 'COLOR',
      gc_column_name_sorting_key TYPE lvc_fname VALUE 'SORTING_KEY',
      gc_column_name_class_name  TYPE lvc_fname VALUE 'CLASS_NAME',
      gc_column_name_method      TYPE lvc_fname VALUE 'METHOD',
      gc_column_name_suggestion  TYPE lvc_fname VALUE 'SUGGESTION',
      gc_column_name_priority    TYPE lvc_fname VALUE 'PRIORITY',
      gc_column_name_user        TYPE lvc_fname VALUE 'USER',

      gc_column_text_class_name  TYPE string VALUE 'Class',
      gc_column_text_method      TYPE string VALUE 'Method',
      gc_column_text_suggestion  TYPE string VALUE 'Comment',
      gc_column_text_priority    TYPE string VALUE 'Priority',
      gc_column_text_user        TYPE string VALUE 'User',

      gc_method_name_global      TYPE string VALUE 'GLOBAL',
      gc_file_extension_xlsx     TYPE string VALUE 'XLSX',

      gc_default_file_name       TYPE string VALUE 'Code review',
      gc_defalult_intense_value  TYPE i VALUE 1,

      gc_color_code_red          TYPE i VALUE 6,
      gc_color_code_orange       TYPE i VALUE 7,
      gc_color_code_yellow       TYPE i VALUE 3.

    TYPES:
      BEGIN OF ts_suggestion_with_tech_info,
        class_name  TYPE string,
        method      TYPE string,
        suggestion  TYPE string,
        priority    TYPE string,
        user        TYPE string,
        sorting_key TYPE string,
        color       TYPE lvc_t_scol,
      END OF ts_suggestion_with_tech_info,

      tt_suggestion_with_tech_info TYPE STANDARD TABLE OF ts_suggestion_with_tech_info WITH DEFAULT KEY.

    METHODS:
      create_xlsx_from_itab IMPORTING !it_fieldcat      TYPE lvc_t_fcat OPTIONAL
                                      !it_sort          TYPE lvc_t_sort OPTIONAL
                                      !it_filt          TYPE lvc_t_filt OPTIONAL
                                      !is_layout        TYPE lvc_s_layo OPTIONAL
                                      !it_hyperlinks    TYPE lvc_t_hype OPTIONAL
                            CHANGING  !it_data          TYPE STANDARD TABLE
                            RETURNING VALUE(rv_xstring) TYPE xstring,

      export_with_gui_download IMPORTING !iv_file_path TYPE string
                                         !iv_file_data TYPE xstring,

      export_with_open_dataset IMPORTING !iv_file_path TYPE string
                                         !iv_file_data TYPE xstring,

      populate_technical_info IMPORTING !it_suggestion                      TYPE tt_suggestion
                              RETURNING VALUE(rt_suggestion_with_tech_info) TYPE tt_suggestion_with_tech_info,

      calculate_sorting_key IMPORTING !is_suggestion TYPE ts_suggestion
                            RETURNING VALUE(rv_key)  TYPE string,

      calculate_color IMPORTING !is_suggestion TYPE ts_suggestion
                      RETURNING VALUE(rv_code) TYPE lvc_s_scol,

      beautify_salv_table IMPORTING !io_salv_table TYPE REF TO cl_salv_table,

      get_default_file_name RETURNING VALUE(rv_file_name) TYPE string.

ENDCLASS.



CLASS lcl_suggestions_exporter IMPLEMENTATION.


  METHOD create_xlsx_from_itab.

    FIELD-SYMBOLS: <ls_tab> TYPE STANDARD TABLE.

    IF it_data IS INITIAL.
      MESSAGE gc_msg_empty_parameter TYPE 'E'.
      RETURN.
    ENDIF.

    IF it_fieldcat IS SUPPLIED AND it_fieldcat IS INITIAL
    OR it_sort IS SUPPLIED AND it_sort IS INITIAL
    OR it_filt IS SUPPLIED AND it_filt IS INITIAL
    OR is_layout IS SUPPLIED AND is_layout IS INITIAL
    OR it_hyperlinks IS SUPPLIED AND it_hyperlinks IS INITIAL.
      MESSAGE gc_msg_supplied_initial_param TYPE 'E'.
    ENDIF.

    DATA(lt_data) = REF #( it_data ).

    IF it_fieldcat IS INITIAL.
      ASSIGN lt_data->* TO <ls_tab>.
      TRY.
          cl_salv_table=>factory( EXPORTING list_display = abap_false
                                  IMPORTING r_salv_table = DATA(salv_table)
                                  CHANGING  t_table      = <ls_tab> ).

          beautify_salv_table( io_salv_table = salv_table ).

          DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog( r_columns      = salv_table->get_columns( )
                                                                             r_aggregations = salv_table->get_aggregations( ) ).
        CATCH cx_salv_msg INTO DATA(lx_salv).
          MESSAGE lx_salv->get_text( ) TYPE 'E'.
      ENDTRY.
    ELSE.
      lt_fcat = it_fieldcat.
    ENDIF.

    cl_salv_bs_lex=>export_from_result_data_table( EXPORTING is_format            = if_salv_bs_lex_format=>mc_format_xlsx
                                                             ir_result_data_table = cl_salv_ex_util=>factory_result_data_table(
                                                             r_data               = lt_data
                                                             s_layout             = is_layout
                                                             t_fieldcatalog       = lt_fcat
                                                             t_sort               = it_sort
                                                             t_filter             = it_filt
                                                             t_hyperlinks         = it_hyperlinks )
                                                   IMPORTING er_result_file       = rv_xstring ).
  ENDMETHOD.


  METHOD export_with_gui_download.

    IF iv_file_path IS INITIAL.
      MESSAGE gc_msg_empty_file_path TYPE 'E'.
    ENDIF.

    DATA(it_raw_string) = cl_bcs_convert=>xstring_to_solix( iv_xstring = iv_file_data ).

    cl_gui_frontend_services=>gui_download( EXPORTING filename     = iv_file_path
                                                      filetype     = gc_file_type_bin
                                                      bin_filesize = xstrlen( iv_file_data )
                                            CHANGING  data_tab     = it_raw_string ).
  ENDMETHOD.


  METHOD export_with_open_dataset.

    DATA msg TYPE string.

    IF iv_file_path IS INITIAL.
      MESSAGE gc_msg_empty_file_path TYPE 'E'.
    ENDIF.

    OPEN DATASET iv_file_path FOR OUTPUT IN BINARY MODE MESSAGE msg.
    IF sy-subrc <> 0.
      MESSAGE gc_msg_failed_to_open_dataset TYPE 'E'.
      MESSAGE msg TYPE 'E'.
    ENDIF.

    TRANSFER iv_file_data TO iv_file_path.
    IF sy-subrc <> 0.
      MESSAGE gc_msg_failed_to_transfer TYPE 'E'.
    ENDIF.

    CLOSE DATASET iv_file_path.
    IF sy-subrc <> 0.
      MESSAGE gc_msg_failed_to_close_dataset TYPE 'E'.
    ENDIF.
  ENDMETHOD.


  METHOD calculate_color.

    IF is_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    rv_code = SWITCH lvc_s_scol( is_suggestion-priority
                    WHEN gc_priority_high   THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_red    int = gc_defalult_intense_value ) )
                    WHEN gc_priority_medium THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_orange int = gc_defalult_intense_value ) )
                    WHEN gc_priority_low    THEN VALUE #( fname = gc_column_name_priority color = VALUE #( col = gc_color_code_yellow int = gc_defalult_intense_value ) )
                    ELSE VALUE #( ) ).
  ENDMETHOD.


  METHOD calculate_sorting_key.

    IF is_suggestion IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_suggestion) = is_suggestion.
    CONDENSE: lv_suggestion-class_name NO-GAPS, lv_suggestion-method NO-GAPS.

    rv_key = |{ lv_suggestion-class_name }|
             && |{ SWITCH stringval( is_suggestion-priority WHEN gc_priority_high   THEN gc_sort_priority_high
                                                            WHEN gc_priority_medium THEN gc_sort_priority_medium
                                                            WHEN gc_priority_low    THEN gc_sort_priority_low
                                                                                    ELSE gc_sort_priority_default ) }|
             && |{ SWITCH stringval( is_suggestion-method WHEN gc_method_name_global THEN gc_sort_priority_high ELSE lv_suggestion-method ) }|.
  ENDMETHOD.


  METHOD populate_technical_info.

    rt_suggestion_with_tech_info = VALUE #( FOR <ls_suggestion> IN it_suggestion
                                            WHERE ( table_line IS NOT INITIAL )
                                                  ( class_name  = <ls_suggestion>-class_name
                                                    method      = <ls_suggestion>-method
                                                    suggestion  = <ls_suggestion>-suggestion
                                                    priority    = <ls_suggestion>-priority
                                                    user        = <ls_suggestion>-user
                                                    sorting_key = calculate_sorting_key( is_suggestion = <ls_suggestion> )
                                                    color       = VALUE #( ( calculate_color( is_suggestion = <ls_suggestion> ) ) ) ) ).
  ENDMETHOD.


  METHOD beautify_salv_table.

    IF io_salv_table IS NOT BOUND.
      RETURN.
    ENDIF.

    TRY.
        io_salv_table->get_columns( )->set_color_column( value = gc_column_name_color ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_sorting_key )->set_visible( if_salv_c_bool_sap=>false ).

        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_class_name )->set_short_text( CONV scrtext_s( gc_column_text_class_name ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_class_name )->set_medium_text( CONV scrtext_m( gc_column_text_class_name ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_class_name )->set_long_text( CONV scrtext_l( gc_column_text_class_name ) ).

        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_method )->set_short_text( CONV scrtext_s( gc_column_text_method ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_method )->set_medium_text( CONV scrtext_m( gc_column_text_method ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_method )->set_long_text( CONV scrtext_l( gc_column_text_method ) ).

        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_suggestion )->set_short_text( CONV scrtext_s( gc_column_text_suggestion ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_suggestion )->set_medium_text( CONV scrtext_m( gc_column_text_suggestion ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_suggestion )->set_long_text( CONV scrtext_l( gc_column_text_suggestion ) ).

        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_priority )->set_short_text( CONV scrtext_s( gc_column_text_priority ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_priority )->set_medium_text( CONV scrtext_m( gc_column_text_priority ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_priority )->set_long_text( CONV scrtext_l( gc_column_text_priority ) ).

        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_user )->set_short_text( CONV scrtext_s( gc_column_text_user ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_user )->set_medium_text( CONV scrtext_m( gc_column_text_user ) ).
        io_salv_table->get_columns( )->get_column( columnname = gc_column_name_user )->set_long_text( CONV scrtext_l( gc_column_text_user ) ).

        io_salv_table->get_functions( )->set_all( abap_true ).
        io_salv_table->get_columns( )->set_optimize( abap_true ).
      CATCH cx_salv_data_error cx_salv_not_found.
        RETURN.
    ENDTRY.
  ENDMETHOD.


  METHOD display_in_alv.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion = it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    TRY.
        cl_salv_table=>factory( EXPORTING list_display = abap_false
                                IMPORTING r_salv_table = DATA(salv_table)
                                CHANGING  t_table      = lt_suggestion_with_tech_info ).
      CATCH cx_salv_msg INTO DATA(lx_salv).
        MESSAGE lx_salv->get_text( ) TYPE 'E'.
    ENDTRY.

    beautify_salv_table( io_salv_table = salv_table ).

    salv_table->display( ).
  ENDMETHOD.


  METHOD export_in_excel.

    DATA: lv_full_path TYPE string,
          lv_path      TYPE string,
          lv_filename  TYPE string.

    IF it_suggestion IS INITIAL.
      MESSAGE gc_msg_empty_parameter TYPE 'E'.
    ENDIF.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion = it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        default_extension         = gc_file_extension_xlsx
        default_file_name         = get_default_file_name( )
      CHANGING
        filename                  = lv_filename
        path                      = lv_path
        fullpath                  = lv_full_path
      EXCEPTIONS
        cntl_error                = 1
        error_no_gui              = 2
        not_supported_by_gui      = 3
        invalid_default_file_name = 4
        OTHERS                    = 5 ).
    IF sy-subrc <> 0 OR lv_full_path IS INITIAL.
      MESSAGE gc_msg_save_dialog_fail TYPE 'E'.
    ENDIF.

    export_with_gui_download( iv_file_path = lv_full_path
                              iv_file_data = create_xlsx_from_itab( CHANGING it_data = lt_suggestion_with_tech_info ) ).
  ENDMETHOD.


  METHOD export_to_server.

    IF iv_file_path IS INITIAL.
      MESSAGE gc_msg_empty_file_path TYPE 'E'.
    ENDIF.

    DATA(lt_suggestion_with_tech_info) = populate_technical_info( it_suggestion = it_suggestion ).
    SORT lt_suggestion_with_tech_info BY sorting_key.

    export_with_open_dataset( iv_file_path = iv_file_path
                              iv_file_data = create_xlsx_from_itab( CHANGING it_data = lt_suggestion_with_tech_info ) ).
  ENDMETHOD.


  METHOD display_in_demo_output.
    cl_demo_output=>display( it_suggestion ).
  ENDMETHOD.

  METHOD get_default_file_name.
    RETURN |{ gc_default_file_name } { sy-datum }{ sy-uzeit }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_abap_source_code_getter DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ts_class_definition,
        class_name       TYPE string,
        local_class_name TYPE string,
        source_code      TYPE string,
      END OF ts_class_definition,

      BEGIN OF ts_class_methods_source,
        class_name TYPE string,
        methods    TYPE string_table,
      END OF ts_class_methods_source,

      BEGIN OF ts_contact,
        class     TYPE seoclsname,
        component TYPE seocmpname,
        contact   TYPE sy-uname,
      END OF ts_contact,

      tt_contact              TYPE STANDARD TABLE OF ts_contact WITH DEFAULT KEY,
      tt_class_definition     TYPE STANDARD TABLE OF ts_class_definition WITH DEFAULT KEY,
      tt_class_methods_source TYPE STANDARD TABLE OF ts_class_methods_source WITH DEFAULT KEY.

    METHODS:
      get_classes_source_code IMPORTING !it_class_name             TYPE string_table
                              RETURNING VALUE(rt_class_definition) TYPE tt_class_definition,

      get_classes_methods_src_code IMPORTING !it_class_name                 TYPE string_table
                                   RETURNING VALUE(rt_class_methods_source) TYPE tt_class_methods_source.

    CLASS-METHODS: get_class_method_contacts IMPORTING it_class                       TYPE tt_class_name
                                             RETURNING VALUE(rt_class_method_contact) TYPE tt_contact.

  PRIVATE SECTION.

    CONSTANTS:
      text_separator       TYPE abap_char1 VALUE cl_abap_char_utilities=>newline,
      gc_class_pool        TYPE string VALUE 'CLASS-POOL',
      gc_comment_pattern   TYPE string VALUE '*"',
      gc_kw_public_section TYPE string VALUE 'PUBLIC SECTION',
      gc_kw_class          TYPE string VALUE 'CLASS',
      gc_kw_endclass       TYPE string VALUE 'ENDCLASS',
      gc_kw_definition     TYPE string VALUE 'DEFINITION',
      gc_kw_implementation TYPE string VALUE 'IMPLEMENTATION',
      gc_kw_method         TYPE string VALUE 'METHOD',
      gc_kw_endmethod      TYPE string VALUE 'ENDMETHOD',
      gc_active_objects    TYPE i VALUE 1.

    METHODS:
      get_class_src_code IMPORTING !iv_class_name              TYPE string
                         RETURNING VALUE(rv_class_source_code) TYPE string,

      get_local_classes_src_code IMPORTING !iv_class_name             TYPE string
                                 RETURNING VALUE(rt_class_definition) TYPE tt_class_definition,

      get_class_methods_src_code IMPORTING !iv_class_name                   TYPE string
                                 RETURNING VALUE(rt_class_methods_src_code) TYPE string_table,

      get_class_pool_src_code IMPORTING !it_source                     TYPE seop_source_string
                                        !iv_class_name                 TYPE string
                              EXPORTING !ev_class_pool_begin_src_code  TYPE string
                                        !ev_class_pool_bridge_src_code TYPE string
                                        !ev_class_pool_ending_src_code TYPE string,

      convert_seop_source_to_string IMPORTING !it_source              TYPE seop_source_string
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


  METHOD get_classes_methods_src_code.

    IF it_class_name IS INITIAL.
      RETURN.
    ENDIF.

    rt_class_methods_source = VALUE #( FOR <ls_cls_name> IN it_class_name WHERE ( table_line IS NOT INITIAL )
                                                                                ( class_name = <ls_cls_name>
                                                                                  methods    = get_class_methods_src_code( <ls_cls_name> ) ) ).
  ENDMETHOD.


  METHOD get_classes_source_code.

    DATA source_code TYPE string.

    IF it_class_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_class_name ASSIGNING FIELD-SYMBOL(<ls_class_name>) WHERE table_line IS NOT INITIAL.

      source_code = get_class_src_code( <ls_class_name> ).
      IF source_code IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( class_name  = <ls_class_name>
                      source_code = source_code ) TO rt_class_definition.

      APPEND LINES OF get_local_classes_src_code( <ls_class_name> ) TO rt_class_definition.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_methods_src_code.

    DATA lo_class_naming TYPE REF TO if_oo_class_incl_naming.

    IF iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_include_naming) = cl_oo_include_naming=>get_instance_by_cifkey( VALUE #( clsname = to_upper( iv_class_name ) ) ).

    IF lo_include_naming IS BOUND.
      lo_class_naming ?= lo_include_naming.
    ELSE.
      RETURN.
    ENDIF.

    DATA(lt_local_cls_methods) = get_local_cls_methods_src_code( io_class_naming = lo_class_naming ).

    rt_class_methods_src_code = get_global_cl_methods_src_code( it_include = lo_class_naming->get_all_method_includes( ) ).

    APPEND LINES OF lt_local_cls_methods TO rt_class_methods_src_code.
  ENDMETHOD.


  METHOD get_class_pool_src_code.

    CLEAR ev_class_pool_begin_src_code.
    CLEAR ev_class_pool_bridge_src_code.
    CLEAR ev_class_pool_ending_src_code.

    DATA lv_class_pool_section_pointer TYPE sytabix.

    IF it_source IS INITIAL
    OR iv_class_name IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<ls_src_line>).
      IF to_upper( <ls_src_line> ) CS gc_class_pool.
        ev_class_pool_begin_src_code = |{ ev_class_pool_begin_src_code }{ <ls_src_line> }{ text_separator }|.
        lv_class_pool_section_pointer = sy-tabix.
        EXIT.
      ENDIF.
    ENDLOOP.

    DATA(lv_section_delimiter) = |{ gc_kw_class } { to_upper( iv_class_name ) } { gc_kw_implementation }|.

    LOOP AT it_source ASSIGNING <ls_src_line> FROM lv_class_pool_section_pointer.
      IF to_upper( <ls_src_line> ) CS gc_kw_endclass.
        ev_class_pool_bridge_src_code = |{ ev_class_pool_bridge_src_code }{ <ls_src_line> }{ text_separator }|.
      ENDIF.

      IF to_upper( <ls_src_line> ) CS lv_section_delimiter.
        ev_class_pool_bridge_src_code = |{ ev_class_pool_bridge_src_code }{ <ls_src_line> }{ text_separator }|.
        lv_class_pool_section_pointer = sy-tabix.
        EXIT.
      ENDIF.
    ENDLOOP.

    LOOP AT it_source ASSIGNING <ls_src_line> FROM lv_class_pool_section_pointer.
      IF to_upper( <ls_src_line> ) CS gc_kw_endclass.
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
      RETURN.
    ENDIF.

    IF lo_include_naming IS BOUND.
      lo_class_naming ?= lo_include_naming.
    ELSE.
      RETURN.
    ENDIF.

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
    DATA(lv_partial_src_code) = convert_seop_source_to_string( it_source = lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Macros
    READ REPORT lo_class_naming->macros INTO lt_source.
    lv_partial_src_code = convert_seop_source_to_string( it_source = lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Public Section
    READ REPORT lo_class_naming->public_section INTO lt_source.
    get_public_section_src_code( EXPORTING it_include                 = lt_source
                                 IMPORTING ev_class_definition_header = DATA(class_def_header_src_code)
                                           ev_public_section          = lv_partial_src_code ).

    rv_class_source_code = |{ rv_class_source_code }{ class_def_header_src_code }{ text_separator }| &
                           |{ lv_partial_src_code }{ text_separator }|.

    " Protected Section
    READ REPORT lo_class_naming->protected_section INTO lt_source.
    lv_partial_src_code = convert_seop_source_to_string( it_source = lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }|.

    " Private Section
    READ REPORT lo_class_naming->private_section INTO lt_source.
    lv_partial_src_code = convert_seop_source_to_string( it_source = lt_source ).

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator }| &
                           |{ lv_class_pool_bridge_src_code }{ text_separator }|.

    " Additional global class methods
    DATA(lv_methods_src_code) = get_global_cl_methods_src_code( it_include = lo_class_naming->get_all_method_includes( ) ).
    CONCATENATE LINES OF lv_methods_src_code INTO lv_partial_src_code SEPARATED BY text_separator.

    rv_class_source_code = |{ rv_class_source_code }{ lv_partial_src_code }{ text_separator } | &
                           |{ lv_class_pool_ending_src_code }{ text_separator }|.
  ENDMETHOD.


  METHOD get_public_section_src_code.

    CLEAR ev_class_definition_header.
    CLEAR ev_public_section.

    IF it_include IS INITIAL.
      RETURN.
    ENDIF.

    DATA(is_public_section) = abap_false.

    LOOP AT it_include ASSIGNING FIELD-SYMBOL(<ls_src_line>)
         WHERE table_line IS NOT INITIAL
           AND table_line NS gc_comment_pattern.

      IF to_upper( <ls_src_line> ) CP |*{ gc_kw_public_section }*| AND is_public_section = abap_false.
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

    DATA(lv_search_pattern) = |{ gc_kw_class }\\s+{ iv_class_name }\\s+{ gc_kw_definition }[\\s\\S]*?{ gc_kw_endclass }|.
    FIND FIRST OCCURRENCE OF PCRE lv_search_pattern
    IN iv_source
    IGNORING CASE
    RESULTS DATA(lv_match).

    rv_class_source = |{ iv_source+lv_match-offset(lv_match-length) }|.

    lv_search_pattern = |{ gc_kw_class }\\s+{ iv_class_name }\\s+{ gc_kw_implementation }[\\s\\S]*?{ gc_kw_endclass }|.
    FIND FIRST OCCURRENCE OF PCRE lv_search_pattern
    IN iv_source
    IGNORING CASE
    RESULTS lv_match.

    rv_class_source = |{ rv_class_source }{ text_separator }{ iv_source+lv_match-offset(lv_match-length) }|.
  ENDMETHOD.


  METHOD get_global_cl_methods_src_code.

    DATA: lt_source          TYPE seop_source_string,
          lv_method_src_code TYPE string.

    IF it_include IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_include ASSIGNING FIELD-SYMBOL(<ls_include>).
      READ REPORT <ls_include>-incname INTO lt_source.

      LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<ls_src_line>).
        lv_method_src_code = |{ lv_method_src_code }{ <ls_src_line> }{ text_separator }|.
      ENDLOOP.

      APPEND lv_method_src_code TO rt_methods_source.
      CLEAR lv_method_src_code.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_local_classes_src_code.

    DATA: lt_local_classes_names TYPE string_table,
          lo_class_naming        TYPE REF TO if_oo_class_incl_naming,
          lt_source              TYPE seop_source_string.

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
      RETURN.
    ENDIF.

    IF lo_include_naming IS BOUND.
      lo_class_naming ?= lo_include_naming.
    ELSE.
      RETURN.
    ENDIF.

    READ REPORT lo_class_naming->locals_def INTO lt_source.
    DATA(lv_locals_def_src) = convert_seop_source_to_string( it_source = lt_source ).

    READ REPORT lo_class_naming->locals_imp INTO lt_source.
    DATA(lv_locals_imp_src) = convert_seop_source_to_string( it_source = lt_source ).

    DATA(lv_local_src) = |{ lv_locals_def_src }{ text_separator }{ lv_locals_imp_src }|.

    FIND ALL OCCURRENCES OF PCRE |{ gc_kw_class }\\s+(\\w\{1,30\})\\s+{ gc_kw_definition }|
    IN lv_local_src
    IGNORING CASE
    RESULTS DATA(lt_matches).

    LOOP AT lt_matches ASSIGNING FIELD-SYMBOL(<ls_match>).
      APPEND substring( val = lv_local_src
                        off = VALUE #( <ls_match>-submatches[ 1 ]-offset OPTIONAL )
                        len = VALUE #( <ls_match>-submatches[ 1 ]-length OPTIONAL ) ) TO lt_local_classes_names.
    ENDLOOP.

    LOOP AT lt_local_classes_names ASSIGNING FIELD-SYMBOL(<ls_cls_name>).
      APPEND VALUE #( class_name       = iv_class_name
                      local_class_name = <ls_cls_name>
                      source_code      = extract_local_cls_by_name( iv_class_name = <ls_cls_name>
                                                                    iv_source     = lv_local_src ) ) TO rt_class_definition.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_local_cls_methods_src_code.

    IF io_class_naming IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA lt_source TYPE seop_source_string.

    READ REPORT io_class_naming->locals_imp INTO lt_source.
    DATA(lv_local_imp_src_code) = convert_seop_source_to_string( it_source = lt_source ).

    FIND ALL OCCURRENCES OF PCRE |{ gc_kw_method }\\s+\\w\{1,30\}[\\s\\S]*?{ gc_kw_endmethod }|
    IN lv_local_imp_src_code
    IGNORING CASE
    RESULTS DATA(lt_matches).

    LOOP AT lt_matches ASSIGNING FIELD-SYMBOL(<ls_match>).
      APPEND lv_local_imp_src_code+<ls_match>-offset(<ls_match>-length) TO rt_methods_source.
    ENDLOOP.
  ENDMETHOD.


  METHOD convert_seop_source_to_string.

    IF it_source IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<ls_src_line>)
         WHERE table_line IS NOT INITIAL
           AND table_line NS gc_comment_pattern.

      rv_source_string = |{ rv_source_string }{ <ls_src_line> }{ text_separator }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_class_method_contacts.

    IF it_class IS INITIAL.
      RETURN.
    ENDIF.

    " Get classes details
    SELECT clsname,
           author,
           changedby
      FROM seoclassdf
      FOR ALL ENTRIES IN @it_class
      WHERE clsname = @it_class-table_line
        AND version = @gc_active_objects
      INTO TABLE @DATA(lt_class_details).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Get classes methods details
    SELECT clsname,
           cmpname,
           author,
           changedby
      FROM seocompodf
      FOR ALL ENTRIES IN @it_class
          WHERE clsname = @it_class-table_line
      INTO TABLE @DATA(lt_class_methods_details).

    lt_class_methods_details = CORRESPONDING #( BASE ( lt_class_methods_details ) lt_class_details ).

    rt_class_method_contact = VALUE #( FOR <ls_detail> IN lt_class_methods_details
                                       ( class = <ls_detail>-clsname
                                       component = <ls_detail>-cmpname
                                       contact = COND #( WHEN <ls_detail>-changedby IS NOT INITIAL
                                                         THEN <ls_detail>-changedby
                                                         ELSE <ls_detail>-author ) ) ).
  ENDMETHOD.

ENDCLASS.

**********************************************************************
*** Selection Screen
**********************************************************************

TABLES sscrfields.

TYPES:
  BEGIN OF ts_selection_option,
    transport_request TYPE tr_trkorr,
    user              TYPE sy-uname,
    class_name        TYPE seoclsname,
  END OF ts_selection_option.

DATA:
  so_selection_options TYPE ts_selection_option.

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
  SELECT-OPTIONS so_cls FOR so_selection_options-class_name NO INTERVALS MATCHCODE OBJECT seo_classes_interfaces.
SELECTION-SCREEN END OF SCREEN 300.

PARAMETERS: p_acttab TYPE sy-ucomm NO-DISPLAY.

SELECTION-SCREEN: BEGIN OF TABBED BLOCK tb_block FOR 7 LINES,
TAB (40) tr_tab USER-COMMAND push1,
TAB (40) cls_tab USER-COMMAND push2,
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

    CONSTANTS:
      gc_screen_number_main          TYPE syst_dynnr VALUE '1000',
      gc_tab_number_transport        TYPE syst_dynnr VALUE '0200',
      gc_tab_number_objects          TYPE syst_dynnr VALUE '0300',

      gc_txt_label_so_tr             TYPE string VALUE 'Request ID(s)',
      gc_txt_label_so_user           TYPE string VALUE 'User Name(s)',
      gc_txt_label_p_cobj            TYPE string VALUE 'Process my Objects',
      gc_txt_label_p_cuser           TYPE string VALUE 'Process my Transport Requests',
      gc_txt_label_so_cls            TYPE string VALUE 'Objects',
      gc_txt_label_p_quick           TYPE string VALUE 'Quick Review',
      gc_txt_label_p_detail          TYPE string VALUE 'Detailed Review',
      gc_txt_label_p_alv             TYPE string VALUE 'Display in ALV',
      gc_txt_label_p_text            TYPE string VALUE 'Display in Text',
      gc_txt_label_p_excel           TYPE string VALUE 'Excel export',
      gc_txt_label_p_xl_srv          TYPE string VALUE 'Excel export to server',
      gc_txt_label_p_path            TYPE string VALUE 'File Path',

      gc_programm_title              TYPE string VALUE 'Automatic AI Code Reviews',
      gc_tab_name_by_transports      TYPE string VALUE 'By Transports',
      gc_tab_name_by_objects         TYPE string VALUE 'By Objects',
      gc_export_block_title          TYPE string VALUE 'Output Options',
      gc_display_block_title         TYPE string VALUE 'AI processing method',
      gc_prompt_editor_title         TYPE string VALUE 'Prompt editor',
      gc_info_button_text            TYPE string VALUE 'User Manual',
      gc_prompt_editor_button_text   TYPE string VALUE 'Prompt Editor',
      gc_trasport_tab_title          TYPE string VALUE 'Get Transports by:',

      gc_uc_tranports_tab            TYPE syucomm VALUE 'PUSH1',
      gc_uc_objects_tab              TYPE syucomm VALUE 'PUSH2',
      gc_uc_programm_description     TYPE syucomm VALUE 'FC01',
      gc_uc_execute                  TYPE syucomm VALUE 'ONLI',
      gc_uc_prompt_edit              TYPE syucomm VALUE 'TXT',

      gc_p_name_objects              TYPE c LENGTH 8 VALUE 'P_COBJ',
      gc_p_name_user                 TYPE c LENGTH 8 VALUE 'P_CUSER',
      gc_p_name_path                 TYPE c LENGTH 8 VALUE 'P_PATH',
      gc_p_path_modif_id             TYPE c LENGTH 8 VALUE 'PID',
      gc_so_name_classes             TYPE c LENGTH 8 VALUE 'SO_CLS',
      gc_so_tr_low                   TYPE screen-name VALUE 'SO_TR-LOW',
      gc_so_tr_high                  TYPE screen-name VALUE 'SO_TR-HIGH',
      gc_so_user_low                 TYPE screen-name VALUE 'SO_USER-LOW',
      gc_so_user_high                TYPE screen-name VALUE 'SO_USER-HIGH',

      gc_msg_transport_not_specified TYPE string VALUE 'Transports or users must be specified',
      gc_msg_user_and_tr_selected    TYPE string VALUE 'You cannot specify Requests by Users and Transports Requests together',
      gc_msg_t_request_not_specified TYPE string VALUE 'Transport Requests must be specified',
      gc_msg_cl_name_not_specified   TYPE string VALUE 'Class name must be specified',
      gc_msg_no_source_code          TYPE string VALUE 'No source code to review',
      gc_msg_so_only_eq_allowed      TYPE string VALUE 'Only EQ (equals) is allowed',

      gc_screen_true                 TYPE c VALUE '1',
      gc_screen_false                TYPE c VALUE '0'.

    CLASS-METHODS: initialize,

      process_at_selection_screen,

      process_at_sel_screen_output,

      process_start_of_selection,

      setup_text_lables.

  PRIVATE SECTION.

    CLASS-METHODS:
      get_programm_description RETURNING VALUE(rv_description) TYPE string.

ENDCLASS.

CLASS lcl_report_helper IMPLEMENTATION.

  METHOD initialize.

    hdr_txt = gc_programm_title.
    tr_tab  = gc_tab_name_by_transports.
    cls_tab = gc_tab_name_by_objects.
    exp     = gc_export_block_title.
    disp    = gc_display_block_title.
    trtbtxt = gc_trasport_tab_title.
    pe_btn_t = gc_prompt_editor_button_text.

    tb_block-prog  = sy-repid.

    tb_block-dynnr = gc_tab_number_transport.

    IF p_prompt IS INITIAL.
      p_prompt = lcl_ai_helper=>get_default_prompt( ).
    ENDIF.

  ENDMETHOD.

  METHOD process_at_selection_screen.

    CASE sscrfields-ucomm.

      WHEN gc_uc_programm_description.

        IF sy-dynnr = gc_screen_number_main.
          cl_demo_output=>display_html( html = get_programm_description( ) ).
        ENDIF.

      WHEN gc_uc_tranports_tab.

        p_acttab = tb_block-activetab.
        tb_block-activetab = gc_uc_tranports_tab.
        tb_block-dynnr = gc_tab_number_transport.

      WHEN gc_uc_objects_tab.

        p_acttab = tb_block-activetab.
        tb_block-activetab = gc_uc_objects_tab.
        tb_block-dynnr = gc_tab_number_objects.

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
          IF so_cls IS INITIAL.
            MESSAGE gc_msg_cl_name_not_specified TYPE 'E'.
            SET CURSOR FIELD gc_so_name_classes.
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

    LOOP AT so_tr ASSIGNING FIELD-SYMBOL(<tr>).
      IF <tr>-option <> 'EQ'.
        MESSAGE gc_msg_so_only_eq_allowed TYPE 'E'.
      ENDIF.
    ENDLOOP.

    LOOP AT so_user ASSIGNING FIELD-SYMBOL(<usr>).
      IF <usr>-option <> 'EQ'.
        MESSAGE gc_msg_so_only_eq_allowed TYPE 'E'.
      ENDIF.
    ENDLOOP.

    LOOP AT so_cls ASSIGNING FIELD-SYMBOL(<cls>).
      IF <cls>-option <> 'EQ'.
        MESSAGE gc_msg_so_only_eq_allowed TYPE 'E'.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD process_at_sel_screen_output.

    IF p_acttab IS NOT INITIAL.
      tb_block-activetab = p_acttab.

      CASE p_acttab.
        WHEN gc_uc_tranports_tab.
          tb_block-dynnr = gc_tab_number_transport.
        WHEN gc_uc_objects_tab.
          tb_block-dynnr = gc_tab_number_objects.
      ENDCASE.
    ELSE.
      tb_block-activetab = gc_uc_tranports_tab.
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
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD process_start_of_selection.

    DATA:
      lt_class      TYPE tt_class_name,
      lv_name       TYPE string,
      lv_prompt     TYPE stringval,
      lt_suggestion TYPE tt_suggestion.

* Get objects from data sources

    DATA(lo_tr_extractor) = NEW lcl_transport_extractor( ).

    CASE tb_block-dynnr.

      WHEN gc_tab_number_transport.
        lt_class = lo_tr_extractor->get_class_from_tr_request( iv_fl_current_objects_only = p_cobj
                                                               iv_fl_current_user_only = p_cuser
                                                               it_tr_requests_headers = VALUE #( FOR <ls_req> IN so_tr[]   ( trkorr = <ls_req>-low ) )
                                                               it_user = VALUE #(                FOR <ls_usr> IN so_user[] ( CONV #( <ls_usr>-low ) ) ) ).
      WHEN gc_tab_number_objects.
        lt_class = VALUE #( FOR <class> IN so_cls[] ( <class>-low ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.

* Core logic

    DATA(lo_class_src_code_getter) = NEW lcl_abap_source_code_getter( ).

    DATA(lt_classes_src_code) = lo_class_src_code_getter->get_classes_source_code(
                                  VALUE #( FOR <ls_class> IN lt_class ( CONV #( <ls_class> ) ) ) ).
    IF lt_classes_src_code IS INITIAL.
      MESSAGE gc_msg_no_source_code TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Detailed mode includes quick + method-by-method review
    IF p_detail = abap_true.
      DATA(lt_classes_methods_src_code) = lo_class_src_code_getter->get_classes_methods_src_code(
                                            VALUE #( FOR <ls_class> IN lt_class ( CONV #( <ls_class> ) ) ) ).
    ENDIF.

    DATA(lo_suggestion_helper)    = NEW lcl_suggestions_exporter( ).
    DATA(lt_class_method_contact) = lcl_abap_source_code_getter=>get_class_method_contacts( lt_class ).
    DATA(lv_target_prompt)        = lcl_ai_helper=>get_final_prompt( p_prompt ).

    " Review entire class
    LOOP AT lt_classes_src_code ASSIGNING FIELD-SYMBOL(<ls_src_code>).

      lv_prompt = |{ lv_target_prompt }{ <ls_src_code>-source_code }|.

      APPEND LINES OF lcl_ai_helper=>deserialize_suggestions(
                        iv_class_name = |{ <ls_src_code>-class_name } { <ls_src_code>-local_class_name }|
                        iv_user       = VALUE #( lt_class_method_contact[ class = CONV #( <ls_src_code>-class_name ) ]-contact OPTIONAL )
                        iv_json       = lcl_ai_helper=>execute_prompt( lv_prompt ) ) TO lt_suggestion.
    ENDLOOP.

    " Method by method review
    LOOP AT lt_classes_methods_src_code ASSIGNING FIELD-SYMBOL(<ls_class_method_src_code>).
      LOOP AT <ls_class_method_src_code>-methods ASSIGNING FIELD-SYMBOL(<ls_method>).

        lv_prompt = |{ lv_target_prompt }{ <ls_method> }|.

        lv_name = VALUE #( lt_class_method_contact[
                           class = CONV #( <ls_src_code>-class_name )
                           component = CONV #( <ls_method> ) ]-contact OPTIONAL ).
        IF lv_name IS INITIAL.
          lv_name = VALUE #( lt_class_method_contact[
                             class = CONV #( <ls_src_code>-class_name ) ]-contact OPTIONAL ).
        ENDIF.

        APPEND LINES OF lcl_ai_helper=>deserialize_suggestions(
                          iv_class_name = <ls_class_method_src_code>-class_name
                          iv_user       = lv_name
                          iv_json       = lcl_ai_helper=>execute_prompt( lv_prompt ) ) TO lt_suggestion.
      ENDLOOP.
    ENDLOOP.

* Export options

    IF p_excel = abap_true.
      lo_suggestion_helper->export_in_excel( lt_suggestion ).
      RETURN.
    ENDIF.

    IF p_alv = abap_true.
      lo_suggestion_helper->display_in_alv( lt_suggestion ).
      RETURN.
    ENDIF.

    IF p_text = abap_true.
      lo_suggestion_helper->display_in_demo_output( lt_suggestion ).
      RETURN.
    ENDIF.

    IF p_xl_srv = abap_true.
      lo_suggestion_helper->export_to_server( iv_file_path  = p_path
                                              it_suggestion = lt_suggestion ).
    ENDIF.

  ENDMETHOD.

  METHOD get_programm_description.
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
        |<p>At the moment the program supports only ABAP classes. | &&
        |Support for function modules and reports may be added in the future.</p>| &&
        || &&
        |<h2>Selecting Objects for Review</h2>| &&
        || &&
        |<p>You can select objects for review either by transport IDs or by object names.</p>| &&
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
        |Before running the report, one method must be implemented in the| &&
        |code (the location is marked). | &&
        |Your implementation should call any reasoning LLM with a single string as input and return a single string as output.</p>| &&
        || &&
        |<p>The program was designed to work without ABAP Git, so| &&
        |installation is straightforward. | &&
        |You can copy and paste the program code into local objects in| &&
        |your system and start using it.</p>|.
  ENDMETHOD.

  METHOD setup_text_lables.
    %_so_tr_%_app_%-text    = gc_txt_label_so_tr.
    %_so_user_%_app_%-text  = gc_txt_label_so_user.
    %_p_cobj_%_app_%-text   = gc_txt_label_p_cuser.
    %_p_cuser_%_app_%-text  = gc_txt_label_p_cobj.
    %_so_cls_%_app_%-text   = gc_txt_label_so_cls.
    %_p_quick_%_app_%-text  = gc_txt_label_p_quick.
    %_p_detail_%_app_%-text = gc_txt_label_p_detail.
    %_p_alv_%_app_%-text    = gc_txt_label_p_alv.
    %_p_text_%_app_%-text   = gc_txt_label_p_text.
    %_p_excel_%_app_%-text  = gc_txt_label_p_excel.
    %_p_xl_srv_%_app_%-text = gc_txt_label_p_xl_srv.
    %_p_path_%_app_%-text   = gc_txt_label_p_path.
  ENDMETHOD.
ENDCLASS.

INITIALIZATION.

  CONCATENATE icon_information lcl_report_helper=>gc_info_button_text INTO sscrfields-functxt_01 SEPARATED BY space.
  SELECTION-SCREEN FUNCTION KEY 1.

  lcl_report_helper=>initialize( ).

AT SELECTION-SCREEN.

  lcl_report_helper=>process_at_selection_screen( ).

AT SELECTION-SCREEN OUTPUT.

  lcl_report_helper=>setup_text_lables( ).

  lcl_report_helper=>process_at_sel_screen_output( ).

START-OF-SELECTION.

  lcl_report_helper=>process_start_of_selection( ).
