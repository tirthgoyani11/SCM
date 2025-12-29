import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import api from './api';

// Auth Store
export const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (email, password) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.post('/auth/login', { email, password });
          const { token, user } = response.data;
          
          if (user.role !== 'admin') {
            throw new Error('Access denied. Admin account required.');
          }
          
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
          set({ user, token, isAuthenticated: true, isLoading: false });
          return true;
        } catch (error) {
          set({ 
            error: error.response?.data?.message || error.message, 
            isLoading: false 
          });
          return false;
        }
      },

      logout: () => {
        delete api.defaults.headers.common['Authorization'];
        set({ user: null, token: null, isAuthenticated: false });
      },

      checkAuth: async () => {
        const { token } = get();
        if (!token) {
          set({ isAuthenticated: false });
          return;
        }
        
        try {
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
          const response = await api.get('/auth/me');
          set({ user: response.data, isAuthenticated: true });
        } catch (error) {
          set({ user: null, token: null, isAuthenticated: false });
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ token: state.token, user: state.user }),
    }
  )
);

// Dashboard Store
export const useDashboardStore = create((set) => ({
  stats: null,
  activeBuses: [],
  recentAlerts: [],
  isLoading: false,

  fetchDashboardData: async () => {
    set({ isLoading: true });
    try {
      const [statsRes, busesRes, alertsRes] = await Promise.all([
        api.get('/admin/stats'),
        api.get('/admin/buses/active'),
        api.get('/admin/alerts/recent'),
      ]);
      
      set({
        stats: statsRes.data,
        activeBuses: busesRes.data,
        recentAlerts: alertsRes.data,
        isLoading: false,
      });
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      set({ isLoading: false });
    }
  },
}));

// Buses Store
export const useBusesStore = create((set) => ({
  buses: [],
  selectedBus: null,
  isLoading: false,

  fetchBuses: async () => {
    set({ isLoading: true });
    try {
      const response = await api.get('/admin/buses');
      set({ buses: response.data, isLoading: false });
    } catch (error) {
      console.error('Error fetching buses:', error);
      set({ isLoading: false });
    }
  },

  createBus: async (busData) => {
    try {
      const response = await api.post('/admin/buses', busData);
      set((state) => ({ buses: [...state.buses, response.data] }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  updateBus: async (id, busData) => {
    try {
      const response = await api.put(`/admin/buses/${id}`, busData);
      set((state) => ({
        buses: state.buses.map((bus) => (bus._id === id ? response.data : bus)),
      }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  deleteBus: async (id) => {
    try {
      await api.delete(`/admin/buses/${id}`);
      set((state) => ({
        buses: state.buses.filter((bus) => bus._id !== id),
      }));
    } catch (error) {
      throw error;
    }
  },

  setSelectedBus: (bus) => set({ selectedBus: bus }),
}));

// Students Store
export const useStudentsStore = create((set) => ({
  students: [],
  isLoading: false,

  fetchStudents: async () => {
    set({ isLoading: true });
    try {
      const response = await api.get('/admin/students');
      set({ students: response.data, isLoading: false });
    } catch (error) {
      console.error('Error fetching students:', error);
      set({ isLoading: false });
    }
  },

  createStudent: async (studentData) => {
    try {
      const response = await api.post('/admin/students', studentData);
      set((state) => ({ students: [...state.students, response.data] }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  updateStudent: async (id, studentData) => {
    try {
      const response = await api.put(`/admin/students/${id}`, studentData);
      set((state) => ({
        students: state.students.map((s) => (s._id === id ? response.data : s)),
      }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  deleteStudent: async (id) => {
    try {
      await api.delete(`/admin/students/${id}`);
      set((state) => ({
        students: state.students.filter((s) => s._id !== id),
      }));
    } catch (error) {
      throw error;
    }
  },
}));

// Routes Store
export const useRoutesStore = create((set) => ({
  routes: [],
  isLoading: false,

  fetchRoutes: async () => {
    set({ isLoading: true });
    try {
      const response = await api.get('/admin/routes');
      set({ routes: response.data, isLoading: false });
    } catch (error) {
      console.error('Error fetching routes:', error);
      set({ isLoading: false });
    }
  },

  createRoute: async (routeData) => {
    try {
      const response = await api.post('/admin/routes', routeData);
      set((state) => ({ routes: [...state.routes, response.data] }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  updateRoute: async (id, routeData) => {
    try {
      const response = await api.put(`/admin/routes/${id}`, routeData);
      set((state) => ({
        routes: state.routes.map((r) => (r._id === id ? response.data : r)),
      }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  deleteRoute: async (id) => {
    try {
      await api.delete(`/admin/routes/${id}`);
      set((state) => ({
        routes: state.routes.filter((r) => r._id !== id),
      }));
    } catch (error) {
      throw error;
    }
  },
}));

// Users Store
export const useUsersStore = create((set) => ({
  users: [],
  isLoading: false,

  fetchUsers: async () => {
    set({ isLoading: true });
    try {
      const response = await api.get('/admin/users');
      set({ users: response.data, isLoading: false });
    } catch (error) {
      console.error('Error fetching users:', error);
      set({ isLoading: false });
    }
  },

  createUser: async (userData) => {
    try {
      const response = await api.post('/admin/users', userData);
      set((state) => ({ users: [...state.users, response.data] }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  updateUser: async (id, userData) => {
    try {
      const response = await api.put(`/admin/users/${id}`, userData);
      set((state) => ({
        users: state.users.map((u) => (u._id === id ? response.data : u)),
      }));
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  deleteUser: async (id) => {
    try {
      await api.delete(`/admin/users/${id}`);
      set((state) => ({
        users: state.users.filter((u) => u._id !== id),
      }));
    } catch (error) {
      throw error;
    }
  },
}));

// Alerts Store
export const useAlertsStore = create((set) => ({
  alerts: [],
  isLoading: false,

  fetchAlerts: async () => {
    set({ isLoading: true });
    try {
      const response = await api.get('/admin/alerts');
      set({ alerts: response.data, isLoading: false });
    } catch (error) {
      console.error('Error fetching alerts:', error);
      set({ isLoading: false });
    }
  },

  resolveAlert: async (id) => {
    try {
      const response = await api.put(`/admin/alerts/${id}/resolve`);
      set((state) => ({
        alerts: state.alerts.map((a) => (a._id === id ? response.data : a)),
      }));
    } catch (error) {
      throw error;
    }
  },
}));
