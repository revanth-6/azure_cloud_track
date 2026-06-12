import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const ProtectedRoute = ({ children, role }) => {
  const { isAuthenticated, user, loading } = useAuth();

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  if (role && user.role !== role) {
    const redirect = user.role === 'admin' ? '/admin/dashboard' : '/staff/dashboard';
    return <Navigate to={redirect} replace />;
  }

  return children;
};

export default ProtectedRoute;
