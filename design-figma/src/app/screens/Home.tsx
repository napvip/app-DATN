import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Search, Plus, QrCode, Cloud, CloudRain, Sun } from 'lucide-react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';
import { motion } from 'motion/react';

// Mock hive data
const hives = [
  {
    id: '1',
    name: 'Hive Alpha',
    status: 'healthy',
    image: 'https://images.unsplash.com/photo-1713705320964-8b8e7f8de9bd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b29kZW4lMjBiZWVoaXZlJTIwYm94ZXN8ZW58MXx8fHwxNzc1NjU2OTM3fDA&ixlib=rb-4.1.0&q=80&w=1080',
    honey: 12.4,
    temperature: 35,
    humidity: 65,
    lastUpdate: '5 min ago'
  },
  {
    id: '2',
    name: 'Hive Beta',
    status: 'warning',
    image: 'https://images.unsplash.com/photo-1569127971771-15d19a5ba26c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVoaXZlJTIwYmVla2VlcGVyJTIwaG9uZXl8ZW58MXx8fHwxNzc1NzI1Nzc4fDA&ixlib=rb-4.1.0&q=80&w=1080',
    honey: 8.2,
    temperature: 38,
    humidity: 72,
    lastUpdate: '12 min ago'
  },
  {
    id: '3',
    name: 'Hive Gamma',
    status: 'attack',
    image: 'https://images.unsplash.com/photo-1758522964459-403b982fb3c2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVoaXZlJTIwZnJhbWVzJTIwaG9uZXl8ZW58MXx8fHwxNzc1NzI1NzgwfDA&ixlib=rb-4.1.0&q=80&w=1080',
    honey: 15.1,
    temperature: 34,
    humidity: 68,
    lastUpdate: '2 min ago'
  },
  {
    id: '4',
    name: 'Hive Delta',
    status: 'healthy',
    image: 'https://images.unsplash.com/photo-1758522966019-01e7b9b39766?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVrZWVwZXIlMjB3b3JraW5nJTIwYXBpYXJ5fGVufDF8fHx8MTc3NTcyNTc3OXww&ixlib=rb-4.1.0&q=80&w=1080',
    honey: 10.8,
    temperature: 36,
    humidity: 63,
    lastUpdate: '8 min ago'
  },
];

const statusConfig = {
  healthy: { color: 'bg-[#16A34A]', text: 'Healthy' },
  warning: { color: 'bg-[#F97316]', text: 'Warning' },
  attack: { color: 'bg-[#DC2626]', text: 'Wasp Attack!' },
};

export function Home() {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="px-6 pt-12 pb-6 space-y-6">
        {/* Greeting */}
        <div>
          <h1 className="text-3xl tracking-tight">Good morning, Alex</h1>
          <p className="text-muted-foreground mt-1">Monitor your beehives</p>
        </div>

        {/* Weather Widget */}
        <div className="bg-gradient-to-br from-primary via-primary to-[#E5A300] rounded-3xl p-6 text-primary-foreground">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Sun className="w-6 h-6" />
                <span className="text-sm opacity-90">Partly Cloudy</span>
              </div>
              <div className="text-5xl mb-1">24°C</div>
              <p className="text-sm opacity-90">Perfect weather for bees</p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-90">Humidity</p>
              <p className="text-2xl">58%</p>
            </div>
          </div>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search hives..."
            className="w-full pl-12 pr-4 py-4 bg-card rounded-2xl border border-border focus:ring-2 focus:ring-primary transition-all outline-none"
          />
        </div>
      </div>

      {/* Hives Grid */}
      <div className="px-6 pb-6">
        <div className="flex items-center justify-between mb-4">
          <h3>Your Hives ({hives.length})</h3>
        </div>

        <div className="grid grid-cols-2 gap-4">
          {hives.map((hive, index) => (
            <motion.div
              key={hive.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => navigate(`/hive/${hive.id}`)}
              className="bg-card rounded-3xl overflow-hidden shadow-sm border border-border active:scale-95 transition-transform cursor-pointer"
            >
              {/* Image */}
              <div className="relative aspect-square">
                <ImageWithFallback
                  src={hive.image}
                  alt={hive.name}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />
                
                {/* Status Badge */}
                <div className={`absolute top-3 right-3 ${statusConfig[hive.status as keyof typeof statusConfig].color} text-white text-xs px-3 py-1.5 rounded-full backdrop-blur-sm`}>
                  {statusConfig[hive.status as keyof typeof statusConfig].text}
                </div>

                {/* Hive Name */}
                <div className="absolute bottom-3 left-3 right-3">
                  <h4 className="text-white">{hive.name}</h4>
                </div>
              </div>

              {/* Metrics */}
              <div className="p-4 space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Honey</span>
                  <span>{hive.honey} kg</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Temp</span>
                  <span>{hive.temperature}°C</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Humidity</span>
                  <span>{hive.humidity}%</span>
                </div>
                <div className="text-xs text-muted-foreground pt-2 border-t border-border">
                  Updated {hive.lastUpdate}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Floating Action Button */}
      <button
        onClick={() => navigate('/add-hive')}
        className="fixed bottom-24 right-6 bg-primary hover:bg-primary/90 text-primary-foreground w-16 h-16 rounded-full shadow-2xl shadow-primary/40 flex items-center justify-center transition-all active:scale-95 z-10"
      >
        <QrCode className="w-7 h-7" />
      </button>
    </div>
  );
}
