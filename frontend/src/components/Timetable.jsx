import React from 'react';

function splitSlot(slot) {
  const index = slot.indexOf('_');
  return {
    day: index === -1 ? slot : slot.slice(0, index),
    time: index === -1 ? slot : slot.slice(index + 1)
  };
}

function unique(values) {
  return [...new Set(values)];
}

export default function Timetable({ schedule, timeslots }) {
  const slotSource = timeslots.length
    ? timeslots
    : unique(schedule.flatMap((assignment) => assignment.occupiedSlots));

  const parsedSlots = slotSource.map((slot) => ({ slot, ...splitSlot(slot) }));
  const days = unique(parsedSlots.map((item) => item.day));
  const times = unique(parsedSlots.map((item) => item.time));

  function slotFor(day, time) {
    return parsedSlots.find((item) => item.day === day && item.time === time)?.slot;
  }

  function assignmentsFor(slot) {
    if (!slot) {
      return [];
    }

    return schedule.filter((assignment) => assignment.occupiedSlots.includes(slot));
  }

  return (
    <section className="timetable-section">
      <div className="section-title">
        <div>
          <h2>Timetable</h2>
          <p>Rows are days, columns are atomic time slots, and filled cells show occupied sessions.</p>
        </div>
      </div>

      <div className="table-wrap">
        <table className="timetable">
          <thead>
            <tr>
              <th>Day</th>
              {times.map((time) => (
                <th key={time}>{time}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {days.map((day) => (
              <tr key={day}>
                <th>{day}</th>
                {times.map((time) => {
                  const slot = slotFor(day, time);
                  const assignments = assignmentsFor(slot);

                  return (
                    <td key={`${day}-${time}`} className={assignments.length ? 'occupied-cell' : ''}>
                      {assignments.map((assignment) => (
                        <div
                          className="slot-card"
                          key={`${assignment.course}-${assignment.session}-${assignment.room}`}
                        >
                          <strong>{assignment.course}</strong>
                          <span>{assignment.room}</span>
                          <span>S{assignment.session}</span>
                        </div>
                      ))}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
