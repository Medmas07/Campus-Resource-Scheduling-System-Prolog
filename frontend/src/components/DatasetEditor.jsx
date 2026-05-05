import React, { useState } from 'react';

const sampleDataset = {
  courses: [
    {
      id: 'programming_101',
      sessions: 2,
      duration: 2,
      group: 'group_a',
      equipment: 'computers',
      instructor: 'dr_sami'
    },
    {
      id: 'calculus_1',
      sessions: 1,
      duration: 1,
      group: 'group_b',
      equipment: 'projector',
      instructor: 'dr_ali'
    },
    {
      id: 'physics_lab',
      sessions: 1,
      duration: 3,
      group: 'group_c',
      equipment: 'lab_benches',
      instructor: 'dr_skander'
    }
  ],
  rooms: [
    {
      id: 'lab_alpha',
      capacity: 30,
      equipment: 'computers',
      building: 'engineering_block',
      energy: 8
    },
    {
      id: 'room_b201',
      capacity: 40,
      equipment: 'projector',
      building: 'science_block',
      energy: 5
    },
    {
      id: 'room_c105',
      capacity: 25,
      equipment: 'lab_benches',
      building: 'science_block',
      energy: 7
    }
  ],
  buildings: [
    { id: 'engineering_block', maxEnergy: 60 },
    { id: 'science_block', maxEnergy: 50 }
  ],
  groups: [
    { id: 'group_a', size: 28 },
    { id: 'group_b', size: 35 },
    { id: 'group_c', size: 22 }
  ],
  timeslots: [
    'monday_08_09',
    'monday_09_10',
    'monday_10_11',
    'monday_11_12',
    'tuesday_08_09',
    'tuesday_09_10',
    'tuesday_10_11',
    'tuesday_11_12',
    'wednesday_14_15',
    'wednesday_15_16'
  ],
  nextSlots: [
    ['monday_08_09', 'monday_09_10'],
    ['monday_09_10', 'monday_10_11'],
    ['monday_10_11', 'monday_11_12'],
    ['tuesday_08_09', 'tuesday_09_10'],
    ['tuesday_09_10', 'tuesday_10_11'],
    ['tuesday_10_11', 'tuesday_11_12'],
    ['wednesday_14_15', 'wednesday_15_16']
  ],
  availability: [
    { instructor: 'dr_sami', slots: ['monday_08_09', 'monday_09_10', 'tuesday_08_09', 'tuesday_09_10'] },
    { instructor: 'dr_ali', slots: ['monday_10_11', 'monday_11_12', 'wednesday_14_15', 'wednesday_15_16'] },
    { instructor: 'dr_skander', slots: ['tuesday_09_10', 'tuesday_10_11', 'tuesday_11_12', 'wednesday_14_15', 'wednesday_15_16'] }
  ]
};

export default function DatasetEditor({ onRunDataset, disabled }) {
  const [text, setText] = useState(JSON.stringify(sampleDataset, null, 2));
  const [validationError, setValidationError] = useState('');

  function loadSampleDataset() {
    setText(JSON.stringify(sampleDataset, null, 2));
    setValidationError('');
  }

  async function handleFileUpload(event) {
    const file = event.target.files?.[0];

    if (!file) {
      return;
    }

    setText(await file.text());
    setValidationError('');
  }

  function runDataset() {
    try {
      const dataset = JSON.parse(text);
      setValidationError('');
      onRunDataset(dataset);
    } catch (err) {
      setValidationError(`Invalid JSON: ${err.message}`);
    }
  }

  return (
    <section className="dataset-panel">
      <div className="section-title">
        <div>
          <h2>Custom Dataset</h2>
          <p>Paste JSON or upload a dataset file, then run the solver with generated facts.</p>
        </div>
        <div className="dataset-actions">
          <label className="file-button">
            Upload JSON
            <input type="file" accept="application/json,.json" onChange={handleFileUpload} />
          </label>
          <button type="button" className="secondary" onClick={loadSampleDataset}>
            Load Sample Dataset
          </button>
          <button type="button" onClick={runDataset} disabled={disabled}>
            {disabled ? 'Running...' : 'Run Solver with Dataset'}
          </button>
        </div>
      </div>

      <textarea
        value={text}
        onChange={(event) => setText(event.target.value)}
        spellCheck="false"
      />

      {validationError && <div className="error compact">{validationError}</div>}
    </section>
  );
}
