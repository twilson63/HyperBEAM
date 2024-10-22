-module(su_registry).
-export([start/0, find/1, find/2, get_wallet/0, get_processes/0]).

-include("include/ao.hrl").
-include_lib("eunit/include/eunit.hrl").

%%% A simple registry for local services in AO, using pg. Currently,
%%% only SU processes are supported.

start() ->
    pg:start(pg),
    ok.

get_wallet() ->
    % TODO: We might want to use a different wallet per SU later.
    ao:wallet().

find(ProcID) -> find(ProcID, false).
find(ProcID, GenIfNotHosted) ->
    case pg:get_local_members({su, ProcID}) of
        [] ->
            maybe_new_proc(ProcID, GenIfNotHosted);
        [Pid] ->
            case is_process_alive(Pid) of
                true -> Pid;
                false -> 
                    maybe_new_proc(ProcID, GenIfNotHosted)
            end
    end.

get_processes() ->
    [ ProcID || {su, ProcID} <- pg:which_groups() ].

maybe_new_proc(_ProcID, false) -> not_found;
maybe_new_proc(ProcID, _) -> 
    Pid = su_process:start(ProcID, get_wallet()),
    try
        pg:join({su, ProcID}, Pid),
        Pid
    catch
        error:badarg ->
            {error, registration_failed}
    end.

%%% Tests

setup() ->
    application:ensure_all_started(ao),
    start().

-define(TEST_PROC_ID1, <<0:256>>).
-define(TEST_PROC_ID2, <<1:256>>).

find_non_existent_process_test() ->
    setup(),
    ?assertEqual(not_found, su_registry:find(?TEST_PROC_ID1)).

create_and_find_process_test() ->
    setup(),
    Pid1 = su_registry:find(?TEST_PROC_ID1, true),
    ?assert(is_pid(Pid1)),
    ?assertEqual(Pid1, su_registry:find(?TEST_PROC_ID1)).

create_multiple_processes_test() ->
    setup(),
    Pid1 = su_registry:find(?TEST_PROC_ID1, true),
    Pid2 = su_registry:find(?TEST_PROC_ID2, true),
    ?assert(is_pid(Pid1)),
    ?assert(is_pid(Pid2)),
    ?assertNotEqual(Pid1, Pid2),
    ?assertEqual(Pid1, su_registry:find(?TEST_PROC_ID1)),
    ?assertEqual(Pid2, su_registry:find(?TEST_PROC_ID2)).

get_all_processes_test() ->
    setup(),
    su_registry:find(?TEST_PROC_ID1, true),
    su_registry:find(?TEST_PROC_ID2, true),
    Processes = su_registry:get_processes(),
    ?assertEqual(2, length(Processes)),
    ?assert(lists:member(?TEST_PROC_ID1, Processes)),
    ?assert(lists:member(?TEST_PROC_ID2, Processes)).
