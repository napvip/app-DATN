import { useParams, useNavigate } from 'react-router';
import { ArrowLeft, Camera, Battery, Droplets, Thermometer, Scale, Activity, AlertTriangle, Video } from 'lucide-react';
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';
import { Switch } from '../components/ui/switch';
import { Slider } from '../components/ui/slider';

// Mock data
const honeyData = [
  { date: 'Apr 1', weight: 8.2 },
  { date: 'Apr 2', weight: 9.1 },
  { date: 'Apr 3', weight: 10.3 },
  { date: 'Apr 4', weight: 11.2 },
  { date: 'Apr 5', weight: 12.4 },
  { date: 'Apr 6', weight: 13.1 },
  { date: 'Apr 7', weight: 14.5 },
];

const tempData = [
  { time: '00:00', temp: 32 },
  { time: '04:00', temp: 31 },
  { time: '08:00', temp: 33 },
  { time: '12:00', temp: 35 },
  { time: '16:00', temp: 36 },
  { time: '20:00', temp: 34 },
  { time: '23:59', temp: 33 },
];

const attacks = [
  {
    id: 1,
    time: '2 hours ago',
    severity: 'High',
    image: 'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXNwJTIwaW5zZWN0JTIwY2xvc2V1cHxlbnwxfHx8fDE3NzU3MjU3ODB8MA&ixlib=rb-4.1.0&q=80&w=1080',
  },
  {
    id: 2,
    time: 'Yesterday at 3:24 PM',
    severity: 'Medium',
    image: 'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXNwJTIwaW5zZWN0JTIwY2xvc2V1cHxlbnwxfHx8fDE3NzU3MjU3ODB8MA&ixlib=rb-4.1.0&q=80&w=1080',
  },
];

