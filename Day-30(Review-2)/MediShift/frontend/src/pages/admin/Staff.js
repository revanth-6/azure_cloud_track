import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const phoneRegex = /^[0-9\s+\-()]{7,15}$/;

const Staff = () => {
  const [staff, setStaff] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ name: '', email: '', phone: '', department_id: '', password: '' });
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchData = async () => {
    try { const [s, d] = await Promise.all([api.get('/api/staff'), api.get('/api/departments')]); setStaff(s.data.data || []); setDepartments(d.data.data || []); }
    catch (e) { console.error(e); }
  };
  useEffect(() => { fetchData(); }, []);
  const showSuccess = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3000); };

  const openCreate = () => { setEditing(null); setForm({ name: '', email: '', phone: '', department_id: '', password: '' }); setError(''); setFieldErrors({}); setShowModal(true); };
  const openEdit = (s) => { setEditing(s); setForm({ name: s.name, email: s.email, phone: s.phone || '', department_id: s.department_id, password: '' }); setError(''); setFieldErrors({}); setShowModal(true); };

  const validate = () => {
    const e = {};
    if (!form.name.trim() || form.name.trim().length < 2) e.name = 'Name must be at least 2 characters';
    if (!editing) {
      if (!form.email.trim()) e.email = 'Email is required'; else if (!emailRegex.test(form.email)) e.email = 'Invalid email format';
      if (!form.password) e.password = 'Password is required'; else if (form.password.length < 6) e.password = 'Min 6 characters';
    }
    if (!form.phone.trim()) e.phone = 'Phone is required'; else if (!phoneRegex.test(form.phone.trim())) e.phone = 'Invalid phone format';
    if (!form.department_id) e.department_id = 'Department is required';
    setFieldErrors(e); return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate() || loading) return;
    setError(''); setLoading(true);
    try {
      if (editing) { await api.put(`/api/staff/${editing.id}`, { name: form.name, phone: form.phone, department_id: form.department_id }); showSuccess('Staff updated'); }
      else { await api.post('/api/staff', form); showSuccess('Staff created'); }
      setShowModal(false); fetchData();
    } catch (err) { setError(err.response?.data?.message || 'Operation failed'); } finally { setLoading(false); }
  };

  const handleDelete = async (s) => {
    if (!window.confirm(`Delete staff member "${s.name}"?`)) return;
    try { await api.delete(`/api/staff/${s.id}`); showSuccess('Staff deleted'); fetchData(); }
    catch (err) { alert(err.response?.data?.message || 'Delete failed'); }
  };

  const FE = ({ field }) => fieldErrors[field] ? <small className="field-error">{fieldErrors[field]}</small> : null;

  return (
    <div>
      <div className="page-header"><h1>Staff Members</h1><button className="btn btn-primary" onClick={openCreate}>+ Add Staff</button></div>
      {success && <div className="alert alert-success">{success}</div>}
      <div className="table-container">
        <table>
          <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th>Department</th><th>Actions</th></tr></thead>
          <tbody>
            {staff.length === 0 ? <tr><td colSpan="5" className="empty-state">No staff members found</td></tr> :
              staff.map(s => (<tr key={s.id}><td><strong>{s.name}</strong></td><td>{s.email}</td><td>{s.phone || '—'}</td><td>{s.department?.name || '—'}</td>
                <td><div className="btn-group"><button className="btn btn-sm btn-primary" onClick={() => openEdit(s)}>Edit</button>
                <button className="btn btn-sm btn-danger" onClick={() => handleDelete(s)}>Delete</button></div></td></tr>))}
          </tbody>
        </table>
      </div>
      {showModal && (<div className="modal-overlay" onClick={() => setShowModal(false)}><div className="modal" onClick={e => e.stopPropagation()}>
        <h2>{editing ? 'Edit Staff' : 'Add Staff Member'}</h2>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <div className="form-group"><label>Full Name</label><input className="form-control" value={form.name} onChange={e => { setForm({ ...form, name: e.target.value }); setFieldErrors(p => ({ ...p, name: '' })); }} /><FE field="name" /></div>
          {!editing && (<><div className="form-group"><label>Email</label><input type="email" className="form-control" value={form.email} onChange={e => { setForm({ ...form, email: e.target.value }); setFieldErrors(p => ({ ...p, email: '' })); }} /><FE field="email" /></div>
          <div className="form-group"><label>Password</label><input type="password" className="form-control" value={form.password} onChange={e => { setForm({ ...form, password: e.target.value }); setFieldErrors(p => ({ ...p, password: '' })); }} /><FE field="password" /></div></>)}
          <div className="form-group"><label>Phone</label><input className="form-control" value={form.phone} onChange={e => { setForm({ ...form, phone: e.target.value }); setFieldErrors(p => ({ ...p, phone: '' })); }} /><FE field="phone" /></div>
          <div className="form-group"><label>Department</label><select className="form-control" value={form.department_id} onChange={e => { setForm({ ...form, department_id: e.target.value }); setFieldErrors(p => ({ ...p, department_id: '' })); }}>
            <option value="">Select Department</option>{departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}</select><FE field="department_id" /></div>
          <div className="modal-actions"><button type="button" className="btn" onClick={() => setShowModal(false)}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={loading}>{loading ? 'Saving...' : editing ? 'Update' : 'Create'}</button></div>
        </form></div></div>)}
    </div>
  );
};

export default Staff;
