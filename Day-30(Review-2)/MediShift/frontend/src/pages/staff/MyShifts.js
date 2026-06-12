import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const MyShifts = () => {
  const [shifts, setShifts] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const fetch = async () => { try { const r = await api.get('/api/shifts/my-shifts'); setShifts(r.data.data || []); } catch (e) { console.error(e); } };
    fetch();
  }, []);

  const today = new Date().toISOString().split('T')[0];
  const filtered = shifts.filter(s => {
    if (filter === 'upcoming') return s.shift_date >= today;
    if (filter === 'past') return s.shift_date < today;
    return true;
  });

  return (
    <div>
      <div className="page-header"><h1>My Shifts</h1></div>
      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
        {['all', 'upcoming', 'past'].map(f => (
          <button key={f} className={`btn btn-sm ${filter === f ? 'btn-primary' : ''}`} style={filter !== f ? { background: '#e2e8f0' } : {}}
            onClick={() => setFilter(f)}>{f.charAt(0).toUpperCase() + f.slice(1)}</button>
        ))}
      </div>
      <div className="table-container"><table>
        <thead><tr><th>Date</th><th>Start</th><th>End</th><th>Type</th></tr></thead>
        <tbody>{filtered.length === 0 ? <tr><td colSpan="4" className="empty-state">No shifts</td></tr> :
          filtered.map(s => (<tr key={s.id}><td><strong>{s.shift_date}</strong></td><td>{s.start_time}</td><td>{s.end_time}</td>
            <td><span className={`badge badge-${s.shift_type}`}>{s.shift_type}</span></td></tr>))}
        </tbody></table></div>
    </div>
  );
};
export default MyShifts;
