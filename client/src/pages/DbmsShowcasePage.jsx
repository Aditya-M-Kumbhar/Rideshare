import React, { useState, useEffect } from 'react';
import { Play, Database, Terminal, Clock, CheckCircle2, AlertCircle } from 'lucide-react';

export default function DbmsShowcasePage() {
  const [catalog, setCatalog] = useState([]);
  const [selectedQueryId, setSelectedQueryId] = useState('');
  const [currentEntry, setCurrentEntry] = useState(null);
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  // Fetch showcase catalog from server
  useEffect(() => {
    fetch('/api/dbms/queries')
      .then(r => r.json())
      .then(data => {
        if (Array.isArray(data) && data.length > 0) {
          setCatalog(data);
          setSelectedQueryId(data[0].id);
          setCurrentEntry(data[0]);
        }
      })
      .catch(err => setError('Failed to load showcase query catalog.'));
  }, []);

  const handleSelectQuery = (id) => {
    setSelectedQueryId(id);
    const item = catalog.find(q => q.id === id);
    setCurrentEntry(item);
    setResult(null);
    setError(null);
  };

  const handleRunQuery = async () => {
    if (!selectedQueryId) return;
    setRunning(true);
    setError(null);
    setResult(null);

    try {
      const res = await fetch('/api/dbms/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ queryId: selectedQueryId })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Query execution failed.');
      }

      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setRunning(false);
    }
  };

  // Automatically run first query on selection for convenience
  useEffect(() => {
    if (currentEntry) {
      handleRunQuery();
    }
  }, [selectedQueryId]);

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">DBMS Viva & Demonstration Suite</h1>
        <p className="page-subtitle">
          Interactive examiner testing workbench running live queries against MySQL 8 with architectural explanations.
        </p>
      </div>

      {error && (
        <div className="alert alert-error" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <AlertCircle size={16} />
          <span>{error}</span>
        </div>
      )}

      {/* Query Selector Bar */}
      <div className="card" style={{ marginBottom: 20, padding: '16px 20px' }}>
        <div className="form-group">
          <label className="form-label" style={{ fontWeight: 600 }}>
            Select DBMS Concept to Demonstrate:
          </label>
          <select
            value={selectedQueryId}
            onChange={e => handleSelectQuery(e.target.value)}
            style={{ fontSize: 14, padding: '10px 12px' }}
          >
            {catalog.map(item => (
              <option key={item.id} value={item.id}>
                [{item.category}] — {item.title}
              </option>
            ))}
          </select>
        </div>
      </div>

      {currentEntry && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Concept Header & Explanation */}
          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10, marginBottom: 12 }}>
              <div>
                <span className="badge badge-neutral" style={{ fontSize: 11, marginBottom: 4 }}>
                  {currentEntry.category}
                </span>
                <h2 style={{ fontSize: 18, fontWeight: 600 }}>{currentEntry.title}</h2>
              </div>

              <button
                className="btn btn-primary"
                onClick={handleRunQuery}
                disabled={running}
              >
                <Play size={14} />
                {running ? 'Executing in MySQL 8...' : 'Re-Run Live Query'}
              </button>
            </div>

            {/* Plain English WHY Explanation */}
            <div className="why-callout">
              <strong style={{ display: 'block', marginBottom: 2 }}>Why This Matters in DBMS:</strong>
              {currentEntry.why}
            </div>

            {/* Formatted SQL Query Viewer */}
            <div style={{ marginTop: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>
                  Executable SQL (from sql/99_test_queries.sql):
                </span>
                {result && (
                  <span style={{ fontSize: 12, color: 'var(--text-secondary)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                    <Clock size={12} /> Execution Latency: <strong>{result.executionTimeMs} ms</strong>
                  </span>
                )}
              </div>
              <pre className="code-block">{currentEntry.sql}</pre>
            </div>
          </div>

          {/* Live Results Table */}
          <div className="card">
            <h3 className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Database size={16} color="var(--accent-primary)" />
              Live Query Result Set
              {result?.rows && (
                <span style={{ fontSize: 12, fontWeight: 400, color: 'var(--text-secondary)' }}>
                  ({result.rows.length} row{result.rows.length === 1 ? '' : 's'} returned)
                </span>
              )}
            </h3>

            {running ? (
              <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
                Querying MySQL connection pool...
              </div>
            ) : !result || !result.rows || result.rows.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '30px 0', color: 'var(--text-secondary)', fontSize: 14 }}>
                Query returned an empty result set (0 rows).
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      {result.columns.map(col => (
                        <th key={col}>{col}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {result.rows.map((row, rIdx) => (
                      <tr key={rIdx}>
                        {result.columns.map(col => {
                          const val = row[col];
                          return (
                            <td key={col}>
                              {val === null || val === undefined ? (
                                <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>NULL</span>
                              ) : typeof val === 'object' ? (
                                <code style={{ fontFamily: 'var(--font-mono)', fontSize: 11 }}>
                                  {JSON.stringify(val)}
                                </code>
                              ) : (
                                String(val)
                              )}
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
