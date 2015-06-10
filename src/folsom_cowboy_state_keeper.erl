%%%
%%% Copyright 2015, Heroku
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%


%%%-------------------------------------------------------------------
%%% File:      folsom_cowboy_state_keeper.erl
%%% @author    Evan Vigil-McClanahan <evan@heroku.com>
%%% @doc       Simple state keeper for stateful metrics.
%%% @end
%%%------------------------------------------------------------------

-module(folsom_cowboy_state_keeper).

-behaviour(gen_server).

%% API
-export([start_link/0, put/2, get/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {d = dict:new()}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

put(Key, Value) ->
    gen_server:call(?SERVER, {put, Key, Value}).

get(Key) ->
    gen_server:call(?SERVER, {get, Key}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({put, Key, Value}, _From, #state{d = D} = State) ->
    D1 = dict:store(Key, Value, D),
    {reply, ok, State#state{d=D1}};
handle_call({get, Key}, _From, #state{d = D} = State) ->
    Rep =
        case dict:find(Key, D) of
            {ok, Val} ->
                Val;
            error ->
                not_found
        end,
    {reply, Rep, State};
handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
