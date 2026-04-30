:- module(facts, [
    course_sessions/2,
    course_duration/2,
    course_group/2,
    course_equipment/2,
    room_capacity/2,
    room_equipment/2,
    room_building/2,
    room_energy/2
]).

course(programming_101, 2, 2, group_a, [computers, projector]).
course(calculus_1, 3, 1, group_b, [whiteboard, projector]).
course(physics_lab, 1, 3, group_c, [lab_benches, projector]).
course(database_systems, 2, 2, group_a, [computers, projector]).

room(lab_alpha, 30, [computers, projector], engineering_block, 8).
room(room_b201, 40, [whiteboard, projector], science_block, 5).
room(room_c105, 25, [lab_benches, projector], science_block, 7).

building(engineering_block, 60).
building(science_block, 50).

timeslot(monday_08_10).
timeslot(monday_10_12).
timeslot(tuesday_08_10).
timeslot(tuesday_10_12).
timeslot(wednesday_14_16).

group_size(group_a, 28).
group_size(group_b, 35).
group_size(group_c, 22).

teaches(dr_smith, programming_101).
teaches(dr_ali, calculus_1).
teaches(dr_khan, physics_lab).
teaches(prof_chen, database_systems).

availability(dr_smith, monday_08_10).
availability(dr_smith, tuesday_08_10).
availability(dr_ali, monday_10_12).
availability(dr_ali, wednesday_14_16).
availability(dr_khan, tuesday_10_12).
availability(dr_khan, wednesday_14_16).
availability(prof_chen, monday_08_10).
availability(prof_chen, tuesday_10_12).

course_sessions(Course, Sessions) :-
    course(Course, Sessions, _, _, _).

course_duration(Course, Duration) :-
    course(Course, _, Duration, _, _).

course_group(Course, Group) :-
    course(Course, _, _, Group, _).

course_equipment(Course, Equipment) :-
    course(Course, _, _, _, Equipment).

room_capacity(Room, Capacity) :-
    room(Room, Capacity, _, _, _).

room_equipment(Room, Equipment) :-
    room(Room, _, Equipment, _, _).

room_building(Room, Building) :-
    room(Room, _, _, Building, _).

room_energy(Room, EnergyCost) :-
    room(Room, _, _, _, EnergyCost).
