import React, { useState, useEffect } from 'react';
import api from '../../services/api';

const Departments = () => {
  const [departments, setDepartments] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [name, setName] = useState('');
  const [error, setError] = useState('');
  const [fieldError, setFieldError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchDepartments = async () => { try { const r = await api.get('/api/departments'); setDepartments(r.data.data || []); } catch (e) { console.error(e); } };
  useEffect(() => { fetchDepartments(); }, []);
  const showSuccess = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3000); };

  const openCreate = () => { setEditing(null); setName(''); setError(''); setFieldError(''); setShowModal(true); };
  const openEdit = (d) => { setEditing(d); setName(d.name); setError(''); setFieldError(''); setShowModal(true); };

  const validate = () => {
    const t = name.trim();
    if (!t) { setFieldError('Department name is required'); return false; }
    if (t.length < 2) { setFieldError('Name must be at least 2 characters'); return false; }
    if (t.length > 100) { setFieldError('Name cannot exceed 100 characters'); return false; }
    setFieldError(''); return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate() || loading) return;
    setError(''); setLoading(true);
    try {
      if (editing) { await api.put(`/api/departments/${editing.id}`, { name: name.trim() }); showSuccess('Department updated'); }
      else { await api.post('/api/departments', { name: name.trim() }); showSuccess('Department created'); }
      setShowModal(false); fetchDepartments();
    } catch (err) { setError(err.response?.data?.message || 'Operation failed'); } finally { setLoading(false); }
  };

  const handleDelete = async (d) => {
    if (!window.confirm(`Delete "${d.name}"?`)) return;
    try { await api.delete(`/api/departments/${d.id}`); showSuccess('Department deleted'); fetchDepartments(); }
    catch (err) { alert(err.response?.data?.message || 'Delete failed'); }
  };

  return (
    <div>
      <div className="page-header"><h1>Departments</h1><button className="btn btn-primary" onClick={openCreate}>+ Add Department</button></div>
      {success && <div className="alert alert-success">{success}</div>}
      <div className="table-container">
        <table>
          <thead><tr><th>Name</th><th>Created</th><th>Actions</th></tr></thead>
          <tbody>
            {departments.length === 0 ? <tr><td colSpan="3" className="empty-state">No departments found</td></tr> :
              departments.map(d => (<tr key={d.id}><td><strong>{d.name}</strong></td><td>{new Date(d.created_at).toLocaleDateString()}</td>
                <td><div className="btn-group"><button className="btn btn-sm btn-primary" onClick={() => openEdit(d)}>Edit</button>
                <button className="btn btn-sm btn-danger" onClick={() => handleDelete(d)}>Delete</button></div></td></tr>))}
          </tbody>
        </table>
      </div>
      {showModal && (<div className="modal-overlay" onClick={() => setShowModal(false)}><div className="modal" onClick={e => e.stopPropagation()}>
        <h2>{editing ? 'Edit Department' : 'Add Department'}</h2>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <div className="form-group"><label>Department Name</label>
            <input className="form-control" value={name} onChange={e => { setName(e.target.value); setFieldError(''); }} placeholder="e.g. Cardiology" />
            {fieldError && <small className="field-error">{fieldError}</small>}</div>
          <div className="modal-actions"><button type="button" className="btn" onClick={() => setShowModal(false)}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={loading}>{loading ? 'Saving...' : editing ? 'Update' : 'Create'}</button></div>
        </form></div></div>)}
    </div>
  );
};

export default Departments;
