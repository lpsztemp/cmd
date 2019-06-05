@echo off

set DOT_ONLY=
set M4_ONLY=
set IMG_TYPE=
set SHOW_HELP=
set INPUT_FILE=
set OUTPUT_FILE=
set DOT_INPUT=%TMP%\dotscript.m4
set DOT_OUTPUT=%TMP%\dotscript.dot
set M4_OUTPUT=%TMP%\m4rules.m4
set M4DIFICATION_OUTPUT=%TMP%\m4dified.oo
set SHOW_DEBUG=
set VIEW_IMAGE=
set KEYWORD_TEXT_DECORATION=
set KEYWORD_TEXT_COLOR=

:parse_command
if "%~1"=="" goto check_params
if "%~1"=="-m4" set M4_ONLY=1 && shift && goto parse_command
if "%~1"=="-d" set DOT_ONLY=1 && shift && goto parse_command
if "%~1"=="-T" goto set_type
if "%~1"=="-h" set SHOW_HELP=1 && shift && goto parse_command
if "%~1"=="-x" set VIEW_IMAGE=1 && shift && goto parse_command
if "%~1"=="-dbg" set SHOW_DEBUG=1 && shift && goto parse_command
if "%~1"=="-kc" goto set_keyword_color
if "%~1"=="-kd" goto set_keyword_decoration
if not defined INPUT_FILE set "INPUT_FILE=%~1" && shift && goto parse_command
if not defined OUTPUT_FILE set "OUTPUT_FILE=%~1" && shift && goto parse_command
goto invalid_usage

:set_type
shift
if "%~1"=="" goto invalid_usage
set IMG_TYPE=%1
shift
goto parse_command

