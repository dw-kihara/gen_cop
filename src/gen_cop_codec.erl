%% @copyright 2014, Takeru Ohta <phjgt308@gmail.com>
%%
%% @doc Encoder/Decoder Interface
%%
%% TODO: doc
-module(gen_cop_codec).

%%----------------------------------------------------------------------------------------------------------------------
%% Exported API
%%----------------------------------------------------------------------------------------------------------------------
-export([make/2, make/3]).
-export([get_state/1, set_state/2]).
-export([encode/3, decode/3]).

-export_type([codec/0]).
-export_type([codec_module/0, codec_state/0]).
-export_type([encode_fun/0, decode_fun/0]).
-export_type([encode_result/0, encode_result/1]).
-export_type([decode_result/0, decode_result/2]).

%%----------------------------------------------------------------------------------------------------------------------
%% Macros & Records & Types
%%----------------------------------------------------------------------------------------------------------------------
-define(CODEC, ?MODULE).

-record(?CODEC,
        {
          state  :: codec_state(),
          encode :: encode_fun(),
          decode :: decode_fun()
        }).

%% -opaque codec() :: #?CODEC{}.
-type codec() :: #?CODEC{}.

%% FIXME:
%% 本当は以下のように定義したいが、これだとdialyzerと相性が悪く、
%% メモリを食い潰す and 解析が終わらない、のでその問題が解決するまで`term()`に置き換えておく.
%%
%% -type context() :: gen_cop_context:context().
-type context() :: term().

-type codec_module() :: module().
-type codec_state() :: term().

-type encode_fun() :: fun (([gen_cop:message()], codec_state(), context()) -> encode_result()).
-type decode_fun() :: fun ((binary(), codec_state(), context()) -> decode_result()).

-type encode_result() :: encode_result(codec_state()).
-type encode_result(State) :: {ok, iodata(), State, context()} | {error, Reason::term(), State, context()}.

-type decode_result() :: decode_result(gen_cop:message(), codec_state()).
-type decode_result(Message, State) :: {ok, [Message], State, context()} | {error, Reason::term(), State, context()}.

%%----------------------------------------------------------------------------------------------------------------------
%% Callback API
%%----------------------------------------------------------------------------------------------------------------------
-callback encode([gen_cop:message()], codec_state(), context()) -> encode_result().
-callback decode(binary(), codec_state(), context()) -> decode_result().

%%----------------------------------------------------------------------------------------------------------------------
%% Exported Functions
%%----------------------------------------------------------------------------------------------------------------------
-spec make(codec_module(), codec_state()) -> codec().
make(Module, State) ->
    make(State, fun Module:encode/3, fun Module:decode/3).

-spec get_state(codec()) -> codec_state().
get_state(#?CODEC{state = State}) ->
    State.

-spec set_state(codec_state(), codec()) -> codec().
set_state(State, Codec) ->
    Codec#?CODEC{state = State}.

-spec make(codec_state(), encode_fun(), decode_fun()) -> codec().
make(State, EncodeFun, DecodeFun) ->
    #?CODEC{state = State, encode = EncodeFun, decode = DecodeFun}.

-spec encode([gen_cop:message()], codec(), context()) -> encode_result().
encode(Messages, Codec, Context0) ->
    case (Codec#?CODEC.encode)(Messages, Codec#?CODEC.state, Context0) of
        {ok, Encoded, State, Context1}   -> {ok, Encoded, Codec#?CODEC{state = State}, Context1};
        {error, Reason, State, Context1} -> {error, Reason, Codec#?CODEC{state = State}, Context1}
    end.

-spec decode(binary(), codec(), context()) -> decode_result().
decode(Bin, Codec, Context0) ->
    case (Codec#?CODEC.decode)(Bin, Codec#?CODEC.state, Context0) of
        {ok, Messages, State, Context1}  -> {ok, Messages, Codec#?CODEC{state = State}, Context1};
        {error, Reason, State, Context1} -> {error, Reason, Codec#?CODEC{state = State}, Context1}
    end.
