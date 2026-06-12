import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Navbar = () => {
  const { user, isAuthenticated, isAdmin, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (!isAuthenticated) return null;

  const isActive = (path) => location.pathname === path ? 'active' : '';

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <span role="img" aria-label="medical">⚕</span> Medi<span>Shift</span>
      </div>

      <div className="navbar-links">
        {isAdmin ? (
          <>
            <Link to="/admin/dashboard" className={isActive('/admin/dashboard')}>Dashboard</Link>
            <Link to="/admin/departments" className={isActive('/admin/departments')}>Departments</Link>
            <Link to="/admin/staff" className={isActive('/admin/staff')}>Staff</Link>
            <Link to="/admin/shifts" className={isActive('/admin/shifts')}>Shifts</Link>
            <Link to="/admin/leaves" className={isActive('/admin/leaves')}>Leaves</Link>
          </>
        ) : (
          <>
            <Link to="/staff/dashboard" className={isActive('/staff/dashboard')}>Dashboard</Link>
            <Link to="/staff/my-shifts" className={isActive('/staff/my-shifts')}>My Shifts</Link>
            <Link to="/staff/my-leaves" className={isActive('/staff/my-leaves')}>My Leaves</Link>
          </>
        )}
      </div>

      <div className="navbar-user">
        <span>{user?.email}</span>
        <span className="badge">{user?.role === 'admin' ? 'Admin' : 'Staff'}</span>
        <button className="btn-logout" onClick={handleLogout}>Logout</button>
      </div>
    </nav>
  );
};

export default Navbar;
