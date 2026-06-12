import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const Leaves = () => {
  const [leaves, setLeaves] = useState([]);
  const [staff, setStaff] = useState([]);
  const [success, setSuccess] = useState('');
  const [actionLoading, setActionLoading] = useState(null);

  const fetchData = async () => {
    try { const [l, s] = await Promise.all([api.get('/api/leaves'), api.get('/api/staff')]); setLeaves(l.data.data || []); setStaff(s.data.data || []); }
    catch (e) { console.error(e); }
  };
  useEffect(() => { fetchData(); }, []);
  const getStaffName = (id) => { const s = staff.find(st => st.id === id); return s ? s.name : 'Unknown'; };
  const showSuccess = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3000); };

  const handleAction = async (leave, status) => {
    if (!window.confirm(`${status === 'approved' ? 'Approve' : 'Reject'} this leave?`)) return;
    setActionLoading(leave.id);
    try { await api.put(`/api/leaves/${leave.id}`, { status }); showSuccess(`Leave ${status}`); fetchData(); }
    catch (err) { alert(err.response?.data?.message || 'Failed'); } finally { setActionLoading(null); }
  };

  return (
    <div>
      <div className="page-header"><h1>Leave Requests</h1></div>
      {success && <div className="alert alert-success">{success}</div>}
      <div className="table-container"><table>
        <thead><tr><th>Staff</th><th>From</th><th>To</th><th>Reason</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>{leaves.length === 0 ? <tr><td colSpan="6" className="empty-state">No leave requests</td></tr> :
          leaves.map(l => (<tr key={l.id}><td><strong>{getStaffName(l.staff_id)}</strong></td><td>{l.from_date}</td><td>{l.to_date}</td><td>{l.reason}</td>
            <td><span className={`badge badge-${l.status}`}>{l.status}</span></td>
            <td>{l.status === 'pending' ? <div className="btn-group">
              <button className="btn btn-sm btn-success" disabled={actionLoading === l.id} onClick={() => handleAction(l, 'approved')}>Approve</button>
              <button className="btn btn-sm btn-danger" disabled={actionLoading === l.id} onClick={() => handleAction(l, 'rejected')}>Reject</button>
            </div> : <span style={{ color: '#94a3b8', fontSize: '0.8rem' }}>Decided</span>}</td></tr>))}
        </tbody></table></div>
    </div>
  );
};
export default Leaves;
