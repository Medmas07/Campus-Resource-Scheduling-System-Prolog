:- module(constraints, [
    generate_schedule/1,
    assign_all_courses/4,
    assign_sessions/5,
    validate_insertion/2,
    timeslot_day/2,
    consecutive_slots/3,
    intersects/2,
    update_energy_state/3,
    energy_ok/2,
    assignment_energy/2,
    total_energy/2,
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
    course_duration/2,
    course_group/2,
    course_equipment/2,
    room_capacity/2,
    room_equipment/2,
    room_building/2,
    room_energy/2,
    instructor_of/2,
    instructor_available/2,
    group_size_of/2,
    building_max_energy/2,
    timeslot/1,
    next_slot/2
]).

%% Conflicts Detectors

intersects([Slot | _], Slots) :-
    member(Slot, Slots),
    !.
intersects([_ | Rest], Slots) :-
    intersects(Rest, Slots).

room_conflicts_with(assign(_, _, Room, _, Slots), [assign(_, _, Room, _, OtherSlots) | _]) :-
    intersects(Slots, OtherSlots),
    !.
room_conflicts_with(Assignment, [_ | Rest]) :-
    room_conflicts_with(Assignment, Rest).

group_conflicts_with(assign(Course, _, _, _, Slots), [assign(OtherCourse, _, _, _, OtherSlots) | _]) :-
    course_group(Course, Group),
    course_group(OtherCourse, Group),
    intersects(Slots, OtherSlots),
    !.
group_conflicts_with(Assignment, [_ | Rest]) :-
    group_conflicts_with(Assignment, Rest).

instructor_conflicts_with(assign(Course, _, _, _, Slots), [assign(OtherCourse, _, _, _, OtherSlots) | _]) :-
    instructor_of(Instructor, Course),
    instructor_of(Instructor, OtherCourse),
    intersects(Slots, OtherSlots),
    !.
instructor_conflicts_with(Assignment, [_ | Rest]) :-
    instructor_conflicts_with(Assignment, Rest).

no_same_course_time(assign(Course, _, _, _, Slots), Schedule) :-
    \+ (
        member(assign(Course, _, _, _, OtherSlots), Schedule),
        intersects(Slots, OtherSlots)
    ).

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
capacity_ok([assign(Course, _, Room, _, _) | Rest]) :-
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    capacity_ok(Rest).

% validates equipments
equipment_ok([]).
equipment_ok([assign(Course, _, Room, _, _) | Rest]) :-
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),
    equipment_ok(Rest).

%   validates teachers' availabilities
availability_ok([]).
availability_ok([assign(Course, _, _, _, OccupiedSlots) | Rest]) :-
    instructor_of(Instructor, Course),
    forall(member(Slot, OccupiedSlots),
           instructor_available(Instructor, Slot)),
    availability_ok(Rest).

%   validates assignments for one course.
%   assumptions: each SessionIndex appears only once in Schedule
%   Internal debugging helper; generation already enforces session creation.
course_assignments_ok(Course, Schedule) :-
    course_sessions(Course, Total),
    findall(SessionIndex, member(assign(Course, SessionIndex, _, _, _), Schedule), Sessions),
    length(Sessions, Total).

%   validates assignment 
validate_insertion(Assignment, Schedule) :-
    \+ room_conflicts_with(Assignment, Schedule),
    \+ group_conflicts_with(Assignment, Schedule),
    \+ instructor_conflicts_with(Assignment, Schedule),
    no_same_course_time(Assignment, Schedule).

%   maps a timeslot atom to its day, e.g. monday_08_09 -> monday.
timeslot_day(Time, Day) :-
    sub_atom(Time, Before, 1, _, '_'),
    !,
    sub_atom(Time, 0, Before, _, Day).
timeslot_day(Time, Time).

%   Builds the list of real consecutive slots occupied by a session.
consecutive_slots(StartTime, 1, [StartTime]) :-
    timeslot(StartTime).
consecutive_slots(StartTime, Duration, [StartTime | Rest]) :-
    Duration > 1,
    next_slot(StartTime, NextTime),
    NextDuration is Duration - 1,
    consecutive_slots(NextTime, NextDuration, Rest).

