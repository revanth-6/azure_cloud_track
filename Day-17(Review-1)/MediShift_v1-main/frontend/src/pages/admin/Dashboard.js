import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';

const Dashboard = () => {
  const [stats, setStats] = useState({ departments: 0, staff: 0, shifts: 0, pending: 0 });
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchStats = async () => {
      let departments = 0, staffCount = 0, shifts = 0, pending = 0;
      try { const r = await api.get('/api/departments'); departments = (r.data.data || []).length; } catch (e) { console.error('Dept fetch failed:', e.message); }
      try { const r = await api.get('/api/staff'); staffCount = (r.data.data || []).length; } catch (e) { console.error('Staff fetch failed:', e.message); }
      try { const r = await api.get('/api/shifts'); shifts = (r.data.data || []).length; } catch (e) { console.error('Shifts fetch failed:', e.message); }
      try { const r = await api.get('/api/leaves'); pending = (r.data.data || []).filter(l => l.status === 'pending').length; } catch (e) { console.error('Leaves fetch failed:', e.message); }
      setStats({ departments, staff: staffCount, shifts, pending });
      setLoading(false);
    };
    fetchStats();
  }, []);

  if (loading) return <div className="loading">Loading dashboard...</div>;

  return (
    <div>
      <div className="page-header"><h1>Admin Dashboard</h1></div>
      <div className="stats-grid">
        <div className="stat-card" onClick={() => navigate('/admin/departments')}><h3>Departments</h3><div className="stat-value">{stats.departments}</div></div>
        <div className="stat-card" onClick={() => navigate('/admin/staff')}><h3>Staff Members</h3><div className="stat-value">{stats.staff}</div></div>
        <div className="stat-card" onClick={() => navigate('/admin/shifts')}><h3>Total Shifts</h3><div className="stat-value">{stats.shifts}</div></div>
        <div className="stat-card" onClick={() => navigate('/admin/leaves')}><h3>Pending Leaves</h3><div className="stat-value">{stats.pending}</div></div>
      </div>
    </div>
  );
};

export default Dashboard;
