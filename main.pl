:- module(main, [
    solve/1,
    solve/2
]).

:- use_module(facts).
:- use_module(constraints).
:- use_module(optimization).

% Final orchestration point for the optimized scheduling system.
solve(BestSchedule, Score) :-
    best_schedule_with_score(BestSchedule, Score).

solve(BestSchedule) :-
    best_schedule(BestSchedule).
