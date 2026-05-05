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

% Compute energy directly here to avoid an extra score/2 call.
scored_schedule(Schedule, Score) :-
    generate_schedule(Schedule),
    total_energy(Schedule, Score).

% setof collects all valid scored schedules and sorts them by Score.
% Lower energy appears first because setof sorts pairs automatically.
best_schedule(BestSchedule) :-
    setof(Score-S,
          (generate_schedule(S), total_energy(S, Score)),
          [_BestScore-BestSchedule | _]).

best_schedule_with_score(BestSchedule, BestScore) :-
    setof(Score-S,
          (generate_schedule(S), total_energy(S, Score)),
          [BestScore-BestSchedule | _]).