%   State = list of energy(Building, Day, Value).
%   Energy state structure: [energy(Building, Day, Value), ...].
%   Updating adds the full assignment energy to its building/day entry.
update_energy_state(Assignment, State, NewState) :-
    Assignment = assign(_, _, Room, StartTime, _),
    room_building(Room, Building),
    timeslot_day(StartTime, Day),
    assignment_energy(Assignment, Cost),
    update_energy_entry(Building, Day, Cost, State, NewState).

update_energy_entry(Building, Day, Cost, [], [energy(Building, Day, Cost)]).
update_energy_entry(Building, Day, Cost, [energy(Building, Day, Current) | Rest],
                    [energy(Building, Day, Updated) | Rest]) :-
    !,
    Updated is Current + Cost.
update_energy_entry(Building, Day, Cost, [Entry | Rest], [Entry | UpdatedRest]) :-
    update_energy_entry(Building, Day, Cost, Rest, UpdatedRest).

%   Pruning condition: after update, building/day energy must stay under max.
energy_ok(assign(_, _, Room, StartTime, _), State) :-
    room_building(Room, Building),
    timeslot_day(StartTime, Day),
    building_max_energy(Building, MaxEnergy),
    energy_used(Building, Day, State, UsedEnergy),
    UsedEnergy =< MaxEnergy.

%   Missing energy entries are treated as 0 for robust checks.
energy_used(Building, Day, State, UsedEnergy) :-
    member(energy(Building, Day, UsedEnergy), State),
    !.
energy_used(_, _, _, 0).

%   Assignment energy includes course duration, so longer sessions cost more.
assignment_energy(assign(Course, _, Room, _, _), Energy) :-
    course_duration(Course, Duration),
    room_energy(Room, Cost),
    Energy is Duration * Cost.

total_energy([], 0).
total_energy([Assignment | Rest], Total) :-
    assignment_energy(Assignment, Cost),
    total_energy(Rest, RestTotal),
    Total is Cost + RestTotal.

%   Rebuilds energy state from the current partial schedule between courses.
energy_state_from_schedule(Schedule, State) :-
    energy_state_from_schedule(Schedule, [], State).

energy_state_from_schedule([], State, State).
energy_state_from_schedule([Assignment | Rest], State, FinalState) :-
    update_energy_state(Assignment, State, NewState),
    energy_state_from_schedule(Rest, NewState, FinalState).

generate_schedule(Schedule) :-
    all_courses(Courses),
    assign_all_courses(Courses, [], [], Schedule),
    no_room_conflict(Schedule),
    no_group_conflict(Schedule),
    no_instructor_conflict(Schedule),
    no_same_course_conflict(Schedule),
    capacity_ok(Schedule),
    equipment_ok(Schedule),
    availability_ok(Schedule).

assign_all_courses([], Schedule, _State, Schedule).
assign_all_courses([Course | Rest], Partial, State, Schedule) :-
    assign_sessions(Course, 1, Partial, State, Updated),
    energy_state_from_schedule(Updated, UpdatedState),
    assign_all_courses(Rest, Updated, UpdatedState, Schedule).

%   bruteforce (+ backtracking) assignments for one course.
assign_sessions(Course, SessionIndex, Partial, _State, Partial) :-
    course_sessions(Course, TotalSessions),
    SessionIndex > TotalSessions.
assign_sessions(Course, SessionIndex, Partial, State, Schedule) :-
    course_sessions(Course, TotalSessions),
    SessionIndex =< TotalSessions,
    course_duration(Course, Duration),

    % Local constraints
    % Equipment
    timeslot(StartTime),
    consecutive_slots(StartTime, Duration, OccupiedSlots),
    course_equipment(Course, Equipment),
    room_equipment(Room, Equipment),

    % Capacity
    course_group(Course, Group),
    group_size_of(Group, GroupSize),
    room_capacity(Room, RoomCapacity),
    GroupSize =< RoomCapacity,
    
    % Instructor availability
    instructor_of(Instructor, Course),
    forall(member(Slot, OccupiedSlots),
           instructor_available(Instructor, Slot)),

    Assignment = assign(Course, SessionIndex, Room, StartTime, OccupiedSlots),

    % Global constraints
    % Validate with other assignments
    validate_insertion(Assignment, Partial),

    update_energy_state(Assignment, State, NewState),
    energy_ok(Assignment, NewState),

    % Next assignment for the same course
    NextIndex is SessionIndex + 1,
    assign_sessions(Course, NextIndex, [Assignment | Partial], NewState, Schedule).
