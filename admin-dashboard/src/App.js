import React, { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './store';

// Layout
import Layout from './components/Layout';

// Pages
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import LiveTrackingPage from './pages/LiveTrackingPage';
import BusesPage from './pages/BusesPage';
import StudentsPage from './pages/StudentsPage';
import RoutesPage from './pages/RoutesPage';
import UsersPage from './pages/UsersPage';
import AlertsPage from './pages/AlertsPage';
import ReportsPage from './pages/ReportsPage';

// Protected Route Component
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, checkAuth } = useAuthStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="tracking" element={<LiveTrackingPage />} />
        <Route path="buses" element={<BusesPage />} />
        <Route path="students" element={<StudentsPage />} />
        <Route path="routes" element={<RoutesPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="alerts" element={<AlertsPage />} />
        <Route path="reports" element={<ReportsPage />} />
      </Route>
      
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default App;
