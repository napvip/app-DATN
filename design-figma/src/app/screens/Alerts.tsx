import { useState } from 'react';
import { Bell, AlertTriangle, Thermometer, WifiOff, BatteryLow, Filter } from 'lucide-react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';

const alerts = [
  {
    id: 1,
    type: 'attack',
    hive: 'Hive Alpha',
    title: 'Wasp Attack Detected',
    description: 'High wasp activity detected near hive entrance',
    time: '2 hours ago',
    severity: 'high',
    image: 'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXNwJTIwaW5zZWN0JTIwY2xvc2V1cHxlbnwxfHx8fDE3NzU3MjU3ODB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    icon: AlertTriangle,
    iconBg: 'bg-[#DC2626]/10',
    iconColor: 'text-[#DC2626]',
    read: false,
  },
  {
    id: 2,
    type: 'temperature',
    hive: 'Hive Beta',
    title: 'Temperature Alert',
    description: 'Temperature exceeded optimal range (38°C)',
    time: '5 hours ago',
    severity: 'medium',
    image: null,
    icon: Thermometer,
    iconBg: 'bg-[#F97316]/10',
    iconColor: 'text-[#F97316]',
    read: false,
  },
  {
    id: 3,
    type: 'offline',
    hive: 'Hive Gamma',
    title: 'Device Offline',
    description: 'Connection lost - last seen 3 hours ago',
    time: '8 hours ago',
    severity: 'high',
    image: null,
    icon: WifiOff,
    iconBg: 'bg-[#DC2626]/10',
    iconColor: 'text-[#DC2626]',
    read: true,
  },
  {
    id: 4,
    type: 'battery',
    hive: 'Hive Delta',
    title: 'Low Battery Warning',
    description: 'Device battery at 15% - charge needed',
    time: 'Yesterday',
    severity: 'low',
    image: null,
    icon: BatteryLow,
    iconBg: 'bg-primary/10',
    iconColor: 'text-primary',
    read: true,
  },
  {
    id: 5,
    type: 'attack',
    hive: 'Hive Alpha',
    title: 'Wasp Activity',
    description: 'Medium wasp activity detected',
    time: 'Yesterday',
    severity: 'medium',
    image: 'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXNwJTIwaW5zZWN0JTIwY2xvc2V1cHxlbnwxfHx8fDE3NzU3MjU3ODB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    icon: AlertTriangle,
    iconBg: 'bg-[#F97316]/10',
    iconColor: 'text-[#F97316]',
    read: true,
  },
];

export function Alerts() {
  const [filter, setFilter] = useState<'all' | 'unread'>('all');
  
  const filteredAlerts = filter === 'unread' ? alerts.filter(a => !a.read) : alerts;
  const unreadCount = alerts.filter(a => !a.read).length;

  return (
    <div className="min-h-screen bg-background max-w-md mx-auto">
      {/* Header */}
      <div className="px-6 pt-12 pb-6">
        <div className="flex items-center justify-between mb-2">
          <h1 className="text-3xl tracking-tight">Alerts</h1>
          <button className="text-muted-foreground hover:text-foreground transition-colors">
            <Filter className="w-5 h-5" />
          </button>
        </div>
        <p className="text-muted-foreground">
          {unreadCount} unread notification{unreadCount !== 1 ? 's' : ''}
        </p>
      </div>

      {/* Filter Tabs */}
      <div className="px-6 mb-6">
        <div className="bg-muted rounded-2xl p-1 inline-flex gap-1">
          <button
            onClick={() => setFilter('all')}
            className={`px-6 py-2 rounded-xl transition-all ${
              filter === 'all'
                ? 'bg-card shadow-sm text-foreground'
                : 'text-muted-foreground'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('unread')}
            className={`px-6 py-2 rounded-xl transition-all ${
              filter === 'unread'
                ? 'bg-card shadow-sm text-foreground'
                : 'text-muted-foreground'
            }`}
          >
            Unread ({unreadCount})
          </button>
        </div>
      </div>

      {/* Alerts List */}
      <div className="px-6 space-y-3 pb-6">
        {filteredAlerts.map((alert) => {
          const Icon = alert.icon;
          
          return (
            <div
              key={alert.id}
              className={`bg-card rounded-3xl p-4 border transition-all active:scale-98 cursor-pointer ${
                alert.read ? 'border-border' : 'border-primary/30 shadow-lg shadow-primary/10'
              }`}
            >
              <div className="flex gap-4">
                {/* Icon or Image */}
                {alert.image ? (
                  <div className="w-16 h-16 rounded-2xl overflow-hidden flex-shrink-0">
                    <ImageWithFallback
                      src={alert.image}
                      alt={alert.title}
                      className="w-full h-full object-cover"
                    />
                  </div>
                ) : (
                  <div className={`w-16 h-16 rounded-2xl ${alert.iconBg} flex items-center justify-center flex-shrink-0`}>
                    <Icon className={`w-7 h-7 ${alert.iconColor}`} />
                  </div>
                )}

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <h4 className="truncate">{alert.title}</h4>
                    {!alert.read && (
                      <div className="w-2 h-2 bg-primary rounded-full flex-shrink-0 mt-2" />
                    )}
                  </div>
                  <p className="text-sm text-muted-foreground mb-2">
                    {alert.description}
                  </p>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground">{alert.hive}</span>
                    <span className="text-xs text-muted-foreground">•</span>
                    <span className="text-xs text-muted-foreground">{alert.time}</span>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Empty State */}
      {filteredAlerts.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 px-6">
          <div className="bg-muted/50 p-6 rounded-full mb-4">
            <Bell className="w-12 h-12 text-muted-foreground" />
          </div>
          <h3 className="mb-2">No unread alerts</h3>
          <p className="text-muted-foreground text-center">
            You're all caught up! We'll notify you of any new activity.
          </p>
        </div>
      )}
    </div>
  );
}
