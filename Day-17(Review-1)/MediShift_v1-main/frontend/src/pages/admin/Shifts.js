import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const getShiftType = (startTime) => {
  if (!startTime) return '';
  const hour = parseInt(startTime.split(':')[0]);
  if (hour >= 5 && hour < 12) return 'Morning 🌅';
  if (hour >= 12 && hour < 18) return 'Afternoon ☀️';
  return 'Night 🌙';
};

const Shifts = () => {
  const [shifts, setShifts] = useState([]);
  const [staff, setStaff] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ staff_id: '', shift_date: '', start_time: '', end_time: '' });
  const [error, setError] = useState('');
  const [warning, setWarning] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchData = async () => {
    try {
      const [shiftRes, staffRes] = await Promise.all([api.get('/api/shifts'), api.get('/api/staff')]);
      setShifts(shiftRes.data.data || []);
      setStaff(staffRes.data.data || []);
    } catch (err) { console.error('Failed to fetch data:', err); }
  };

  useEffect(() => { fetchData(); }, []);

  const getStaffName = (staffId) => { const s = staff.find(st => st.id === staffId); return s ? s.name : staffId; };
  const showSuccess = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3000); };
  const todayStr = new Date().toISOString().split('T')[0];

  const openCreate = () => {
    setEditing(null); setForm({ staff_id: '', shift_date: '', start_time: '', end_time: '' });
    setError(''); setWarning(''); setFieldErrors({}); setShowModal(true);
  };
  const openEdit = (shift) => {
    setEditing(shift); setForm({ staff_id: shift.staff_id, shift_date: shift.shift_date, start_time: shift.start_time, end_time: shift.end_time });
    setError(''); setWarning(''); setFieldErrors({}); setShowModal(true);
  };

  const validate = () => {
    const e = {};
    if (!form.staff_id) e.staff_id = 'Staff member is required';
    if (!form.shift_date) e.shift_date = 'Date is required';
    else if (form.shift_date < todayStr) e.shift_date = 'Cannot select a past date';
    if (!form.start_time) e.start_time = 'Start time is required';
    if (!form.end_time) e.end_time = 'End time is required';

    if (form.start_time && form.end_time) {
      const st = getShiftType(form.start_time);
      if (st !== 'Night 🌙' && form.end_time <= form.start_time) {
        e.end_time = 'End time must be after start time';
      }
    }
    setFieldErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate() || loading) return;
    setError(''); setWarning(''); setLoading(true);
    try {
      let response;
      if (editing) {
        response = await api.put(`/api/shifts/${editing.id}`, form);
        showSuccess('Shift updated successfully');
      } else {
        response = await api.post('/api/shifts', form);
        showSuccess('Shift created successfully');
      }
      if (response.data.warning) setWarning(response.data.warning);
      setShowModal(false); fetchData();
    } catch (err) {
      setError(err.response?.data?.message || 'Operation failed');
    } finally { setLoading(false); }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this shift?')) return;
    try {
      await api.delete(`/api/shifts/${id}`);
      showSuccess('Shift deleted successfully'); fetchData();
    } catch (err) { alert(err.response?.data?.message || 'Delete failed'); }
  };

  const FieldError = ({ field }) => fieldErrors[field] ? <small style={{ color: 'var(--danger)', fontSize: '0.78rem' }}>{fieldErrors[field]}</small> : null;

  return (
    <div>
      <div className="page-header">
        <h1>Shifts</h1>
        <button className="btn btn-primary" onClick={openCreate}>+ Create Shift</button>
      </div>

      {success && <div className="alert alert-success">{success}</div>}
      {warning && <div className="alert" style={{ background: 'var(--warning-bg)', color: 'var(--warning)', border: '1px solid #fbbf24' }}>{warning}</div>}

      <div className="table-container">
        <table>
          <thead><tr><th>Staff</th><th>Date</th><th>Start</th><th>End</th><th>Type</th><th>Actions</th></tr></thead>
          <tbody>
            {shifts.length === 0 ? (
              <tr><td colSpan="6" className="empty-state">No shifts found</td></tr>
            ) : shifts.map(shift => (
              <tr key={shift.id}>
                <td><strong>{getStaffName(shift.staff_id)}</strong></td>
                <td>{shift.shift_date}</td>
                <td>{shift.start_time}</td>
                <td>{shift.end_time}</td>
                <td><span className={`badge badge-${shift.shift_type}`}>{shift.shift_type}</span></td>
                <td>
                  <div className="btn-group">
                    <button className="btn btn-sm btn-primary" onClick={() => openEdit(shift)}>Edit</button>
                    <button className="btn btn-sm btn-danger" onClick={() => handleDelete(shift.id)}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editing ? 'Edit Shift' : 'Create Shift'}</h2>
            {error && <div className="alert alert-error">{error}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Staff Member</label>
                <select className="form-control" value={form.staff_id} onChange={e => setForm({...form, staff_id: e.target.value})}>
                  <option value="">Select Staff</option>
                  {staff.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
                <FieldError field="staff_id" />
              </div>
              <div className="form-group">
                <label>Date</label>
                <input type="date" className="form-control" min={todayStr} value={form.shift_date} onChange={e => setForm({...form, shift_date: e.target.value})} />
                <FieldError field="shift_date" />
              </div>
              <div className="form-group">
                <label>Start Time</label>
                <input type="time" className="form-control" value={form.start_time} onChange={e => setForm({...form, start_time: e.target.value})} />
                <FieldError field="start_time" />
              </div>
              <div className="form-group">
                <label>End Time</label>
                <input type="time" className="form-control" value={form.end_time} onChange={e => setForm({...form, end_time: e.target.value})} />
                <FieldError field="end_time" />
              </div>
              <div className="form-group">
                <label>Shift Type (auto-detected)</label>
                <div className="form-control" style={{ background: '#f1f5f9', fontWeight: 500 }}>
                  {getShiftType(form.start_time) || 'Enter start time to detect shift type'}
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={loading}>{loading ? 'Saving...' : editing ? 'Update' : 'Create'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Shifts;
