:- module(constraints, [
    generate_schedule/1,
    assign_all_courses/3,
    assign_sessions/4,
    valid_partial/1,
    no_room_conflict/1,
    no_group_conflict/1,
    capacity_ok/1,
    equipment_ok/1,
    availability_ok/1
]).

:- use_module(facts, [
    course_sessions/2,
    course_group/2,
    course_equipment/2,
    room_capacity/2,
    room_equipment/2,
    instructor_of/2,
    instructor_available/2,
    group_size_of/2,
    timeslot/1
]).

generate_schedule(Schedule) :-
    all_courses(Courses),
    assign_all_courses(Courses, [], Schedule).

assign_all_courses([], Schedule, Schedule).
assign_all_courses([Course | Rest], Partial, Schedule) :-
    assign_sessions(Course, 1, Partial, Updated),
    assign_all_courses(Rest, Updated, Schedule).

assign_sessions(Course, SessionIndex, Partial, Partial) :-
    course_sessions(Course, TotalSessions),
    SessionIndex > TotalSessions.
assign_sessions(Course, SessionIndex, Partial, Schedule) :-
    course_sessions(Course, TotalSessions),
    SessionIndex =< TotalSessions,
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    instructor_of(Instructor, Course),
    instructor_available(Instructor, Time),
    timeslot(Time),
    Assignment = assign(Course, SessionIndex, Room, Time),
    valid_partial([Assignment | Partial]),
    NextIndex is SessionIndex + 1,
    assign_sessions(Course, NextIndex, [Assignment | Partial], Schedule).

valid_partial(Schedule) :-
    no_room_conflict(Schedule),
    no_group_conflict(Schedule),
    capacity_ok(Schedule),
    equipment_ok(Schedule),
    availability_ok(Schedule).

no_room_conflict([]).
no_room_conflict([Assignment | Rest]) :-
    \+ room_conflicts_with(Assignment, Rest),
    no_room_conflict(Rest).

no_group_conflict([]).
no_group_conflict([Assignment | Rest]) :-
    \+ group_conflicts_with(Assignment, Rest),
    no_group_conflict(Rest).

capacity_ok([]).
capacity_ok([assign(Course, _, Room, _) | Rest]) :-
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    capacity_ok(Rest).

equipment_ok([]).
equipment_ok([assign(Course, _, Room, _) | Rest]) :-
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),
    equipment_ok(Rest).

availability_ok([]).
availability_ok([assign(Course, _, _, Time) | Rest]) :-
    instructor_of(Instructor, Course),
    instructor_available(Instructor, Time),
    availability_ok(Rest).

room_conflicts_with(assign(_, _, Room, Time), [assign(_, _, Room, Time) | _]).
room_conflicts_with(Assignment, [_ | Rest]) :-
    room_conflicts_with(Assignment, Rest).

group_conflicts_with(assign(Course, _, _, Time), [assign(OtherCourse, _, _, Time) | _]) :-
    course_group(Course, Group),
    course_group(OtherCourse, Group).
group_conflicts_with(Assignment, [_ | Rest]) :-
    group_conflicts_with(Assignment, Rest).

assigned_course(Course, Schedule) :-
    course_sessions(Course, Total),
    findall(SessionIndex, member(assign(Course, SessionIndex, _, _), Schedule), Sessions),
    length(Sessions, Total).

all_courses(Courses) :-
    findall(Course, course_sessions(Course, _), Courses).