export function HiveDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background max-w-md mx-auto">
      {/* Header */}
      <div className="sticky top-0 bg-background/80 backdrop-blur-xl border-b border-border z-10">
        <div className="flex items-center gap-4 px-6 py-4">
          <button
            onClick={() => navigate('/app')}
            className="text-foreground hover:text-primary transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h2>Hive Alpha</h2>
            <p className="text-sm text-muted-foreground">Live monitoring</p>
          </div>
          <div className="bg-[#16A34A] text-white text-xs px-3 py-1.5 rounded-full">
            Healthy
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        {/* Live Camera */}
        <div className="bg-card rounded-3xl overflow-hidden shadow-sm border border-border">
          <div className="relative aspect-video bg-muted">
            <ImageWithFallback
              src="https://images.unsplash.com/photo-1758522966091-4c7b94b5c3de?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxob25leWNvbWIlMjBiZWVzJTIwY2xvc2V8ZW58MXx8fHwxNzc1NzI1Nzc5fDA&ixlib=rb-4.1.0&q=80&w=1080"
              alt="Live camera feed"
              className="w-full h-full object-cover"
            />
            <div className="absolute top-4 left-4 bg-red-500 text-white px-3 py-1 rounded-full text-xs flex items-center gap-2">
              <div className="w-2 h-2 bg-white rounded-full animate-pulse" />
              LIVE
            </div>
            <div className="absolute bottom-4 right-4">
              <button className="bg-white/90 backdrop-blur-sm text-foreground p-3 rounded-full hover:bg-white transition-colors">
                <Video className="w-5 h-5" />
              </button>
            </div>
          </div>
          <div className="p-4">
            <h4 className="mb-1">Live Camera Feed</h4>
            <p className="text-sm text-muted-foreground">High-resolution monitoring with AI detection</p>
          </div>
        </div>

        {/* Quick Metrics */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-card rounded-2xl p-4 border border-border">
            <div className="flex items-center gap-3 mb-3">
              <div className="bg-primary/10 p-2 rounded-xl">
                <Scale className="w-5 h-5 text-primary" />
              </div>
              <span className="text-sm text-muted-foreground">Honey Weight</span>
            </div>
            <div className="text-2xl">14.5 kg</div>
            <div className="text-xs text-[#16A34A] mt-1">+2.1 kg this week</div>
          </div>

          <div className="bg-card rounded-2xl p-4 border border-border">
            <div className="flex items-center gap-3 mb-3">
              <div className="bg-[#F97316]/10 p-2 rounded-xl">
                <Thermometer className="w-5 h-5 text-[#F97316]" />
              </div>
              <span className="text-sm text-muted-foreground">Temperature</span>
            </div>
            <div className="text-2xl">35°C</div>
            <div className="text-xs text-muted-foreground mt-1">Optimal range</div>
          </div>

          <div className="bg-card rounded-2xl p-4 border border-border">
            <div className="flex items-center gap-3 mb-3">
              <div className="bg-[#3B82F6]/10 p-2 rounded-xl">
                <Droplets className="w-5 h-5 text-[#3B82F6]" />
              </div>
              <span className="text-sm text-muted-foreground">Humidity</span>
            </div>
            <div className="text-2xl">65%</div>
            <div className="text-xs text-muted-foreground mt-1">Normal levels</div>
          </div>

          <div className="bg-card rounded-2xl p-4 border border-border">
            <div className="flex items-center gap-3 mb-3">
              <div className="bg-[#16A34A]/10 p-2 rounded-xl">
                <Battery className="w-5 h-5 text-[#16A34A]" />
              </div>
              <span className="text-sm text-muted-foreground">Device Battery</span>
            </div>
            <div className="text-2xl">87%</div>
            <div className="text-xs text-muted-foreground mt-1">~14 days left</div>
          </div>
        </div>

        {/* AI Prediction Card */}
        <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-transparent rounded-3xl p-6 border border-primary/20">
          <div className="flex items-start gap-4">
            <div className="bg-primary/20 p-3 rounded-2xl">
              <Activity className="w-6 h-6 text-primary" />
            </div>
            <div className="flex-1">
              <h4 className="mb-2">AI Prediction</h4>
              <p className="text-sm text-muted-foreground mb-3">
                Based on current trends, this hive will produce approximately <span className="text-primary font-semibold">18-22 kg</span> of honey this month.
              </p>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <div className="w-2 h-2 bg-[#16A34A] rounded-full" />
                <span>95% confidence</span>
              </div>
            </div>
          </div>
        </div>

        {/* Honey Production Chart */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <h4 className="mb-4">Honey Production Trend</h4>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={honeyData}>
              <defs>
                <linearGradient id="honeyGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#F5B400" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#F5B400" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E5E5" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="#737373" />
              <YAxis tick={{ fontSize: 12 }} stroke="#737373" />
              <Tooltip />
              <Area type="monotone" dataKey="weight" stroke="#F5B400" strokeWidth={3} fill="url(#honeyGradient)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Temperature History */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <h4 className="mb-4">Temperature (24h)</h4>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={tempData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E5E5" />
              <XAxis dataKey="time" tick={{ fontSize: 12 }} stroke="#737373" />
              <YAxis tick={{ fontSize: 12 }} stroke="#737373" />
              <Tooltip />
              <Line type="monotone" dataKey="temp" stroke="#F97316" strokeWidth={3} dot={{ fill: '#F97316', r: 4 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Wasp Attack Timeline */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <div className="flex items-center gap-3 mb-4">
            <AlertTriangle className="w-5 h-5 text-[#DC2626]" />
            <h4>Recent Wasp Detections</h4>
          </div>
          <div className="space-y-4">
            {attacks.map((attack) => (
              <div key={attack.id} className="flex gap-4">
                <div className="w-20 h-20 rounded-2xl overflow-hidden flex-shrink-0">
                  <ImageWithFallback
                    src={attack.image}
                    alt="Wasp detection"
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`px-2 py-1 rounded-full text-xs ${
                      attack.severity === 'High' ? 'bg-[#DC2626] text-white' : 'bg-[#F97316] text-white'
                    }`}>
                      {attack.severity} Risk
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground">{attack.time}</p>
                  <p className="text-sm mt-1">AI detected wasp activity near entrance</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Device Controls */}
        <div className="bg-card rounded-3xl p-6 border border-border space-y-6">
          <h4>Device Controls</h4>
          
          <div className="flex items-center justify-between">
            <div>
              <p>Camera</p>
              <p className="text-sm text-muted-foreground">Live feed streaming</p>
            </div>
            <Switch defaultChecked />
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <p>Alert Sensitivity</p>
              <span className="text-sm text-muted-foreground">High</span>
            </div>
            <Slider defaultValue={[75]} max={100} step={1} />
            <p className="text-xs text-muted-foreground">
              Higher sensitivity means more frequent alerts for potential threats
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
