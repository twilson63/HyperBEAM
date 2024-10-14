-module(dev_scheduler).
-export([init/3, end_of_schedule/1, uses/0, checkpoint/1]).

-include("include/ao.hrl").

%%% A simple scheduler scheme for AO.

init(State, [{<<"Location">>, Location} | _], _) ->
    case State of
        #{schedule := []} ->
            {ok, update_schedule(State#{su_location => Location})};
        _ ->
            {ok, State}
    end;
init(State, _, _) ->
    {ok, State}.

end_of_schedule(State) -> {ok, update_schedule(State)}.

update_schedule(State = #{store := Store, process := Proc, schedule := []}) ->
    CurrentSlot = maps:get(slot, State, 0),
    ToSlot = maps:get(to, State),
    ?c({updating_schedule_current, CurrentSlot, to, ToSlot}),
    % TODO: Get from slot via checkpoint
    Assignments = ao_client:get_assignments(Proc#tx.id, CurrentSlot, ToSlot),
    ?c(got_assignments),
    ?c({assignments_recvd, length(Assignments)}),
    lists:foreach(
        fun(Assignment) ->
            ?c({writing_recvd_assignment, ar_util:encode(Assignment#tx.id)}),
            ao_cache:write(Store, Assignment)
        end,
        Assignments
    ),
    State#{schedule => Assignments}.

checkpoint(State) -> {ok, State}.

uses() -> all.
