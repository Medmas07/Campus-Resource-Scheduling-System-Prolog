# Prolog Course Scheduling System

## Project Overview

This project is a Prolog-based course scheduling system. Its goal is to build a valid timetable by assigning course sessions to rooms and time slots while respecting scheduling constraints.

The scheduler works as a constraint satisfaction problem. It uses Prolog backtracking to try assignments and reject invalid partial schedules as early as possible.

The system checks constraints such as:

- room conflicts
- student group conflicts
- room capacity
- equipment compatibility
- instructor availability

The main entry point is:

```prolog
generate_schedule(Schedule).
```

If the facts in the knowledge base are satisfiable, the system returns a schedule. If they are not satisfiable, Prolog returns `false`. This is expected behavior and means no valid schedule exists for the current input data.

## File Structure

`facts.pl`

- Defines the knowledge base.
- Contains facts for courses, rooms, buildings, time slots, group sizes, instructors, and availability.
- Provides accessor predicates used by the scheduling engine.

`constraints.pl`

- Defines the scheduling logic.
- Builds schedules incrementally using recursive assignment.
- Applies constraints during generation so invalid partial schedules fail early.

Main predicate:

```prolog
generate_schedule(Schedule).
```

## How the Code Works

### 1. `generate_schedule/1`

This is the main predicate used to request a schedule.

```prolog
?- generate_schedule(Schedule).
```

It first collects the list of courses and then starts recursive assignment.

### 2. `all_courses/1`

This predicate gathers all course identifiers from the knowledge base.

Example:

```prolog
?- all_courses(Courses).
```

It returns a list of all courses that must be scheduled.

### 3. `assign_all_courses/3`

This predicate processes the course list one course at a time.

```prolog
assign_all_courses(Courses, PartialSchedule, FinalSchedule)
```

Behavior:

- if the course list is empty, the schedule is complete
- otherwise, it schedules all sessions of the first course
- then it recursively continues with the remaining courses

### 4. Recursive Session Assignment

For each course, `assign_sessions/4` assigns every session index using the representation:

```prolog
assign(Course, SessionIndex, Room, Time)
```

The engine tries room and time combinations through Prolog backtracking.

### 5. Constraint Checking

Each new assignment is checked before the search continues. The main validation predicate is:

```prolog
valid_partial(Schedule)
```

It enforces:

- `no_room_conflict/1`
- `no_group_conflict/1`
- `capacity_ok/1`
- `equipment_ok/1`
- `availability_ok/1`

This means the system does not generate a full schedule and then filter it afterward. It prunes invalid choices immediately.

### 6. Prolog Backtracking and Failure

The scheduler relies on Prolog search:

- Prolog tries a possible assignment
- if a constraint fails, Prolog backtracks
- it then tries another room or time slot
- if all possibilities fail, the predicate returns `false`

This failure is meaningful. It indicates that no valid schedule exists under the current facts and constraints.

## Installation / Setup

### 1. Install SWI-Prolog

Download and install SWI-Prolog:

https://www.swi-prolog.org/

### 2. Start Prolog

Open a terminal in the project directory and run:

```bash
swipl
```

### 3. Load the project files

Inside the Prolog REPL:

```prolog
?- [facts].
?- [constraints].
```

You can also load both files in one command:

```prolog
?- [facts, constraints].
```

## How to Run the System

The main query is:

```prolog
?- generate_schedule(S).
```

Behavior:

- returns a schedule if one exists
- returns `false` if the constraints are impossible to satisfy

Example:

```prolog
?- generate_schedule(S).
S = [assign(...), assign(...), ...].
```

If no solution exists:

```prolog
?- generate_schedule(S).
false.
```

## Testing and Debugging

This project is easiest to test directly from the Prolog REPL.

### Test 1: Check that courses are loaded

```prolog
?- all_courses(C).
```

What it verifies:

- the course facts are visible through the scheduling module
- the engine can enumerate the courses it needs to schedule

Typical result:

```prolog
C = [programming_101, calculus_1, physics_lab, database_systems].
```

### Test 2: Base case of course assignment

```prolog
?- assign_all_courses([], [], S).
```

What it verifies:

- the recursion base case works correctly
- an empty course list returns the current partial schedule unchanged

Typical result:

```prolog
S = [].
```

### Test 3: Schedule one course with feasible constraints

```prolog
?- assign_all_courses([programming_101], [], S).
```

What it verifies:

- recursive session assignment works
- room selection works
- instructor availability is respected
- partial schedule validation succeeds for a satisfiable course

Typical result:

```prolog
S = [
  assign(programming_101, 2, lab_alpha, tuesday_08_10),
  assign(programming_101, 1, lab_alpha, monday_08_10)
].
```

### Test 4: Detect failure for an unschedulable course

```prolog
?- assign_all_courses([calculus_1], [], S).
```

What it verifies:

- the engine correctly fails when a course cannot be assigned
- constraint failure propagates through the recursive scheduler

Typical result:

```prolog
false.
```

### Trace-based debugging

To inspect the execution path:

```prolog
?- trace, generate_schedule(S).
```

What it helps with:

- identifying where failure occurs
- seeing which choices are tried first
- understanding how backtracking explores alternatives

This is the most useful debugging tool when the scheduler returns `false` unexpectedly.

## Common Failure Cases

If Prolog returns:

```prolog
false.
```

it means no valid schedule exists for the current dataset and constraints.

Common reasons:

- conflicting room assignments at the same time
- two courses for the same student group at the same time
- room capacity smaller than the group size
- equipment mismatch between course and room
- instructor unavailable at the chosen time
- missing facts in `facts.pl`
- too few compatible time slots
- too few compatible rooms

The system does not fail randomly. It fails because every candidate assignment eventually violates at least one constraint.

## Example Output

A successful schedule is a list of assignment terms:

```prolog
S = [
  assign(programming_101, 2, lab_alpha, tuesday_08_10),
  assign(programming_101, 1, lab_alpha, monday_08_10)
].
```

Structure of each item:

```prolog
assign(Course, SessionNumber, Room, TimeSlot)
```

Meaning:

- `Course`: the course identifier
- `SessionNumber`: which session of the course is being scheduled
- `Room`: the assigned room
- `TimeSlot`: the assigned time slot

## How to Extend the System

### Add a new course

In `facts.pl`, add a new `course/5` fact and ensure related facts exist:

- a student group with `group_size/2`
- an instructor with `teaches/2`
- matching instructor availability with `availability/2`

Example:

```prolog
course(ai_intro, 2, 2, group_d, projector).
group_size(group_d, 20).
teaches(dr_nadia, ai_intro).
availability(dr_nadia, monday_10_12).
availability(dr_nadia, tuesday_10_12).
```

### Add a new room

In `facts.pl`, add a room with suitable capacity and equipment:

```prolog
room(room_d301, 50, projector, science_block, 6).
```

### Add a new time slot

In `facts.pl`, add:

```prolog
timeslot(thursday_08_10).
```

### Modify constraints

To change scheduling behavior, update `constraints.pl`.

Examples:

- add a new conflict rule
- tighten availability rules
- restrict certain courses to certain rooms

When adding new constraints, keep them in separate predicates and include them in `valid_partial/1` so failure happens early.

## Key Insight

This project is a constraint satisfaction problem.

The scheduler does not construct a timetable by optimization or guessing randomly. It builds a schedule incrementally, checks each partial assignment against the constraints, and backtracks whenever a violation occurs.

If the system returns `false`, that is not a bug by itself. It means the current facts and constraints do not admit any valid schedule.
