import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const MyLeaves = () => {
  const [leaves, setLeaves] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ from_date: '', to_date: '', reason: '' });
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchLeaves = async () => { try { const r = await api.get('/api/leaves/my-leaves'); setLeaves(r.data.data || []); } catch (e) { console.error(e); } };
  useEffect(() => { fetchLeaves(); }, []);
  const todayStr = new Date().toISOString().split('T')[0];
  const showSuccessMsg = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3000); };

  const getDays = () => {
    if (!form.from_date || !form.to_date) return 0;
    return Math.max(0, Math.ceil((new Date(form.to_date) - new Date(form.from_date)) / (1000 * 60 * 60 * 24)) + 1);
  };

  const validate = () => {
    const e = {};
    if (!form.from_date) e.from_date = 'From date is required'; else if (form.from_date < todayStr) e.from_date = 'Cannot select past date';
    if (!form.to_date) e.to_date = 'To date is required'; else if (form.to_date < form.from_date) e.to_date = 'End cannot be before start'; else if (getDays() > 30) e.to_date = 'Max 30 days';
    if (!form.reason.trim()) e.reason = 'Reason is required'; else if (form.reason.trim().length < 10) e.reason = 'Min 10 characters'; else if (form.reason.trim().length > 500) e.reason = 'Max 500 characters';
    setFieldErrors(e); return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate() || loading) return;
    setError(''); setLoading(true);
    try {
      await api.post('/api/leaves', { from_date: form.from_date, to_date: form.to_date, reason: form.reason.trim() });
      setShowModal(false); showSuccessMsg('Leave submitted'); setForm({ from_date: '', to_date: '', reason: '' }); fetchLeaves();
    } catch (err) { setError(err.response?.data?.message || 'Failed'); } finally { setLoading(false); }
  };

  const FE = ({ field }) => fieldErrors[field] ? <small className="field-error">{fieldErrors[field]}</small> : null;

  return (
    <div>
      <div className="page-header"><h1>My Leaves</h1><button className="btn btn-primary" onClick={() => { setError(''); setFieldErrors({}); setShowModal(true); }}>+ Apply for Leave</button></div>
      {success && <div className="alert alert-success">{success}</div>}
      <div className="table-container"><table>
        <thead><tr><th>From</th><th>To</th><th>Reason</th><th>Status</th></tr></thead>
        <tbody>{leaves.length === 0 ? <tr><td colSpan="4" className="empty-state">No leave applications</td></tr> :
          leaves.map(l => (<tr key={l.id}><td>{l.from_date}</td><td>{l.to_date}</td><td>{l.reason}</td>
            <td><span className={`badge badge-${l.status}`}>{l.status}</span></td></tr>))}
        </tbody></table></div>
      {showModal && (<div className="modal-overlay" onClick={() => setShowModal(false)}><div className="modal" onClick={e => e.stopPropagation()}>
        <h2>Apply for Leave</h2>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <div className="form-group"><label>From Date</label><input type="date" className="form-control" min={todayStr} value={form.from_date} onChange={e => { setForm({ ...form, from_date: e.target.value }); setFieldErrors(p => ({ ...p, from_date: '' })); }} /><FE field="from_date" /></div>
          <div className="form-group"><label>To Date</label><input type="date" className="form-control" min={form.from_date || todayStr} value={form.to_date} onChange={e => { setForm({ ...form, to_date: e.target.value }); setFieldErrors(p => ({ ...p, to_date: '' })); }} /><FE field="to_date" />
            {form.from_date && form.to_date && !fieldErrors.to_date && <small style={{ color: '#3b82f6' }}>{getDays()} day(s)</small>}</div>
          <div className="form-group"><label>Reason</label><textarea className="form-control" value={form.reason} maxLength={500} placeholder="Explain reason (min 10 chars)..."
            onChange={e => { setForm({ ...form, reason: e.target.value }); setFieldErrors(p => ({ ...p, reason: '' })); }} /><div style={{ display: 'flex', justifyContent: 'space-between' }}><FE field="reason" /><small style={{ color: '#94a3b8' }}>{form.reason.length}/500</small></div></div>
          <div className="modal-actions"><button type="button" className="btn" onClick={() => setShowModal(false)}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={loading}>{loading ? 'Submitting...' : 'Submit'}</button></div>
        </form></div></div>)}
    </div>
  );
};
export default MyLeaves;
