-module(pulsedb_realtime_SUITE).
-compile(export_all).
-define(TICK_COUNT, 5).


all() ->
  [{group, subscribe}].


groups() ->
  [{subscribe, [parallel], [
    t1
  ]}].


init_per_suite(Config) ->
  application:start(pulsedb),
  Config.


end_per_suite(Config) ->
  application:stop(pulsedb),
  Config.

t1(_) ->
  N = ?TICK_COUNT,
  {UTC,_} = pulsedb:current_second(),
  spawn(fun () -> send_tick(N, {<<"input">>, UTC, 10, [{<<"name">>,<<"src1">>}]}) end),
  pulsedb_realtime:subscribe(<<"input">>),
  ok = collect_ticks(N,UTC,1200).
  
  
send_tick(0, _) -> ok;
send_tick(N, {Name, UTC, Value, Tags}=Pulse) ->
  pulsedb_memory:append(Pulse, seconds),
  Pulse1 = {Name, UTC+1, Value, Tags},
  timer:sleep(1000),
  send_tick(N-1, Pulse1).
  

collect_ticks(0,_,_) -> ok;
collect_ticks(N,UTC,Timeout) ->
  receive
    {UTC,_} -> collect_ticks(N-1,UTC+1,Timeout)
  after
    Timeout -> error(collect_timed_out)
  end.
