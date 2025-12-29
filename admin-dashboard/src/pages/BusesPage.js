import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  IconButton,
  Chip,
  Avatar,
  MenuItem,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  DirectionsBus as BusIcon,
} from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { useBusesStore, useUsersStore } from '../store';

const BusesPage = () => {
  const { buses, isLoading, fetchBuses, createBus, updateBus, deleteBus } = useBusesStore();
  const { users, fetchUsers } = useUsersStore();
  
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingBus, setEditingBus] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [busToDelete, setBusToDelete] = useState(null);

  const { control, handleSubmit, reset, formState: { errors } } = useForm();

  useEffect(() => {
    fetchBuses();
    fetchUsers();
  }, [fetchBuses, fetchUsers]);

  const drivers = users.filter((u) => u.role === 'driver');

  const columns = [
    {
      field: 'busNumber',
      headerName: 'Bus Number',
      width: 150,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Avatar sx={{ bgcolor: 'primary.light', width: 32, height: 32 }}>
            <BusIcon sx={{ fontSize: 18, color: 'primary.main' }} />
          </Avatar>
          <Typography fontWeight="medium">{params.value}</Typography>
        </Box>
      ),
    },
    { field: 'licensePlate', headerName: 'License Plate', width: 130 },
    { field: 'model', headerName: 'Model', width: 130 },
    { field: 'year', headerName: 'Year', width: 100 },
    { field: 'capacity', headerName: 'Capacity', width: 100 },
    {
      field: 'driver',
      headerName: 'Driver',
      width: 180,
      valueGetter: (params) => params.row.driver?.name || 'Not Assigned',
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value || 'Active'}
          size="small"
          color={params.value === 'maintenance' ? 'warning' : 'success'}
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      sortable: false,
      renderCell: (params) => (
        <Box>
          <IconButton
            size="small"
            onClick={() => handleEdit(params.row)}
            color="primary"
          >
            <EditIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            onClick={() => handleDeleteClick(params.row)}
            color="error"
          >
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Box>
      ),
    },
  ];

  const handleOpenDialog = () => {
    setEditingBus(null);
    reset({
      busNumber: '',
      licensePlate: '',
      model: '',
      year: new Date().getFullYear(),
      capacity: 40,
      driver: '',
      status: 'active',
    });
    setDialogOpen(true);
  };

  const handleEdit = (bus) => {
    setEditingBus(bus);
    reset({
      busNumber: bus.busNumber,
      licensePlate: bus.licensePlate,
      model: bus.model,
      year: bus.year,
      capacity: bus.capacity,
      driver: bus.driver?._id || '',
      status: bus.status || 'active',
    });
    setDialogOpen(true);
  };

  const handleDeleteClick = (bus) => {
    setBusToDelete(bus);
    setDeleteDialogOpen(true);
  };

  const handleDelete = async () => {
    if (busToDelete) {
      await deleteBus(busToDelete._id);
      setDeleteDialogOpen(false);
      setBusToDelete(null);
    }
  };

  const onSubmit = async (data) => {
    try {
      if (editingBus) {
        await updateBus(editingBus._id, data);
      } else {
        await createBus(data);
      }
      setDialogOpen(false);
    } catch (error) {
      console.error('Error saving bus:', error);
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight="bold">
            Bus Management
          </Typography>
          <Typography color="text.secondary">
            Manage your school bus fleet
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Add Bus
        </Button>
      </Box>

      <Card>
        <CardContent>
          <DataGrid
            rows={buses}
            columns={columns}
            getRowId={(row) => row._id}
            loading={isLoading}
            autoHeight
            pageSizeOptions={[10, 25, 50]}
            initialState={{
              pagination: { paginationModel: { pageSize: 10 } },
            }}
            disableRowSelectionOnClick
            sx={{
              border: 'none',
              '& .MuiDataGrid-cell:focus': { outline: 'none' },
            }}
          />
        </CardContent>
      </Card>

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <form onSubmit={handleSubmit(onSubmit)}>
          <DialogTitle>
            {editingBus ? 'Edit Bus' : 'Add New Bus'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={6}>
                <Controller
                  name="busNumber"
                  control={control}
                  rules={{ required: 'Bus number is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Bus Number"
                      error={!!errors.busNumber}
                      helperText={errors.busNumber?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={6}>
                <Controller
                  name="licensePlate"
                  control={control}
                  rules={{ required: 'License plate is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="License Plate"
                      error={!!errors.licensePlate}
                      helperText={errors.licensePlate?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={6}>
                <Controller
                  name="model"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Model" />
                  )}
                />
              </Grid>
              <Grid item xs={6}>
                <Controller
                  name="year"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Year" type="number" />
                  )}
                />
              </Grid>
              <Grid item xs={6}>
                <Controller
                  name="capacity"
                  control={control}
                  rules={{ required: 'Capacity is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Capacity"
                      type="number"
                      error={!!errors.capacity}
                      helperText={errors.capacity?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={6}>
                <Controller
                  name="driver"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Driver" select>
                      <MenuItem value="">No Driver</MenuItem>
                      {drivers.map((driver) => (
                        <MenuItem key={driver._id} value={driver._id}>
                          {driver.name}
                        </MenuItem>
                      ))}
                    </TextField>
                  )}
                />
              </Grid>
              <Grid item xs={12}>
                <Controller
                  name="status"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Status" select>
                      <MenuItem value="active">Active</MenuItem>
                      <MenuItem value="maintenance">Maintenance</MenuItem>
                      <MenuItem value="inactive">Inactive</MenuItem>
                    </TextField>
                  )}
                />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button type="submit" variant="contained">
              {editingBus ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete bus "{busToDelete?.busNumber}"?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDelete} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default BusesPage;
