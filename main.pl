:- module(main, [
    solve/1,
    solve/2,
    print_solution_json/0
]).

:- use_module(library(http/json)).
:- use_module(facts).
:- use_module(constraints).
:- use_module(optimization).

% Final orchestration point for the optimized scheduling system.
solve(BestSchedule, Score) :-
    best_schedule_with_score(BestSchedule, Score).

solve(BestSchedule) :-
    best_schedule(BestSchedule).

% JSON bridge used by the Node.js backend.
print_solution_json :-
    solve(Schedule, Score),
    total_energy(Schedule, TotalEnergy),
    load_imbalance(Schedule, LoadImbalance),
    room_usage_imbalance(Schedule, RoomUsageImbalance),
    schedule_to_json(Schedule, JsonSchedule),
    json_write(current_output,
               json([score=Score,
                     totalEnergy=TotalEnergy,
                     loadImbalance=LoadImbalance,
                     roomUsageImbalance=RoomUsageImbalance,
                     schedule=JsonSchedule])),
    nl.

schedule_to_json([], []).
schedule_to_json([Assignment | Rest], [JsonAssignment | JsonRest]) :-
    assignment_to_json(Assignment, JsonAssignment),
    schedule_to_json(Rest, JsonRest).

assignment_to_json(assign(Course, Session, Room, StartTime, OccupiedSlots),
                   json([course=Course,
                         session=Session,
                         room=Room,
                         startTime=StartTime,
                         occupiedSlots=OccupiedSlots])).
