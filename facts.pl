:- module(facts, [
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
    group_size/2,
    teaches/2,
    availability/2,
    building/2,
    timeslot/1,
    next_slot/2
]).

%% Data Structures
% course(Course, Sessions, Duration, Group, Equipment)
course(programming_101 , 2, 2, group_a, computers  ).
course(calculus_1      , 1, 1, group_b, projector  ).
course(physics_lab     , 1, 3, group_c, lab_benches).
% course(database_systems, 2, 2, group_a, computers  ).

% room(Room, Capacity, Equipment, Building, EnergyCost)
room(lab_alpha, 30, computers  , engineering_block, 8).
room(room_b201, 40, projector  ,     science_block, 5).
room(room_c105, 25, lab_benches,     science_block, 7).

% building(Building, MaxEnergy)
building(engineering_block, 60).
building(science_block    , 50).

% day_start_end
timeslot(   monday_08_09).
timeslot(   monday_09_10).
timeslot(   monday_10_11).
timeslot(   monday_11_12).
timeslot(  tuesday_08_09).
timeslot(  tuesday_09_10).
timeslot(  tuesday_10_11).
timeslot(  tuesday_11_12).
timeslot(wednesday_14_15).
timeslot(wednesday_15_16).

% Atomic slots are ordered only within the same day.
next_slot(   monday_08_09,    monday_09_10).
next_slot(   monday_09_10,    monday_10_11).
next_slot(   monday_10_11,    monday_11_12).
next_slot(  tuesday_08_09,   tuesday_09_10).
next_slot(  tuesday_09_10,   tuesday_10_11).
next_slot(  tuesday_10_11,   tuesday_11_12).
next_slot(wednesday_14_15, wednesday_15_16).

group_size(group_a, 28).
group_size(group_b, 35).
group_size(group_c, 22).

teaches(dr_sami,    programming_101 ).
% database_systems is disabled in the small dataset, so its instructor facts stay disabled too.
% teaches(prof_anwer, database_systems).
teaches(dr_ali,     calculus_1      ).
teaches(dr_skander, physics_lab     ).

availability(dr_sami   ,    monday_08_09).
availability(dr_sami   ,    monday_09_10).
availability(dr_sami   ,   tuesday_08_09).
availability(dr_sami   ,   tuesday_09_10).
availability(dr_ali    ,    monday_10_11).
availability(dr_ali    ,    monday_11_12).
availability(dr_ali    , wednesday_14_15).
availability(dr_ali    , wednesday_15_16).
% physics_lab has duration 3, so dr_skander needs three consecutive atomic slots.
availability(dr_skander,   tuesday_09_10).
availability(dr_skander,   tuesday_10_11).
availability(dr_skander,   tuesday_11_12).
availability(dr_skander, wednesday_14_15).
availability(dr_skander, wednesday_15_16).
% availability(prof_anwer,    monday_08_09).
% availability(prof_anwer,    monday_09_10).
% availability(prof_anwer,   tuesday_10_11).
% availability(prof_anwer,   tuesday_11_12).








%% Component Accessors

course_sessions(Course, Sessions)   :- course(Course, Sessions, _, _, _).
course_duration(Course, Duration)   :- course(Course, _, Duration, _, _).
course_group(Course, Group)         :- course(Course, _, _, Group, _).
course_equipment(Course, Equipment) :- course(Course, _, _, _, Equipment).

room_capacity(Room, Capacity)   :- room(Room, Capacity, _, _, _).
room_equipment(Room, Equipment) :- room(Room, _, Equipment, _, _).
room_building(Room, Building)   :- room(Room, _, _, Building, _).
room_energy(Room, EnergyCost)   :- room(Room, _, _, _, EnergyCost).

instructor_of(Instructor, Course)      :- teaches(Instructor, Course).
instructor_available(Instructor, Time) :- availability(Instructor, Time).

group_size_of(Group, Size) :- group_size(Group, Size).

building_max_energy(Building, MaxEnergy) :- building(Building, MaxEnergy).








%% Loaders

all_courses(Courses) :-
    findall(Course, course_sessions(Course, _), Courses).
