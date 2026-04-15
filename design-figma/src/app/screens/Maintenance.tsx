import { useState } from 'react';
import { Calendar, MessageCircle, FileText, Shield, Plus, Check } from 'lucide-react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';

const upcomingServices = [
  {
    id: 1,
    hive: 'Hive Beta',
    type: 'Battery Replacement',
    date: 'Apr 12, 2026',
    time: '10:00 AM',
    technician: 'Mike Johnson',
    status: 'scheduled',
  },
  {
    id: 2,
    hive: 'Hive Delta',
    type: 'Routine Inspection',
    date: 'Apr 15, 2026',
    time: '2:00 PM',
    technician: 'Sarah Williams',
    status: 'scheduled',
  },
];

const serviceHistory = [
  {
    id: 1,
    hive: 'Hive Alpha',
    type: 'Camera Calibration',
    date: 'Apr 5, 2026',
    status: 'completed',
  },
  {
    id: 2,
    hive: 'Hive Gamma',
    type: 'Sensor Maintenance',
    date: 'Apr 2, 2026',
    status: 'completed',
  },
];

export function Maintenance() {
  const [activeTab, setActiveTab] = useState<'upcoming' | 'history'>('upcoming');

  return (
    <div className="min-h-screen bg-background max-w-md mx-auto">
      {/* Header */}
      <div className="px-6 pt-12 pb-6">
        <h1 className="text-3xl tracking-tight mb-2">Maintenance</h1>
        <p className="text-muted-foreground">Manage device servicing & support</p>
      </div>

      {/* Quick Actions */}
      <div className="px-6 mb-6">
        <div className="grid grid-cols-2 gap-4">
          <button className="bg-primary hover:bg-primary/90 text-primary-foreground rounded-2xl p-4 flex flex-col items-start gap-2 transition-all active:scale-95 shadow-lg shadow-primary/20">
            <Calendar className="w-6 h-6" />
            <span className="text-sm">Book Service</span>
          </button>
          <button className="bg-card hover:bg-muted text-foreground border border-border rounded-2xl p-4 flex flex-col items-start gap-2 transition-all active:scale-95">
            <MessageCircle className="w-6 h-6" />
            <span className="text-sm">Live Chat</span>
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-6 mb-6">
        <div className="bg-muted rounded-2xl p-1 inline-flex gap-1 w-full">
          <button
            onClick={() => setActiveTab('upcoming')}
            className={`flex-1 px-6 py-2 rounded-xl transition-all ${
              activeTab === 'upcoming'
                ? 'bg-card shadow-sm text-foreground'
                : 'text-muted-foreground'
            }`}
          >
            Upcoming
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`flex-1 px-6 py-2 rounded-xl transition-all ${
              activeTab === 'history'
                ? 'bg-card shadow-sm text-foreground'
                : 'text-muted-foreground'
            }`}
          >
            History
          </button>
        </div>
      </div>

      <div className="px-6 space-y-4 pb-6">
        {/* Upcoming Services */}
        {activeTab === 'upcoming' && (
          <>
            {upcomingServices.map((service) => (
              <div
                key={service.id}
                className="bg-card rounded-3xl p-5 border border-border space-y-4"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="mb-1">{service.type}</h4>
                    <p className="text-sm text-muted-foreground">{service.hive}</p>
                  </div>
                  <div className="bg-primary/10 text-primary text-xs px-3 py-1.5 rounded-full">
                    Scheduled
                  </div>
                </div>

                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-3">
                    <Calendar className="w-4 h-4 text-muted-foreground" />
                    <span>{service.date} at {service.time}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <Shield className="w-4 h-4 text-muted-foreground" />
                    <span>Technician: {service.technician}</span>
                  </div>
                </div>

                <div className="flex gap-3 pt-2">
                  <button className="flex-1 bg-muted hover:bg-muted/80 text-foreground py-2 rounded-xl transition-colors text-sm">
                    Reschedule
                  </button>
                  <button className="flex-1 border border-border hover:bg-muted text-foreground py-2 rounded-xl transition-colors text-sm">
                    Cancel
                  </button>
                </div>
              </div>
            ))}

            {upcomingServices.length === 0 && (
              <div className="text-center py-12">
                <div className="bg-muted/50 p-6 rounded-full w-fit mx-auto mb-4">
                  <Calendar className="w-8 h-8 text-muted-foreground" />
                </div>
                <h4 className="mb-2">No upcoming services</h4>
                <p className="text-muted-foreground text-sm">
                  Schedule maintenance to keep your devices running smoothly
                </p>
              </div>
            )}
          </>
        )}

        {/* Service History */}
        {activeTab === 'history' && (
          <>
            {serviceHistory.map((service) => (
              <div
                key={service.id}
                className="bg-card rounded-3xl p-5 border border-border"
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h4 className="mb-1">{service.type}</h4>
                    <p className="text-sm text-muted-foreground">{service.hive}</p>
                  </div>
                  <div className="bg-[#16A34A]/10 text-[#16A34A] p-2 rounded-full">
                    <Check className="w-4 h-4" />
                  </div>
                </div>
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Calendar className="w-4 h-4" />
                  <span>{service.date}</span>
                </div>
              </div>
            ))}
          </>
        )}

        {/* Resources */}
        <div className="bg-card rounded-3xl p-6 border border-border mt-8">
          <h4 className="mb-4">Resources & Support</h4>
          <div className="space-y-3">
            <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-muted transition-colors">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-muted-foreground" />
                <span className="text-sm">Troubleshooting Guide</span>
              </div>
              <span className="text-muted-foreground">→</span>
            </button>
            <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-muted transition-colors">
              <div className="flex items-center gap-3">
                <Shield className="w-5 h-5 text-muted-foreground" />
                <span className="text-sm">Warranty Information</span>
              </div>
              <span className="text-muted-foreground">→</span>
            </button>
            <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-muted transition-colors">
              <div className="flex items-center gap-3">
                <MessageCircle className="w-5 h-5 text-muted-foreground" />
                <span className="text-sm">Contact Support</span>
              </div>
              <span className="text-muted-foreground">→</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