:set_keyword_color
shift
if "%~1"=="" goto invalid_usage
set KEYWORD_TEXT_COLOR=define^(HIGHLIGHT_TAG_COLOR, `^^^<FONT COLOR="%1"^^^>$1^^^</FONT^^^>'^)
shift
goto parse_command

:set_keyword_decoration
shift
if "%~1"=="" goto invalid_usage
if "%~1"=="normal" set KEYWORD_TEXT_DECORATION=define^(HIGHLIGHT_TAG_DECORATION, $1^) && shift && goto parse_command
if "%~1"=="italic" set KEYWORD_TEXT_DECORATION=define^(HIGHLIGHT_TAG_DECORATION, `^^^<I^^^>$1^^^</I^^^>'^) && shift && goto parse_command
if "%~1"=="bold" set KEYWORD_TEXT_DECORATION=define^(HIGHLIGHT_TAG_DECORATION, `^^^<B^^^>$1^^^</B^^^>'^) && shift && goto parse_command
goto invalid_usage

:check_params
if defined DOT_ONLY (
	if defined M4_ONLY goto invalid_usage
	if defined IMG_TYPE goto invalid_usage
	if defined SHOW_HELP goto invalid_usage
	if defined VIEW_IMAGE goto invalid_usage
	if not defined INPUT_FILE goto invalid_usage
	if not defined OUTPUT_FILE goto invalid_usage
	set DOT_OUTPUT=%OUTPUT_FILE%
) else if defined M4_ONLY (
	if defined IMG_TYPE goto invalid_usage
	if defined SHOW_HELP goto invalid_usage
	if defined VIEW_IMAGE goto invalid_usage
	if not defined INPUT_FILE goto invalid_usage
	if not defined OUTPUT_FILE goto invalid_usage
	set M4_OUTPUT=%OUTPUT_FILE%
) else if defined IMG_TYPE (
	if not defined INPUT_FILE goto invalid_usage
	if not defined OUTPUT_FILE goto invalid_usage
) else if defined SHOW_HELP (
	if defined IMG_TYPE goto invalid_usage
	if defined VIEW_IMAGE goto invalid_usage
	if defined INPUT_FILE goto invalid_usage
	if defined OUTPUT_FILE goto invalid_usage
	if defined KEYWORD_TEXT_COLOR goto invalid_usage
	if defined KEYWORD_TEXT_DECORATION goto invalid_usage
	goto show_usage
) else (
	if not defined INPUT_FILE goto invalid_usage
	if not defined OUTPUT_FILE goto invalid_usage
	set IMG_TYPE=jpg
)

if not defined KEYWORD_TEXT_COLOR set KEYWORD_TEXT_COLOR=define^(HIGHLIGHT_TAG_COLOR, `^^^<FONT COLOR="blue"^^^>$1^^^</FONT^^^>'^)
if not defined KEYWORD_TEXT_DECORATION set KEYWORD_TEXT_DECORATION=define^(HIGHLIGHT_TAG_DECORATION, `^^^<B^^^>$1^^^</B^^^>'^)

rem ==Those are checks of input for debugging==
if defined SHOW_DEBUG (
	echo DOT_ONLY="%DOT_ONLY%"
	echo M4_ONLY="%M4_ONLY%"
	echo IMG_TYPE="%IMG_TYPE%"
	echo SHOW_HELP="%SHOW_HELP%"
	echo INPUT_FILE="%INPUT_FILE%"
	echo OUTPUT_FILE="%OUTPUT_FILE%"
	echo DOT_INPUT="%DOT_INPUT%"
	echo DOT_OUTPUT="%DOT_OUTPUT%"
	echo M4_OUTPUT="%M4_OUTPUT%"
	echo SHOW_DEBUG="%SHOW_DEBUG%"
	echo VIEW_IMAGE="%VIEW_IMAGE%"
	echo INPUT_FILE="%INPUT_FILE%"
	echo OUTPUT_FILE="%OUTPUT_FILE%"
	echo KEYWORD_TEXT_COLOR="%KEYWORD_TEXT_COLOR%"
	echo KEYWORD_TEXT_DECORATION="%KEYWORD_TEXT_DECORATION%"
	echo.
)

if not exist "%INPUT_FILE%" (
	echo Error: input file "%INPUT_FILE%" does not exist.
	goto end
)

setlocal DisableDelayedExpansion
if defined SHOW_DEBUG echo Performing M4-dificaton of "%INPUT_FILE%".
(
	for /f "usebackqdelims=" %%a in ("%INPUT_FILE%") do (
		set "line=%%a"
		setlocal EnableDelayedExpansion
		set "line=!line:&=&amp;!"
		set "line=!line:#=&#35;!"
		set "line=!line:\[=&#91;!"
		set "line=!line:\]=&#93;!"
		echo !line!
		endlocal
	)
) > %M4DIFICATION_OUTPUT%

echo Done.

if defined SHOW_DEBUG echo Producing M4 output.
echo changecom(/*,*/)dnl > "%M4_OUTPUT%"
echo changequote dnl >> "%M4_OUTPUT%"
echo define(REPLACE_HTML, `patsubst(patsubst(patsubst(patsubst(patsubst(patsubst(```````$*''''''', `^<', `^&lt;'), `^>', `^&gt;'), ` +', `^&nbsp;'), `:', `^&#58;'), `,(\w)', `, \1'), `\\n', `^<BR/^>')')dnl >> "%M4_OUTPUT%"
echo define(GET_CLASS_NAME, `REPLACE_HTML($@)')dnl >> "%M4_OUTPUT%"
echo %KEYWORD_TEXT_COLOR%dnl >> "%M4_OUTPUT%"
echo %KEYWORD_TEXT_DECORATION%dnl >> "%M4_OUTPUT%"
echo define(HIGHLIGHT_TAG, `HIGHLIGHT_TAG_COLOR(HIGHLIGHT_TAG_DECORATION(`$1'))')dnl >> "%M4_OUTPUT%"
echo define(HIGHLIGHT_TAGS, `ifelse(`$#', `0', `none', `$#', 1, `$1', `$#', 2, `patsubst(`$1', `\b$2\b', HIGHLIGHT_TAG(`$2'))', `$0($0(``$1'', $2), shift(shift($@)))')')dnl >> "%M4_OUTPUT%"
echo define(HIGHLIGHT_KEYWORDS, `HIGHLIGHT_TAGS(``$*'', `class', `template', `const', `volatile', `struct', `int', `long', `short', `char', `double', `float', `bool', `true', `false', `auto', `typedef', `noexcept', `enum', `constexpr', `signed', `unsigned', `operator')')dnl >> "%M4_OUTPUT%"
echo define(NODE_NAME, `translit(`$1', `^<^>:, .*+-()^&#-;', `0123456789abcdefgh')')dnl >> "%M4_OUTPUT%"
echo define(CLASS_COMMENT_BOX, `NODE_NAME(`$1')`'_COMMENT_BOX')dnl >> "%M4_OUTPUT%"
echo define(PORT_NAME, `NODE_NAME(`$*')')dnl >> "%M4_OUTPUT%"
echo define(CLASS_MEMBER_COMMENT_BOX, `PORT_NAME(`$1', `$2')'``''_COMMENT_BOX)dnl >> "%M4_OUTPUT%"
echo define(IMPLEMENTATION, ``style=dashed,arrowhead=empty'')dnl >> "%M4_OUTPUT%"
echo define(INHERITANCE, ``style=solid,arrowhead=normal'')dnl >> "%M4_OUTPUT%"
echo define(AGGREGATION, ``style=solid,arrowhead=odiamond'')dnl >> "%M4_OUTPUT%"
echo define(COMPOSITION, ``style=solid,arrowhead=diamond'')dnl >> "%M4_OUTPUT%"
echo define(ASSOCIATION, ``style=solid,arrowhead=none,dir=none'')dnl >> "%M4_OUTPUT%"
echo define(CLASS_BEGIN,dnl >> "%M4_OUTPUT%"
echo 	`ifelse(`$#', `0',dnl >> "%M4_OUTPUT%"
echo 		`_unnamed_node[color=red, label=^< dnl >> "%M4_OUTPUT%"
echo 			^<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0"^> dnl >> "%M4_OUTPUT%"
echo 				^<TR^>^<TD align="left"^>HIGHLIGHT_KEYWORDS(`class') ^<B^>_UNNAMED^</B^>',  >> "%M4_OUTPUT%"
echo 		pushdef(`CURRENT_CLASS_NAME', NODE_NAME(`$1'))dnl >> "%M4_OUTPUT%"
echo 		`NODE_NAME(`$1')'`[label=^< dnl >> "%M4_OUTPUT%"
echo 			^<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0"^> dnl >> "%M4_OUTPUT%"
echo 				^<TR^>^<TD align="left"^>'HIGHLIGHT_KEYWORDS(ifelse(`$#', `1', `', `template^&lt;'`REPLACE_HTML(shift($@))'`^&gt;^</TD^>^</TR^>^<TR^>^<TD ALIGN="left"^>')`class ^<B^>'REPLACE_HTML(``$1'')^</B^>))'`^</TD^>^</TR^>')dnl  >> "%M4_OUTPUT%"
echo define(CLASS_MEMBER, `	^<TR^>^<TD align="left" PORT="'`PORT_NAME(CURRENT_CLASS_NAME(),`$*')'`"^>^&nbsp;^&nbsp;^&nbsp;'`HIGHLIGHT_KEYWORDS(REPLACE_HTML(`$*'))'`^</TD^>^</TR^>')dnl  >> "%M4_OUTPUT%"
echo define(STATIC_MEMBER, `	^<TR^>^<TD align="left" PORT="'`PORT_NAME(CURRENT_CLASS_NAME(),`$*')'`"^>^&nbsp;^&nbsp;^&nbsp;^<U^>'`HIGHLIGHT_KEYWORDS(REPLACE_HTML(`$*'))'`^</U^>^</TD^>^</TR^>')dnl  >> "%M4_OUTPUT%"
echo define(CLASS_END, popdef(`CURRENT_CLASS_NAME')`^</TABLE^>^>];')dnl  >> "%M4_OUTPUT%"
echo define(TYPEDEF, `NODE_NAME(`$1')'`[label=^<GET_CLASS_NAME(`$*')^>];')dnl  >> "%M4_OUTPUT%"
echo define(COMMENT, `ifelse(`$#', `2', CLASS_COMMENT_BOX(`$1') [shape=box`,' label=^"`$2'^"] >> "%M4_OUTPUT%"
echo { rank=same; CLASS_COMMENT_BOX(`$1'); `NODE_NAME(`$1')';} >> "%M4_OUTPUT%"
echo CLASS_COMMENT_BOX(`$1')-^>`NODE_NAME(`$1')' [constraint=false`,' arrowhead=none`,'dir=none], CLASS_MEMBER_COMMENT_BOX(`$1', `$2') [shape=box`,' label="`$3'"] >> "%M4_OUTPUT%"
REM echo { rank=same; CLASS_MEMBER_COMMENT_BOX(`$1', `$2'); `NODE_NAME(`$1')';} >> "%M4_OUTPUT%"
echo CLASS_MEMBER_COMMENT_BOX(`$1', `$2')-^>$1:``''PORT_NAME(`$1', `$2') [arrowhead=none`,'dir=none])')dnl >> "%M4_OUTPUT%"

if defined SHOW_DEBUG echo Done.
if defined M4_ONLY goto end_cleanup_files

if defined SHOW_DEBUG echo Producing DOT output.
echo strict digraph OptionalGraphName > "%DOT_INPUT%"
echo { >> "%DOT_INPUT%"
echo graph [dpi=300]; >> "%DOT_INPUT%"
echo node [shape=box]; >> "%DOT_INPUT%"
echo edge [labeldistance="1.5", labelfontsize="10", arrowhead="none"]; >> "%DOT_INPUT%"
echo rankdir=BT; >> "%DOT_INPUT%"
type %M4DIFICATION_OUTPUT% >> "%DOT_INPUT%"
echo. >> "%DOT_INPUT%"
echo } >> "%DOT_INPUT%"

if defined SHOW_DEBUG echo Done.

if defined SHOW_DEBUG echo Performing M4 substitution.
m4 "%M4_OUTPUT%" "%DOT_INPUT%" > "%DOT_OUTPUT%" || goto end_cleanup_files

if defined SHOW_DEBUG echo Done.
if defined DOT_ONLY goto end_cleanup_files

if defined SHOW_DEBUG echo Executing DOT interpreter.
dot -T%IMG_TYPE% -o"%OUTPUT_FILE%" "%DOT_OUTPUT%" || goto end_cleanup_files
if defined SHOW_DEBUG echo Done.

if defined VIEW_IMAGE "%OUTPUT_FILE%"

goto end_cleanup_files

:show_usage
echo Builds an Object Model Class Diagram by their dot and M4 definitions
echo Call syntax:
echo omcd.bat ^<[-d^|-m4^|-T diagram_type -x] [-kc ^<color^>] -kd [normal^|italic^|bold^] [-dbg] ^<input_script^> ^<output_script^>^> ^| -h
echo -d - Make necessary substitutes and produce dot-syntax graph definition only.
echo -m4 - Produce only a file with m4 rules. The input_script is ignored in this case.
echo -T diagram_type - Specifies an image type used to visialize the graph. It must be supported by graphviz. By default it is jpg.
echo -dbg - Shows intermediate information for debugging.
echo -x - Display the resulting image, after the processing has been complete.
echo -kc color - specifies a color of text used to highlight C++ keywords. The color is specified using the HTML syntax. By default, the value is blue.
echo -kd text_decoration - decorates text used for denoting keywords. The options are: normal, bold (default), or italic.
echo 
echo -h - Show this message.
echo.
echo 	The input file must be defined via a set of m4 macros as follows. Each macro invocation must occupy its own line.
echo.
echo 	Definitions of classes are specified using four macros: TYPEDEF, CLASS_BEGIN, CLASS_MEMBER, and CLASS_END. The TYPEDEF designated a simple type without extra definitions of methods, template parameters, etc. The CLASS_BEGIN macro specifies a beginning of a full class definition. A zero or more invocations of the CLASS_MEMBER and STATIC_MEMBER macros define a set of members within the class. The CLASS_END macro defines an end to the class definition.
echo 	All invocations of the CLASS_MEMBER and STATIC_MEMBER macros must be encompassed by only one CLASS_BEGIN-CLASS_END pair.
echo 	The relations between different classes are specified as for a dot compiler, i.e. with arrows ("-^>") with the difference that all node names must be produced via the NODE_NAME macro invoked with an actual name of the class. Also, the type of the relation is defined by the macros ASSOCIATION, IMPLEMENTATION, INHERITANCE, AGGREGATION or COMPOSITION. This type, which may optionally be accompanied by headlabel="text", taillabel="text", and label="text" specifications, must be enclosed by square brackets ("[" and "]") and placed to the right of the relation specification. A headlabel mark specifies a text associated with an object of the relation, i.e. a class receiving the relation. A taillabel mark specifies a subject of the relation, i.e. a class initiating the relation. Also, a label mark can associate some text with the relation itself. All of the marks are optional. For instance, if a class A aggregates a class B, then their relation is specified as:
echo	NODE_NAME(A)-^>NODE_NAME(B) [AGGREGATION, headlabel="A label near the class A", taillabel = "A label near the class B", label = "A description of the relation"].
echo	If a class, e.g. a class template, specification requires square brackets, i.e. "[" and\or "]", they must be escaped in the source specification with a backslash character, i.e. "\[" and "\]" respectively.
echo 	There are three kinds of comments supported by this processor.
echo 	The first one is a source comment that should not be displayed in any of output files, should it be the M4 script, the dot script or the final image. Those comments are specified with M4 dnl builtin macro which causes the interpreter to ignore the rest of the line and omit it when producing output. Those comments can contain non-ASCII characters.
echo 	The second type is for graphviz comments. Those are specified in C-like manner, i.e. either as "//" (single-line comments) or as "/*" and "*/" pairs for multiline purposes. These comments will be passed by the M4 on its output as-is. Note the limitations of these comments. First, the characters of the comment marks, if they are inside a node name M4 definition, are replaced by special characters to avoid conflicts with the dot syntax. Therefore, the comment will not be there anymore when the node is passed from M4 to graphviz. This means that the only place to safely specify C-like comments is outside of a node definition. But the graphviz implementation of dot does not support non-ASCII characters outside of labels or any text in a sence of the dot syntax. Both of these flaws mean that C-like comments cannot be specified with non-ASCII symbols.
echo 	The second type of comments is for comments that should be displayed on the final image. These comments are specified with the COMMENT macro - with two or three parameters which specify a class, to which the comment is given, an optional member of the class, to which the comment relates, and the text of the comment itself. Such comments are defined as separate dot nodes attached to the specified class node (parameter $1) - for two-parameters version of the member, or to the specified members of the class, as specified by the three-parameter call (parameter $2).
echo.
echo 	CLASS_BEGIN(element_name, template_parameter_1, ..., template_parameter_n) - defines a beginning of a class definition. The parameter is a one-line string, possibly with C-like escape symbols (e.g. \n for a new line) and angle brackets (for C++ template instances), specifying a class name. If the name contains commas ("," symbol), like when specifying template specializations, then the name must be given in quotation marks - "`" is used as an opening quotation, and "'" is used as a closing quotation. Otherwise, the use of quotation marks is optional. 
echo 	Also, the definition may optionally include C++-like template parameters along with a type of the template parameters. These parameters cause the interpreter to produce a definition of a template with these parameters. Note, that specialization parameters are specified as a part of element_name, not as additional template_parameter_* values.
echo 	When the class is referenced, one should use NODE_NAME(element_name, template_parameter_1, ..., template_parameter_n) with the same parameters to refer to the node. For instance, this is required to specify class relations.
echo 	CLASS_MEMBER(member_name) - adds a member of a class within a definition of the class delimited by the CLASS_BEGIN and CLASS_END macros. The member_name parameter, always specified WITHOUT quotation marks, can specify template parameters of the member, ordinary parameters, a return type, and a UML accessor ("-" - for private members, "#" - for protected members, "+" - for public members. All these elements, except for a name of the element itself, are optional.
echo 	STATIC_MEMBER(member_name) - adds a static member of a class within a definition of the class. Its requirements and behaviour is the same as for the CLASS_MEMBER macro except that the output for static members is underlined.
echo 	CLASS_END - defines an end of a class definition begun by the corresponding CLASS_BEGIN macro.
echo 	TYPEDEF - defines a simple type name with no members or special decorations of text performed by the CLASS_* macros. The TYPEDEF types can participate in relation definitions and refered to with the NODE_NAME macro.
echo 	NODE_NAME(element_name, template_parameter_1, ..., template_parameter_n) - is used to produce a DOT-compatible node name for a given name of an element. The macro is used to refer to names given with escape symbols or special symbols (like asterisks, angle brackets, etc.). To match a name specified by the TYPEDEF or CLASS_BEGIN macros, the parameter of NODE_NAME must be the same. Moreover, it is advised to supply a class definition for every node, even if the class has no members, especially if the class declaration is complex (e.g. it is a template or template specialization).
echo 	ASSOCIATION - is specified as a parameter of a relation between classes to specify the association relation.
echo 	IMPLEMENTATION - is specified as a parameter of a relation between classes to specify that a subject of the relation implements an object of the relation.
echo 	INHERITANCE - is specified as a parameter of a relation between classes to specify inheritance of a subject of the relation from an object of the relation.
echo 	AGGREGATION - is specified as a parameter of a relation between classes to specify that a subject of the relation aggregates an object of the relation.
echo 	COMPOSITION - is specified as a parameter of a relation between classes to specify that a subject of the relation is a composition of an object of the relation.
echo 	headlabel="text" - is an optional parameter of a relation between classes to specify a text mark near an object of the relation.
echo 	taillabel="text" - is an optional parameter of a relation between classes to specify a text mark near a subject of the relation.
echo 	label="text" - is an optional parameter of a relation between classes to specify a text associated with the relation itself.
echo 	COMMENT(class_name, comment_text) associates a visual comment with the specified class. The visual layout of the comment is box with the comment_text. The box is associated with the class. Classes with complex names, like templates and template specializations, should be processed with the NODE_NAME macro beforehand. E.g. COMMENT(NODE_NAME(`A^<T*, int^>', class T), `Comment text').
echo 	COMMENT(class_name, member_name, comment_text) - [NOT RECOMMENDED] a for of a commment visually associated with a specific member of the specified class. The line connecting the command box with the member will be attached in the vicinity of the member in the resulting graph. The class_name must be processed via the NODE_NAME macro prior to the call. The member name must be specified exactly how it was specified during its class definition. I.e. member_name should receive the value of member_name, specified with the quotation marks ("`" and "'") of the corresponding CLASS_MEMBER or STATIC_MEMBER invocation. The use of the definition is not recomended due to the bug in graphviz which does not match ports of nodes with the 'rank=same' subgraph property and the constraint=false edge property. Use class comments instead.
echo.
echo ==Example of possible input==
echo CLASS_BEGIN(ClassTemplate, class template_type_param, std::size_t non_type_param, template ^<class...^> class...template_template_param)
echo CLASS_MEMBER(-private_function(x:int, k:double):void)
echo CLASS_MEMBER(#protected_function(const char* pString, std::size_t cchString):template_type_param^<template_template_param^<non_type_param^>...^>)
echo CLASS_MEMBER(+public_function(const std::string^& str))
echo CLASS_END
echo.
echo CLASS_BEGIN(`ClassTemplate^<template_type_param*, 123, int, void*^>', class template_type_param)
echo CLASS_MEMBER(-private_function(x:int, k:double))
echo CLASS_MEMBER(#protected_function(const char* pString, std::size_t cchString))
echo CLASS_MEMBER(+public_function(const std::string^& str))
echo STATIC_MEMBER(+public_static_member:const int)
echo CLASS_END
echo.
echo CLASS_BEGIN(`ClassTemplate2', class T)
echo CLASS_MEMBER(-private_function(x:int, k:double))
echo CLASS_MEMBER(#protected_function(const char* pString, std::size_t cchString))
echo CLASS_MEMBER(+public_function(const std::string^& str))
echo STATIC_MEMBER(+public_static_member:const int)
echo CLASS_END
echo.
echo CLASS_BEGIN(`ClassTemplate2^<T\[\]^>', class T)
echo CLASS_MEMBER(-private_function(x:int, k:double))
echo CLASS_MEMBER(#protected_function(const char* pString, std::size_t cchString))
echo CLASS_MEMBER(+public_function(const std::string^& str))
echo STATIC_MEMBER(+public_static_member:const int)
echo CLASS_END
echo.
echo NODE_NAME(`ClassTemplate2^<T\[\]^>')-^>NODE_NAME(`ClassTemplate2') [ASSOCIATION]
echo.
echo NODE_NAME(ImplementationClass)-^>NODE_NAME(Interface1) [IMPLEMENTATION]
echo NODE_NAME(ImplementationClass)-^>NODE_NAME(Interface2) [IMPLEMENTATION]
echo NODE_NAME(DerivedClass)-^>NODE_NAME(BaseClass) [INHERITANCE]
echo NODE_NAME(Aggregate)-^>NODE_NAME(Aggregatee) [AGGREGATION]
echo NODE_NAME(Composition)-^>NODE_NAME(Element, class T, T N) [COMPOSITION]
echo NODE_NAME(Association1)-^>NODE_NAME(Association2) [ASSOCIATION]
echo.
echo NODE_NAME(Association2)-^>NODE_NAME(Interface1)[IMPLEMENTATION]
echo NODE_NAME(Association1)-^>NODE_NAME(Interface1)[IMPLEMENTATION]
echo NODE_NAME(`Composition')-^>NODE_NAME(Element) [COMPOSITION, headlabel="*", taillabel="1"]
echo.
echo TYPEDEF(base_type)
echo NODE_NAME(DerivedClass)-^>NODE_NAME(base_type) [INHERITANCE]
echo.
echo.
echo define(MNN, `NODE_NAME($@)') dnl One has access to M4 commands...
echo define(Specialization, ``ClassTemplate^<template_type_param*, 123, int, void*^>', class template_type_param') /*...and as well as dot commands...*/
echo define(Generalization, `ClassTemplate, class template_type_param, template ^<class...^> class...template_template_param') //...like this
echo.
echo MNN(Specialization)-^> MNN(Generalization)[INHERITANCE, label="Some\ndescription"]
echo.
echo COMMENT(MNN(Specialization), `This is a class comment')
echo COMMENT(MNN(Specialization), `#protected_function(const char* pString, std::size_t cchString)', `This is a class\nmember comment')

goto end

:invalid_usage
echo Invalid usage
echo Call syntax:
echo omcd.bat ^<[-d^|-m4^|-T diagram_type -x] [-kc ^<color^>] -kd [normal^|italic^|bold^] ^<input_script^> ^<output_script^>^> ^| -h
echo Use -h parameter for help
goto end

:end_cleanup_files
if defined SHOW_DEBUG set DELETE_SWITCH=/S

if exist %M4DIFICATION_OUTPUT% del %M4DIFICATION_OUTPUT%
if exist "%DOT_INPUT%" del %DELETE_SWITCH% "%DOT_INPUT%"
if exist "%DOT_OUTPUT%" (
	if not defined DOT_ONLY del %DELETE_SWITCH% "%DOT_OUTPUT%"
)
if exist "%M4_OUTPUT%" (
	if not defined M4_ONLY del %DELETE_SWITCH% "%M4_OUTPUT%"
)

:end

set DOT_INPUT=
set DOT_OUTPUT=
set M4_OUTPUT=
set DOT_ONLY=
set M4_ONLY=
set IMG_TYPE=
set SHOW_HELP=
set INPUT_FILE=
set OUTPUT_FILE=
set SHOW_DEBUG=
set VIEW_IMAGE=
set KEYWORD_TEXT_DECORATION=
set KEYWORD_TEXT_COLOR=
set M4DIFICATION_OUTPUT=
