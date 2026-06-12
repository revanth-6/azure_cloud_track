import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import Navbar from './components/Navbar';
import ProtectedRoute from './components/ProtectedRoute';
import Login from './pages/Login';
import AdminDashboard from './pages/admin/Dashboard';
import Departments from './pages/admin/Departments';
import Staff from './pages/admin/Staff';
import Shifts from './pages/admin/Shifts';
import Leaves from './pages/admin/Leaves';
import StaffDashboard from './pages/staff/Dashboard';
import MyShifts from './pages/staff/MyShifts';
import MyLeaves from './pages/staff/MyLeaves';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Navbar />
        <div className="container">
          <Routes>
            <Route path="/login" element={<Login />} />

            <Route path="/admin/dashboard" element={<ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>} />
            <Route path="/admin/departments" element={<ProtectedRoute role="admin"><Departments /></ProtectedRoute>} />
            <Route path="/admin/staff" element={<ProtectedRoute role="admin"><Staff /></ProtectedRoute>} />
            <Route path="/admin/shifts" element={<ProtectedRoute role="admin"><Shifts /></ProtectedRoute>} />
            <Route path="/admin/leaves" element={<ProtectedRoute role="admin"><Leaves /></ProtectedRoute>} />

            <Route path="/staff/dashboard" element={<ProtectedRoute role="staff"><StaffDashboard /></ProtectedRoute>} />
            <Route path="/staff/my-shifts" element={<ProtectedRoute role="staff"><MyShifts /></ProtectedRoute>} />
            <Route path="/staff/my-leaves" element={<ProtectedRoute role="staff"><MyLeaves /></ProtectedRoute>} />

            <Route path="/" element={<Navigate to="/login" replace />} />
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        </div>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
