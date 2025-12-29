import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  IconButton,
  LinearProgress,
  Alert,
  AlertTitle,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Badge,
  Tooltip,
} from '@mui/material';
import {
  Videocam,
  VideocamOff,
  Speed,
  Warning,
  BatteryFull,
  BatteryAlert,
  SignalCellularAlt,
  SignalCellularOff,
  GpsFixed,
  Close,
  Fullscreen,
  VolumeUp,
  VolumeOff,
} from '@mui/icons-material';
import { io } from 'socket.io-client';
import { useStore } from '../store';

// IoT Device Card Component
const IoTDeviceCard = ({ bus, onViewStream }) => {
  const batteryLevel = bus.deviceInfo?.batteryLevel || 100;
  const isOnline = bus.deviceInfo?.isOnline ?? true;
  const hasStream = bus.streamAvailable || false;
  const speed = bus.currentLocation?.speed ? (bus.currentLocation.speed * 3.6).toFixed(1) : '0';

  return (
    <Card sx={{ height: '100%', position: 'relative' }}>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="flex-start">
          <Typography variant="h6" gutterBottom>
            {bus.busNumber}
          </Typography>
          <Box display="flex" gap={0.5}>
            {/* Online Status */}
            <Tooltip title={isOnline ? 'Online' : 'Offline'}>
              {isOnline ? (
                <SignalCellularAlt color="success" fontSize="small" />
              ) : (
                <SignalCellularOff color="error" fontSize="small" />
              )}
            </Tooltip>
            
            {/* Battery Status */}
            <Tooltip title={`Battery: ${batteryLevel}%`}>
              {batteryLevel > 20 ? (
                <BatteryFull color="success" fontSize="small" />
              ) : (
                <BatteryAlert color="warning" fontSize="small" />
              )}
            </Tooltip>
            
            {/* Stream Status */}
            <Tooltip title={hasStream ? 'Live Stream Available' : 'No Stream'}>
              {hasStream ? (
                <Badge color="error" variant="dot">
                  <Videocam color="primary" fontSize="small" />
                </Badge>
              ) : (
                <VideocamOff color="disabled" fontSize="small" />
              )}
            </Tooltip>
          </Box>
        </Box>

        <Typography color="textSecondary" variant="body2">
          Driver: {bus.driverName || 'Not Assigned'}
        </Typography>

        <Box mt={2}>
          <Grid container spacing={2}>
            <Grid item xs={6}>
              <Box display="flex" alignItems="center" gap={1}>
                <Speed color="primary" />
                <Typography variant="h6">{speed} km/h</Typography>
              </Box>
            </Grid>
            <Grid item xs={6}>
              <Box display="flex" alignItems="center" gap={1}>
                <GpsFixed color={isOnline ? 'success' : 'disabled'} />
                <Typography variant="body2">
                  {isOnline ? 'Tracking' : 'Offline'}
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Box>

        {/* Battery Bar */}
        <Box mt={2}>
          <Box display="flex" justifyContent="space-between" mb={0.5}>
            <Typography variant="caption">Battery</Typography>
            <Typography variant="caption">{batteryLevel}%</Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={batteryLevel}
            color={batteryLevel > 20 ? 'success' : 'warning'}
          />
        </Box>

        {/* View Stream Button */}
        {hasStream && (
          <Box mt={2}>
            <Button
              variant="contained"
              size="small"
              startIcon={<Videocam />}
              onClick={() => onViewStream(bus)}
              fullWidth
            >
              View Live Stream
            </Button>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

// Driving Events Alert Component
const DrivingEventAlert = ({ event, onDismiss }) => {
  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return 'error';
      case 'medium': return 'warning';
      default: return 'info';
    }
  };

  const getEventTitle = (type) => {
    switch (type) {
      case 'harsh_braking': return 'Harsh Braking Detected';
      case 'speeding': return 'Speeding Alert';
      case 'sharp_turn': return 'Sharp Turn Detected';
      default: return 'Driving Event';
    }
  };

  return (
    <Alert
      severity={getSeverityColor(event.severity)}
      onClose={onDismiss}
      sx={{ mb: 1 }}
    >
      <AlertTitle>{getEventTitle(event.type)}</AlertTitle>
      Bus: {event.busId} | {new Date(event.timestamp).toLocaleTimeString()}
      {event.data?.speed && ` | Speed: ${event.data.speed.toFixed(1)} km/h`}
    </Alert>
  );
};

// Live Stream Dialog Component
const LiveStreamDialog = ({ open, bus, onClose }) => {
  const videoRef = useRef(null);
  const [isConnecting, setIsConnecting] = useState(true);
  const [isMuted, setIsMuted] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (open && bus) {
      // Initialize WebRTC connection to view stream
      // This would connect to the driver's stream via backend signaling
      setIsConnecting(true);
      
      // Simulated connection delay
      setTimeout(() => {
        setIsConnecting(false);
      }, 2000);
    }

    return () => {
      // Cleanup WebRTC connection
    };
  }, [open, bus]);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Box display="flex" alignItems="center" gap={1}>
            <Videocam color="error" />
            <Typography>
              Live Stream - {bus?.busNumber}
            </Typography>
            <Chip label="LIVE" color="error" size="small" />
          </Box>
          <Box>
            <IconButton onClick={() => setIsMuted(!isMuted)}>
              {isMuted ? <VolumeOff /> : <VolumeUp />}
            </IconButton>
            <IconButton>
              <Fullscreen />
            </IconButton>
            <IconButton onClick={onClose}>
              <Close />
            </IconButton>
          </Box>
        </Box>
      </DialogTitle>
      <DialogContent>
        <Box
          sx={{
            width: '100%',
            height: 480,
            backgroundColor: '#000',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            borderRadius: 1,
            position: 'relative',
          }}
        >
          {isConnecting ? (
            <Box textAlign="center">
              <Typography color="white" mb={2}>
                Connecting to live stream...
              </Typography>
              <LinearProgress sx={{ width: 200 }} />
            </Box>
          ) : error ? (
            <Typography color="error">{error}</Typography>
          ) : (
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted={isMuted}
              style={{ width: '100%', height: '100%', objectFit: 'contain' }}
            />
          )}
          
          {/* Stream info overlay */}
          <Box
            sx={{
              position: 'absolute',
              bottom: 16,
              left: 16,
              backgroundColor: 'rgba(0,0,0,0.7)',
              color: 'white',
              padding: '4px 12px',
              borderRadius: 1,
            }}
          >
            <Typography variant="caption">
              {bus?.busNumber} | Driver: {bus?.driverName || 'Unknown'}
            </Typography>
          </Box>
        </Box>
      </DialogContent>
    </Dialog>
  );
};

