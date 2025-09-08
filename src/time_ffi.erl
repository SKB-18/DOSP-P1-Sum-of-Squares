%% src/time_ffi.erl
%% Minimal wrapper around erlang:statistics/1 for CPU + REAL timing.

-module(time_ffi).
-export([reset/0, read/0, fdiv/2, to_float/1, schedulers/0, logical_processors/0]).

reset() ->
    erlang:statistics(runtime),
    erlang:statistics(wall_clock),
    ok.

read() ->
    {_, Cpu}  = erlang:statistics(runtime),
    {_, Real} = erlang:statistics(wall_clock),
    {Cpu, Real}.

to_float(I) when is_integer(I) -> erlang:float(I);
to_float(F) when is_float(F)   -> F.

fdiv(A, B) ->
    to_float(A) / to_float(B).

%% Extra metrics for context
schedulers() ->
    erlang:system_info(schedulers_online).

logical_processors() ->
    erlang:system_info(logical_processors_available).
