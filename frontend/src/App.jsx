import React, { useState } from 'react';
import DatasetEditor from './components/DatasetEditor.jsx';
import MetricsCards from './components/MetricsCards.jsx';
import Timetable from './components/Timetable.jsx';

const API_URL = 'http://localhost:3001';

export default function App() {
  const [result, setResult] = useState(null);
  const [timeslots, setTimeslots] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function requestSolver(path, options = {}) {
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const response = await fetch(`${API_URL}${path}`, options);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.details || data.error || 'Solver request failed');
      }

      if (data.error) {
        throw new Error(data.error);
      }

      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function runDefaultSolver() {
    setTimeslots([]);
    requestSolver('/api/solve');
  }

  function runDatasetSolver(dataset) {
    setTimeslots(dataset.timeslots || []);
    requestSolver('/api/solve-dataset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dataset)
    });
  }

  return (
    <main className="page">
      <section className="header">
        <div>
          <h1>Campus Scheduler</h1>
          <p>Run the SWI-Prolog optimizer with default facts or a custom JSON dataset.</p>
        </div>
        <button onClick={runDefaultSolver} disabled={loading}>
          {loading ? 'Running...' : 'Run Default Solver'}
        </button>
      </section>

      <DatasetEditor onRunDataset={runDatasetSolver} disabled={loading} />

      {error && <div className="error">{error}</div>}

      {result && (
        <>
          <MetricsCards result={result} />
          <Timetable schedule={result.schedule} timeslots={timeslots} />
        </>
      )}
    </main>
  );
}
