import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  TextField,
  MenuItem,
  Button,
} from '@mui/material';
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
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Download as DownloadIcon,
  DateRange as DateRangeIcon,
} from '@mui/icons-material';

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

const ReportsPage = () => {
  const [dateRange, setDateRange] = useState('week');
  const [reportType, setReportType] = useState('trips');

  // Sample data for charts
  const tripData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        label: 'Morning Trips',
        data: [22, 24, 23, 24, 25, 10, 8],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.5)',
      },
      {
        label: 'Evening Trips',
        data: [22, 23, 22, 24, 24, 10, 8],
        borderColor: 'rgb(255, 99, 132)',
        backgroundColor: 'rgba(255, 99, 132, 0.5)',
      },
    ],
  };

  const studentData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    datasets: [
      {
        label: 'Students Transported',
        data: [245, 252, 248, 250, 255],
        backgroundColor: 'rgba(54, 162, 235, 0.8)',
      },
    ],
  };

  const attendanceData = {
    labels: ['Present', 'Absent', 'Late'],
    datasets: [
      {
        data: [85, 10, 5],
        backgroundColor: [
          'rgba(75, 192, 192, 0.8)',
          'rgba(255, 99, 132, 0.8)',
          'rgba(255, 206, 86, 0.8)',
        ],
        borderWidth: 0,
      },
    ],
  };

  const alertsData = {
    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    datasets: [
      {
        label: 'Delays',
        data: [12, 8, 15, 10],
        backgroundColor: 'rgba(255, 206, 86, 0.8)',
      },
      {
        label: 'Breakdowns',
        data: [2, 1, 3, 1],
        backgroundColor: 'rgba(255, 159, 64, 0.8)',
      },
      {
        label: 'Emergencies',
        data: [0, 1, 0, 0],
        backgroundColor: 'rgba(255, 99, 132, 0.8)',
      },
    ],
  };

  const handleExport = () => {
    // In a real app, this would generate and download a report
    alert('Report export functionality would be implemented here');
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight="bold">
            Reports & Analytics
          </Typography>
          <Typography color="text.secondary">
            View and export system reports
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<DownloadIcon />}
          onClick={handleExport}
        >
          Export Report
        </Button>
      </Box>

      {/* Filters */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                select
                label="Date Range"
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value)}
                size="small"
              >
                <MenuItem value="today">Today</MenuItem>
                <MenuItem value="week">This Week</MenuItem>
                <MenuItem value="month">This Month</MenuItem>
                <MenuItem value="quarter">This Quarter</MenuItem>
                <MenuItem value="year">This Year</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                select
                label="Report Type"
                value={reportType}
                onChange={(e) => setReportType(e.target.value)}
                size="small"
              >
                <MenuItem value="trips">Trip Analytics</MenuItem>
                <MenuItem value="students">Student Analytics</MenuItem>
                <MenuItem value="alerts">Alert Analytics</MenuItem>
                <MenuItem value="performance">Performance</MenuItem>
              </TextField>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Charts */}
      <Grid container spacing={3}>
        {/* Trip Analytics */}
        <Grid item xs={12} lg={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Trip Analytics
              </Typography>
              <Box sx={{ height: 300 }}>
                <Line
                  data={tripData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'top' },
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

        {/* Attendance Overview */}
        <Grid item xs={12} lg={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Student Attendance
              </Typography>
              <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Doughnut
                  data={attendanceData}
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

        {/* Students Transported */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Daily Students Transported
              </Typography>
              <Box sx={{ height: 300 }}>
                <Bar
                  data={studentData}
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

        {/* Alerts by Type */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Alerts by Type
              </Typography>
              <Box sx={{ height: 300 }}>
                <Bar
                  data={alertsData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'top' },
                    },
                    scales: {
                      x: { stacked: true },
                      y: { stacked: true, beginAtZero: true },
                    },
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Summary Stats */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Summary Statistics
              </Typography>
              <Grid container spacing={3}>
                <Grid item xs={6} sm={3}>
                  <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'primary.light', borderRadius: 2 }}>
                    <Typography variant="h3" fontWeight="bold" color="primary.main">
                      324
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Total Trips
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                  <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'success.light', borderRadius: 2 }}>
                    <Typography variant="h3" fontWeight="bold" color="success.main">
                      98%
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      On-Time Rate
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                  <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'info.light', borderRadius: 2 }}>
                    <Typography variant="h3" fontWeight="bold" color="info.main">
                      1,250
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Students Served
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                  <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'warning.light', borderRadius: 2 }}>
                    <Typography variant="h3" fontWeight="bold" color="warning.main">
                      45
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Total Alerts
                    </Typography>
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ReportsPage;
