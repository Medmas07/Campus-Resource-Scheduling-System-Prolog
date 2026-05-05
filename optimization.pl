:- module(optimization, [
    score/2,
    scored_schedule/2,
    energy_per_day/3,
    load_imbalance/2,
    best_schedule/1,
    best_schedule_with_score/2
]).

:- use_module(constraints).
:- use_module(library(lists), [max_list/2, min_list/2]).

% Score = total energy + load balancing penalty.
% Lower score = better schedule.
% total_energy alone may be identical for many schedules, so imbalance is added.
score(Schedule, Score) :-
    total_energy(Schedule, Total),
    load_imbalance(Schedule, Imbalance),
    Score is Total + 10 * Imbalance.

% Computes the energy consumed on one specific day.
energy_per_day([], _Day, 0).
energy_per_day([Assignment | Rest], Day, Energy) :-
    Assignment = assign(_, _, _, Time),
    timeslot_day(Time, AssignmentDay),
    energy_per_day(Rest, Day, RestEnergy),
    (   AssignmentDay = Day
    ->  assignment_energy(Assignment, AssignmentEnergy),
        Energy is AssignmentEnergy + RestEnergy
    ;   Energy = RestEnergy
    ).

% Extracts the day used by an assignment.
schedule_day(assign(_, _, _, Time), Day) :-
    timeslot_day(Time, Day).

% Imbalance = max daily energy - min daily energy.
% Smaller imbalance means energy demand is distributed more evenly.
load_imbalance([], 0).
load_imbalance(Schedule, Imbalance) :-
    findall(Day,
            (member(Assignment, Schedule),
             schedule_day(Assignment, Day)),
            Days0),
    sort(Days0, Days),
    findall(Energy,
            (member(Day, Days),
             energy_per_day(Schedule, Day, Energy)),
            Energies),
    max_list(Energies, MaxEnergy),
    min_list(Energies, MinEnergy),
    Imbalance is MaxEnergy - MinEnergy.

% Generates a valid schedule and computes its optimization score.
scored_schedule(Schedule, Score) :-
    generate_schedule(Schedule),
    score(Schedule, Score).

% setof sorts Score-Schedule pairs automatically.
% The first result has the lowest score.
% setof/3 performs exhaustive optimization over all valid schedules.
% This is correct for the current small dataset; Branch and Bound would scale better.
best_schedule(BestSchedule) :-
    setof(Score-Schedule,
          scored_schedule(Schedule, Score),
          [_BestScore-BestSchedule | _]).

best_schedule_with_score(BestSchedule, BestScore) :-
    setof(Score-Schedule,
          scored_schedule(Schedule, Score),
          [BestScore-BestSchedule | _]).
