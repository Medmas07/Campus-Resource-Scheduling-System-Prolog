import fs from 'node:fs/promises';

const EXPORTS = [
  'all_courses/1',
  'course_sessions/2',
  'course_duration/2',
  'course_group/2',
  'course_equipment/2',
  'room_capacity/2',
  'room_equipment/2',
  'room_building/2',
  'room_energy/2',
  'instructor_of/2',
  'instructor_available/2',
  'group_size_of/2',
  'building_max_energy/2',
  'group_size/2',
  'teaches/2',
  'availability/2',
  'building/2',
  'timeslot/1',
  'next_slot/2'
];

function assertArray(value, name) {
  if (!Array.isArray(value)) {
    throw new Error(`${name} must be an array`);
  }
}

function assertPositiveInteger(value, name) {
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
}

export function toPrologAtom(value) {
  if (typeof value !== 'string' && typeof value !== 'number') {
    throw new Error('Atom value must be a string or number');
  }

  const atom = String(value)
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, '_')
    .replace(/[^a-z0-9_]/g, '')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');

  if (!/^[a-z][a-z0-9_]*$/.test(atom)) {
    throw new Error(`Invalid Prolog atom: ${value}`);
  }

  return atom;
}

function atomList(values, name) {
  assertArray(values, name);
  return values.map((value) => toPrologAtom(value));
}

export function validateDataset(dataset) {
  if (!dataset || typeof dataset !== 'object') {
    throw new Error('Dataset must be a JSON object');
  }

  assertArray(dataset.courses, 'courses');
  assertArray(dataset.rooms, 'rooms');
  assertArray(dataset.buildings, 'buildings');
  assertArray(dataset.groups, 'groups');
  assertArray(dataset.timeslots, 'timeslots');
  assertArray(dataset.nextSlots, 'nextSlots');
  assertArray(dataset.availability, 'availability');

  const courseIds = new Set();
  const roomIds = new Set();
  const buildingIds = new Set();
  const groupIds = new Set();
  const timeslots = new Set(atomList(dataset.timeslots, 'timeslots'));

  if (timeslots.size === 0) {
    throw new Error('timeslots must not be empty');
  }

  dataset.buildings.forEach((building, index) => {
    const id = toPrologAtom(building.id);
    assertPositiveInteger(building.maxEnergy, `buildings[${index}].maxEnergy`);
    buildingIds.add(id);
  });

  dataset.groups.forEach((group, index) => {
    const id = toPrologAtom(group.id);
    assertPositiveInteger(group.size, `groups[${index}].size`);
    groupIds.add(id);
  });

  dataset.rooms.forEach((room, index) => {
    const id = toPrologAtom(room.id);
    const building = toPrologAtom(room.building);
    assertPositiveInteger(room.capacity, `rooms[${index}].capacity`);
    assertPositiveInteger(room.energy, `rooms[${index}].energy`);
    toPrologAtom(room.equipment);

    if (!buildingIds.has(building)) {
      throw new Error(`rooms[${index}].building references unknown building`);
    }

    roomIds.add(id);
  });

  dataset.courses.forEach((course, index) => {
    const id = toPrologAtom(course.id);
    const group = toPrologAtom(course.group);
    assertPositiveInteger(course.sessions, `courses[${index}].sessions`);
    assertPositiveInteger(course.duration, `courses[${index}].duration`);
    toPrologAtom(course.equipment);
    toPrologAtom(course.instructor);

    if (!groupIds.has(group)) {
      throw new Error(`courses[${index}].group references unknown group`);
    }

    courseIds.add(id);
  });

  if (courseIds.size === 0) {
    throw new Error('courses must not be empty');
  }

  if (roomIds.size === 0) {
    throw new Error('rooms must not be empty');
  }

  dataset.nextSlots.forEach((pair, index) => {
    if (!Array.isArray(pair) || pair.length !== 2) {
      throw new Error(`nextSlots[${index}] must be a pair`);
    }

    const from = toPrologAtom(pair[0]);
    const to = toPrologAtom(pair[1]);

    if (!timeslots.has(from) || !timeslots.has(to)) {
      throw new Error(`nextSlots[${index}] references an unknown timeslot`);
    }
  });

  dataset.availability.forEach((entry, index) => {
    toPrologAtom(entry.instructor);
    const slots = atomList(entry.slots, `availability[${index}].slots`);

    if (slots.length === 0) {
      throw new Error(`availability[${index}].slots must not be empty`);
    }

    slots.forEach((slot) => {
      if (!timeslots.has(slot)) {
        throw new Error(`availability[${index}] references unknown slot ${slot}`);
      }
    });
  });
}

function moduleHeader() {
  return [
    ':- module(facts, [',
    ...EXPORTS.map((name, index) => `    ${name}${index === EXPORTS.length - 1 ? '' : ','}`),
    ']).',
    ''
  ].join('\n');
}

function accessors() {
  return `
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
`;
}

export async function generateFactsFile(dataset, outputPath) {
  validateDataset(dataset);

  const lines = [
    moduleHeader(),
    '%% Generated Data Structures',
    ''
  ];

  dataset.courses.forEach((course) => {
    lines.push(
      `course(${toPrologAtom(course.id)}, ${course.sessions}, ${course.duration}, ${toPrologAtom(course.group)}, ${toPrologAtom(course.equipment)}).`
    );
  });

  lines.push('');

  dataset.rooms.forEach((room) => {
    lines.push(
      `room(${toPrologAtom(room.id)}, ${room.capacity}, ${toPrologAtom(room.equipment)}, ${toPrologAtom(room.building)}, ${room.energy}).`
    );
  });

  lines.push('');

  dataset.buildings.forEach((building) => {
    lines.push(`building(${toPrologAtom(building.id)}, ${building.maxEnergy}).`);
  });

  lines.push('');

  dataset.timeslots.forEach((slot) => {
    lines.push(`timeslot(${toPrologAtom(slot)}).`);
  });

  lines.push('');

  dataset.nextSlots.forEach(([from, to]) => {
    lines.push(`next_slot(${toPrologAtom(from)}, ${toPrologAtom(to)}).`);
  });

  lines.push('');

  dataset.groups.forEach((group) => {
    lines.push(`group_size(${toPrologAtom(group.id)}, ${group.size}).`);
  });

  lines.push('');

  dataset.courses.forEach((course) => {
    lines.push(`teaches(${toPrologAtom(course.instructor)}, ${toPrologAtom(course.id)}).`);
  });

  lines.push('');

  dataset.availability.forEach((entry) => {
    const instructor = toPrologAtom(entry.instructor);
    entry.slots.forEach((slot) => {
      lines.push(`availability(${instructor}, ${toPrologAtom(slot)}).`);
    });
  });

  lines.push(accessors());

  await fs.writeFile(outputPath, `${lines.join('\n')}\n`, 'utf8');
}
