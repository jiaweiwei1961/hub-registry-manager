import { createBrowserRouter } from 'react-router-dom';
import AppLayout from './components/Layout/AppLayout';
import { ProtectedRoute } from './components/Auth/ProtectedRoute';
import { AdminRoute } from './components/Auth/AdminRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Namespaces from './pages/Namespaces';
import NamespaceDetail from './pages/NamespaceDetail';
import Repositories from './pages/Repositories';
import RepositoryDetail from './pages/RepositoryDetail';
import System from './pages/System';
import Users from './pages/Users';
import AuditLogs from './pages/AuditLogs';

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <Login />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <AppLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Dashboard /> },
      { path: 'namespaces', element: <Namespaces /> },
      { path: 'namespaces/:id', element: <NamespaceDetail /> },
      { path: 'repositories', element: <Repositories /> },
      { path: 'repositories/:id', element: <RepositoryDetail /> },
      { path: 'system', element: <AdminRoute><System /></AdminRoute> },
      { path: 'users', element: <AdminRoute><Users /></AdminRoute> },
      { path: 'audit-logs', element: <AdminRoute><AuditLogs /></AdminRoute> },
    ],
  },
]);