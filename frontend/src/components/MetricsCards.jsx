import React from 'react';

function MetricCard({ label, value }) {
  return (
    <div className="metric-card">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

export default function MetricsCards({ result }) {
  return (
    <section className="metrics" aria-label="Optimization metrics">
      <MetricCard label="Score" value={result.score} />
      <MetricCard label="Total Energy" value={result.totalEnergy} />
      <MetricCard label="Load Imbalance" value={result.loadImbalance} />
      <MetricCard label="Room Usage Imbalance" value={result.roomUsageImbalance} />
    </section>
  );
}
