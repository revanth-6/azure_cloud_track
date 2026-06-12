import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';

const Dashboard = () => {
  const [shifts, setShifts] = useState([]);
  const [leaves, setLeaves] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try { const r = await api.get('/api/shifts/my-shifts'); setShifts(r.data.data || []); } catch (e) { console.error('Shifts error:', e.message); setShifts([]); }
      try { const r = await api.get('/api/leaves/my-leaves'); setLeaves(r.data.data || []); } catch (e) { console.error('Leaves error:', e.message); setLeaves([]); }
      setLoading(false);
    };
    fetchData();
  }, []);

  if (loading) return <div className="loading">Loading dashboard...</div>;

  const today = new Date().toISOString().split('T')[0];
  const upcoming = shifts.filter(s => s.shift_date >= today);
  const pending = leaves.filter(l => l.status === 'pending');
  const approved = leaves.filter(l => l.status === 'approved');

  return (
    <div>
      <div className="page-header"><h1>My Dashboard</h1></div>
      <div className="stats-grid">
        <div className="stat-card" onClick={() => navigate('/staff/my-shifts')}><h3>Total Shifts</h3><div className="stat-value">{shifts.length}</div></div>
        <div className="stat-card" onClick={() => navigate('/staff/my-shifts')}><h3>Upcoming</h3><div className="stat-value">{upcoming.length}</div></div>
        <div className="stat-card" onClick={() => navigate('/staff/my-leaves')}><h3>Pending Leaves</h3><div className="stat-value">{pending.length}</div></div>
        <div className="stat-card" onClick={() => navigate('/staff/my-leaves')}><h3>Approved Leaves</h3><div className="stat-value">{approved.length}</div></div>
      </div>
      <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1.5rem' }}>
        <button className="btn btn-primary" onClick={() => navigate('/staff/my-shifts')}>View My Shifts</button>
        <button className="btn btn-success" onClick={() => navigate('/staff/my-leaves')}>Apply for Leave</button>
      </div>
      {upcoming.length > 0 && <div className="card"><h2 style={{ marginBottom: '1rem', fontSize: '1.1rem' }}>Upcoming Shifts</h2>
        <table><thead><tr><th>Date</th><th>Start</th><th>End</th><th>Type</th></tr></thead>
        <tbody>{upcoming.slice(0, 5).map(s => (<tr key={s.id}><td>{s.shift_date}</td><td>{s.start_time}</td><td>{s.end_time}</td>
          <td><span className={`badge badge-${s.shift_type}`}>{s.shift_type}</span></td></tr>))}</tbody></table></div>}
    </div>
  );
};
export default Dashboard;
