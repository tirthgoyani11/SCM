import React, { useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  IconButton,
  Chip,
  Avatar,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import {
  Warning as WarningIcon,
  CheckCircle as ResolveIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useAlertsStore } from '../store';

const AlertsPage = () => {
  const { alerts, isLoading, fetchAlerts, resolveAlert } = useAlertsStore();

  useEffect(() => {
    fetchAlerts();
  }, [fetchAlerts]);

  const getAlertColor = (type) => {
    switch (type) {
      case 'accident':
      case 'emergency':
        return 'error';
      case 'breakdown':
        return 'warning';
      case 'medical':
        return 'info';
      case 'delay':
        return 'secondary';
      default:
        return 'default';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'resolved':
        return 'success';
      case 'acknowledged':
        return 'info';
      case 'pending':
      default:
        return 'warning';
    }
  };

  const columns = [
    {
      field: 'type',
      headerName: 'Type',
      width: 140,
      renderCell: (params) => (
        <Chip
          icon={<WarningIcon />}
          label={params.value}
          size="small"
          color={getAlertColor(params.value)}
        />
      ),
    },
    {
      field: 'message',
      headerName: 'Message',
      width: 300,
      renderCell: (params) => (
        <Typography variant="body2" sx={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
          {params.value}
        </Typography>
      ),
    },
    {
      field: 'bus',
      headerName: 'Bus',
      width: 120,
      valueGetter: (params) => params.row.bus?.busNumber || '-',
    },
    {
      field: 'driver',
      headerName: 'Driver',
      width: 150,
      valueGetter: (params) => params.row.driver?.name || '-',
    },
    {
      field: 'location',
      headerName: 'Location',
      width: 150,
      valueGetter: (params) => {
        const loc = params.row.location;
        if (!loc || !loc.coordinates) return '-';
        return `${loc.coordinates[1].toFixed(4)}, ${loc.coordinates[0].toFixed(4)}`;
      },
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 130,
      renderCell: (params) => (
        <Chip
          label={params.value || 'pending'}
          size="small"
          color={getStatusColor(params.value)}
          variant="outlined"
        />
      ),
    },
    {
      field: 'createdAt',
      headerName: 'Time',
      width: 180,
      valueFormatter: (params) => {
        if (!params.value) return '-';
        return format(new Date(params.value), 'MMM dd, yyyy HH:mm');
      },
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 100,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          color="success"
          onClick={() => handleResolve(params.row._id)}
          disabled={params.row.status === 'resolved'}
          title="Mark as Resolved"
        >
          <ResolveIcon />
        </IconButton>
      ),
    },
  ];

  const handleResolve = async (alertId) => {
    try {
      await resolveAlert(alertId);
    } catch (error) {
      console.error('Error resolving alert:', error);
    }
  };

  const pendingAlerts = alerts.filter((a) => a.status !== 'resolved');
  const resolvedAlerts = alerts.filter((a) => a.status === 'resolved');

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight="bold">
            Emergency Alerts
          </Typography>
          <Typography color="text.secondary">
            Monitor and manage emergency alerts from drivers
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={fetchAlerts}
        >
          Refresh
        </Button>
      </Box>

      {/* Summary Cards */}
      <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
        <Card sx={{ flex: 1 }}>
          <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar sx={{ bgcolor: 'warning.light', width: 48, height: 48 }}>
              <WarningIcon sx={{ color: 'warning.main' }} />
            </Avatar>
            <Box>
              <Typography variant="h4" fontWeight="bold">
                {pendingAlerts.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Pending Alerts
              </Typography>
            </Box>
          </CardContent>
        </Card>
        
        <Card sx={{ flex: 1 }}>
          <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar sx={{ bgcolor: 'success.light', width: 48, height: 48 }}>
              <ResolveIcon sx={{ color: 'success.main' }} />
            </Avatar>
            <Box>
              <Typography variant="h4" fontWeight="bold">
                {resolvedAlerts.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Resolved Alerts
              </Typography>
            </Box>
          </CardContent>
        </Card>
        
        <Card sx={{ flex: 1 }}>
          <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar sx={{ bgcolor: 'error.light', width: 48, height: 48 }}>
              <WarningIcon sx={{ color: 'error.main' }} />
            </Avatar>
            <Box>
              <Typography variant="h4" fontWeight="bold">
                {alerts.filter((a) => a.type === 'emergency' || a.type === 'accident').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Critical Alerts
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Box>

      <Card>
        <CardContent>
          <DataGrid
            rows={alerts}
            columns={columns}
            getRowId={(row) => row._id}
            loading={isLoading}
            autoHeight
            pageSizeOptions={[10, 25, 50]}
            initialState={{
              pagination: { paginationModel: { pageSize: 10 } },
              sorting: {
                sortModel: [{ field: 'createdAt', sort: 'desc' }],
              },
            }}
            disableRowSelectionOnClick
            getRowClassName={(params) => {
              if (params.row.status !== 'resolved' && 
                  (params.row.type === 'emergency' || params.row.type === 'accident')) {
                return 'critical-row';
              }
              return '';
            }}
            sx={{
              border: 'none',
              '& .MuiDataGrid-cell:focus': { outline: 'none' },
              '& .critical-row': {
                bgcolor: 'error.light',
                '&:hover': {
                  bgcolor: 'error.light',
                },
              },
            }}
          />
        </CardContent>
      </Card>
    </Box>
  );
};

export default AlertsPage;
