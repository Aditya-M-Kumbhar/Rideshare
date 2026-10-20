import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

// Preset demo users from seed data for instant examiner / viva testing
export const DEMO_USERS = [
  {
    userId: 1,
    name: 'Aarav Sharma',
    email: 'aarav.sharma@coep.ac.in',
    isDriver: true,
    isVerified: true,
    college: 'COEP Tech',
    roleLabel: 'COEP Driver'
  },
  {
    userId: 4,
    name: 'Priya Kulkarni',
    email: 'priya.k@coep.ac.in',
    isDriver: false,
    isVerified: true,
    college: 'COEP Tech',
    roleLabel: 'COEP Rider'
  },
  {
    userId: 3,
    name: 'Rohan Patil',
    email: 'rohan.patil@mitwpu.edu.in',
    isDriver: true,
    isVerified: true,
    college: 'MIT-WPU',
    roleLabel: 'MIT Driver'
  },
  {
    userId: 2,
    name: 'Ananya Deshmukh',
    email: 'ananya.d@pict.edu',
    isDriver: false,
    isVerified: true,
    college: 'PICT Pune',
    roleLabel: 'PICT Rider'
  },
  {
    userId: 6,
    name: 'Neha Shinde',
    email: 'neha.shinde@mitwpu.edu.in',
    isDriver: false,
    isVerified: false,
    college: 'MIT-WPU',
    roleLabel: 'Unverified Student'
  }
];

export function AuthProvider({ children }) {
  // Default to Aarav (User #1, Driver) so examiner can test immediately
  const [currentUser, setCurrentUser] = useState(() => {
    const saved = localStorage.getItem('campuspool_user');
    return saved ? JSON.parse(saved) : DEMO_USERS[0];
  });

  const [token, setToken] = useState(() => {
    return localStorage.getItem('campuspool_token') || 'demo_token';
  });

  const switchUser = (selectedUser) => {
    setCurrentUser(selectedUser);
    localStorage.setItem('campuspool_user', JSON.stringify(selectedUser));
  };

  const loginUser = (userData, userToken) => {
    setCurrentUser(userData);
    setToken(userToken);
    localStorage.setItem('campuspool_user', JSON.stringify(userData));
    localStorage.setItem('campuspool_token', userToken);
  };

  const logoutUser = () => {
    switchUser(DEMO_USERS[0]);
  };

  return (
    <AuthContext.Provider value={{ currentUser, token, switchUser, loginUser, logoutUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
