:- module(optimization, [
    score/2,
    scored_schedule/2,
    best_schedule/1,
    best_schedule_with_score/2
]).

:- use_module(constraints).

% Score represents total energy consumption.
% Lower score = better schedule.
score(Schedule, Score) :-
    total_energy(Schedule, Score).

scored_schedule(Schedule, Score) :-
    generate_schedule(Schedule),
    score(Schedule, Score).

% setof collects all valid scored schedules and sorts them by Score.
best_schedule(BestSchedule) :-
    setof(Score-S,
          (generate_schedule(S), score(S, Score)),
          [_BestScore-BestSchedule | _]).

best_schedule_with_score(BestSchedule, BestScore) :-
    setof(Score-S,
          (generate_schedule(S), score(S, Score)),
          [BestScore-BestSchedule | _]).
