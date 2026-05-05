:- module(optimization, [
    score/2,
    scored_schedule/2,
    energy_per_day/3,
    load_imbalance/2,
    room_usage/3,
    room_usage_counts/2,
    room_usage_imbalance/2,
    best_schedule/1,
    best_schedule_with_score/2
]).

:- use_module(constraints).
:- use_module(library(lists), [max_list/2, min_list/2]).

% Score = total energy + load balancing penalty.
% Lower score = better schedule.
% total_energy alone may be identical for many schedules, so imbalance is added.
% Room usage imbalance penalizes overusing one room when alternatives exist.
score(Schedule, Score) :-
    total_energy(Schedule, Total),
    load_imbalance(Schedule, LoadImbalance),
    room_usage_imbalance(Schedule, RoomImbalance),
    Score is Total + 10 * LoadImbalance + 5 * RoomImbalance.

% Computes the energy consumed on one specific day.
energy_per_day([], _Day, 0).
energy_per_day([Assignment | Rest], Day, Energy) :-
    Assignment = assign(_, _, _, StartTime, _),
    timeslot_day(StartTime, AssignmentDay),
    energy_per_day(Rest, Day, RestEnergy),
    (   AssignmentDay = Day
    ->  assignment_energy(Assignment, AssignmentEnergy),
        Energy is AssignmentEnergy + RestEnergy
    ;   Energy = RestEnergy
    ).

% Extracts the day used by an assignment.
schedule_day(assign(_, _, _, StartTime, _), Day) :-
    timeslot_day(StartTime, Day).

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

% Counts how many assignments use one room from the generated schedule.
room_usage(Schedule, Room, Count) :-
    findall(Room0,
            member(assign(_, _, Room0, _, _), Schedule),
            Rooms0),
    sort(Rooms0, Rooms),
    member(Room, Rooms),
    findall(1,
            member(assign(_, _, Room, _, _), Schedule),
            Uses),
    length(Uses, Count).

% Uses only rooms that appear in the schedule for fairness comparison.
room_usage_counts(Schedule, Counts) :-
    findall(Room,
            member(assign(_, _, Room, _, _), Schedule),
            Rooms0),
    sort(Rooms0, Rooms),
    findall(Count,
            (member(Room, Rooms),
             room_usage(Schedule, Room, Count)),
            Counts).

% Room imbalance = max room usage - min room usage.
% Smaller imbalance means room allocation is fairer.
room_usage_imbalance([], 0).
room_usage_imbalance(Schedule, Imbalance) :-
    room_usage_counts(Schedule, Counts),
    max_list(Counts, MaxUsage),
    min_list(Counts, MinUsage),
    Imbalance is MaxUsage - MinUsage.

% Generates a valid schedule and computes its optimization score.
scored_schedule(Schedule, Score) :-
    generate_schedule(Schedule),
    score(Schedule, Score).

% setof sorts Score-Schedule pairs automatically.
% The first result has the lowest score.
% setof/3 performs exhaustive optimization over all valid schedules.
% This is correct for the current small dataset; Branch and Bound would scale better.
% Scalable optimization would require Branch and Bound integrated into generation.
best_schedule(BestSchedule) :-
    setof(Score-Schedule,
          scored_schedule(Schedule, Score),
          [_BestScore-BestSchedule | _]).

best_schedule_with_score(BestSchedule, BestScore) :-
    setof(Score-Schedule,
          scored_schedule(Schedule, Score),
          [BestScore-BestSchedule | _]).
