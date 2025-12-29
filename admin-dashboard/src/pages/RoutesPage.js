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
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Route as RouteIcon,
} from '@mui/icons-material';
import { useForm, Controller, useFieldArray } from 'react-hook-form';
import { useRoutesStore } from '../store';

const RoutesPage = () => {
  const { routes, isLoading, fetchRoutes, createRoute, updateRoute, deleteRoute } = useRoutesStore();
  
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingRoute, setEditingRoute] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [routeToDelete, setRouteToDelete] = useState(null);

  const { control, handleSubmit, reset, formState: { errors } } = useForm({
    defaultValues: {
      name: '',
      description: '',
      stops: [],
      status: 'active',
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'stops',
  });

  useEffect(() => {
    fetchRoutes();
  }, [fetchRoutes]);

  const columns = [
    {
      field: 'name',
      headerName: 'Route Name',
      width: 200,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <RouteIcon sx={{ color: 'primary.main' }} />
          <Typography fontWeight="medium">{params.value}</Typography>
        </Box>
      ),
    },
    { field: 'description', headerName: 'Description', width: 250 },
    {
      field: 'stops',
      headerName: 'Stops',
      width: 120,
      valueGetter: (params) => params.row.stops?.length || 0,
      renderCell: (params) => (
        <Chip label={`${params.value} stops`} size="small" variant="outlined" />
      ),
    },
    {
      field: 'buses',
      headerName: 'Assigned Buses',
      width: 150,
      valueGetter: (params) => params.row.buses?.length || 0,
      renderCell: (params) => (
        <Chip label={`${params.value} buses`} size="small" color="primary" variant="outlined" />
      ),
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value || 'Active'}
          size="small"
          color={params.value === 'inactive' ? 'default' : 'success'}
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
    setEditingRoute(null);
    reset({
      name: '',
      description: '',
      stops: [],
      status: 'active',
    });
    setDialogOpen(true);
  };

  const handleEdit = (route) => {
    setEditingRoute(route);
    reset({
      name: route.name,
      description: route.description || '',
      stops: route.stops || [],
      status: route.status || 'active',
    });
    setDialogOpen(true);
  };

  const handleDeleteClick = (route) => {
    setRouteToDelete(route);
    setDeleteDialogOpen(true);
  };

  const handleDelete = async () => {
    if (routeToDelete) {
      await deleteRoute(routeToDelete._id);
      setDeleteDialogOpen(false);
      setRouteToDelete(null);
    }
  };

  const onSubmit = async (data) => {
    try {
      if (editingRoute) {
        await updateRoute(editingRoute._id, data);
      } else {
        await createRoute(data);
      }
      setDialogOpen(false);
    } catch (error) {
      console.error('Error saving route:', error);
    }
  };

  const addStop = () => {
    append({
      name: '',
      address: '',
      arrivalTime: '',
      latitude: '',
      longitude: '',
    });
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight="bold">
            Route Management
          </Typography>
          <Typography color="text.secondary">
            Configure bus routes and stops
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Add Route
        </Button>
      </Box>

      <Card>
        <CardContent>
          <DataGrid
            rows={routes}
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
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <form onSubmit={handleSubmit(onSubmit)}>
          <DialogTitle>
            {editingRoute ? 'Edit Route' : 'Add New Route'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="name"
                  control={control}
                  rules={{ required: 'Route name is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Route Name"
                      error={!!errors.name}
                      helperText={errors.name?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="status"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Status" select>
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                    </TextField>
                  )}
                />
              </Grid>
              <Grid item xs={12}>
                <Controller
                  name="description"
                  control={control}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Description"
                      multiline
                      rows={2}
                    />
                  )}
                />
              </Grid>
              
              {/* Stops Section */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="subtitle1" fontWeight="bold">
                    Route Stops
                  </Typography>
                  <Button size="small" startIcon={<AddIcon />} onClick={addStop}>
                    Add Stop
                  </Button>
                </Box>
                
                <List>
                  {fields.map((field, index) => (
                    <ListItem key={field.id} sx={{ bgcolor: 'grey.50', mb: 1, borderRadius: 1 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={4}>
                          <Controller
                            name={`stops.${index}.name`}
                            control={control}
                            render={({ field }) => (
                              <TextField {...field} fullWidth size="small" label="Stop Name" />
                            )}
                          />
                        </Grid>
                        <Grid item xs={12} sm={4}>
                          <Controller
                            name={`stops.${index}.address`}
                            control={control}
                            render={({ field }) => (
                              <TextField {...field} fullWidth size="small" label="Address" />
                            )}
                          />
                        </Grid>
                        <Grid item xs={12} sm={3}>
                          <Controller
                            name={`stops.${index}.arrivalTime`}
                            control={control}
                            render={({ field }) => (
                              <TextField
                                {...field}
                                fullWidth
                                size="small"
                                label="Arrival Time"
                                type="time"
                                InputLabelProps={{ shrink: true }}
                              />
                            )}
                          />
                        </Grid>
                        <Grid item xs={12} sm={1} sx={{ display: 'flex', alignItems: 'center' }}>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => remove(index)}
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Grid>
                      </Grid>
                    </ListItem>
                  ))}
                </List>
                
                {fields.length === 0 && (
                  <Typography color="text.secondary" sx={{ textAlign: 'center', py: 2 }}>
                    No stops added yet. Click "Add Stop" to add route stops.
                  </Typography>
                )}
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button type="submit" variant="contained">
              {editingRoute ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete route "{routeToDelete?.name}"?
            This will also remove all associated stops.
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

export default RoutesPage;
