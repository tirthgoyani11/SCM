import React, { useEffect, useState, useCallback } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  Chip,
  TextField,
  InputAdornment,
  ToggleButtonGroup,
  ToggleButton,
  Paper,
} from '@mui/material';
import {
  DirectionsBus as BusIcon,
  Search as SearchIcon,
  Speed as SpeedIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { GoogleMap, LoadScript, Marker, InfoWindow } from '@react-google-maps/api';
import { io } from 'socket.io-client';
import { useBusesStore } from '../store';

const mapContainerStyle = {
  width: '100%',
  height: '100%',
};

const defaultCenter = {
  lat: 40.7128,
  lng: -74.006,
};

const LiveTrackingPage = () => {
  const { buses, fetchBuses } = useBusesStore();
  const [socket, setSocket] = useState(null);
  const [busLocations, setBusLocations] = useState({});
  const [selectedBus, setSelectedBus] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [map, setMap] = useState(null);

  useEffect(() => {
    fetchBuses();
  }, [fetchBuses]);

  useEffect(() => {
    const newSocket = io(process.env.REACT_APP_SOCKET_URL || 'http://localhost:5000', {
      auth: {
        token: JSON.parse(localStorage.getItem('auth-storage'))?.state?.token,
      },
    });

    newSocket.on('connect', () => {
      console.log('Connected to socket server');
      newSocket.emit('admin:subscribe');
    });

    newSocket.on('bus:location', (data) => {
      setBusLocations((prev) => ({
        ...prev,
        [data.busId]: {
          lat: data.latitude,
          lng: data.longitude,
          speed: data.speed,
          heading: data.heading,
          timestamp: new Date(),
        },
      }));
    });

    setSocket(newSocket);

    return () => {
      newSocket.disconnect();
    };
  }, []);

  const onLoad = useCallback((mapInstance) => {
    setMap(mapInstance);
  }, []);

  const handleBusClick = (bus) => {
    setSelectedBus(bus);
    const location = busLocations[bus._id];
    if (location && map) {
      map.panTo({ lat: location.lat, lng: location.lng });
      map.setZoom(15);
    }
  };

  const filteredBuses = buses.filter((bus) => {
    const matchesSearch = 
      bus.busNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      bus.driver?.name?.toLowerCase().includes(searchTerm.toLowerCase());
    
    if (filterStatus === 'all') return matchesSearch;
    if (filterStatus === 'active') return matchesSearch && busLocations[bus._id];
    if (filterStatus === 'inactive') return matchesSearch && !busLocations[bus._id];
    return matchesSearch;
  });

  const getMarkerIcon = (busId) => {
    const isActive = busLocations[busId];
    return {
      url: isActive 
        ? 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="20" cy="20" r="18" fill="#4CAF50" stroke="white" stroke-width="3"/>
              <path d="M12 18V26C12 26.5523 12.4477 27 13 27H27C27.5523 27 28 26.5523 28 26V18C28 16.3431 26.6569 15 25 15H15C13.3431 15 12 16.3431 12 18Z" fill="white"/>
              <rect x="14" y="23" width="3" height="2" rx="0.5" fill="#4CAF50"/>
              <rect x="23" y="23" width="3" height="2" rx="0.5" fill="#4CAF50"/>
            </svg>
          `)
        : 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="20" cy="20" r="18" fill="#9E9E9E" stroke="white" stroke-width="3"/>
              <path d="M12 18V26C12 26.5523 12.4477 27 13 27H27C27.5523 27 28 26.5523 28 26V18C28 16.3431 26.6569 15 25 15H15C13.3431 15 12 16.3431 12 18Z" fill="white"/>
              <rect x="14" y="23" width="3" height="2" rx="0.5" fill="#9E9E9E"/>
              <rect x="23" y="23" width="3" height="2" rx="0.5" fill="#9E9E9E"/>
            </svg>
          `),
      scaledSize: { width: 40, height: 40 },
    };
  };

  return (
    <Box sx={{ display: 'flex', height: 'calc(100vh - 128px)', gap: 2 }}>
      {/* Sidebar */}
      <Paper sx={{ width: 360, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Box sx={{ p: 2 }}>
          <Typography variant="h6" fontWeight="bold" gutterBottom>
            Live Bus Tracking
          </Typography>
          
          <TextField
            fullWidth
            size="small"
            placeholder="Search buses..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ mb: 2 }}
          />
          
          <ToggleButtonGroup
            value={filterStatus}
            exclusive
            onChange={(e, value) => value && setFilterStatus(value)}
            fullWidth
            size="small"
          >
            <ToggleButton value="all">All</ToggleButton>
            <ToggleButton value="active">Active</ToggleButton>
            <ToggleButton value="inactive">Inactive</ToggleButton>
          </ToggleButtonGroup>
        </Box>
        
        <List sx={{ flex: 1, overflow: 'auto' }}>
          {filteredBuses.map((bus) => {
            const location = busLocations[bus._id];
            const isActive = !!location;
            
            return (
              <ListItem
                key={bus._id}
                button
                selected={selectedBus?._id === bus._id}
                onClick={() => handleBusClick(bus)}
                sx={{
                  borderLeft: selectedBus?._id === bus._id ? 3 : 0,
                  borderColor: 'primary.main',
                }}
              >
                <ListItemAvatar>
                  <Avatar sx={{ bgcolor: isActive ? 'success.light' : 'grey.300' }}>
                    <BusIcon sx={{ color: isActive ? 'success.main' : 'grey.500' }} />
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={bus.busNumber}
                  secondary={
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        {bus.driver?.name || 'No driver assigned'}
                      </Typography>
                      {location && (
                        <Box sx={{ display: 'flex', alignItems: 'center', mt: 0.5 }}>
                          <SpeedIcon sx={{ fontSize: 14, mr: 0.5 }} />
                          <Typography variant="caption">
                            {location.speed?.toFixed(0) || 0} km/h
                          </Typography>
                        </Box>
                      )}
                    </Box>
                  }
                />
                <Chip
                  label={isActive ? 'Active' : 'Offline'}
                  size="small"
                  color={isActive ? 'success' : 'default'}
                />
              </ListItem>
            );
          })}
        </List>
        
        <Box sx={{ p: 2, borderTop: 1, borderColor: 'divider' }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: 'success.main', mr: 1 }} />
              <Typography variant="body2">Active: {Object.keys(busLocations).length}</Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: 'grey.400', mr: 1 }} />
              <Typography variant="body2">
                Offline: {buses.length - Object.keys(busLocations).length}
              </Typography>
            </Box>
          </Box>
        </Box>
      </Paper>

      {/* Map */}
      <Card sx={{ flex: 1, overflow: 'hidden' }}>
        <CardContent sx={{ height: '100%', p: '0 !important' }}>
          <LoadScript googleMapsApiKey={process.env.REACT_APP_GOOGLE_MAPS_KEY || ''}>
            <GoogleMap
              mapContainerStyle={mapContainerStyle}
              center={defaultCenter}
              zoom={12}
              onLoad={onLoad}
              options={{
                styles: [
                  {
                    featureType: 'poi',
                    elementType: 'labels',
                    stylers: [{ visibility: 'off' }],
                  },
                ],
              }}
            >
              {buses.map((bus) => {
                const location = busLocations[bus._id] || bus.lastLocation;
                if (!location) return null;
                
                return (
                  <Marker
                    key={bus._id}
                    position={{ lat: location.lat, lng: location.lng }}
                    icon={getMarkerIcon(bus._id)}
                    onClick={() => setSelectedBus(bus)}
                  />
                );
              })}
              
              {selectedBus && busLocations[selectedBus._id] && (
                <InfoWindow
                  position={busLocations[selectedBus._id]}
                  onCloseClick={() => setSelectedBus(null)}
                >
                  <Box sx={{ p: 1 }}>
                    <Typography variant="subtitle1" fontWeight="bold">
                      {selectedBus.busNumber}
                    </Typography>
                    <Typography variant="body2">
                      Driver: {selectedBus.driver?.name || 'Unknown'}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 2, mt: 1 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <SpeedIcon sx={{ fontSize: 16, mr: 0.5 }} />
                        <Typography variant="body2">
                          {busLocations[selectedBus._id].speed?.toFixed(0) || 0} km/h
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <PeopleIcon sx={{ fontSize: 16, mr: 0.5 }} />
                        <Typography variant="body2">
                          {selectedBus.capacity || 0} seats
                        </Typography>
                      </Box>
                    </Box>
                  </Box>
                </InfoWindow>
              )}
            </GoogleMap>
          </LoadScript>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LiveTrackingPage;