// Main IoT Dashboard Page
const IoTDashboardPage = () => {
  const [buses, setBuses] = useState([]);
  const [drivingEvents, setDrivingEvents] = useState([]);
  const [selectedBus, setSelectedBus] = useState(null);
  const [streamDialogOpen, setStreamDialogOpen] = useState(false);
  const { token } = useStore();

  useEffect(() => {
    // Connect to Socket.IO
    const socket = io(process.env.REACT_APP_SOCKET_URL || 'http://localhost:5000', {
      auth: { token },
    });

    // Listen for IoT telemetry updates
    socket.on('bus:location', (data) => {
      setBuses((prev) => {
        const index = prev.findIndex((b) => b._id === data.busId);
        if (index >= 0) {
          const updated = [...prev];
          updated[index] = {
            ...updated[index],
            currentLocation: data.location,
            deviceInfo: data.deviceInfo,
          };
          return updated;
        }
        return prev;
      });
    });

    // Listen for driving alerts
    socket.on('driving:alert', (event) => {
      setDrivingEvents((prev) => [event, ...prev].slice(0, 10));
    });

    // Listen for stream availability
    socket.on('stream:available', (data) => {
      setBuses((prev) => {
        const index = prev.findIndex((b) => b._id === data.busId);
        if (index >= 0) {
          const updated = [...prev];
          updated[index] = { ...updated[index], streamAvailable: true };
          return updated;
        }
        return prev;
      });
    });

    socket.on('stream:stopped', (data) => {
      setBuses((prev) => {
        const index = prev.findIndex((b) => b._id === data.busId);
        if (index >= 0) {
          const updated = [...prev];
          updated[index] = { ...updated[index], streamAvailable: false };
          return updated;
        }
        return prev;
      });
    });

    // Initial data fetch
    fetchBuses();

    return () => {
      socket.disconnect();
    };
  }, [token]);

  const fetchBuses = async () => {
    try {
      const response = await fetch('/api/admin/buses', {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      setBuses(data);
    } catch (error) {
      console.error('Error fetching buses:', error);
    }
  };

  const handleViewStream = (bus) => {
    setSelectedBus(bus);
    setStreamDialogOpen(true);
  };

  const dismissEvent = (index) => {
    setDrivingEvents((prev) => prev.filter((_, i) => i !== index));
  };

  // Statistics
  const onlineBuses = buses.filter((b) => b.deviceInfo?.isOnline !== false).length;
  const lowBatteryBuses = buses.filter((b) => (b.deviceInfo?.batteryLevel || 100) < 20).length;
  const activeStreams = buses.filter((b) => b.streamAvailable).length;

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        IoT Edge Devices Dashboard
      </Typography>

      {/* Stats Summary */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Online Devices
              </Typography>
              <Typography variant="h3">
                {onlineBuses} / {buses.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Active Live Streams
              </Typography>
              <Typography variant="h3">{activeStreams}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Low Battery Alerts
              </Typography>
              <Typography variant="h3" color={lowBatteryBuses > 0 ? 'warning.main' : 'inherit'}>
                {lowBatteryBuses}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Driving Events */}
      {drivingEvents.length > 0 && (
        <Box mb={3}>
          <Typography variant="h6" gutterBottom>
            <Warning color="warning" sx={{ mr: 1, verticalAlign: 'middle' }} />
            Recent Driving Events
          </Typography>
          {drivingEvents.map((event, index) => (
            <DrivingEventAlert
              key={`${event.busId}-${event.timestamp}`}
              event={event}
              onDismiss={() => dismissEvent(index)}
            />
          ))}
        </Box>
      )}

      {/* IoT Devices Grid */}
      <Typography variant="h6" gutterBottom>
        IoT Edge Devices (Driver Phones)
      </Typography>
      <Grid container spacing={3}>
        {buses.map((bus) => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={bus._id}>
            <IoTDeviceCard bus={bus} onViewStream={handleViewStream} />
          </Grid>
        ))}
      </Grid>

      {/* Live Stream Dialog */}
      <LiveStreamDialog
        open={streamDialogOpen}
        bus={selectedBus}
        onClose={() => setStreamDialogOpen(false)}
      />
    </Box>
  );
};

export default IoTDashboardPage;
