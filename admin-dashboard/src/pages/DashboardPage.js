import React, { useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  Chip,
} from '@mui/material';
import {
  DirectionsBus as BusIcon,
  People as PeopleIcon,
  Route as RouteIcon,
  Warning as WarningIcon,
  TrendingUp as TrendingUpIcon,
  AccessTime as TimeIcon,
} from '@mui/icons-material';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';
import { Line, Doughnut } from 'react-chartjs-2';
import { useDashboardStore } from '../store';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
);

const StatCard = ({ title, value, icon, color, trend }) => (
  <Card>
    <CardContent>
      <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <Box>
          <Typography color="text.secondary" variant="body2" gutterBottom>
            {title}
          </Typography>
          <Typography variant="h4" fontWeight="bold">
            {value}
          </Typography>
          {trend && (
            <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
              <TrendingUpIcon sx={{ fontSize: 16, color: 'success.main', mr: 0.5 }} />
              <Typography variant="body2" color="success.main">
                {trend}
              </Typography>
            </Box>
          )}
        </Box>
        <Avatar sx={{ bgcolor: `${color}.light`, width: 56, height: 56 }}>
          {React.cloneElement(icon, { sx: { color: `${color}.main` } })}
        </Avatar>
      </Box>
    </CardContent>
  </Card>
);

const DashboardPage = () => {
  const { stats, activeBuses, recentAlerts, isLoading, fetchDashboardData } = useDashboardStore();

  useEffect(() => {
    fetchDashboardData();
  }, [fetchDashboardData]);

  if (isLoading && !stats) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  const tripData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        label: 'Trips Completed',
        data: stats?.weeklyTrips || [45, 52, 49, 48, 55, 20, 15],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        fill: true,
        tension: 0.4,
      },
    ],
  };

  const studentData = {
    labels: ['Picked Up', 'Dropped Off', 'In Transit', 'Absent'],
    datasets: [
      {
        data: stats?.studentStatus || [120, 100, 30, 15],
        backgroundColor: [
          'rgba(75, 192, 192, 0.8)',
          'rgba(54, 162, 235, 0.8)',
          'rgba(255, 206, 86, 0.8)',
          'rgba(255, 99, 132, 0.8)',
        ],
        borderWidth: 0,
      },
    ],
  };

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom>
        Dashboard Overview
      </Typography>
      <Typography color="text.secondary" paragraph>
        Welcome back! Here's what's happening with your school bus system.
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Buses"
            value={stats?.activeBuses || activeBuses.length}
            icon={<BusIcon />}
            color="primary"
            trend="+5% from last week"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Students"
            value={stats?.totalStudents || 265}
            icon={<PeopleIcon />}
            color="success"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Routes"
            value={stats?.activeRoutes || 12}
            icon={<RouteIcon />}
            color="info"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Alerts"
            value={stats?.activeAlerts || recentAlerts.length}
            icon={<WarningIcon />}
            color="warning"
          />
        </Grid>
      </Grid>

      {/* Charts and Lists */}
      <Grid container spacing={3}>
        {/* Trip Chart */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Weekly Trip Activity
              </Typography>
              <Box sx={{ height: 300 }}>
                <Line
                  data={tripData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { display: false },
                    },
                    scales: {
                      y: { beginAtZero: true },
                    },
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Student Status */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Student Status Today
              </Typography>
              <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Doughnut
                  data={studentData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'bottom' },
                    },
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Active Buses */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Active Buses
              </Typography>
              <List>
                {(activeBuses.length > 0 ? activeBuses : [
                  { _id: 1, busNumber: 'BUS-001', driver: { name: 'John Smith' }, currentTrip: { route: { name: 'Route A' } } },
                  { _id: 2, busNumber: 'BUS-002', driver: { name: 'Mike Johnson' }, currentTrip: { route: { name: 'Route B' } } },
                  { _id: 3, busNumber: 'BUS-003', driver: { name: 'Sarah Davis' }, currentTrip: { route: { name: 'Route C' } } },
                ]).slice(0, 5).map((bus) => (
                  <ListItem key={bus._id} divider>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: 'success.light' }}>
                        <BusIcon sx={{ color: 'success.main' }} />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={bus.busNumber}
                      secondary={`Driver: ${bus.driver?.name || 'Unknown'}`}
                    />
                    <Chip
                      label={bus.currentTrip?.route?.name || 'On Route'}
                      size="small"
                      color="success"
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Recent Alerts */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Recent Alerts
              </Typography>
              <List>
                {(recentAlerts.length > 0 ? recentAlerts : [
                  { _id: 1, type: 'delay', message: 'Bus BUS-001 delayed by 10 minutes', createdAt: new Date().toISOString() },
                  { _id: 2, type: 'breakdown', message: 'Bus BUS-005 reported breakdown', createdAt: new Date().toISOString() },
                  { _id: 3, type: 'route_change', message: 'Route B modified due to construction', createdAt: new Date().toISOString() },
                ]).slice(0, 5).map((alert) => (
                  <ListItem key={alert._id} divider>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: getAlertColor(alert.type) + '.light' }}>
                        <WarningIcon sx={{ color: getAlertColor(alert.type) + '.main' }} />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={alert.message}
                      secondary={
                        <Box sx={{ display: 'flex', alignItems: 'center', mt: 0.5 }}>
                          <TimeIcon sx={{ fontSize: 14, mr: 0.5 }} />
                          {new Date(alert.createdAt).toLocaleTimeString()}
                        </Box>
                      }
                    />
                    <Chip
                      label={alert.type}
                      size="small"
                      color={getAlertColor(alert.type)}
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

const getAlertColor = (type) => {
  switch (type) {
    case 'accident':
    case 'emergency':
      return 'error';
    case 'breakdown':
    case 'delay':
      return 'warning';
    default:
      return 'info';
  }
};

export default DashboardPage;
