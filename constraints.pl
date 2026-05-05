:- module(constraints, [
    generate_schedule/1,
    assign_all_courses/3,
    assign_sessions/4,
    validate_insertion/2,
    no_same_course_time/2,
    no_room_conflict/1,
    no_group_conflict/1,
    no_instructor_conflict/1,
    no_same_course_conflict/1,
    capacity_ok/1,
    equipment_ok/1,
    availability_ok/1
]).

:- use_module(facts, [
    all_courses/1,
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

%% Conflicts Detectors

room_conflicts_with(assign(_, _, Room, Time), [assign(_, _, Room, Time) | _]) :-
    !.
room_conflicts_with(Assignment, [_ | Rest]) :-
    room_conflicts_with(Assignment, Rest).

group_conflicts_with(assign(Course, _, _, Time), [assign(OtherCourse, _, _, Time) | _]) :-
    course_group(Course, Group),
    course_group(OtherCourse, Group),
    !.
group_conflicts_with(Assignment, [_ | Rest]) :-
    group_conflicts_with(Assignment, Rest).

instructor_conflicts_with(assign(Course, _, _, Time), [assign(OtherCourse, _, _, Time) | _]) :-
    instructor_of(Instructor, Course),
    instructor_of(Instructor, OtherCourse),
    !.
instructor_conflicts_with(Assignment, [_ | Rest]) :-
    instructor_conflicts_with(Assignment, Rest).

no_same_course_time(assign(Course, _, _, Time), Schedule) :-
    \+ member(assign(Course, _, _, Time), Schedule).

no_room_conflict([]).
no_room_conflict([Assignment | Rest]) :-
    \+ room_conflicts_with(Assignment, Rest),
    no_room_conflict(Rest).

% validattes groups availabilites
no_group_conflict([]).
no_group_conflict([Assignment | Rest]) :-
    \+ group_conflicts_with(Assignment, Rest),
    no_group_conflict(Rest).

no_instructor_conflict([]).
no_instructor_conflict([Assignment | Rest]) :-
    \+ instructor_conflicts_with(Assignment, Rest),
    no_instructor_conflict(Rest).

no_same_course_conflict([]).
no_same_course_conflict([Assignment | Rest]) :-
    no_same_course_time(Assignment, Rest),
    no_same_course_conflict(Rest).

capacity_ok([]).
capacity_ok([assign(Course, _, Room, _) | Rest]) :-
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    capacity_ok(Rest).

% validates equipments
equipment_ok([]).
equipment_ok([assign(Course, _, Room, _) | Rest]) :-
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),
    equipment_ok(Rest).

%   validates teachers' availabilities
availability_ok([]).
availability_ok([assign(Course, _, _, Time) | Rest]) :-
    instructor_of(Instructor, Course),
    instructor_available(Instructor, Time),
    availability_ok(Rest).

%   validates assignments for one course.
%   assumptions: each SessionIndex appears only once in Schedule
course_assignments_ok(Course, Schedule) :-
    course_sessions(Course, Total),
    findall(SessionIndex, member(assign(Course, SessionIndex, _, _), Schedule), Sessions),
    length(Sessions, Total).

%   validates assignment 
validate_insertion(Assignment, Schedule) :-
    \+ room_conflicts_with(Assignment, Schedule),
    \+ group_conflicts_with(Assignment, Schedule),
    \+ instructor_conflicts_with(Assignment, Schedule),
    no_same_course_time(Assignment, Schedule).

generate_schedule(Schedule) :-
    all_courses(Courses),
    assign_all_courses(Courses, [], Schedule),
    no_room_conflict(Schedule),
    no_group_conflict(Schedule),
    no_instructor_conflict(Schedule),
    no_same_course_conflict(Schedule),
    capacity_ok(Schedule),
    equipment_ok(Schedule),
    availability_ok(Schedule).

assign_all_courses([], Schedule, Schedule).
assign_all_courses([Course | Rest], Partial, Schedule) :-
    assign_sessions(Course, 1, Partial, Updated),
    assign_all_courses(Rest, Updated, Schedule).

%   bruteforce (+ backtracking) assignments for one course.
assign_sessions(Course, SessionIndex, Partial, Partial) :-
    course_sessions(Course, TotalSessions),
    SessionIndex > TotalSessions.
assign_sessions(Course, SessionIndex, Partial, Schedule) :-
    course_sessions(Course, TotalSessions),
    SessionIndex =< TotalSessions,

    % Local constraints
    % Equipment
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),

    % Capacity
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    
    % Instructor availability
    instructor_of(Instructor, Course),
    instructor_available(Instructor, Time),
    timeslot(Time),

    Assignment = assign(Course, SessionIndex, Room, Time),

    % Global constraints
    % Validate with other assignments
    validate_insertion(Assignment, Partial),

    % Next assignment for the same course
    NextIndex is SessionIndex + 1,
    assign_sessions(Course, NextIndex, [Assignment | Partial], Schedule).
