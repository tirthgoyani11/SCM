import mongoose, { Schema, Document } from 'mongoose';

// User Interface
export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  email: string;
  password: string;
  role: 'parent' | 'driver' | 'admin';
  name: string;
  phone: string;
  profileImage?: string;
  fcmToken?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['parent', 'driver', 'admin'], required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  profileImage: { type: String },
  fcmToken: { type: String },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export const User = mongoose.model<IUser>('User', UserSchema);

// Student Interface
export interface IStudent extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  grade: string;
  section: string;
  rollNumber: string;
  parentId: mongoose.Types.ObjectId;
  busId?: mongoose.Types.ObjectId;
  routeId?: mongoose.Types.ObjectId;
  stopId?: mongoose.Types.ObjectId;
  profileImage?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const StudentSchema: Schema = new Schema({
  name: { type: String, required: true },
  grade: { type: String, required: true },
  section: { type: String, required: true },
  rollNumber: { type: String, required: true },
  parentId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  busId: { type: Schema.Types.ObjectId, ref: 'Bus' },
  routeId: { type: Schema.Types.ObjectId, ref: 'Route' },
  stopId: { type: Schema.Types.ObjectId, ref: 'Stop' },
  profileImage: { type: String },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export const Student = mongoose.model<IStudent>('Student', StudentSchema);

// Bus Interface
export interface IBus extends Document {
  _id: mongoose.Types.ObjectId;
  busNumber: string;
  licensePlate: string;
  capacity: number;
  driverId?: mongoose.Types.ObjectId;
  routeId?: mongoose.Types.ObjectId;
  currentLocation?: {
    latitude: number;
    longitude: number;
    heading?: number;
    speed?: number;
    timestamp: Date;
  };
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const BusSchema: Schema = new Schema({
  busNumber: { type: String, required: true, unique: true },
  licensePlate: { type: String, required: true, unique: true },
  capacity: { type: Number, required: true },
  driverId: { type: Schema.Types.ObjectId, ref: 'User' },
  routeId: { type: Schema.Types.ObjectId, ref: 'Route' },
  currentLocation: {
    latitude: { type: Number },
    longitude: { type: Number },
    heading: { type: Number },
    speed: { type: Number },
    timestamp: { type: Date }
  },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export const Bus = mongoose.model<IBus>('Bus', BusSchema);

// Route Interface
export interface IRoute extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  description?: string;
  stops: mongoose.Types.ObjectId[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const RouteSchema: Schema = new Schema({
  name: { type: String, required: true },
  description: { type: String },
  stops: [{ type: Schema.Types.ObjectId, ref: 'Stop' }],
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export const Route = mongoose.model<IRoute>('Route', RouteSchema);

// Stop Interface
export interface IStop extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  address: string;
  location: {
    latitude: number;
    longitude: number;
  };
  estimatedTime?: string;
  order: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const StopSchema: Schema = new Schema({
  name: { type: String, required: true },
  address: { type: String, required: true },
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  estimatedTime: { type: String },
  order: { type: Number, required: true },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export const Stop = mongoose.model<IStop>('Stop', StopSchema);

// Trip Interface
export interface ITrip extends Document {
  _id: mongoose.Types.ObjectId;
  busId: mongoose.Types.ObjectId;
  driverId: mongoose.Types.ObjectId;
  routeId: mongoose.Types.ObjectId;
  type: 'pickup' | 'drop';
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  startTime?: Date;
  endTime?: Date;
  locationHistory: Array<{
    latitude: number;
    longitude: number;
    timestamp: Date;
  }>;
  studentPickups: Array<{
    studentId: mongoose.Types.ObjectId;
    stopId: mongoose.Types.ObjectId;
    status: 'pending' | 'picked_up' | 'dropped' | 'absent';
    timestamp?: Date;
  }>;
  isLiveStreamActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const TripSchema: Schema = new Schema({
  busId: { type: Schema.Types.ObjectId, ref: 'Bus', required: true },
  driverId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  routeId: { type: Schema.Types.ObjectId, ref: 'Route', required: true },
  type: { type: String, enum: ['pickup', 'drop'], required: true },
  status: { type: String, enum: ['scheduled', 'in_progress', 'completed', 'cancelled'], default: 'scheduled' },
  startTime: { type: Date },
  endTime: { type: Date },
  locationHistory: [{
    latitude: { type: Number },
    longitude: { type: Number },
    timestamp: { type: Date }
  }],
  studentPickups: [{
    studentId: { type: Schema.Types.ObjectId, ref: 'Student' },
    stopId: { type: Schema.Types.ObjectId, ref: 'Stop' },
    status: { type: String, enum: ['pending', 'picked_up', 'dropped', 'absent'], default: 'pending' },
    timestamp: { type: Date }
  }],
  isLiveStreamActive: { type: Boolean, default: false }
}, { timestamps: true });

export const Trip = mongoose.model<ITrip>('Trip', TripSchema);

// Notification Interface
export interface INotification extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  title: string;
  body: string;
  type: 'bus_approaching' | 'pickup_confirmation' | 'drop_confirmation' | 'emergency' | 'general';
  data?: Record<string, any>;
  isRead: boolean;
  createdAt: Date;
}

const NotificationSchema: Schema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  type: { type: String, enum: ['bus_approaching', 'pickup_confirmation', 'drop_confirmation', 'emergency', 'general'], required: true },
  data: { type: Schema.Types.Mixed },
  isRead: { type: Boolean, default: false }
}, { timestamps: true });

export const Notification = mongoose.model<INotification>('Notification', NotificationSchema);

// Emergency Alert Interface
export interface IEmergencyAlert extends Document {
  _id: mongoose.Types.ObjectId;
  tripId: mongoose.Types.ObjectId;
  busId: mongoose.Types.ObjectId;
  driverId: mongoose.Types.ObjectId;
  location: {
    latitude: number;
    longitude: number;
  };
  type: 'panic' | 'accident' | 'breakdown' | 'other';
  description?: string;
  status: 'active' | 'acknowledged' | 'resolved';
  acknowledgedBy?: mongoose.Types.ObjectId;
  resolvedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const EmergencyAlertSchema: Schema = new Schema({
  tripId: { type: Schema.Types.ObjectId, ref: 'Trip', required: true },
  busId: { type: Schema.Types.ObjectId, ref: 'Bus', required: true },
  driverId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  type: { type: String, enum: ['panic', 'accident', 'breakdown', 'other'], required: true },
  description: { type: String },
  status: { type: String, enum: ['active', 'acknowledged', 'resolved'], default: 'active' },
  acknowledgedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  resolvedAt: { type: Date }
}, { timestamps: true });

export const EmergencyAlert = mongoose.model<IEmergencyAlert>('EmergencyAlert', EmergencyAlertSchema);
