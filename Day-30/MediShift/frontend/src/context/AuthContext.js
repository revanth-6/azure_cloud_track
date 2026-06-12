import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const useAuth = () => useContext(AuthContext);

const isTokenExpired = (token) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const payload = JSON.parse(window.atob(base64));
    const currentTime = Math.floor(Date.now() / 1000);
    return payload.exp < currentTime;
  } catch (e) {
    return true;
  }
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    try {
      const savedToken = localStorage.getItem('token');
      const savedUser = localStorage.getItem('user');

      if (savedToken && savedUser) {
        if (isTokenExpired(savedToken)) {
          localStorage.removeItem('token');
          localStorage.removeItem('user');
        } else {
          setToken(savedToken);
          setUser(JSON.parse(savedUser));
        }
      }
    } catch (e) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    }
    setLoading(false);
  }, []);

  const login = (tokenData, userData) => {
    localStorage.setItem('token', tokenData);
    localStorage.setItem('user', JSON.stringify(userData));
    setToken(tokenData);
    setUser(userData);
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
    setUser(null);
  };

  const value = {
    user,
    token,
    loading,
    login,
    logout,
    isAuthenticated: !!token,
    isAdmin: user?.role === 'admin',
    isStaff: user?.role === 'staff'
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
