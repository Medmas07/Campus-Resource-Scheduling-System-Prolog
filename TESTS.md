# Tests

## Setup

Load the project modules in SWI-Prolog:

```prolog
?- [facts].
?- [constraints].
?- [optimization].
?- [main].
```

## Test Atomic Slot Existence

```prolog
?- timeslot(monday_08_09).
```

Expected:

```prolog
true.
```

## Test next_slot/2

```prolog
?- next_slot(monday_08_09, X).
```

Expected:

```prolog
X = monday_09_10.
```

## Test Consecutive Slots

```prolog
?- consecutive_slots(monday_08_09, 2, Slots).
```

Expected:

```prolog
Slots = [monday_08_09, monday_09_10].
```

## Test End-of-Day Failure

```prolog
?- consecutive_slots(monday_11_12, 2, Slots).
```

Expected:

```prolog
false.
```

## Test Room Overlap Conflict

```prolog
?- no_room_conflict([
     assign(c1, 1, r1, monday_08_09, [monday_08_09, monday_09_10]),
     assign(c2, 1, r1, monday_09_10, [monday_09_10, monday_10_11])
   ]).
```

Expected:

```prolog
false.
```

## Test Non-Overlap Room Usage

```prolog
?- no_room_conflict([
     assign(c1, 1, r1, monday_08_09, [monday_08_09]),
     assign(c2, 1, r1, monday_09_10, [monday_09_10])
   ]).
```

Expected:

```prolog
true.
```

## Test Assignment Energy

```prolog
?- assignment_energy(
     assign(programming_101, 1, lab_alpha, monday_08_09,
            [monday_08_09, monday_09_10]),
     E
   ).
```

Expected:

```prolog
E = 16.
```

Explanation:

```text
programming_101 duration = 2
lab_alpha energy cost = 8
2 x 8 = 16
```

## Test Total Energy

```prolog
?- generate_schedule(S), total_energy(S, E).
```

Expected:

```prolog
E = 58.
```

## Test solve/2

```prolog
?- solve(S, Score).
```

Expected:

```prolog
Score = 223.
```

An optimal schedule may be returned in a different order if it has the same score.

## Test Score Components

```prolog
?- solve(S, Score),
   total_energy(S, E),
   load_imbalance(S, I),
   room_usage_imbalance(S, R).
```

Expected:

```prolog
E = 58,
I = 16,
R = 1,
Score = 223.
```

Score calculation:

```text
Score = 58 + 10 x 16 + 5 x 1 = 223
```

## Test Exhaustive vs Branch and Bound

```prolog
?- compare_optimization_methods(ExhaustiveScore, BranchBoundScore).
```

Expected:

```prolog
ExhaustiveScore = BranchBoundScore,
BranchBoundScore = 223.
```

Equivalent display:

```prolog
ExhaustiveScore = BranchBoundScore = 223.
```

## Test Energy Threshold Failure

Instruction: temporarily change this fact in `facts.pl`:

```prolog
building(engineering_block, 60).
```

to:

```prolog
building(engineering_block, 15).
```

Reload the project and run:

```prolog
?- solve(S, Score).
```

Expected:

```prolog
false.
```

Explanation:

```text
A single programming_101 session costs 2 x 8 = 16.
This exceeds the engineering_block threshold of 15.
```
