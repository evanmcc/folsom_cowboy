%%%
%%% Copyright 2011, Boundary
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
%%% File:      folsom_webmachine_system_handler.erl
%%% @author    joe williams <j@boundary.com>
%%% @doc
%%% http system end point
%%% @end
%%%------------------------------------------------------------------

-module(folsom_cowboy_system_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/3]).

-define(scheds, scheds).

init({_Any, http}, Req, []) ->
    %% enable scheduler wall time accounting
    %% is this safe to leave on all the time?
    erlang:system_flag(scheduler_wall_time, true),
    {ok, Req, undefined}.

handle(Req, State) ->
    NewScheds = lists:sort(erlang:statistics(scheduler_wall_time)),
    Scheds =
        case folsom_cowboy_state_keeper:get(?scheds) of
            not_found ->
                [];
            OldScheds ->
                [diff_scheds(OldScheds, NewScheds)]
        end,
    folsom_cowboy_state_keeper:put(?scheds, NewScheds),
    {ok, Req2} = cowboy_req:reply(200,
                                  [],
                                  mochijson2:encode(folsom_vm_metrics:get_system_info()
                                                    ++ Scheds),
                                  Req),
    {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
    ok.

%% do we care about the load on particular schedulers?
%% assuming no, so delivering the average across them
diff_scheds(Old, New) ->
    Diff = lists:map(fun({{I, A0, T0}, {I, A1, T1}}) ->
                             {I, (A1 - A0)/(T1 - T0)}
                     end,
                     lists:zip(Old,New)),
    Avg = lists:sum([V||{_,V} <- Diff])/length(Diff),
    {sched_util, trunc(Avg * 100)}.
