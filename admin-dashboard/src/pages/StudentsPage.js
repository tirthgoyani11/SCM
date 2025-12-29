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
  School as StudentIcon,
} from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { useStudentsStore, useBusesStore, useUsersStore } from '../store';

const StudentsPage = () => {
  const { students, isLoading, fetchStudents, createStudent, updateStudent, deleteStudent } = useStudentsStore();
  const { buses, fetchBuses } = useBusesStore();
  const { users, fetchUsers } = useUsersStore();
  
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [studentToDelete, setStudentToDelete] = useState(null);

  const { control, handleSubmit, reset, formState: { errors } } = useForm();

  useEffect(() => {
    fetchStudents();
    fetchBuses();
    fetchUsers();
  }, [fetchStudents, fetchBuses, fetchUsers]);

  const parents = users.filter((u) => u.role === 'parent');

  const columns = [
    {
      field: 'name',
      headerName: 'Student Name',
      width: 200,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Avatar sx={{ bgcolor: 'secondary.light', width: 32, height: 32 }}>
            {params.value?.[0]?.toUpperCase() || 'S'}
          </Avatar>
          <Typography fontWeight="medium">{params.value}</Typography>
        </Box>
      ),
    },
    { field: 'grade', headerName: 'Grade', width: 100 },
    { field: 'section', headerName: 'Section', width: 100 },
    { field: 'rollNumber', headerName: 'Roll No.', width: 100 },
    {
      field: 'parent',
      headerName: 'Parent',
      width: 180,
      valueGetter: (params) => params.row.parent?.name || 'Not Assigned',
    },
    {
      field: 'bus',
      headerName: 'Bus',
      width: 120,
      valueGetter: (params) => params.row.bus?.busNumber || 'Not Assigned',
    },
    {
      field: 'pickupStop',
      headerName: 'Pickup Stop',
      width: 150,
      valueGetter: (params) => params.row.pickupStop?.name || '-',
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
    setEditingStudent(null);
    reset({
      name: '',
      grade: '',
      section: '',
      rollNumber: '',
      parent: '',
      bus: '',
      pickupAddress: '',
      dropoffAddress: '',
      emergencyContact: '',
      status: 'active',
    });
    setDialogOpen(true);
  };

  const handleEdit = (student) => {
    setEditingStudent(student);
    reset({
      name: student.name,
      grade: student.grade,
      section: student.section,
      rollNumber: student.rollNumber,
      parent: student.parent?._id || '',
      bus: student.bus?._id || '',
      pickupAddress: student.pickupAddress || '',
      dropoffAddress: student.dropoffAddress || '',
      emergencyContact: student.emergencyContact || '',
      status: student.status || 'active',
    });
    setDialogOpen(true);
  };

  const handleDeleteClick = (student) => {
    setStudentToDelete(student);
    setDeleteDialogOpen(true);
  };

  const handleDelete = async () => {
    if (studentToDelete) {
      await deleteStudent(studentToDelete._id);
      setDeleteDialogOpen(false);
      setStudentToDelete(null);
    }
  };

  const onSubmit = async (data) => {
    try {
      if (editingStudent) {
        await updateStudent(editingStudent._id, data);
      } else {
        await createStudent(data);
      }
      setDialogOpen(false);
    } catch (error) {
      console.error('Error saving student:', error);
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight="bold">
            Student Management
          </Typography>
          <Typography color="text.secondary">
            Manage student registrations and bus assignments
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Add Student
        </Button>
      </Box>

      <Card>
        <CardContent>
          <DataGrid
            rows={students}
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
            {editingStudent ? 'Edit Student' : 'Add New Student'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="name"
                  control={control}
                  rules={{ required: 'Name is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Student Name"
                      error={!!errors.name}
                      helperText={errors.name?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={6} sm={3}>
                <Controller
                  name="grade"
                  control={control}
                  rules={{ required: 'Grade is required' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Grade"
                      error={!!errors.grade}
                      helperText={errors.grade?.message}
                    />
                  )}
                />
              </Grid>
              <Grid item xs={6} sm={3}>
                <Controller
                  name="section"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Section" />
                  )}
                />
              </Grid>
              <Grid item xs={6} sm={4}>
                <Controller
                  name="rollNumber"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Roll Number" />
                  )}
                />
              </Grid>
              <Grid item xs={6} sm={4}>
                <Controller
                  name="parent"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Parent" select>
                      <MenuItem value="">No Parent</MenuItem>
                      {parents.map((parent) => (
                        <MenuItem key={parent._id} value={parent._id}>
                          {parent.name}
                        </MenuItem>
                      ))}
                    </TextField>
                  )}
                />
              </Grid>
              <Grid item xs={6} sm={4}>
                <Controller
                  name="bus"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Bus" select>
                      <MenuItem value="">No Bus</MenuItem>
                      {buses.map((bus) => (
                        <MenuItem key={bus._id} value={bus._id}>
                          {bus.busNumber}
                        </MenuItem>
                      ))}
                    </TextField>
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="pickupAddress"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Pickup Address" multiline rows={2} />
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="dropoffAddress"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Dropoff Address" multiline rows={2} />
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="emergencyContact"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Emergency Contact" />
                  )}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="status"
                  control={control}
                  render={({ field }) => (
                    <TextField {...field} fullWidth label="Status" select>
                      <MenuItem value="active">Active</MenuItem>
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
              {editingStudent ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete student "{studentToDelete?.name}"?
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

export default StudentsPage;
